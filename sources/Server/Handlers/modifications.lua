local players = game:GetService("Players")
local replicatedstorage = game:GetService("ReplicatedStorage")
local serverstorage = game:GetService("ServerStorage")

local itemconfig = require(replicatedstorage:WaitForChild("ItemConfig"))
local itemreplication = require(replicatedstorage:WaitForChild("ItemReplicationService"))
local modification = require(replicatedstorage:WaitForChild("Util"):WaitForChild("Modification"))
local skinvfxhandle = require(replicatedstorage:WaitForChild("Modules"):WaitForChild("SkinVFXHandle"))
local skinvfx = require(replicatedstorage:WaitForChild("Util"):WaitForChild("SkinVFX"))
local skinnedrigs = replicatedstorage:WaitForChild("Assets"):FindFirstChild("SkinnedRigs")

local keys = itemreplication.KEYS

local admins = { notbloxfruitscopy = true, Zakouplays6 = true }
local vfxnames = { Tiger = "Leopard" }
local auraadornee = 1445

local catalog = {}
local byadornee = {}
local handles = setmetatable({}, { __mode = "k" })
local serverdata
local modevent

local function nullable(result)
	local ok, value = pcall(function()
		return result:asNullable()
	end)
	return ok and value or nil
end

local function buildcatalog()
	for _, idtype in ipairs({ "Skin", "Mutation" }) do
		local ok, list = pcall(itemconfig.Query.select, { Index = { IdType = idtype } })
		if not ok then
			warn("[modifications] query " .. idtype .. " failed: " .. tostring(list))
		end
		if ok then
			for _, item in list do
				local id = item.Index.ItemId
				local adornee = nullable(modification.matchAdornee(id))
				if adornee then
					local entry = {
						id = id,
						kind = idtype,
						adornee = adornee,
						name = item.Index.StorageKey,
						display = (item.Display and (item.Display.Name or item.Display.Title)) or item.Index.StorageKey,
						isdefault = item.Skin ~= nil and item.Skin.IsDefault == true,
					}
					catalog[id] = entry
					byadornee[adornee] = byadornee[adornee] or {}
					table.insert(byadornee[adornee], entry)
				end
			end
		end
	end
end

local function mutationtarget(entry)
	if entry.kind ~= "Mutation" then
		return nil
	end
	local item = itemconfig.tryGet(entry.id)
	local physical = item and item.Mutation and item.Mutation.Physical
	local physicalitem = physical and itemconfig.tryGet(physical)
	return physicalitem and physicalitem.Index.StorageKey or nil
end

local function store(player)
	local extra = serverdata.GetExtra(player)
	if not extra then
		return nil
	end
	if type(extra.Modifications) ~= "table" then
		extra.Modifications = {}
	end
	local data = extra.Modifications
	data.owned = type(data.owned) == "table" and data.owned or {}
	data.preferred = type(data.preferred) == "table" and data.preferred or {}
	return data
end

local function replicate(player, key, id, value)
	pcall(function()
		itemreplication:ReplicateItem(player, key, id, nil, value)
	end)
end

local function isfruittool(tool)
	return tool:IsA("Tool") and type(tool:GetAttribute("ItemId")) == "number"
		and (tool:GetAttribute("WeaponType") == "Demon Fruit" or tool.ToolTip == "Blox Fruit" or string.match(tool.Name, "^(.+)%-%1$") ~= nil)
end

local function adorneeof(player, tool)
	local id = tool:GetAttribute("ItemId")
	if tool.Name == "Dragon-Dragon" then
		local data = player:FindFirstChild("Data")
		local devil = data and data:FindFirstChild("DevilFruit")
		local kind = (devil and devil:GetAttribute("DragonType")) or tool:GetAttribute("DragonType")
		if kind == "East" or kind == "Eastern" then
			return 1436
		end
		return 1435
	end
	return id
end

local function fruittools(player)
	local list = {}
	for _, container in ipairs({ player.Character, player:FindFirstChildOfClass("Backpack") }) do
		if container then
			for _, child in ipairs(container:GetChildren()) do
				if isfruittool(child) then
					table.insert(list, child)
				end
			end
		end
	end
	return list
