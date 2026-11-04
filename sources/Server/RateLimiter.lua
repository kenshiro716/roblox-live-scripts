local Players = game:GetService("Players")

local RateLimiter = {}

local buckets = {}

local function bucketsFor(player)
	local list = buckets[player]
	if not list then
		list = {}
		buckets[player] = list
	end
	return list
end

function RateLimiter.allow(player, key, perSecond, burst)
	local now = os.clock()
	local list = bucketsFor(player)
	burst = burst or perSecond
	local bucket = list[key]
	if not bucket then
		bucket = { tokens = burst, last = now }
		list[key] = bucket
	end
	bucket.tokens = math.min(burst, bucket.tokens + (now - bucket.last) * perSecond)
	bucket.last = now
	if bucket.tokens < 1 then
		return false
	end
	bucket.tokens -= 1
	return true
end

function RateLimiter.cooldown(player, key, seconds)
	local now = os.clock()
	local list = bucketsFor(player)
	local last = list["cd_" .. key]
	if last and now - last < seconds then
		return false
	end
	list["cd_" .. key] = now
	return true
end

Players.PlayerRemoving:Connect(function(player)
	buckets[player] = nil
end)

return RateLimiter
