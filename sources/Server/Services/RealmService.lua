local ServerStorage = game:GetService("ServerStorage")

local Realms = require(ServerStorage.Realms)

local RealmService = {}

function RealmService.Register(Router)
	Router.netFunction("GetRealmDifficulty", function()
		return Realms.getCurrentRealm().Difficulty
	end, { requireData = false, rate = 10, burst = 20 })
	Router.netFunction("GetRealmHasTag", function(_, tag)
		if type(tag) ~= "string" or #tag > 64 then
			return false
		end
		return Realms.getCurrentRealm():HasTag(tag) == true
	end, { requireData = false, rate = 30, burst = 60 })
end

return RealmService