end

local function hasbuso(player)
	local extra = serverdata.GetExtra(player)
	return extra and type(extra.Abilities) == "table" and extra.Abilities.Buso == true
end

local function ownedmods(player)
	local data = store(player)
	local owned = {}
	if not data then
		return owned
	end
	for key in pairs(data.owned) do
		local id = tonumber(key)
		if id and catalog[id] then
			owned[id] = true
		end
	end
	if hasbuso(player) then
		for _, entry in ipairs(byadornee[auraadornee] or {}) do
			if entry.isdefault then
				owned[entry.id] = true
			end
		end
	end
	for _, tool in ipairs(fruittools(player)) do
		local adornee = adorneeof(player, tool)
		for _, entry in ipairs(byadornee[adornee] or {}) do
			if entry.isdefault then
				owned[entry.id] = true
			end
		end
		for _, entries in pairs(byadornee) do
			for _, entry in ipairs(entries) do
				if entry.kind == "Mutation" and mutationtarget(entry) == tool.Name then
					owned[entry.id] = true
				end
			end
		end
	end
	return owned
end

local function payload(player)
	local ok, data = pcall(modification.Data.Modification.fromItemReplication, player)
	if ok and data then
		return data
	end
	return buffer.create(5)
end

local function dosync(player)
	local data = store(player)
	if not data then
		return
	end
	local owned = ownedmods(player)
	local ownedcount = 0
	for _ in pairs(owned) do
		ownedcount += 1
	end
	player:SetAttribute("modificationsowned", ownedcount)
	player:SetAttribute("modificationtools", #fruittools(player))
	local stacks = {}
	for id, entry in pairs(catalog) do
		local preferred = owned[id] and data.preferred[tostring(id)] or nil
		replicate(player, keys.IS_OWNED, id, owned[id] or nil)
		replicate(player, keys.QUANTITY, id, owned[id] and 1 or nil)
		replicate(player, keys.IS_PREFERRED, id, preferred)
		if owned[id] then
			local item = itemconfig.tryGet(id)
			local stackkey = item and item.Inventory and item.Inventory.StackKey or tostring(id)
			local score = (preferred and entry.kind == "Skin" and 4) or (preferred and 3) or (entry.isdefault and 2) or 1
			local current = stacks[stackkey]
			if not current or score > current.score or (score == current.score and id < current.id) then
				stacks[stackkey] = { id = id, score = score }
			end
		end
	end
	local leaders = {}
	for _, leader in pairs(stacks) do
		leaders[leader.id] = true
	end
	for id in pairs(catalog) do
		replicate(player, keys.IS_STACK_LEADER, id, leaders[id] or nil)
	end
	local current = player:FindFirstChild("Data") and player.Data:FindFirstChild("DevilFruit")
	for _, tool in ipairs(fruittools(player)) do
		local adornee = adorneeof(player, tool)
		replicate(player, keys.IS_OWNED, adornee, true)
		replicate(player, keys.IS_EQUIPPED, adornee, (current == nil or current.Value == "" or current.Value == tool.Name) or nil)
		local skin, mutation = nil, nil
		for _, entry in ipairs(byadornee[adornee] or {}) do
			if entry.kind == "Skin" and entry.isdefault and skin == nil then
				skin = entry.id
			end
		end
		for _, entries in pairs(byadornee) do
			for _, entry in ipairs(entries) do
				if owned[entry.id] and data.preferred[tostring(entry.id)] then
					if entry.kind == "Skin" and entry.adornee == adornee then
						skin = entry.id
					elseif entry.kind == "Mutation" and mutationtarget(entry) == tool.Name then
						mutation = entry.id
					end
				end
			end
		end
		replicate(player, keys.EQUIPPED_SKIN, adornee, skin)
		replicate(player, keys.PREFERRED_MUTATION, adornee, mutation)
	end
	local auraskin = nil
	for _, entry in ipairs(byadornee[auraadornee] or {}) do
		if entry.kind == "Skin" and owned[entry.id] then
			if data.preferred[tostring(entry.id)] then
				auraskin = entry.id
				break
			elseif entry.isdefault then
				auraskin = entry.id
			end
		end
	end
	if hasbuso(player) then
		replicate(player, keys.IS_OWNED, auraadornee, true)
		replicate(player, keys.IS_EQUIPPED, auraadornee, true)
		replicate(player, keys.EQUIPPED_SKIN, auraadornee, auraskin)
	end
	player:SetAttribute("auraskin", auraskin or 0)
	if modevent then
		pcall(function()
			modevent:FireClient(player, { Type = "DataChanged", Data = payload(player) })
		end)
	end
end

local function sync(player)
	local ok, err = pcall(dosync, player)
	if not ok then
		warn("[modifications] sync failed for " .. player.Name .. ": " .. tostring(err))
	end
end

local function vfxname(tool)
	local base = tool.Name:match("^(.-)%-") or tool.Name
	local inner = base:match("%((.-)%)")
	base = inner or base
	return (vfxnames[base] or base) .. "FruitVFXColor"
end

local function rigpath(player, tool)
	local name = tool.Name
	if name == "Dragon-Dragon" then
		name = adorneeof(player, tool) == 1436 and "Dragon (East)-Dragon (East)" or "Dragon (West)-Dragon (West)"
	end
	local transformations = skinnedrigs and skinnedrigs:FindFirstChild("Transformations")
	if transformations and transformations:FindFirstChild(name) then
		return "Transformations." .. name
	end
	return nil
end

local function bindrig(player, tool, handle)
	local rigobject = tool:FindFirstChild("TransformedRigObject")
	if not rigobject or not rigobject:IsA("ObjectValue") then
		return
	end
	local function apply(skinid)
		local rig = rigobject.Value
		local path = rig and rigpath(player, tool)
		if not path or not rig.Parent then
			return
		end
		skinid = skinid or handle:GetEquippedSkin()
		local okapply, err = pcall(skinvfx.applySkin, skinid, { [rig] = path })
		if not okapply then
			warn("[modifications] rig skin failed for " .. tool.Name .. ": " .. tostring(err))
		end
	end
	local changed = rigobject.Changed:Connect(function()
		task.defer(apply)
	end)
	local disconnect = handle:ConnectUpdateLoop(function(skinid)
		apply(skinid)
	end)
	table.insert(handle._CleanUpCallbacks, function()
		changed:Disconnect()
		disconnect()
	end)
	if rigobject.Value then
		task.defer(apply)
	end
end

local function attachskin(player, tool)
	if handles[tool] or not isfruittool(tool) then
		return
	end
	local adornee = adorneeof(player, tool)
	if not byadornee[adornee] then
		return
	end
	local ok, handle = pcall(skinvfxhandle.new, player, adornee, tool, vfxname(tool))
	if ok and handle then
		handles[tool] = handle
		pcall(handle.BindToHandle, handle, tool)
		bindrig(player, tool, handle)
	else
		warn("[modifications] skin handle failed for " .. tool.Name .. ": " .. tostring(handle))
	end
end

local function swapfruit(player, toolname)
	local items = serverstorage:FindFirstChild("Items")
	local template = items and items:FindFirstChild(toolname)
	if not template then
		return false
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local wasequipped = false
	for _, tool in ipairs(fruittools(player)) do
		if tool.Name ~= toolname then
			wasequipped = wasequipped or tool.Parent == character
			if humanoid and tool.Parent == character then
				humanoid:UnequipTools()
			end
			tool:SetAttribute("ending", true)
			task.wait(0.1)
			if tool.Parent then
				tool:Destroy()
			end
		end
	end
	local existing = nil
	for _, tool in ipairs(fruittools(player)) do
		if tool.Name == toolname then
			existing = tool
		end
	end
	local tool = existing or template:Clone()
	tool.Parent = player:FindFirstChildOfClass("Backpack")
	local data = player:FindFirstChild("Data")
	local devil = data and data:FindFirstChild("DevilFruit")
	if devil then
		devil.Value = toolname
	end
	if wasequipped and humanoid then
		task.defer(function()
			if tool.Parent then
				humanoid:EquipTool(tool)
			end
		end)
	end
	return true
end

local function setequip(player, itemid, isequipped)
	local entry = catalog[itemid]
	if not entry then
		return { Type = "Generic", Success = false, Message = "Unknown item." }
	end
	local data = store(player)
	if not data then
		return { Type = "Generic", Success = false, Message = "Data not loaded." }
	end
	local owned = ownedmods(player)
	if not owned[itemid] then
		return { Type = "Generic", Success = false, Message = "You don't own this." }
	end
	if isequipped then
		for _, other in ipairs(byadornee[entry.adornee] or {}) do
			if other.kind == entry.kind then
				data.preferred[tostring(other.id)] = nil
			end
		end
		if not entry.isdefault then
			data.preferred[tostring(itemid)] = true
		end
		if entry.kind == "Mutation" then
			local target = mutationtarget(entry)
			if target and not swapfruit(player, target) then
				serverdata.Notify(player, "<Color=Red>" .. tostring(entry.display) .. " isn't available yet.<Color=/>")
			end
		end
	else
		data.preferred[tostring(itemid)] = nil
	end
	sync(player)
	return { Type = "GetData", Data = payload(player) }
end

local function grant(player, query, kind)
	local data = store(player)
	if not data then
		return 0
	end
	query = string.lower(query or "")
	local count = 0
	for id, entry in pairs(catalog) do
		if (kind == nil or entry.kind == kind) and not entry.isdefault and (query == "all" or string.find(string.lower(entry.name), query, 1, true) or string.find(string.lower(tostring(entry.display)), query, 1, true)) then
			data.owned[tostring(id)] = true
			count += 1
		end
	end
	sync(player)
	return count
end

local function isadmin(player)
	return admins[string.lower(player.Name)] == true or player.UserId == game.CreatorId or game:GetService("RunService"):IsStudio()
end

local function watch(player)
	if not serverdata.WaitReady(player, 30) then
		return
	end
	local function hook(container)
		if not container then
			return
		end
		container.ChildAdded:Connect(function(child)
			if isfruittool(child) then
				task.defer(attachskin, player, child)
				task.delay(0.2, sync, player)
			end
		end)
		for _, child in ipairs(container:GetChildren()) do
			if isfruittool(child) then
				task.defer(attachskin, player, child)
			end
		end
	end
	hook(player:FindFirstChildOfClass("Backpack"))
	hook(player.Character)
	player.ChildAdded:Connect(function(child)
		if child:IsA("Backpack") then
			hook(child)
		end
	end)
	player.CharacterAdded:Connect(hook)
	player.Chatted:Connect(function(message)
		if not isadmin(player) then
			return
		end
		local command, rest = message:match("^/(%w+)%s*(.*)$")
		command = command and command:lower()
		if command == "skin" or command == "mutation" then
			local count = grant(player, rest ~= "" and rest or "all", command == "skin" and "Skin" or "Mutation")
			serverdata.Notify(player, "Unlocked <Color=Green>" .. count .. "<Color=/> " .. command .. (count == 1 and "" or "s") .. ".")
		end
	end)
	sync(player)
end

return function(router, data)
	serverdata = data
	local built, err = pcall(buildcatalog)
	if not built then
		warn("[modifications] catalog failed: " .. tostring(err))
	end
	local count = 0
	for _ in pairs(catalog) do
		count += 1
	end
	workspace:SetAttribute("modificationcatalog", count)
	local ok, net = pcall(require, replicatedstorage:WaitForChild("Modules"):WaitForChild("Net"))
	if ok then
		modevent = net:RemoteEvent("ModificationEvent")
	end
	router.netFunction("ModificationFunction", function(player, request)
		if type(request) ~= "table" then
			return { Type = "Generic", Success = false }
		end
		if request.Type == "GetData" then
			return { Type = "GetData", Data = payload(player) }
		elseif request.Type == "SetEquip" and type(request.ItemId) == "number" and type(request.IsEquipped) == "boolean" then
			return setequip(player, request.ItemId, request.IsEquipped)
		end
		return { Type = "Generic", Success = false }
	end)
	players.PlayerAdded:Connect(function(player)
		task.spawn(watch, player)
	end)
	for _, player in ipairs(players:GetPlayers()) do
		task.spawn(watch, player)
	end
end
