local replicatedstorage = game:GetService("ReplicatedStorage")

local function register(router)
	local itemconfig = require(replicatedstorage:WaitForChild("ItemConfig"))
	local itemreplication = require(replicatedstorage:WaitForChild("ItemReplicationService"))
	local modification = require(replicatedstorage:WaitForChild("Util"):WaitForChild("Modification"))
	local keys = itemreplication.KEYS

	router.netFunction("ModificationFunction", function(player, request)
		if type(request) ~= "table" or request.Type ~= "SetEquip" then
			return { Type = "Error", Message = "Invalid request." }
		end
		local itemid = request.ItemId
		if type(itemid) ~= "number" or itemid % 1 ~= 0 then
			return { Type = "Error", Message = "Invalid item." }
		end
		local ok, item = pcall(function()
			return itemconfig.match(itemid):unwrap()
		end)
		if not ok or not item then
			return { Type = "Error", Message = "Invalid item." }
		end
		local isskin = item.Index.IdType == "Skin"
		local ismutation = item.Index.IdType == "Mutation"
		if not isskin and not ismutation then
			return { Type = "Error", Message = "This item cannot be equipped here." }
		end
		local owned = itemreplication:ReadItem(player, keys.IS_OWNED, itemid, nil)
		if owned ~= true then
			return { Type = "Error", Message = "You do not own this modification." }
		end
		local adorneeid
		if isskin then
			adorneeid = item.Skin and item.Skin.Adornee
		else
			adorneeid = item.Mutation and item.Mutation.Adornee
		end
		if type(adorneeid) ~= "number" or itemreplication:ReadItem(player, keys.IS_EQUIPPED, adorneeid, nil) ~= true then
			return { Type = "Error", Message = "Equip the matching fruit first." }
		end
		local modificationkey = isskin and keys.EQUIPPED_SKIN or keys.PREFERRED_MUTATION
		if request.IsEquipped == true then
			itemreplication:ReplicateItem(player, modificationkey, adorneeid, nil, itemid)
		elseif request.IsEquipped == false then
			local current = itemreplication:ReadItem(player, modificationkey, adorneeid, nil)
			if current == itemid then
				itemreplication:ReplicateItem(player, modificationkey, adorneeid, nil, nil)
			end
		else
			return { Type = "Error", Message = "Invalid equip state." }
		end
		return { Type = "GetData", Data = modification.Data.Modification.fromItemReplication(player) }
	end, { rate = 8, burst = 16 })
end

return register
