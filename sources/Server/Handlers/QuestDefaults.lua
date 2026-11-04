local Server = script.Parent.Parent
local Util = require(Server.Util)

return function(Router, ServerData)
	local function register(name, defaults)
		Router.commF(name, function(player, action)
			if action ~= nil then
				return false
			end
			local extra = ServerData.GetExtra(player)
			local progress = Util.deepCopy(defaults)
			local saved = extra and extra.Quest[name]
			if type(saved) == "table" then
				progress = Util.reconcile(Util.deepCopy(saved), progress)
			end
			return progress
		end, { rate = 10, burst = 20 })
	end

	register("ProQuestProgress", {
		UsedTorch = false,
		UsedCup = false,
		TalkedSon = false,
		KilledMob = false,
		UsedRelic = false,
		KilledShanks = false,
		Plates = {},
	})

	register("TushitaProgress", { OpenedDoor = false, Torches = {} })
	register("CDKQuest", { Good = 0, Evil = 0, Opened = false, Finished = false })
	register("BartiloQuestProgress", { DidPlates = false, KilledBandits = false, KilledSpring = false })
	register("CitizenQuestProgress", { FoundTreasure = false, KilledBandits = false, KilledBoss = false })
	register("DressrosaQuestProgress", { KilledIceBoss = false, TalkedDetective = false, UsedKey = false })
	register("RaidsNpc", { Dough = false, Phoenix = false })
	register("Cousin", { Done = false, Granted = false, Text = {} })
	register("Awakener", { Key = "", Cost = 0 })

	Router.commF("TempleClock", function(player)
		local race = ServerData.Get(player, "Race")
		return {
			HadPoint = false,
			Race = type(race) == "string" and race or "Human",
			RaceDetails = { Gears = {} },
			RaceLevel = 0,
		}
	end, { rate = 10, burst = 20 })

	Router.commF("getAwakenedAbilities", function()
		return {}
	end, { rate = 10, burst = 20 })

	Router.commF("getTradeInventory", function()
		return { Items = {} }
	end, { rate = 10, burst = 20 })

	Router.commF("getEquipmentForFruit", function(player, fruitName)
		local equipped = ServerData.Get(player, "DevilFruit")
		return {
			Description = "",
			Equipment = {},
			Mastery = 0,
			IsFruitAccessible = type(fruitName) == "string" and equipped == fruitName,
			IsFruitEquipped = type(fruitName) == "string" and equipped == fruitName,
		}
	end, { rate = 10, burst = 20 })
end
