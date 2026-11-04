local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedServices = {}

local INITIALIZERS = {
	"SaleService",
	"PriceService",
	"ItemReplicationService",
	"WrapHighlightService",
}

function SharedServices.Init()
	for _, name in ipairs(INITIALIZERS) do
		task.spawn(function()
			local ok, err = pcall(function()
				local container = ReplicatedStorage:WaitForChild(name, 30)
				if not container then
					error("module not found")
				end
				local service = require(container)
				local init = service.init or service.Init
				if type(init) ~= "function" then
					error("no init function")
				end
				init()
			end)
			if not ok then
				warn(("[SharedServices] %s.init failed: %s"):format(name, tostring(err)))
			end
		end)
	end
end

return SharedServices
