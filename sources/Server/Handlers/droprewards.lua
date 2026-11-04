local replicatedstorage = game:GetService("ReplicatedStorage")
local serverstorage = game:GetService("ServerStorage")

return function(router, serverdata)
	local itemconfig = require(replicatedstorage:WaitForChild("ItemConfig"))
	local itemreplication = require(replicatedstorage:WaitForChild("ItemReplicationService"))
	local effectmodule = require(replicatedstorage:WaitForChild("Effect"))
	local keys = itemreplication.KEYS
	local random = Random.new()

	local function grant(player, itemid)
		if not serverdata.IsReady(player) then
			return false
		end
		local ok, item = pcall(function()
			return itemconfig.match(itemid):unwrap()
		end)
		if not ok or not item then
			return false
		end
		local extra = serverdata.GetExtra(player)
		if not extra then
			return false
		end
		extra.Shop = type(extra.Shop) == "table" and extra.Shop or { quantity = {}, weapons = {} }
		extra.Shop.quantity = type(extra.Shop.quantity) == "table" and extra.Shop.quantity or {}
		local amount = (tonumber(extra.Shop.quantity[tostring(itemid)]) or 0) + 1
		extra.Shop.quantity[tostring(itemid)] = amount
		itemreplication:ReplicateItem(player, keys.QUANTITY, itemid, nil, amount)
		itemreplication:ReplicateItem(player, keys.IS_OWNED, itemid, nil, true)
		serverdata.Notify(player, "Received " .. item.Index.StorageKey .. ".")
		local character = player.Character
		if character and character:FindFirstChildOfClass("Humanoid") and character:FindFirstChild("HumanoidRootPart") then
			pcall(function()
				effectmodule.new("itemreward"):replicate({ { Character = character, ItemId = itemid, ItemName = item.Index.StorageKey } })
			end)
		end
		local commevent = replicatedstorage:FindFirstChild("Remotes") and replicatedstorage.Remotes:FindFirstChild("CommE")
		if commevent then
			commevent:FireClient(player, "ItemChanged")
		end
		return true
	end

	local events = serverstorage:WaitForChild("hitboxevents", 30)
	local enemykilled = events and events:WaitForChild("enemydropeligible", 30)
	if enemykilled and enemykilled:IsA("BindableEvent") then
		enemykilled.Event:Connect(function(player, model)
			if not player or not player:IsA("Player") or not model or not model:IsA("Model") then
				return
			end
			local itemid = model:GetAttribute("DropItemId")
			local chance = model:GetAttribute("DropChance")
			if type(itemid) ~= "number" or type(chance) ~= "number" or chance <= 0 then
				return
			end
			if random:NextNumber() <= math.clamp(chance, 0, 1) then
				grant(player, itemid)
			end
		end)
	end
end
