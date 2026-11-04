local function proxy()
	return setmetatable({}, {
		__index = function()
			return proxy()
		end,
		__call = function()
			return proxy()
		end,
	})
end

return proxy()
