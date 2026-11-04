local players = game:GetService("Players")
local replicatedstorage = game:GetService("ReplicatedStorage")
local serverstorage = game:GetService("ServerStorage")
local server = script.Parent.Parent
local config = require(server.Config)
local quests = require(replicatedstorage:WaitForChild("Quests"))
local questupdate = replicatedstorage:WaitForChild("Remotes"):WaitForChild("QuestUpdate")
local effectmodule = require(replicatedstorage:WaitForChild("Effect"))
local activequests = {}
local serverdata
local util

local function commas(amount)
	local text = tostring(math.floor(amount))
	local formatted = text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (formatted:gsub("^,", ""))
end

local function requiredexp(level)
	return math.ceil(2 * level ^ 2.3 + 84)
end

local function awardexp(player, amount)
	local level = serverdata.Get(player, "Level")
	local exp = serverdata.Get(player, "Exp")
	if type(level) ~= "number" or type(exp) ~= "number" then
		return 0
	end
	local previouslevel = level
	local awarded = math.max(0, math.floor(amount))
	exp += awarded
	local points = serverdata.Get(player, "Points") or 0
	while level < config.MaxLevel do
		local needed = requiredexp(level)
		if exp < needed then
			break
		end
		exp -= needed
		level += 1
		points += config.PointsPerLevel
	end
	serverdata.Set(player, "Exp", exp)
	if level ~= previouslevel then
		serverdata.Set(player, "Level", level)
		serverdata.Set(player, "Points", points)
		serverdata.Notify(player, "<Color=Green>LEVEL UP!<Color=/> (" .. tostring(level) .. ")")
		pcall(serverdata.RefreshCharacter, player)
		local restoreonlevel = player.Character
		local restorehumanoid = restoreonlevel and restoreonlevel:FindFirstChildOfClass("Humanoid")
		if restorehumanoid and restorehumanoid.Health > 0 and restoreonlevel:GetAttribute("InCombat") ~= true then
			restorehumanoid.Health = restorehumanoid.MaxHealth
			local energy = restoreonlevel:FindFirstChild("Energy")
			if energy then
				energy.Value = energy.MaxValue
			end
		end
		pcall(function()
			require(replicatedstorage.Util.LevelCap).replicateLevelCap(player)
		end)
		local character = player.Character
		if character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChildOfClass("Humanoid") then
			pcall(function()
				effectmodule.new("LevelUp"):replicate({ { Character = character } })
			end)
		end
	end
	return awarded
end

local function award(player, exp, beli)
	if not player or not player:IsA("Player") or not serverdata.IsReady(player) then
		return
	end
	if type(beli) == "number" and beli >= 1 then
		serverdata.Increment(player, "Beli", math.floor(beli))
		serverdata.Notify(player, "Earned <Color=Green>$" .. commas(beli) .. "<Color=/>")
	end
	if type(exp) == "number" and exp >= 1 then
		local awarded = awardexp(player, exp)
		if awarded > 0 then
			serverdata.Notify(player, "Earned <Color=Cyan>" .. commas(awarded) .. " Exp.<Color=/>")
		end
	end
end

local function sendstate(player, state, context)
	questupdate:FireClient(player, state, context)
end

local function makepayload(state)
	return {
		InternalQuestName = state.questname,
		Info = {
			Job = true,
			Name = state.definition.Name,
			Task = state.definition.Task,
		},
		Progress = {
			[state.target] = state.killed,
		},
		Reward = state.definition.Reward,
		Target = state.target,
		Killed = state.killed,
		Required = state.required,
		RewardExp = state.definition.Reward.Exp or 0,
		RewardBeli = state.definition.Reward.Beli or 0,
	}
end

local function startquest(player, questname, questindex)
	if type(questname) ~= "string" or not util.isInteger(questindex) then
		return 1
	end
	local group = quests[questname]
	local definition = group and group[questindex]
	if not definition then
		return 1
	end
	local level = serverdata.Get(player, "Level") or 1
	if level < (definition.LevelReq or 0) then
		return definition.LevelReq
	end
	local target, required = next(definition.Task)
	if type(target) ~= "string" or type(required) ~= "number" or required < 1 then
		return 1
	end
	local state = {
		questname = questname,
		questindex = questindex,
		definition = definition,
		target = target,
		required = required,
		killed = 0,
	}
	activequests[player] = state
	sendstate(player, makepayload(state), { Context = "Start", InternalQuestName = questname, Name = definition.Name })
	return 0
end

local function abandonquest(player)
	local state = activequests[player]
	if not state then
		return false
	end
	activequests[player] = nil
	sendstate(player, nil, { Context = "Abandon", InternalQuestName = state.questname, Name = state.definition.Name })
	return true
end

local function onenemykilled(killer, model, enemyname, level)
	if not killer or not killer:IsA("Player") or not serverdata.IsReady(killer) then
		return
	end
	local isboss = model and model:GetAttribute("IsBoss") == true
	local multiplier = isboss and 4 or 1
	local rewardexp = model and model:GetAttribute("RewardExp")
	local rewardbeli = model and model:GetAttribute("RewardBeli")
	rewardexp = type(rewardexp) == "number" and rewardexp or math.max(10, math.floor((level or 1) * 8))
	rewardbeli = type(rewardbeli) == "number" and rewardbeli or math.max(5, math.floor((level or 1) * 8))
	award(killer, rewardexp * multiplier, rewardbeli * multiplier)

	local state = activequests[killer]
	if not state or state.target ~= enemyname then
		return
	end
	state.killed += 1
	if state.killed >= state.required then
		activequests[killer] = nil
		local reward = state.definition.Reward
		award(killer, reward.Exp or 0, reward.Beli or 0)
		local payload = makepayload(state)
		payload.Killed = state.required
		payload.Completed = true
		sendstate(killer, payload, {
			Context = "Complete",
			InternalQuestName = state.questname,
			Name = state.definition.Name,
		})
		return
	end
	sendstate(killer, makepayload(state), { Context = "Update", InternalQuestName = state.questname, Name = state.definition.Name })
end

return function(router, data)
	serverdata = data
	util = require(server.Util)
	router.commF("StartQuest", startquest, { rate = 2, burst = 4 })
	router.commF("AbandonQuest", abandonquest, { rate = 2, burst = 4 })
	local events = serverstorage:WaitForChild("hitboxevents", 30)
	local enemykilled = events and events:WaitForChild("enemykilled", 30)
	if enemykilled and enemykilled:IsA("BindableEvent") then
		enemykilled.Event:Connect(onenemykilled)
	end
	players.PlayerRemoving:Connect(function(player)
		activequests[player] = nil
	end)
end