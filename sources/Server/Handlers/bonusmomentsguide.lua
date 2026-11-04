local function register(router, serverdata)
	local function statefor(player)
		local extra = serverdata.GetExtra(player)
		if not extra then
			return nil, nil
		end
		extra.BonusMoments = type(extra.BonusMoments) == "table" and extra.BonusMoments or {}
		local moments = extra.BonusMoments
		moments.EarlyAccessStage = math.clamp(math.floor(tonumber(moments.EarlyAccessStage) or 0), 0, 5)
		local available = moments.EarlyAccessAvailable == true or player:GetAttribute("EarlyAccessAvailable") == true
		return moments, available
	end

	router.netFunction("BonusMomentsGuide", function(player, action)
		local moments, available = statefor(player)
		local stage = moments and moments.EarlyAccessStage or 0
		if action == "GetState" then
			return stage
		end
		if action == "IsAvailable" then
			return available == true
		end
		if action == "GetRewardTracker" then
			return nil
		end
		if action == "InteractQuestGiver" then
			if not available then
				return "Unavailable", stage
			end
			if stage == 0 then
				return "Intro", stage
			end
			if stage == 4 then
				return "Reward", stage
			end
			if stage >= 5 then
				return "Completed", stage
			end
			return "Reminder", stage
		end
		if not moments or not available then
			return "Denied", stage
		end
		if action == "AcceptQuest" and stage == 0 then
			moments.EarlyAccessStage = 1
			return "Accepted", 1
		end
		if action == "CollectKey" and stage == 1 then
			moments.EarlyAccessStage = 2
			return "Collected", 2
		end
		if action == "InteractMansionDoor" then
			if stage == 2 then
				moments.EarlyAccessStage = 3
				return "Infiltration", 3
			end
			return "Locked", stage
		end
		if action == "FinishInfiltration" and stage == 3 then
			moments.EarlyAccessStage = 4
			return "Finished", 4
		end
		if action == "ClaimReward" and stage == 4 then
			moments.EarlyAccessStage = 5
			return "Completed", 5
		end
		if action == "InteractTesterDoor" then
			return stage >= 5 and "QuestGiver" or "Denied", stage
		end
		return nil
	end, { requireData = false, rate = 8, burst = 16 })
end

return register
