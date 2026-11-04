local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Teams = game:GetService("Teams")

local Server = script.Parent
local Config = require(Server.Config)
local Util = require(Server.Util)
local PlayerStore = require(Server.PlayerStore)
local ServerSignals = require(ServerStorage.ServerSignals)
local statscaling = require(ServerStorage:WaitForChild("statscaling"))

local ServerData = {}

local states = {}
local characterStates = {}
local spawning = {}

_G.session = _G.session or {}

local function defaultExtra()
	return { Inventory = {}, Fruits = {}, Fish = {}, Unlockables = {}, Titles = {}, Settings = {}, Flags = {}, Quest = {}, BonusMoments = {}, CompletedMaps = {}, AuraExp = 0 }
end

local function newValue(parent, className, name, value)
	local instance = Instance.new(className)
	instance.Name = name
	if value ~= nil then
		instance.Value = value
	end
	instance.Parent = parent
	return instance
end

local function newFolder(parent, className, name)
	local instance = Instance.new(className)
	instance.Name = name
	instance.Parent = parent
	return instance
end

local function buildFallbackTemplate()
	local container = Instance.new("Folder")
	local data = newFolder(container, "Folder", "Data")
	newValue(data, "IntValue", "Beli", 0)
	newValue(data, "StringValue", "CrewID", "")
	newValue(data, "StringValue", "DevilFruit", "")
	newValue(data, "IntValue", "Exp", 0)
	newValue(data, "IntValue", "Fragments", 0)
	newValue(data, "IntValue", "FruitCap", 1)
	newValue(data, "StringValue", "LastSpawnPoint", Config.DefaultSpawnName)
	newValue(data, "IntValue", "Level", 1)
	newValue(data, "IntValue", "Points", 3)
	local race = newValue(data, "StringValue", "Race", "Human")
	newValue(race, "IntValue", "A", 0)
	newValue(race, "IntValue", "B", 0)
	newValue(race, "IntValue", "C", 0)
	newValue(data, "IntValue", "RaceRerolls", 0)
	newValue(data, "IntValue", "SeaEventsCleared", 0)
	newValue(data, "StringValue", "SpawnPoint", Config.DefaultSpawnName)
	newValue(data, "IntValue", "StatRefunds", 0)
	newValue(data, "StringValue", "Subclass", "")
	newValue(data, "IntValue", "Valor", 0)
	local stats = newFolder(data, "Folder", "Stats")
	local stars = newFolder(data, "Folder", "Stars")
	for _, name in ipairs(Config.StatNames) do
		local stat = newFolder(stats, "Folder", name)
		newValue(stat, "IntValue", "Exp", 0)
		newValue(stat, "IntValue", "Level", 0)
		newValue(stat, "IntValue", "Original", 0)
	end
	for _, name in ipairs({ "Gun", "Sword", "Melee", "Blox Fruit", "Max" }) do
		newValue(stars, "IntValue", name, 1)
	end
	newValue(container, "BoolValue", "DataLoaded", false)
	newFolder(container, "ObjectValue", "LocationTag")
	local leaderstats = newValue(container, "IntValue", "leaderstats", 0)
	newValue(leaderstats, "IntValue", "Bounty/Honor", 0)
	return container
end

local function findTemplate()
	local stored = ServerStorage:FindFirstChild("PlayerData")
	local template = stored and stored:FindFirstChild(Config.TemplateFolderName)
	if template and #template:GetChildren() > 0 then
		return template
	end
	local host = ServerScriptService:FindFirstChild(Config.TemplateHostName)
	template = host and host:FindFirstChild(Config.TemplateFolderName)
	if template and #template:GetChildren() > 0 then
		return template
	end
	return nil
end

local function instantiateTemplate()
	local template = findTemplate()
	if not template then
		return buildFallbackTemplate()
	end
	local container = Instance.new("Folder")
	for _, child in ipairs(template:GetChildren()) do
		child:Clone().Parent = container
	end
	return container
end

