local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Server = script.Parent.Parent
local Config = require(Server.Config)

local Result = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Result"))

local function getPrefix()
	local ok, constants = pcall(function()
		return require(ReplicatedStorage:WaitForChild("TestingGroupUtil"):WaitForChild("CONSTANTS"))
	end)
	if ok and type(constants) == "table" and type(constants.TESTING_GROUP_PREFIX) == "string" then
		return constants.TESTING_GROUP_PREFIX
	end
	return "TestingGroupUtil_"
end

local PREFIX = getPrefix()

local TestingService = {}

local initialized = false

local function hash(text)
	local value = 5381
	for index = 1, #text do
		value = (value * 33 + string.byte(text, index)) % 4294967296
	end
	return value
end

local function sortedGroupNames(experiment)
	local names = {}
	for name in pairs(experiment.groups) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

function TestingService.Resolve(userId, experimentName)
	local experiment = Config.Experiments[experimentName]
	if not experiment then
		return nil
	end
	local forced = Config.ForcedGroups[experimentName]
	if forced ~= nil and experiment.groups[forced] ~= nil then
		return forced
	end
	local names = sortedGroupNames(experiment)
	local total = 0
	for _, name in ipairs(names) do
		total += experiment.groups[name]
	end
	if total <= 0 then
		return experiment.default
	end
	local bucket = hash(tostring(userId) .. ":" .. experimentName) % total
	local running = 0
	for _, name in ipairs(names) do
		running += experiment.groups[name]
		if bucket < running then
			return name
		end
	end
	return experiment.default
end

function TestingService.AssignPlayer(player)
	for experimentName in pairs(Config.Experiments) do
		player:SetAttribute(PREFIX .. experimentName, TestingService.Resolve(player.UserId, experimentName))
	end
end

function TestingService:GetIfInitialized()
	return initialized
end

function TestingService:GetGroup(userId, experimentName)
	if type(userId) ~= "number" or type(experimentName) ~= "string" then
		return Result.err("BadArguments")
	end
	local value = TestingService.Resolve(userId, experimentName)
	if value == nil then
		return Result.err("UnknownExperiment")
	end
	return Result.ok(value)
end

function TestingService.getGroup(data, experimentName)
	local userId = type(data) == "table" and data.UserId or nil
	if type(userId) ~= "number" or type(experimentName) ~= "string" then
		return Result.err("BadArguments")
	end
	local value = TestingService.Resolve(userId, experimentName)
	if value == nil then
		return Result.err("UnknownExperiment")
	end
	return Result.ok(value)
end

function TestingService:GetAllGroups(userId)
	local groups = {}
	for experimentName in pairs(Config.Experiments) do
		groups[experimentName] = TestingService.Resolve(userId, experimentName)
	end
	return groups
end

function TestingService.Register(Router)
	Router.netFunction("GetTestingGroup", function(player, experimentName)
		if type(experimentName) ~= "string" or #experimentName > 64 then
			return nil
		end
		return TestingService.Resolve(player.UserId, experimentName)
	end, { requireData = false, rate = 10, burst = 20 })
end

function TestingService.Init()
	if initialized then
		return
	end
	Players.PlayerAdded:Connect(TestingService.AssignPlayer)
	for _, player in ipairs(Players:GetPlayers()) do
		TestingService.AssignPlayer(player)
	end
	initialized = true
end

return TestingService
