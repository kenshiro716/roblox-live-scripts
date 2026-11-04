local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local AssetStreaming = {}

local ALLOWED_KINDS = { FX = true }

local cache = {}

local function findAsset(kind, name)
	local serverContainer = ServerStorage:FindFirstChild(kind)
	local asset = serverContainer and serverContainer:FindFirstChild(name)
	if asset then
		return asset
	end
	local sharedContainer = ReplicatedStorage:FindFirstChild(kind)
	return sharedContainer and sharedContainer:FindFirstChild(name) or nil
end

function AssetStreaming.Register(Router)
	local ok, xisd = pcall(function()
		return require(ReplicatedStorage:WaitForChild("xisd", 30))
	end)
	if not ok or type(xisd) ~= "table" or type(xisd.ser) ~= "function" then
		warn("[AssetStreaming] xisd serializer unavailable: " .. tostring(xisd))
		return
	end
	if not ReplicatedStorage:FindFirstChild("xisd_SurfaceAppearances") then
		local folder = Instance.new("Folder")
		folder.Name = "xisd_SurfaceAppearances"
		folder.Parent = ReplicatedStorage
	end
	Router.remote("xisd", function(_, kind, name)
		if type(kind) ~= "string" or type(name) ~= "string" or #kind > 32 or #name > 100 then
			return false
		end
		if not ALLOWED_KINDS[kind] then
			return false
		end
		local key = kind .. "/" .. name
		local cached = cache[key]
		if cached then
			return true, cached
		end
		local asset = findAsset(kind, name)
		if not asset then
			return false
		end
		local serialized, data = pcall(xisd.ser, asset)
		if not serialized or type(data) ~= "string" then
			warn(("[AssetStreaming] could not serialize %s: %s"):format(key, tostring(data)))
			return false
		end
		cache[key] = data
		return true, data
	end, { className = "RemoteFunction", requireData = false, rate = 20, burst = 60 })
end

return AssetStreaming
