local players = game:GetService("Players")
local replicatedstorage = game:GetService("ReplicatedStorage")
local serverstorage = game:GetService("ServerStorage")
local starterpack = game:GetService("StarterPack")
local runservice = game:GetService("RunService")
local istransformed = require(game:GetService("ReplicatedStorage"):WaitForChild("Util"):WaitForChild("IsTransformed"))

local studiobeli = 50000000
local fallbackprices = {
	["Empyrean (Kitsune)-Empyrean (Kitsune)"] = 12000000,
	["Dragon-Dragon"] = 15000000,
}
local startingitems = { "Triple Dark Blade" }

return function(Router, ServerData)
	local itemconfig = require(replicatedstorage:WaitForChild("ItemConfig"))
	local itemreplication = require(replicatedstorage:WaitForChild("ItemReplicationService"))
	local legacybeli = require(replicatedstorage:WaitForChild("Shop"):WaitForChild("LEGACY_BELI_ITEMS"))
	local keys = itemreplication.KEYS

	local itemsfolder = serverstorage:WaitForChild("Items")
	local accessoriesfolder = serverstorage:WaitForChild("Accessories")
	local commevent = replicatedstorage:WaitForChild("Remotes"):WaitForChild("CommE")

	local fruits = {}
	local fruitbykey = {}
	local accessories = {}
	local accessorybykey = {}
	local weaponbykey = {}

	local function config(id)
		local ok, result = pcall(function()
			return itemconfig.match(id):unwrap()
		end)
		return ok and result or nil
	end

	local function normalize(name)
		return (string.lower(name):gsub("[^%w]", ""))
	end

	for _, tool in ipairs(itemsfolder:GetChildren()) do
		if tool:IsA("Tool") then
			local cfg = config(tool:GetAttribute("ItemId"))
			if tool.ToolTip == "Blox Fruit" and cfg then
				local physical = cfg.Moveset and cfg.Moveset.Physical
				local physicalcfg = physical and config(physical)
				local entry = {
					tool = tool.Name,
					key = cfg.Index.StorageKey,
					physicalid = physicalcfg and physicalcfg.Index.ItemId or cfg.Index.ItemId,
					physicalkey = physicalcfg and physicalcfg.Index.StorageKey or cfg.Index.StorageKey,
					rarity = cfg.Quality and cfg.Quality.RarityValue or 0,
				}
				local legacy = legacybeli[tool.Name] or legacybeli[entry.key]
				entry.price = (legacy and legacy.Price) or fallbackprices[tool.Name] or 1000000
				table.insert(fruits, entry)
				fruitbykey[tool.Name] = entry
				fruitbykey[entry.key] = entry
				fruitbykey[entry.physicalkey] = entry
			elseif cfg then
				local entry = { tool = tool.Name, key = cfg.Index.StorageKey, id = cfg.Index.ItemId }
				weaponbykey[tool.Name] = entry
				weaponbykey[entry.key] = entry
			end
		end
	end

	local registry = {}
	for id in pairs(require(replicatedstorage.Economy.ItemId)._IDS:unwrap()) do
		local cfg = config(id)
		if cfg and cfg.Index.IdType == "Accessory" then
			registry[normalize(cfg.Index.StorageKey)] = cfg.Index
		end
	end
	for _, model in ipairs(accessoriesfolder:GetChildren()) do
		if model:IsA("Accessory") then
			local index = registry[normalize(model.Name)]
			if index then
				local entry = { model = model.Name, key = index.StorageKey, id = index.ItemId }
				table.insert(accessories, entry)
				accessorybykey[model.Name] = entry
				accessorybykey[index.StorageKey] = entry
			end
		end
	end

	local function profileof(player)
		local extra = ServerData.GetExtra(player)
		if not extra then
			return nil
		end
		if type(extra.Shop) ~= "table" then
			extra.Shop = { quantity = {}, accessory = nil, fruit = nil, weapons = {}, granted = false }
		end
		extra.Shop.quantity = extra.Shop.quantity or {}
		extra.Shop.weapons = extra.Shop.weapons or {}
		return extra.Shop, extra
	end

	local function replicate(player, key, id, value)
		pcall(function()
			itemreplication:ReplicateItem(player, key, id, nil, value)
		end)
	end

	local function quantity(player, id)
		local profile = profileof(player)
		return profile and profile.quantity[tostring(id)] or 0
	end

	local function setquantity(player, id, amount)
		local profile = profileof(player)
		profile.quantity[tostring(id)] = amount > 0 and amount or nil
		replicate(player, keys.QUANTITY, id, amount > 0 and amount or nil)
		replicate(player, keys.IS_OWNED, id, amount > 0 or nil)
	end

	local function setequipped(player, id, equipped)
		replicate(player, keys.IS_EQUIPPED, id, equipped or nil)
	end

	local function notifychanged(player)
		pcall(function()
			commevent:FireClient(player, "ItemChanged")
		end)
	end

	local function findtool(player, name)
		local character = player.Character
		local backpack = player:FindFirstChildOfClass("Backpack")
		return (character and character:FindFirstChild(name)) or (backpack and backpack:FindFirstChild(name))
	end

	local function sourcetool(name)
		local fromstarter = starterpack:FindFirstChild(name)
		if fromstarter and fromstarter:FindFirstChild("Data") then
			return fromstarter
		end
		return itemsfolder:FindFirstChild(name)
	end

	local function givetool(player, name)
		if findtool(player, name) then
			return true
		end
		local source = sourcetool(name)
		local backpack = player:FindFirstChildOfClass("Backpack")
		if not source or not backpack then
			return false
		end
		source:Clone().Parent = backpack
		return true
	end

	local function removetool(player, name)
		local tool = findtool(player, name)
		if not tool then
			return
		end
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and tool.Parent == character then
			humanoid:UnequipTools()
		end
		tool:SetAttribute("ending", true)
		task.wait(0.1)
		if tool.Parent then
			tool:Destroy()
		end
	end

	local function wearaccessory(player)
		local profile = profileof(player)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not profile or not humanoid then
			return
		end
		for _, child in ipairs(character:GetChildren()) do
			if child:IsA("Accessory") and child:GetAttribute("inventoryaccessory") then
				child:Destroy()
			end
		end
		local entry = profile.accessory and accessorybykey[profile.accessory]
		local model = entry and accessoriesfolder:FindFirstChild(entry.model)
		if model then
			local clone = model:Clone()
			clone:SetAttribute("inventoryaccessory", true)
			humanoid:AddAccessory(clone)
		end
	end

	local function equipaccessory(player, entry)
		local profile = profileof(player)
		local previous = profile.accessory and accessorybykey[profile.accessory]
		if previous then
			setequipped(player, previous.id, false)
		end
		profile.accessory = entry and entry.key or nil
		if entry then
			setequipped(player, entry.id, true)
		end
		wearaccessory(player)
		return true
	end

	local function removefruittools(player, except)
		for _, entry in ipairs(fruits) do
			if entry.tool ~= except then
				removetool(player, entry.tool)
			end
		end
	end

	local function equipfruit(player, entry)
		local profile = profileof(player)
		local previous = profile.fruit and fruitbykey[profile.fruit]
		if previous and previous ~= entry then
			setequipped(player, previous.physicalid, false)
		end
		removefruittools(player, entry.tool)
		profile.fruit = entry.tool
		givetool(player, entry.tool)
		setequipped(player, entry.physicalid, true)
		ServerData.Set(player, "DevilFruit", entry.tool)
	end

	local function syncplayer(player)
		local profile, extra = profileof(player)
		if not profile then
			return
		end
		if not profile.granted then
			profile.granted = true
			if runservice:IsStudio() then
				local beli = ServerData.Get(player, "Beli") or 0
				ServerData.Set(player, "Beli", math.max(beli, studiobeli))
			end
		end
		if runservice:IsStudio() then
			for _, entry in ipairs(fruits) do
				if quantity(player, entry.physicalid) <= 0 then
					setquantity(player, entry.physicalid, 1)
				end
			end
		end
		for _, entry in ipairs(accessories) do
			if quantity(player, entry.id) <= 0 then
				profile.quantity[tostring(entry.id)] = 1
			end
		end
		for _, name in ipairs(startingitems) do
			local entry = weaponbykey[name]
			if entry and quantity(player, entry.id) <= 0 then
				profile.quantity[tostring(entry.id)] = 1
			end
		end
		for _, entry in ipairs(fruits) do
			local count = quantity(player, entry.physicalid)
			extra.Fruits[entry.tool] = count > 0 and count or nil
		end
		for id, amount in pairs(profile.quantity) do
			replicate(player, keys.QUANTITY, tonumber(id), amount)
			replicate(player, keys.IS_OWNED, tonumber(id), true)
		end
		local accessory = profile.accessory and accessorybykey[profile.accessory]
		if accessory then
			setequipped(player, accessory.id, true)
		end
		local fruit = profile.fruit and fruitbykey[profile.fruit]
		if fruit then
			setequipped(player, fruit.physicalid, true)
		end
		for name in pairs(profile.weapons) do
			local entry = weaponbykey[name]
			if entry then
				setequipped(player, entry.id, true)
			end
		end
	end

	local function restorecharacter(player, character)
		local profile = profileof(player)
		if not profile or player.Character ~= character then
			return
		end
		wearaccessory(player)
		if profile.fruit then
			removefruittools(player, profile.fruit)
			givetool(player, profile.fruit)
		end
		for name in pairs(profile.weapons) do
			givetool(player, name)
		end
	end

	local function onplayer(player)
		if not ServerData.WaitReady(player, 60) then
			return
		end
		syncplayer(player)
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("CharacterReady", 30)
			restorecharacter(player, character)
		end)
		if player.Character then
			restorecharacter(player, player.Character)
		end
	end

	players.PlayerAdded:Connect(onplayer)
	for _, player in ipairs(players:GetPlayers()) do
		task.spawn(onplayer, player)
	end

	local function loaditem(player, name)
		local accessory = accessorybykey[name]
		if accessory then
			if quantity(player, accessory.id) <= 0 then
				return false
			end
			return equipaccessory(player, accessory)
		end
		local weapon = weaponbykey[name]
		if weapon then
			if quantity(player, weapon.id) <= 0 then
				return false
			end
			profileof(player).weapons[weapon.tool] = true
			givetool(player, weapon.tool)
			setequipped(player, weapon.id, true)
			return true
		end
		return false
	end

	local function storeitem(player, name)
		local profile = profileof(player)
		local accessory = accessorybykey[name]
		if accessory then
			if profile.accessory == accessory.key then
				equipaccessory(player, nil)
			end
			return true
		end
		local weapon = weaponbykey[name]
		if weapon then
			profile.weapons[weapon.tool] = nil
			removetool(player, weapon.tool)
			setequipped(player, weapon.id, false)
			return true
		end
		return false
	end

	local function setdragontype(player, kind)
		if kind ~= "East" and kind ~= "West" then
			return
		end
		local profile = profileof(player)
		if profile then
			profile.dragontype = kind
		end
		local data = player:FindFirstChild("Data")
		local fruit = data and data:FindFirstChild("DevilFruit")
		if fruit then
			fruit:SetAttribute("DragonType", kind)
		end
	end

	local function getdragontype(player)
		local data = player:FindFirstChild("Data")
		local fruit = data and data:FindFirstChild("DevilFruit")
		local kind = fruit and fruit:GetAttribute("DragonType")
		if kind ~= "East" and kind ~= "West" then
			local profile = profileof(player)
			kind = profile and profile.dragontype
		end
		if kind ~= "East" and kind ~= "West" then
			local tool = itemsfolder:FindFirstChild("Dragon-Dragon")
			kind = tool and tool:GetAttribute("DragonType") or "West"
		end
		return kind
	end

	local function loadfruit(player, name, dragontype)
		if istransformed(player.Character, true, true) then
			return false, "You can’t switch fruits while transformed."
		end
		local entry = type(name) == "string" and (fruitbykey[name] or fruitbykey[(name:gsub("Permanent ", ""))])
		if not entry or quantity(player, entry.physicalid) <= 0 then
			return false, "You don't own this fruit."
		end
		if entry.tool == "Dragon-Dragon" then
			setdragontype(player, dragontype or getdragontype(player))
		end
		equipfruit(player, entry)
		notifychanged(player)
		return true
	end

	local function storefruit(player)
		local profile = profileof(player)
		local entry = profile.fruit and fruitbykey[profile.fruit]
		if not entry then
			return false
		end
		removetool(player, entry.tool)
		setequipped(player, entry.physicalid, false)
		profile.fruit = nil
		ServerData.Set(player, "DevilFruit", "")
		notifychanged(player)
		return true
	end

	local function addfruit(player, entry)
		local _, extra = profileof(player)
		local count = quantity(player, entry.physicalid) + 1
		setquantity(player, entry.physicalid, count)
		extra.Fruits[entry.tool] = count
		notifychanged(player)
	end

	local function getfruits(player)
		local list = {}
		for _, entry in ipairs(fruits) do
			table.insert(list, {
				Name = entry.tool == "Dragon-Dragon" and entry.tool or entry.key,
				OnSale = true,
				Offsale = false,
				Rarity = entry.rarity,
				Price = entry.price,
				HasPermanent = quantity(player, entry.physicalid) > 0,
			})
		end
		return list
	end

	local function purchasefruit(player, name, _, dragontype)
		local entry = type(name) == "string" and fruitbykey[name]
		if not entry then
			return false
		end
		if entry.tool == "Dragon-Dragon" then
			setdragontype(player, dragontype)
		end
		local beli = ServerData.Get(player, "Beli") or 0
		if beli < entry.price then
			ServerData.Notify(player, "Not enough money.")
			return false
		end
		ServerData.Set(player, "Beli", beli - entry.price)
		addfruit(player, entry)
		ServerData.Notify(player, "Purchased " .. entry.tool .. "! Open your inventory to equip it.")
		return true
	end

	local function buyitem(player, name)
		local legacy = type(name) == "string" and legacybeli[name]
		local accessory = accessorybykey[name]
		local weapon = weaponbykey[name]
		local id = (accessory and accessory.id) or (weapon and weapon.id)
		if not legacy or not legacy.Price or not id then
			return 0
		end
		if quantity(player, id) > 0 then
			return 2
		end
		if legacy.LevelReq and (ServerData.Get(player, "Level") or 1) < legacy.LevelReq then
			return 3
		end
		local beli = ServerData.Get(player, "Beli") or 0
		if beli < legacy.Price then
			return 0
		end
		ServerData.Set(player, "Beli", beli - legacy.Price)
		setquantity(player, id, 1)
		notifychanged(player)
		return 1
	end

	local function buyrobuxshop(player, info)
		local name = type(info) == "table" and info.StorageName or info
		local entry = type(name) == "string" and (fruitbykey[name] or fruitbykey[(name:gsub("Permanent ", ""))])
		if not entry then
			ServerData.Notify(player, "This item isn't available.")
			return false
		end
		if quantity(player, entry.physicalid) <= 0 then
			addfruit(player, entry)
		end
		return true
	end

	local options = { rate = 6, burst = 12 }
	Router.commF("LoadItem", loaditem, options)
	Router.commF("StoreItem", storeitem, options)
	Router.commF("LoadFruit", loadfruit, options)
	Router.commF("SwitchFruit", loadfruit, options)
	Router.commF("StoreFruit", storefruit, options)
	Router.commF("GetFruits", getfruits, { rate = 10, burst = 20 })
	Router.commF("DragonType", getdragontype, { rate = 10, burst = 20 })
	Router.commF("PurchaseRawFruit", purchasefruit, options)
	Router.commF("BuyItem", buyitem, options)
	Router.commF("buyRobuxShop", buyrobuxshop, options)
end