local function getCharactersFolder()
	local folder = workspace:FindFirstChild("Characters")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Characters"
		folder.Parent = workspace
	end
	return folder
end

local function dataFolder(player)
	return player:FindFirstChild("Data")
end

function ServerData.GetValueObject(player, name)
	local folder = dataFolder(player)
	return folder and folder:FindFirstChild(name) or nil
end

function ServerData.Get(player, name)
	local object = ServerData.GetValueObject(player, name)
	if object and object:IsA("ValueBase") then
		return object.Value
	end
	return nil
end

function ServerData.Set(player, name, value)
	local object = ServerData.GetValueObject(player, name)
	if object and object:IsA("ValueBase") and typeof(object.Value) == typeof(value) then
		object.Value = value
		return true
	end
	return false
end

function ServerData.Increment(player, name, delta)
	local current = ServerData.Get(player, name)
	if type(current) ~= "number" or not Util.isNumber(delta) then
		return nil
	end
	ServerData.Set(player, name, current + delta)
	return current + delta
end

function ServerData.GetStat(player, statName)
	local folder = dataFolder(player)
	local stats = folder and folder:FindFirstChild("Stats")
	local stat = stats and stats:FindFirstChild(statName)
	local level = stat and stat:FindFirstChild("Level")
	return level and level.Value or 0
end

function ServerData.GetExtra(player)
	local state = states[player]
	return state and state.extra or nil
end

function ServerData.GetState(player)
	return states[player]
end

function ServerData.IsReady(player)
	local state = states[player]
	return state ~= nil and state.ready == true
end

function ServerData.WaitReady(player, timeout)
	local deadline = os.clock() + (timeout or 20)
	while player.Parent and not ServerData.IsReady(player) and os.clock() < deadline do
		task.wait(0.1)
	end
	return ServerData.IsReady(player)
end

function ServerData.Notify(player, message)
	if type(message) ~= "string" or not player.Parent then
		return
	end
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local remote = remotes and remotes:FindFirstChild("CommE")
	if remote then
		remote:FireClient(player, "Notify", message)
	end
end

function ServerData.SetPlayerAttribute(player, name, value)
	player:SetAttribute(name, value)
end

function ServerData.SetCharacterAttribute(player, name, value)
	local character = Util.getCharacter(player)
	if character then
		character:SetAttribute(name, value)
	end
end

function ServerData.ApplyCharacterAttributes(character, overrides)
	for name, value in pairs(Config.CharacterAttributes) do
		character:SetAttribute(name, value)
	end
	if overrides then
		for name, value in pairs(overrides) do
			character:SetAttribute(name, value)
		end
	end
end

local function teamNameOf(player)
	return player.Team and player.Team.Name or nil
end

local function spawnsFolder(teamName)
	local origin = workspace:FindFirstChild("_WorldOrigin")
	local spawns = origin and origin:FindFirstChild("PlayerSpawns")
	return spawns and teamName and spawns:FindFirstChild(teamName) or nil
end

local function spawnParts(model)
	local parts = {}
	if model:IsA("BasePart") then
		table.insert(parts, model)
	else
		for _, child in ipairs(model:GetChildren()) do
			if child:IsA("BasePart") then
				table.insert(parts, child)
			end
		end
	end
	return parts
end

