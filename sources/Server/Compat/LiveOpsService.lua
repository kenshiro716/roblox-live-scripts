local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Result = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Result"))

local LiveOpsService = {}

LiveOpsService.IsInitialized = true

local node = {}

function node.ScheduleCallback(_, callback)
	task.spawn(callback, Result.ok(false))
	return { Disconnect = function() end }
end

function node.Get()
	return Result.ok(false)
end

LiveOpsService.Nodes = setmetatable({}, {
	__index = function()
		return node
	end,
})

function LiveOpsService.GetIfInitialized()
	return true
end

return LiveOpsService
