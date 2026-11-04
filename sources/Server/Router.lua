local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Server = script.Parent
local Config = require(Server.Config)
local RateLimiter = require(Server.RateLimiter)
local ServerData = require(Server.ServerData)

local Router = {}

Router.CLIENT_ERROR = "[client]"

local commF = {}
local commE = {}
local netModule = nil

local function normalise(options)
	options = options or {}
	if options.requireData == nil then
		options.requireData = true
	end
	return options
end

local function invoke(name, entry, player, ...)
	if entry.options.requireData and not ServerData.IsReady(player) then
		return nil
	end
	if entry.options.rate then
		local burst = entry.options.burst or entry.options.rate * 2
		if not RateLimiter.allow(player, "cmd:" .. name, entry.options.rate, burst) then
			return nil
		end
	end
	local results = table.pack(pcall(entry.handler, player, ...))
	if not results[1] then
		local message = tostring(results[2])
		if string.sub(message, 1, #Router.CLIENT_ERROR) == Router.CLIENT_ERROR then
			error(message, 0)
		end
		warn(("[Router] %s failed: %s"):format(name, message))
		return nil
	end
	return table.unpack(results, 2, results.n)
end

local function getNet()
	if netModule == nil then
		local ok, result = pcall(function()
			return require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net"))
		end)
		netModule = ok and result or false
		if not ok then
			warn("[Router] Net module failed to load: " .. tostring(result))
		end
	end
	return netModule or nil
end

local function getRemote(container, name, className)
	local remote = container:FindFirstChild(name)
	if remote then
		return remote
	end
	remote = Instance.new(className)
	remote.Name = name
	remote.Parent = container
	return remote
end

local function bind(remote, name, entry, limit)
	if remote:IsA("RemoteFunction") then
		remote.OnServerInvoke = function(player, ...)
			if not RateLimiter.allow(player, "RF:" .. name, limit.rate, limit.burst) then
				return nil
			end
			return invoke(name, entry, player, ...)
		end
	elseif remote:IsA("RemoteEvent") then
		remote.OnServerEvent:Connect(function(player, ...)
			if not RateLimiter.allow(player, "RE:" .. name, limit.rate, limit.burst) then
				return
			end
			invoke(name, entry, player, ...)
		end)
	end
	return remote
end

function Router.commF(name, handler, options)
	commF[name] = { handler = handler, options = normalise(options) }
end

function Router.commE(name, handler, options)
	commE[name] = { handler = handler, options = normalise(options) }
end

function Router.remote(name, handler, options)
	local entry = { handler = handler, options = normalise(options) }
	local container = entry.options.container or ReplicatedStorage:WaitForChild("Remotes")
	local remote = getRemote(container, name, entry.options.className or "RemoteEvent")
	return bind(remote, name, entry, entry.options.limit or Config.Limits.NetRF)
end

function Router.netFunction(name, handler, options)
	local Net = getNet()
	if not Net then
		return nil
	end
	local entry = { handler = handler, options = normalise(options) }
	return bind(Net:RemoteFunction(name), "N:" .. name, entry, Config.Limits.NetRF)
end

function Router.netEvent(name, handler, options)
	local Net = getNet()
	if not Net then
		return nil
	end
	local entry = { handler = handler, options = normalise(options) }
	return bind(Net:RemoteEvent(name), "N:" .. name, entry, entry.options.limit or Config.Limits.NetRE)
end

function Router.fireClient(remoteName, player, ...)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local remote = remotes and remotes:FindFirstChild(remoteName)
	if remote and player.Parent then
		remote:FireClient(player, ...)
	end
end

function Router.Start()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local commFRemote = getRemote(remotes, "CommF_", "RemoteFunction")
	local commFLimit = Config.Limits.CommF_
	commFRemote.OnServerInvoke = function(player, command, ...)
		if type(command) ~= "string" or #command > 64 then
			return nil
		end
		if not RateLimiter.allow(player, "CommF_", commFLimit.rate, commFLimit.burst) then
			return nil
		end
		local entry = commF[command]
		if not entry then
			return nil
		end
		return invoke(command, entry, player, ...)
	end
	local commERemote = getRemote(remotes, "CommE", "RemoteEvent")
	local commELimit = Config.Limits.CommE
	commERemote.OnServerEvent:Connect(function(player, command, ...)
		if type(command) ~= "string" or #command > 64 then
			return
		end
		if not RateLimiter.allow(player, "CommE", commELimit.rate, commELimit.burst) then
			return
		end
		local entry = commE[command]
		if not entry then
			return
		end
		invoke(command, entry, player, ...)
	end)
end

return Router