local function cframeFromSpawn(model)
	local parts = spawnParts(model)
	if #parts > 0 then
		local part = parts[math.random(#parts)]
		return part.CFrame + Vector3.new(0, part.Size.Y / 2 + Config.SpawnHeightOffset, 0)
	end
	local ok, pivot = pcall(function()
		return model:GetPivot()
	end)
	if ok then
		return pivot + Vector3.new(0, Config.SpawnHeightOffset, 0)
	end
	return nil
end

function ServerData.GetSpawnModel(player, name)
	local folder = spawnsFolder(teamNameOf(player))
	if not folder then
		return nil
	end
	local model = nil
	if type(name) == "string" and name ~= "" then
		model = folder:FindFirstChild(name)
	end
	if not model then
		model = folder:FindFirstChild(Config.DefaultSpawnName) or folder:GetChildren()[1]
	end
	return model
end

function ServerData.GetSpawnCFrame(player)
	local chosen = ServerData.Get(player, "SpawnPoint")
	if type(chosen) ~= "string" or chosen == "" then
		chosen = ServerData.Get(player, "LastSpawnPoint")
	end
	local model = ServerData.GetSpawnModel(player, chosen)
	local cframe = model and cframeFromSpawn(model) or nil
	return cframe or CFrame.new(0, 60, 0), model
end

local function focalPoint(player)
	local folder = spawnsFolder(teamNameOf(player))
	local default = folder and folder:FindFirstChild(Config.DefaultSpawnName)
	local parts = default and spawnParts(default) or {}
	return parts[1] and parts[1].Position or nil
end

local function validateSpawnTarget(player, name)
	if type(name) ~= "string" or #name == 0 or #name > 64 then
		return nil
	end
	local folder = spawnsFolder(teamNameOf(player))
	local model = folder and folder:FindFirstChild(name)
	if not model then
		return nil
	end
	local root = Util.getRoot(player)
	if root then
		local ok, pivot = pcall(function()
			return model:GetPivot()
		end)
		if ok and (root.Position - pivot.Position).Magnitude > Config.SpawnPointMaxDistance then
			return nil
		end
	end
	return model
end

function ServerData.SetLastSpawnPoint(player, name)
	local model = validateSpawnTarget(player, name)
	if not model then
		return false
	end
	return ServerData.Set(player, "LastSpawnPoint", model.Name)
end

function ServerData.SetSpawnPoint(player)
	local last = ServerData.Get(player, "LastSpawnPoint")
	local model = validateSpawnTarget(player, last)
	if not model then
		return false
	end
	ServerData.Set(player, "SpawnPoint", model.Name)
	return true
end

function ServerData.TeleportToSpawn(player)
	local state = states[player]
	if not state or not Util.isAlive(player) then
		return nil
	end
	local character = player.Character
	if character:GetAttribute("InCombat") == true then
		ServerData.Notify(player, "You cannot do this while in combat.")
		return nil
	end
	local now = workspace:GetServerTimeNow()
	if state.nextHome and now < state.nextHome then
		return state.nextHome
	end
	local readyAt = now + Config.HomeTeleportDelay
	state.nextHome = readyAt + Config.HomeTeleportCooldown
	task.delay(Config.HomeTeleportDelay, function()
		if player.Parent and player.Character == character and Util.isAlive(player) then
			local cframe = ServerData.GetSpawnCFrame(player)
			character:PivotTo(cframe)
		end
	end)
	return readyAt
end

function ServerData.EnablePvp(player)
	if player:GetAttribute("PvpDisabled") == false then
		return false
	end
	player:SetAttribute("PvpDisabled", false)
	local character = Util.getCharacter(player)
	if character then
		character:SetAttribute("PvpDisabled", false)
	end
	return true
end

local function healthMaxFor(player)
	return math.floor(statscaling.health(player))
end

local function energyMaxFor(player)
	return math.floor(statscaling.energy(player))
end

function ServerData.RefreshCharacter(player)
	local character = Util.getCharacter(player)
	local characterState = character and characterStates[character]
	if not characterState then
		return
	end
	local humanoid = characterState.humanoid
	local ratio = humanoid.Health / math.max(humanoid.MaxHealth, 1)
	local maxHealth = healthMaxFor(player)
	humanoid.MaxHealth = maxHealth
	humanoid.Health = math.max(1, maxHealth * ratio)
	local maxEnergy = energyMaxFor(player)
	characterState.energy.MaxValue = maxEnergy
end

function ServerData.AddPoint(player, statName, amount)
	if type(statName) ~= "string" or not Util.isInteger(amount) or amount < 1 then
		return false
	end
	local folder = dataFolder(player)
	local stats = folder and folder:FindFirstChild("Stats")
	local stat = stats and stats:FindFirstChild(statName)
	local level = stat and stat:FindFirstChild("Level")
	local points = folder and folder:FindFirstChild("Points")
	if not level or not points then
		return false
	end
	amount = math.min(amount, points.Value, Config.StatCap - level.Value)
	if amount <= 0 then
		return false
	end
	level.Value += amount
	points.Value -= amount
	ServerData.RefreshCharacter(player)
	return true
end

function ServerData.SpendEnergy(player, amount)
	local character = Util.getCharacter(player)
	local characterState = character and characterStates[character]
	if not characterState or not Util.isNumber(amount) or amount < 0 then
		return false
	end
	if characterState.energy.Value < amount then
		return false
	end
	characterState.energy.Value = math.max(0, characterState.energy.Value - math.ceil(amount))
	return true
end

function ServerData.GetCharacterState(player)
	local character = Util.getCharacter(player)
	return character and characterStates[character] or nil
end

local buttonprops = { Position = true, Scale = true }

local function buttoncustomization(extra)
	local stored = extra.Settings.MobileButtonCustomization
	if type(stored) ~= "table" then
		stored = { Position = {}, Scale = {} }
		extra.Settings.MobileButtonCustomization = stored
	end
	stored.Position = type(stored.Position) == "table" and stored.Position or {}
	stored.Scale = type(stored.Scale) == "table" and stored.Scale or {}
	return stored
end

local function changebuttoncustomization(extra, change)
	if type(change) ~= "table" then
		return false
	end
	if change.Prop == "Reset" then
		extra.Settings.MobileButtonCustomization = { Position = {}, Scale = {} }
		return true
	end
	if not buttonprops[change.Prop] or type(change.ButtonName) ~= "string" or #change.ButtonName > 64 then
		return false
	end
	local value = change.Value
	if change.Prop == "Scale" then
		if not Util.isNumber(value) then
			return false
		end
		value = math.clamp(value, 0.25, 4)
	else
		if type(value) ~= "table" or not Util.isNumber(value.X) or not Util.isNumber(value.Y) then
			return false
		end
		value = { X = math.clamp(value.X, -2, 2), Y = math.clamp(value.Y, -2, 2) }
	end
	buttoncustomization(extra)[change.Prop][change.ButtonName] = value
	return true
end

function ServerData.GetSetting(player, name, prop)
	local extra = ServerData.GetExtra(player)
	if not extra or type(name) ~= "string" then
		return nil
	end
	if name == "MobileButtonCustomization" then
		local stored = buttoncustomization(extra)
		if buttonprops[prop] then
			return table.clone(stored[prop])
		end
		return { Position = table.clone(stored.Position), Scale = table.clone(stored.Scale) }
	end
	local value = extra.Settings[name]
	if value == nil then
		return Config.DefaultSettings[name]
	end
	return value
end

function ServerData.ChangeSetting(player, name, value)
	local extra = ServerData.GetExtra(player)
	if not extra or type(name) ~= "string" then
		return false
	end
	if name == "MobileButtonCustomization" then
		return changebuttoncustomization(extra, value)
	end
	local default = Config.DefaultSettings[name]
	if default == nil or type(value) ~= type(default) then
		return false
	end
	extra.Settings[name] = value
	return true
end

local function setupCharacter(player, character)
	if not ServerData.WaitReady(player, 30) then
		return
	end
	if not player.Parent or player.Character ~= character then
		return
	end
	local deadline = os.clock() + 10
	while not character:IsDescendantOf(workspace) and player.Character == character and os.clock() < deadline do
		task.wait()
	end
	if player.Character ~= character or not character:IsDescendantOf(workspace) then
		return
	end
	character.Parent = getCharactersFolder()
	local humanoid = character:WaitForChild("Humanoid", 10)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not humanoid or not root or not character.Parent then
		return
	end
	humanoid.AutomaticScalingEnabled = true
	local cframe = ServerData.GetSpawnCFrame(player)
	character:PivotTo(cframe)
	local maxHealth = healthMaxFor(player)
	humanoid.MaxHealth = maxHealth
	humanoid.Health = maxHealth
	local busy = newValue(character, "BoolValue", "Busy", false)
	local stun = newValue(character, "NumberValue", "Stun", 0)
	newValue(character, "NumberValue", "Rage", 0)
	local maxEnergy = energyMaxFor(player)
	local energy = Instance.new("IntConstrainedValue")
	energy.Name = "Energy"
	energy.MinValue = 0
	energy.MaxValue = maxEnergy
	energy.Value = maxEnergy
	energy.Parent = character
	ServerData.ApplyCharacterAttributes(character)
	local pvp = player:GetAttribute("PvpDisabled")
	character:SetAttribute("PvpDisabled", pvp == nil and true or pvp)
	root:SetAttribute("DoneSpawning", true)
	local focal = focalPoint(player)
	if focal then
		player:SetAttribute("FocalSpawnPoint", focal)
	end
	characterStates[character] = {
		player = player,
		character = character,
		humanoid = humanoid,
		root = root,
		energy = energy,
		busy = busy,
		stun = stun,
		regen = 0,
		lastDodge = 0,
		lastJump = 0,
	}
	newFolder(character, "Folder", "CharacterReady")
	humanoid.Died:Connect(function()
		characterStates[character] = nil
		task.delay(Config.RespawnDelay, function()
			if player.Parent and player.Character == character then
				ServerData.Spawn(player)
			end
		end)
	end)
	character.AncestryChanged:Connect(function()
		if not character:IsDescendantOf(workspace) then
			characterStates[character] = nil
		end
	end)
	ServerSignals.CharacterReady():Fire(player, character)
end

function ServerData.ChangeTeam(player, teamName)
	local team = Teams:FindFirstChild(teamName)
	if not team or not Config.Teams[teamName] then
		return false
	end
	player.Team = team
	local focal = focalPoint(player)
	if focal then
		player:SetAttribute("FocalSpawnPoint", focal)
	end
	return true
end

function ServerData.Spawn(player)
	if spawning[player] or not player.Parent or not player.Team then
		return false
	end
	spawning[player] = true
	local ok, err = pcall(function()
		player:LoadCharacter()
	end)
	spawning[player] = nil
	if not ok then
		warn(err)
		return false
	end
	return true
end

function ServerData.SetTeam(player, teamName)
	if type(teamName) ~= "string" or not Config.Teams[teamName] then
		return false
	end
	local team = Teams:FindFirstChild(teamName)
	if not team then
		return false
	end
	if player.Team and player.Character and characterStates[player.Character] then
		return false
	end
	player.Team = team
	local gui = player:FindFirstChildOfClass("PlayerGui")
	local selector = gui and gui:FindFirstChild(Config.TeamSelectGuiName)
	if selector then
		selector:Destroy()
	end
	return ServerData.Spawn(player)
end

local function cloneHostGuis(player)
	if not Config.CloneHostGuis then
		return
	end
	local host = ServerScriptService:FindFirstChild(Config.TemplateHostName)
	if not host then
		return
	end
	local gui = player:WaitForChild("PlayerGui", 10)
	if not gui then
		return
	end
	for _, source in ipairs(host:GetChildren()) do
		local allowed = Config.CloneAllHostGuis or source.Name == Config.TeamSelectGuiName
		if source:IsA("ScreenGui") and allowed and not gui:FindFirstChild(source.Name) then
			source:Clone().Parent = gui
		end
	end
end

local function createSession(player, state)
	state.extra.UserId = player.UserId
	local wrap = { player = player }
	local session = { player = player, userId = player.UserId, wrap = wrap, state = state, Data = state.extra }
	function wrap.notify(first, second)
		ServerData.Notify(player, type(first) == "string" and first or second)
	end
	function wrap.getSession()
		return session
	end
	function wrap.replicateItemId()
	end
	function wrap.replicateItem()
	end
	_G.session[player] = session
	_G.session[player.UserId] = session
end

local function save(player, release)
	local state = states[player]
	if not state or not state.ready or state.saving then
		return false
	end
	local blob = PlayerStore.Serialize(player)
	blob.Extra = state.extra
	return PlayerStore.Write(player.UserId, blob, release == true)
end

function ServerData.Save(player, release)
	return save(player, release)
end

local function onPlayerAdded(player)
	if states[player] then
		return
	end
	local state = { ready = false, extra = defaultExtra() }
	states[player] = state
	player.CharacterAdded:Connect(function(character)
		task.spawn(setupCharacter, player, character)
	end)
	local ok, blob = PlayerStore.Fetch(player.UserId)
	if not player.Parent then
		if ok then
			PlayerStore.Write(player.UserId, blob or { v = 1, Entries = {} }, true)
		end
		states[player] = nil
		return
	end
	if not ok then
		states[player] = nil
		player:Kick("Your data could not be loaded. Please rejoin in a moment.")
		return
	end
	local container = instantiateTemplate()
	local loaded = container:FindFirstChild("DataLoaded")
	if loaded then
		loaded.Value = false
	end
	if blob then
		PlayerStore.Apply(container, blob)
		if type(blob.Extra) == "table" then
			state.extra = Util.reconcile(blob.Extra, defaultExtra())
		end
	end
	for _, child in ipairs(container:GetChildren()) do
		child.Parent = player
	end
	container:Destroy()
	for name, value in pairs(Config.PlayerAttributes) do
		player:SetAttribute(name, value)
	end
	state.ready = true
	createSession(player, state)
	task.spawn(function()
		local replicated, err = pcall(function()
			require(ReplicatedStorage.Util.LevelCap).replicateLevelCap(player)
		end)
		if not replicated then
			warn("[ServerData] LevelCap replication failed: " .. tostring(err))
		end
	end)
	local flag = player:FindFirstChild("DataLoaded")
	if flag then
		flag.Value = true
	end
	task.spawn(cloneHostGuis, player)
	ServerSignals.PlayerDataLoaded():Fire(player)
end

local function onPlayerRemoving(player)
	local state = states[player]
	if not state then
		return
	end
	if state.ready then
		ServerSignals.PlayerDataSaving():Fire(player)
		save(player, true)
		state.saving = true
	end
	_G.session[player] = nil
	_G.session[player.UserId] = nil
	states[player] = nil
	spawning[player] = nil
end

function ServerData.Init()
	Players.CharacterAutoLoads = false
	getCharactersFolder()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayerAdded, player)
	end
	task.spawn(function()
		while true do
			task.wait(Config.AutoSaveInterval)
			for player in pairs(states) do
				task.spawn(save, player, false)
			end
		end
	end)
	RunService.Heartbeat:Connect(function(deltaTime)
		for character, characterState in pairs(characterStates) do
			if characterState.humanoid.Health > 0 then
				local energy = characterState.energy
				if energy.Value < energy.MaxValue then
					local grounded = characterState.humanoid.FloorMaterial ~= Enum.Material.Air
					characterState.regen += math.max(Config.EnergyRegenPerSecond, energy.MaxValue * 0.03) * (grounded and 2 or 1) * deltaTime
					if characterState.regen >= 1 then
						local whole = math.floor(characterState.regen)
						characterState.regen -= whole
						energy.Value = math.min(energy.MaxValue, energy.Value + whole)
					end
				end
				if characterState.stun.Value > 0 then
					characterState.stun.Value = math.max(0, characterState.stun.Value - deltaTime)
				end
			end
		end
	end)
	game:BindToClose(function()
		local pending = 0
		for player, state in pairs(states) do
			if state.ready and not state.saving then
				state.saving = true
				pending += 1
				task.spawn(function()
					local blob = PlayerStore.Serialize(player)
					blob.Extra = state.extra
					PlayerStore.Write(player.UserId, blob, true)
					pending -= 1
				end)
			end
		end
		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do
			task.wait()
		end
	end)
end

return ServerData
