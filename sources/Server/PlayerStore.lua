local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local Server = script.Parent
local Config = require(Server.Config)
local Util = require(Server.Util)

local PlayerStore = {}

local memory = {}
local store = nil
local checked = false

local VALUE_CLASSES = { IntValue = true, NumberValue = true, StringValue = true, BoolValue = true }
local CONTAINER_CLASSES = { Folder = true, Configuration = true }

local function getStore()
	if checked then
		return store
	end
	checked = true
	local ok, result = pcall(function()
		local dataStore = DataStoreService:GetDataStore(Config.DataStoreName)
		dataStore:GetAsync("__probe")
		return dataStore
	end)
	if ok then
		store = result
	elseif RunService:IsStudio() then
		store = nil
	else
		store = DataStoreService:GetDataStore(Config.DataStoreName)
	end
	return store
end

local function keyFor(userId)
	return "Player_" .. tostring(userId)
end

local function lockedByOther(record)
	return record ~= nil
		and record.lock ~= nil
		and record.lock ~= game.JobId
		and os.time() - (record.lockTime or 0) < Config.LockTimeout
end

function PlayerStore.Fetch(userId)
	local dataStore = getStore()
	if not dataStore then
		return true, Util.deepCopy(memory[userId])
	end
	local key = keyFor(userId)
	for attempt = 1, Config.SaveRetries do
		local locked = false
		local blob = nil
		local ok = pcall(function()
			dataStore:UpdateAsync(key, function(old)
				if lockedByOther(old) then
					locked = true
					return nil
				end
				old = old or {}
				old.lock = game.JobId
				old.lockTime = os.time()
				blob = old.data
				return old
			end)
		end)
		if ok and not locked then
			return true, blob
		end
		task.wait(locked and 4 or attempt)
	end
	return false, nil
end

function PlayerStore.Write(userId, blob, release)
	local dataStore = getStore()
	if not dataStore then
		memory[userId] = Util.deepCopy(blob)
		return true
	end
	local key = keyFor(userId)
	for attempt = 1, Config.SaveRetries do
		local ok = pcall(function()
			dataStore:UpdateAsync(key, function(old)
				if lockedByOther(old) then
					return nil
				end
				return {
					data = blob,
					lock = (not release) and game.JobId or nil,
					lockTime = os.time(),
				}
			end)
		end)
		if ok then
			return true
		end
		task.wait(attempt)
	end
	return false
end

local function cleanAttributes(instance)
	local result = nil
	for name, value in pairs(instance:GetAttributes()) do
		local kind = type(value)
		if kind == "number" or kind == "string" or kind == "boolean" then
			result = result or {}
			result[name] = value
		end
	end
	return result
end

local function describe(instance, path)
	local entry = nil
	if VALUE_CLASSES[instance.ClassName] then
		entry = { p = path, c = instance.ClassName, v = instance.Value }
	elseif CONTAINER_CLASSES[instance.ClassName] then
		entry = { p = path, c = instance.ClassName }
	end
	if entry then
		local attributes = cleanAttributes(instance)
		if attributes then
			entry.a = attributes
		end
	end
	return entry
end

function PlayerStore.Serialize(player)
	local entries = {}
	local function walk(instance, path)
		for _, child in ipairs(instance:GetChildren()) do
			local childPath = table.clone(path)
			table.insert(childPath, child.Name)
			local entry = describe(child, childPath)
			if entry then
				table.insert(entries, entry)
				walk(child, childPath)
			end
		end
	end
	for _, rootName in ipairs(Config.PersistedRoots) do
		local root = player:FindFirstChild(rootName)
		if root then
			local rootPath = { rootName }
			local entry = describe(root, rootPath)
			if entry then
				table.insert(entries, entry)
				walk(root, rootPath)
			end
		end
	end
	return { v = 1, Entries = entries }
end

local function resolve(container, path)
	local current = container
	for index = 1, #path - 1 do
		local nextInstance = current:FindFirstChild(path[index])
		if not nextInstance then
			nextInstance = Instance.new("Folder")
			nextInstance.Name = path[index]
			nextInstance.Parent = current
		end
		current = nextInstance
	end
	local name = path[#path]
	return current, name, current:FindFirstChild(name)
end

function PlayerStore.Apply(container, blob)
	if type(blob) ~= "table" or type(blob.Entries) ~= "table" then
		return
	end
	for _, entry in ipairs(blob.Entries) do
		if type(entry) == "table" and type(entry.p) == "table" and #entry.p > 0 and type(entry.c) == "string" then
			local parent, name, target = resolve(container, entry.p)
			if VALUE_CLASSES[entry.c] then
				if not target then
					target = Instance.new(entry.c)
					target.Name = name
					target.Parent = parent
				end
				if target:IsA("ValueBase") and typeof(entry.v) == typeof(target.Value) then
					target.Value = entry.v
				end
			elseif CONTAINER_CLASSES[entry.c] and not target then
				target = Instance.new(entry.c)
				target.Name = name
				target.Parent = parent
			end
			if target and type(entry.a) == "table" then
				for attributeName, attributeValue in pairs(entry.a) do
					target:SetAttribute(attributeName, attributeValue)
				end
			end
		end
	end
end

return PlayerStore
