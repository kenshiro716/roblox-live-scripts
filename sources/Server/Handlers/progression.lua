local players = game:GetService("Players")
local replicatedstorage = game:GetService("ReplicatedStorage")

local tracked = setmetatable({}, { __mode = "k" })
local zonecache = {}
local zonestamp = 0

local function commevent()
	local remotes = replicatedstorage:FindFirstChild("Remotes")
	return remotes and remotes:FindFirstChild("CommE")
end

local function zones()
	if os.clock() - zonestamp < 5 then
		return zonecache
	end
	zonestamp = os.clock()
	table.clear(zonecache)
	local origin = workspace:FindFirstChild("_WorldOrigin")
	local folder = origin and origin:FindFirstChild("SafeZones")
	if not folder then
		return zonecache
	end
	for _, part in ipairs(folder:GetChildren()) do
		if part:IsA("BasePart") then
			local mesh = part:FindFirstChildOfClass("SpecialMesh")
			local radius = mesh and mesh.Scale.X / 2 or math.max(part.Size.X, part.Size.Z) / 2
			table.insert(zonecache, { position = part.Position, radius = radius })
		end
	end
	return zonecache
end

local function insafezone(position)
	for _, zone in ipairs(zones()) do
		if (position - zone.position).Magnitude <= zone.radius then
			return true
		end
	end
	return false
end

local function updatezone(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local inside = root ~= nil and insafezone(root.Position)
	if player:GetAttribute("InSafeZone") ~= inside then
		player:SetAttribute("InSafeZone", inside)
		local remote = commevent()
		if remote then
			remote:FireClient(player, "SafeZone")
		end
	end
	if character and character:GetAttribute("InSafeZone") ~= inside then
		character:SetAttribute("InSafeZone", inside)
	end
end

local function masterystore(serverdata, player)
	local extra = serverdata.GetExtra(player)
	if not extra then
		return nil
	end
	if type(extra.Mastery) ~= "table" then
		extra.Mastery = {}
	end
	return extra.Mastery
end

local function trackmastery(serverdata, player, tool)
	if not tool:IsA("Tool") or tracked[tool] then
		return
	end
	local level = tool:FindFirstChild("Level")
	if not level or not level:IsA("IntValue") then
		return
	end
	if not serverdata.WaitReady(player, 30) then
		return
	end
	local store = masterystore(serverdata, player)
	if not store or tracked[tool] then
		return
	end
	tracked[tool] = true
	local exp = tool:FindFirstChild("Exp")
	local saved = store[tool.Name]
	if type(saved) == "table" and type(saved.Level) == "number" then
		local value = math.max(saved.Level, 1)
		level.Value = value
		if tool:GetAttribute("Level") ~= nil or value > 1 then
			tool:SetAttribute("Level", value)
		end
		if exp and exp:IsA("IntValue") and type(saved.Exp) == "number" then
			exp.Value = saved.Exp
		end
	end
	local function write()
		local current = masterystore(serverdata, player)
		if not current then
			return
		end
		local entry = current[tool.Name]
		if type(entry) ~= "table" then
			entry = {}
			current[tool.Name] = entry
		end
		entry.Level = math.max(level.Value, tool:GetAttribute("Level") or 0)
		entry.Exp = exp and exp:IsA("IntValue") and exp.Value or 0
	end
	write()
	level.Changed:Connect(write)
	tool:GetAttributeChangedSignal("Level"):Connect(function()
		local value = tool:GetAttribute("Level")
		if type(value) == "number" and level.Value ~= value then
			level.Value = value
		end
		write()
	end)
	if exp and exp:IsA("IntValue") then
		exp.Changed:Connect(write)
	end
end

local function watchcontainer(serverdata, player, container)
	container.ChildAdded:Connect(function(child)
		task.spawn(trackmastery, serverdata, player, child)
	end)
	for _, child in ipairs(container:GetChildren()) do
		task.spawn(trackmastery, serverdata, player, child)
	end
end

local function onplayer(serverdata, player)
	player.ChildAdded:Connect(function(child)
		if child:IsA("Backpack") then
			watchcontainer(serverdata, player, child)
		end
	end)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack then
		watchcontainer(serverdata, player, backpack)
	end
	player.CharacterAdded:Connect(function(character)
		watchcontainer(serverdata, player, character)
	end)
	if player.Character then
		watchcontainer(serverdata, player, player.Character)
	end
end

return function(_, serverdata)
	players.PlayerAdded:Connect(function(player)
		onplayer(serverdata, player)
	end)
	for _, player in ipairs(players:GetPlayers()) do
		task.spawn(onplayer, serverdata, player)
	end
	task.spawn(function()
		while true do
			for _, player in ipairs(players:GetPlayers()) do
				pcall(updatezone, player)
			end
			task.wait(0.5)
		end
	end)
end
