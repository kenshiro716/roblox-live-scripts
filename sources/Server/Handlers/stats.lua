local players = game:GetService("Players")
local serverstorage = game:GetService("ServerStorage")

local server = script.Parent.Parent
local config = require(server.Config)

local statnames = { "Melee", "Defense", "Sword", "Gun", "Demon Fruit" }
local racechances = {
	{ "Human", 62.5 },
	{ "Mink", 12.5 },
	{ "Fishman", 12.5 },
	{ "Skypiea", 12.5 },
}
local random = Random.new()

local serverdata

local function datafolder(player)
	return player:FindFirstChild("Data")
end

local function statlevel(player, name)
	local data = datafolder(player)
	local stats = data and data:FindFirstChild("Stats")
	local stat = stats and stats:FindFirstChild(name)
	return stat and stat:FindFirstChild("Level")
end

local function levelcap(player)
	local cap = player:GetAttribute("LevelCap")
	if type(cap) ~= "number" then
		cap = config.StatCap
	end
	return math.min(cap, config.StatCap)
end

local function addpoint(player, statname, amount)
	if type(statname) ~= "string" or not table.find(statnames, statname) then
		return false
	end
	amount = tonumber(amount)
	if not amount or amount < 1 or amount % 1 ~= 0 then
		return false
	end
	local level = statlevel(player, statname)
	local points = datafolder(player) and datafolder(player):FindFirstChild("Points")
	if not level or not points then
		return false
	end
	amount = math.min(amount, points.Value, levelcap(player) - level.Value)
	if amount <= 0 then
		if level.Value >= levelcap(player) then
			serverdata.Notify(player, "<Color=Red>This stat is already maxed!<Color=/>")
		end
		return false
	end
	level.Value += amount
	points.Value -= amount
	serverdata.RefreshCharacter(player)
	return true
end

local function refund(player)
	local data = datafolder(player)
	local refunds = data and data:FindFirstChild("StatRefunds")
	local points = data and data:FindFirstChild("Points")
	if not refunds or not points then
		return false
	end
	if refunds.Value <= 0 then
		serverdata.Notify(player, "<Color=Red>You don't have any Stat Refunds.<Color=/>")
		return false
	end
	local returned = 0
	for _, name in ipairs(statnames) do
		local level = statlevel(player, name)
		if level and level.Value > 1 then
			returned += level.Value - 1
			level.Value = 1
		end
	end
	refunds.Value -= 1
	points.Value += returned
	serverdata.RefreshCharacter(player)
	serverdata.Notify(player, "Your stats have been reset! <Color=Green>" .. tostring(returned) .. "<Color=/> points refunded.")
	return true
end

local function rollrace(current)
	for _ = 1, 20 do
		local roll = random:NextNumber(0, 100)
		local total = 0
		for _, entry in ipairs(racechances) do
			total += entry[2]
			if roll <= total then
				if entry[1] ~= current then
					return entry[1]
				end
				break
			end
		end
	end
	for _, entry in ipairs(racechances) do
		if entry[1] ~= current then
			return entry[1]
		end
	end
	return "Human"
end

local function reroll(player)
	local data = datafolder(player)
	local rerolls = data and data:FindFirstChild("RaceRerolls")
	local race = data and data:FindFirstChild("Race")
	if not rerolls or not race then
		return false
	end
	if rerolls.Value <= 0 then
		serverdata.Notify(player, "<Color=Red>You don't have any Race Rerolls.<Color=/>")
		return false
	end
	local character = player.Character
	if character and character:GetAttribute("InCombat") == true then
		serverdata.Notify(player, "<Color=Red>You cannot do this while in combat.<Color=/>")
		return false
	end
	local newrace = rollrace(race.Value)
	rerolls.Value -= 1
	race.Value = newrace
	for _, name in ipairs({ "A", "B", "C" }) do
		local value = race:FindFirstChild(name)
		if value and value:IsA("IntValue") then
			value.Value = 0
		end
	end
	local evolved = race:FindFirstChild("Evolved")
	if evolved then
		evolved:Destroy()
	end
	serverdata.Notify(player, "You are now a <Color=Green>" .. newrace .. "<Color=/>!")
	task.defer(serverdata.Spawn, player)
	return newrace
end

local function onplayer(player)
	if not serverdata.WaitReady(player, 30) then
		return
	end
	for _, name in ipairs(statnames) do
		local level = statlevel(player, name)
		if level and level.Value < 1 then
			level.Value = 1
		end
	end
end

return function(router, data)
	serverdata = data
	router.commF("AddPoint", addpoint, { rate = 10, burst = 20 })
	router.commF("redeemRefundPoints", refund, { rate = 1, burst = 2 })
	router.commF("RerollRace", reroll, { rate = 1, burst = 2 })
	players.PlayerAdded:Connect(onplayer)
	for _, player in ipairs(players:GetPlayers()) do
		task.spawn(onplayer, player)
	end
end
