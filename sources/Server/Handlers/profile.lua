local players = game:GetService("Players")
local replicatedstorage = game:GetService("ReplicatedStorage")
local serverstorage = game:GetService("ServerStorage")
local datastoreservice = game:GetService("DataStoreService")
local teleportservice = game:GetService("TeleportService")

local server = script.Parent.Parent
local config = require(server.Config)

local itemconfig = require(replicatedstorage:WaitForChild("ItemConfig"))
local profilebackgrounds = require(replicatedstorage:WaitForChild("Modules"):WaitForChild("ProfileBackgrounds"))
local islandlookup = require(replicatedstorage.Modules:WaitForChild("IslandLocationLookup"))

local displaytitle = nil
pcall(function()
	displaytitle = require(replicatedstorage:WaitForChild("DisplayTitle"))
end)

local statnames = {
	"Fighting Styles Unlocked",
	"Swords Unlocked",
	"Guns Unlocked",
	"Money",
	"Sea Events Cleared",
	"Races Evolved",
	"First Joined",
	"Total Fish Caught",
	"Fish Types Caught",
	"Fragments",
	"Bounty",
	"Honor",
	"Gifts Sent",
	"Permanent Fruits Owned",
	"Fruits Mastered",
	"Fighting Styles Mastered",
	"Races Fully Awakened",
}

local statmax = {
	["Fighting Styles Unlocked"] = 12,
	["Swords Unlocked"] = 40,
	["Guns Unlocked"] = 14,
	["Races Evolved"] = 7,
	["Fish Types Caught"] = 60,
	["Permanent Fruits Owned"] = 42,
	["Fruits Mastered"] = 43,
	["Fighting Styles Mastered"] = 13,
	["Races Fully Awakened"] = 7,
}

local packed = {
	Money = 1000000000,
	Fragments = 1000000000,
	Bounty = 30000000,
	Honor = 30000000,
	["First Joined"] = math.huge,
}

local settingnames = {
	"JoinServer",
	"LevelVisible",
	"RaceVisible",
	"AccessoriesVisible",
	"CombatToolsVisible",
	"ShowcaseVisible",
	"CrewVisible",
	"LocationVisible",
	"FindInRecent",
	"CanReceiveGifts",
}
local settingvalues = { Everyone = true, FriendsOnly = true, Nobody = true }

local races = { Human = true, Fishman = true, Mink = true, Skypiea = true, Ghoul = true, Cyborg = true, Draco = true }
local rarities = { Common = 1, Uncommon = 2, Rare = 3, Legendary = 4, Mythical = 5 }

local locationids = {}
for id, name in pairs(islandlookup.IdToValue or {}) do
	locationids[name] = id
end
for name, id in pairs(islandlookup.ValueToId or {}) do
	locationids[name] = id
end

local serverdata
local recentlimit = 30

local function profileof(player)
	local extra = serverdata.GetExtra(player)
	if not extra then
		return nil, nil
	end
	local profile = extra.Profile
	if type(profile) ~= "table" then
		profile = {}
		extra.Profile = profile
	end
	profile.StatusId = tonumber(profile.StatusId) or 0
	profile.SubStatusId = tonumber(profile.SubStatusId) or 0
	profile.BackgroundIndex = tonumber(profile.BackgroundIndex) or 0
	profile.Showcase = type(profile.Showcase) == "table" and profile.Showcase or {}
	profile.Stats = type(profile.Stats) == "table" and profile.Stats or {}
	profile.Settings = type(profile.Settings) == "table" and profile.Settings or {}
	for _, name in ipairs(settingnames) do
		if not settingvalues[profile.Settings[name]] then
			profile.Settings[name] = "Everyone"
		end
	end
	profile.OwnedBackgrounds = type(profile.OwnedBackgrounds) == "table" and profile.OwnedBackgrounds or {}
	profile.NewBackgrounds = type(profile.NewBackgrounds) == "table" and profile.NewBackgrounds or {}
	profile.Recent = type(profile.Recent) == "table" and profile.Recent or {}
	if type(profile.FirstJoined) ~= "number" then
		profile.FirstJoined = os.time()
	end
	profile.GiftsSent = tonumber(profile.GiftsSent) or 0
	return profile, extra
end

local function datavalue(player, name)
	local value = serverdata.Get(player, name)
	return value
end

local function weapontype(name)
	local items = serverstorage:FindFirstChild("Items")
	local tool = items and items:FindFirstChild(name)
	if not tool then
		return nil, nil
	end
	local kind = tool:GetAttribute("WeaponType")
	if not kind and string.match(name, "^(.+)%-%1$") then
		kind = "Demon Fruit"
	end
	return kind, tool:GetAttribute("ItemId")
end

local function ownedtools(player, extra)
	local owned = {}
	local function add(name)
		if type(name) == "string" then
			owned[name] = true
		end
	end
	for _, container in ipairs({ player:FindFirstChildOfClass("Backpack"), player.Character }) do
		if container then
			for _, child in ipairs(container:GetChildren()) do
				if child:IsA("Tool") then
					add(child.Name)
				end
			end
		end
	end
	local shop = extra and extra.Shop
	if type(shop) == "table" and type(shop.weapons) == "table" then
		for name in pairs(shop.weapons) do
			add(name)
		end
	end
	return owned
end

local function counttypes(owned, kind)
	local count = 0
	for name in pairs(owned) do
		if weapontype(name) == kind then
			count += 1
		end
	end
	return count
end

local function mastered(extra, kind)
	local count = 0
	if type(extra.Mastery) == "table" then
		for name, entry in pairs(extra.Mastery) do
			if type(entry) == "table" and (tonumber(entry.Level) or 0) >= 600 and weapontype(name) == kind then
				count += 1
			end
		end
	end
	return count
end

local function fishstats(extra)
	local total, kinds = 0, 0
	if type(extra.Fish) == "table" then
		for _, value in pairs(extra.Fish) do
			kinds += 1
			if type(value) == "number" then
				total += value
			elseif type(value) == "table" then
				total += tonumber(value.Count or value.Amount or value.Caught) or 1
			else
				total += 1
			end
		end
	end
	return total, kinds
end

local function racelevel(player)
	local data = player:FindFirstChild("Data")
	local race = data and data:FindFirstChild("Race")
	if not race then
		return "Human", 1, 0, 0
	end
	local name = races[race.Value] and race.Value or "Human"
	local evolved = race:FindFirstChild("Evolved") ~= nil
	local level = evolved and 2 or 1
	local c = race:FindFirstChild("C")
	if evolved and c and c:IsA("ValueBase") and tonumber(c.Value) and c.Value >= 1 then
		level = 3
	end
	local awakened = race:FindFirstChild("Awakened") ~= nil or player:GetAttribute("RaceAwakened") == true
	if awakened then
		level = 4
	end
	return name, level, evolved and 1 or 0, awakened and 1 or 0
end

local function pack(value)
	value = math.clamp(math.floor(value), 0, 4294967295)
	return {
		Progression = bit32.band(value, 0xFFFF),
		MaxProgression = bit32.rshift(value, 16),
	}
end

local function statvalues(player)
	local profile, extra = profileof(player)
	if not profile then
		return nil
	end
	local owned = ownedtools(player, extra)
	local leaderstats = player:FindFirstChild("leaderstats")
	local bountyhonor = leaderstats and leaderstats:FindFirstChild("Bounty/Honor")
	local bh = bountyhonor and bountyhonor.Value or 0
	local pirate = player.Team == nil or player.Team.Name ~= "Marines"
	local totalfish, fishkinds = fishstats(extra)
	local _, _, evolved, awakened = racelevel(player)
	local permanent = 0
	if type(extra.Fruits) == "table" then
		for _, count in pairs(extra.Fruits) do
			if (tonumber(count) or 0) > 0 then
				permanent += 1
			end
		end
	end
	return {
		["Fighting Styles Unlocked"] = counttypes(owned, "Melee"),
		["Swords Unlocked"] = counttypes(owned, "Sword"),
		["Guns Unlocked"] = counttypes(owned, "Gun"),
		Money = datavalue(player, "Beli") or 0,
		["Sea Events Cleared"] = datavalue(player, "SeaEventsCleared") or 0,
		["Races Evolved"] = evolved,
		["First Joined"] = profile.FirstJoined,
		["Total Fish Caught"] = totalfish,
		["Fish Types Caught"] = fishkinds,
		Fragments = datavalue(player, "Fragments") or 0,
		Bounty = pirate and bh or 0,
		Honor = pirate and 0 or bh,
		["Gifts Sent"] = profile.GiftsSent,
		["Permanent Fruits Owned"] = permanent,
		["Fruits Mastered"] = mastered(extra, "Demon Fruit"),
		["Fighting Styles Mastered"] = mastered(extra, "Melee"),
		["Races Fully Awakened"] = awakened,
	}
end

local function statentry(values, statid)
	local name = statnames[statid + 1]
	if not name then
		return nil
	end
	local value = tonumber(values[name]) or 0
	if packed[name] then
		local entry = pack(math.min(value, packed[name]))
		entry.StatId = statid
		return entry
	end
	return {
		StatId = statid,
		Progression = math.max(0, math.floor(value)),
		MaxProgression = statmax[name] or 0,
	}
end

local function equipped(player)
	local result = { Demon = 0, Sword = 0, Gun = 0, Melee = 0 }
	local function scan(container, overwrite)
		if not container then
			return
		end
		for _, child in ipairs(container:GetChildren()) do
			if child:IsA("Tool") then
				local kind, itemid = weapontype(child.Name)
				itemid = child:GetAttribute("ItemId") or itemid
				local slot = kind == "Demon Fruit" and "Demon" or kind
				if slot and result[slot] ~= nil and type(itemid) == "number" and (overwrite or result[slot] == 0) then
					result[slot] = itemid
				end
			end
		end
	end
	scan(player:FindFirstChildOfClass("Backpack"), false)
	scan(player.Character, true)
	return result
end

local function titleof(player, extra)
	local name = player:GetAttribute("Title") or player:GetAttribute("EquippedTitle") or extra.EquippedTitle
	if type(name) ~= "string" or name == "" then
		return "", Color3.new(0, 0, 0)
	end
	local text, color = name, nil
	if displaytitle then
		pcall(function()
			text = displaytitle.GetTitleText(name)
			color = displaytitle.GetTitleColor(name)
		end)
	end
	if typeof(color) ~= "Color3" then
		color = Color3.fromRGB(255, 255, 255)
	end
	return string.sub(tostring(text), 1, 32), color
end

local function crewof(player)
	local crew = datavalue(player, "CrewID")
	if type(crew) == "string" and crew ~= "" then
		return string.sub(player:GetAttribute("CrewName") or crew, 1, 32)
	end
	return ""
end

local function location(player)
	local current = player:GetAttribute("CurrentLocation")
	if type(current) == "string" and locationids[current] then
		return locationids[current]
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local origin = workspace:FindFirstChild("_WorldOrigin")
	local locations = origin and origin:FindFirstChild("Locations")
	if not root or not locations then
		return 0
	end
	local best, bestdistance = 0, 2500
	for _, part in ipairs(locations:GetChildren()) do
		if part:IsA("BasePart") and locationids[part.Name] then
			local distance = (Vector3.new(part.Position.X, 0, part.Position.Z) - Vector3.new(root.Position.X, 0, root.Position.Z)).Magnitude
			if distance < bestdistance then
				best, bestdistance = locationids[part.Name], distance
			end
		end
	end
	return best
end

local function rarityof(itemid)
	local item = itemid ~= 0 and itemconfig.tryGet(itemid) or nil
	local rarity = item and item.Quality and item.Quality.Rarity
	return rarities[rarity] or (item and 1 or 0)
end

local function quantityof(extra, itemid)
	local shop = extra.Shop
	local amount = type(shop) == "table" and type(shop.quantity) == "table" and tonumber(shop.quantity[tostring(itemid)]) or nil
	return math.clamp(amount or 1, 0, 65535)
end

local function buildprofile(player)
	local profile, extra = profileof(player)
	if not profile then
		return nil
	end
	local race, level = racelevel(player)
	local gear = equipped(player)
	local titletext, titlecolor = titleof(player, extra)
	local crew = crewof(player)
	local shop = extra.Shop
	local accessory = type(shop) == "table" and tonumber(shop.accessory) or 0
	local data = {
		Verified = false,
		Online = true,
		IsInCrew = crew ~= "",
		IsStarCreator = false,
		IsDeveloper = player.UserId == game.CreatorId or player.UserId == 5425038292,
		Race = race,
		RaceLevel = level,
		Level = datavalue(player, "Level") or 1,
		EquippedAccessory = accessory or 0,
		EquippedFightingStyle = gear.Melee,
		EquippedFruit = gear.Demon,
		EquippedGun = gear.Gun,
		EquippedSword = gear.Sword,
		EquippedTrinket1 = 0,
		EquippedTrinket2 = 0,
		Settings = table.clone(profile.Settings),
		CrewName = crew,
		TitleText = titletext,
		TitleColor = titlecolor,
		StatusId = profile.StatusId,
		SubStatusId = profile.SubStatusId,
		LastLocation = location(player),
		BackgroundIndex = profile.BackgroundIndex,
		StanceOverrideId = 0,
	}
	for i = 1, 6 do
		local itemid = tonumber(profile.Showcase[tostring(i)]) or 0
		data[`ShowcaseSlot{ i }Id`] = itemid
		data[`ShowcaseSlot{ i }Rarity`] = rarityof(itemid)
		data[`ShowcaseSlot{ i }Quantity`] = itemid ~= 0 and quantityof(extra, itemid) or 0
	end
	local values = statvalues(player)
	for i = 1, 4 do
		local statid = tonumber(profile.Stats[tostring(i)])
		data[`Stat{ i }`] = statid and values and statentry(values, statid) or nil
	end
	return data
end

local function serialize(data)
	local copy = table.clone(data)
	copy.Settings = table.clone(data.Settings)
	copy.TitleColor = { data.TitleColor.R, data.TitleColor.G, data.TitleColor.B }
	copy.Online = false
	return copy
end

local function deserialize(copy)
	if type(copy) ~= "table" then
		return nil
	end
	local data = table.clone(copy)
	local color = copy.TitleColor
	data.TitleColor = type(color) == "table" and Color3.new(color[1] or 0, color[2] or 0, color[3] or 0) or Color3.new(0, 0, 0)
	data.Online = false
	return data
end

local function snapshot(player)
	local _, extra = profileof(player)
	if not extra then
		return
	end
	local ok, data = pcall(buildprofile, player)
	if ok and data then
		extra.ProfileSnapshot = serialize(data)
	end
end

local store = nil
local function readoffline(userid)
	if store == nil then
		local ok, result = pcall(function()
			return datastoreservice:GetDataStore(config.DataStoreName)
		end)
		store = ok and result or false
	end
	if not store then
		return nil
	end
	local ok, record = pcall(function()
		return store:GetAsync("Player_" .. tostring(userid))
	end)
	if not ok then
		return false
	end
	local extra = type(record) == "table" and type(record.data) == "table" and record.data.Extra
	return type(extra) == "table" and deserialize(extra.ProfileSnapshot) or nil
end

local function addrecent(player, other, context)
	if not other or other == player or not serverdata.IsReady(player) then
		return
	end
	local profile = profileof(player)
	if not profile then
		return
	end
	local otherprofile = serverdata.IsReady(other) and profileof(other) or nil
	if otherprofile and otherprofile.Settings.FindInRecent == "Nobody" then
		return
	end
	for index = #profile.Recent, 1, -1 do
		if profile.Recent[index].UserId == other.UserId then
			table.remove(profile.Recent, index)
		end
	end
	table.insert(profile.Recent, 1, { UserId = other.UserId, Username = other.Name, Context = context, Time = os.time() })
	while #profile.Recent > recentlimit do
		table.remove(profile.Recent)
	end
end

local function friendsonline(player)
	local ok, list = pcall(player.GetFriendsOnline, player, 200)
	local map = {}
	if ok and type(list) == "table" then
		for _, entry in ipairs(list) do
			map[entry.VisitorId] = entry
		end
	end
	return map
end

local function isfriend(player, userid)
	local ok, result = pcall(player.IsFriendsWith, player, userid)
	return ok and result == true
end

local function lookup(player, category)
	local result = {}
	if category == "Server" then
		for _, other in ipairs(players:GetPlayers()) do
			if other ~= player then
				table.insert(result, {
					UserId = other.UserId,
					Username = other.Name,
					Context = "In your server",
					IsFriend = isfriend(player, other.UserId),
					IsOnline = true,
				})
			end
		end
	elseif category == "Recent" then
		local profile = profileof(player)
		local online = friendsonline(player)
		for _, entry in ipairs(profile and profile.Recent or {}) do
			table.insert(result, {
				UserId = entry.UserId,
				Username = entry.Username,
				Context = entry.Context or "Recently interacted",
				IsFriend = isfriend(player, entry.UserId),
				IsOnline = players:GetPlayerByUserId(entry.UserId) ~= nil or online[entry.UserId] ~= nil,
			})
		end
	elseif category == "Global" then
		local online = friendsonline(player)
		local ok, pages = pcall(players.GetFriendsAsync, players, player.UserId)
		if ok and pages then
			local count = 0
			while count < 200 do
				for _, friend in ipairs(pages:GetCurrentPage()) do
					count += 1
					table.insert(result, {
						UserId = friend.Id,
						Username = friend.Username,
						Context = "Friend",
						IsFriend = true,
						IsOnline = online[friend.Id] ~= nil or players:GetPlayerByUserId(friend.Id) ~= nil,
					})
				end
				if pages.IsFinished then
					break
				end
				local advanced = pcall(pages.AdvanceToNextPageAsync, pages)
				if not advanced then
					break
				end
			end
		end
		table.sort(result, function(a, b)
			if a.IsOnline ~= b.IsOnline then
				return a.IsOnline
			end
			return a.Username < b.Username
		end)
	end
	return result
end

local function ownsbackground(player, profile, name, index)
	if index == 0 or name == "Default" then
		return true
	end
	local entry = profilebackgrounds.List[name]
	if entry and entry.SelectCriteria then
		local ok, allowed = pcall(entry.SelectCriteria, player.UserId, { IsDeveloper = player.UserId == game.CreatorId or player.UserId == 5425038292 })
		if ok and allowed then
			return true
		end
	end
	return profile.OwnedBackgrounds[name] == true
end

local function ownsitem(player, extra, itemid)
	local item = itemconfig.tryGet(itemid)
	if not item then
		return false
	end
	local shop = extra.Shop
	if type(shop) == "table" and type(shop.quantity) == "table" and (tonumber(shop.quantity[tostring(itemid)]) or 0) > 0 then
		return true
	end
	for _, container in ipairs({ player:FindFirstChildOfClass("Backpack"), player.Character }) do
		if container then
			for _, child in ipairs(container:GetChildren()) do
				if child:IsA("Tool") and (child:GetAttribute("ItemId") == itemid or child.Name == item.Index.StorageKey) then
					return true
				end
			end
		end
	end
	if item.Index.IdType == "Title" and type(extra.Titles) == "table" and extra.Titles[item.Index.StorageKey] then
		return true
	end
	return type(shop) == "table" and type(shop.weapons) == "table" and shop.weapons[item.Index.StorageKey] == true
end

local function update(player, action, first, second)
	local profile, extra = profileof(player)
	if not profile then
		return false, "Data not loaded"
	end
	if action == "Background" then
		local index = tonumber(first)
		local name = index and profilebackgrounds.IdToNameMap[index]
		if not name or not ownsbackground(player, profile, name, index) then
			return false, "Background not owned"
		end
		profile.BackgroundIndex = index
	elseif action == "ClearNewBackground" then
		if type(first) ~= "string" then
			return false, "Bad background"
		end
		profile.NewBackgrounds[first] = nil
	elseif action == "Showcase" then
		local slot = tonumber(first)
		local itemid = tonumber(second)
		if not slot or slot < 1 or slot > 6 or slot % 1 ~= 0 or not itemid then
			return false, "Bad slot"
		end
		if itemid ~= 0 then
			if not ownsitem(player, extra, itemid) then
				return false, "Item not owned"
			end
			for i = 1, 6 do
				if tonumber(profile.Showcase[tostring(i)]) == itemid then
					profile.Showcase[tostring(i)] = nil
				end
			end
			profile.Showcase[tostring(slot)] = itemid
		else
			profile.Showcase[tostring(slot)] = nil
		end
	elseif action == "Stat" then
		local slot = tonumber(first)
		local statid = tonumber(second)
		if not slot or slot < 1 or slot > 4 or slot % 1 ~= 0 or not statid or not statnames[statid + 1] then
			return false, "Bad stat"
		end
		local wasselected = tonumber(profile.Stats[tostring(slot)]) == statid
		for i = 1, 4 do
			if tonumber(profile.Stats[tostring(i)]) == statid then
				profile.Stats[tostring(i)] = nil
			end
		end
		if not wasselected then
			profile.Stats[tostring(slot)] = statid
		end
	elseif action == "Status" then
		local statusid = tonumber(first)
		if not statusid or statusid < 0 or statusid > 200 or statusid % 1 ~= 0 then
			return false, "Bad status"
		end
		profile.StatusId = statusid ~= 0 and statusid or 9
		profile.SubStatusId = 0
	elseif action == "SubStatus" then
		local substatus = tonumber(first)
		if not substatus or substatus < 0 or substatus > 32 or substatus % 1 ~= 0 then
			return false, "Bad sub status"
		end
		profile.SubStatusId = substatus
	elseif action == "Setting" then
		if not table.find(settingnames, first) or not settingvalues[second] then
			return false, "Bad setting"
		end
		profile.Settings[first] = second
	else
		return false, "Unknown action"
	end
	task.defer(snapshot, player)
	return true
end

local function profiledata(player, userid)
	userid = tonumber(userid)
	if not userid then
		return nil
	end
	local target = players:GetPlayerByUserId(userid)
	if target then
		if not serverdata.WaitReady(target, 10) then
			return nil
		end
		if target ~= player then
			addrecent(player, target, "Viewed their profile")
		end
		return buildprofile(target)
	end
	return readoffline(userid)
end

local function onlinestatus(player, userid)
	userid = tonumber(userid)
	if not userid then
		return false
	end
	if players:GetPlayerByUserId(userid) then
		return true
	end
	return friendsonline(player)[userid] ~= nil
end

local function joinplayer(player, userid)
	userid = tonumber(userid)
	if not userid or players:GetPlayerByUserId(userid) then
		return
	end
	local entry = friendsonline(player)[userid]
	if not entry or entry.PlaceId ~= game.PlaceId or type(entry.GameId) ~= "string" then
		serverdata.Notify(player, "<Color=Red>That player isn't in a joinable server.<Color=/>")
		return
	end
	local ok = pcall(teleportservice.TeleportToPlaceInstance, teleportservice, game.PlaceId, entry.GameId, player)
	if not ok then
		serverdata.Notify(player, "<Color=Red>Failed to join that player.<Color=/>")
	end
end

return function(router, data)
	serverdata = data
	local rf = { className = "RemoteFunction", limit = { rate = 4, burst = 10 } }
	router.remote("GetPlayerProfileData", profiledata, { className = "RemoteFunction", limit = { rate = 2, burst = 6 } })
	router.remote("GetPlayerStats", function(player)
		local values = statvalues(player)
		if not values then
			return {}
		end
		local list = {}
		for index, name in ipairs(statnames) do
			local entry = statentry(values, index - 1)
			entry.DisplayName = name
			table.insert(list, entry)
		end
		return list
	end, rf)
	router.remote("GetPlayerStatDisplayNames", function()
		return table.clone(statnames)
	end, { className = "RemoteFunction", requireData = false, limit = { rate = 4, burst = 10 } })
	router.remote("GetProfileBackgroundList", function(player)
		local profile = profileof(player)
		if not profile then
			return false
		end
		local owned = { Default = true }
		for index, name in pairs(profilebackgrounds.IdToNameMap) do
			if ownsbackground(player, profile, name, index) then
				owned[name] = true
			end
		end
		return true, owned, table.clone(profile.NewBackgrounds)
	end, { className = "RemoteFunction", limit = { rate = 4, burst = 10 } })
	router.remote("UpdatePlayerProfileValue", update, { className = "RemoteFunction", limit = { rate = 6, burst = 12 } })
	router.remote("MarkPlayerProfileOpened", function(player)
		local profile = profileof(player)
		if profile then
			profile.Opened = true
		end
	end, { limit = { rate = 2, burst = 4 } })
	router.remote("GetPlayerProfileOpened", function(player)
		local profile = profileof(player)
		return profile ~= nil and profile.Opened == true
	end, { className = "RemoteFunction", limit = { rate = 4, burst = 8 } })
	router.remote("GetPlayerLookupInfo", function(player, category)
		if category ~= "Server" and category ~= "Recent" and category ~= "Global" then
			return {}
		end
		return lookup(player, category)
	end, { className = "RemoteFunction", limit = { rate = 3, burst = 6 } })
	router.remote("GetPlayerLookupOnlineStatus", onlinestatus, { className = "RemoteFunction", limit = { rate = 3, burst = 6 } })
	router.remote("JoinPlayerFromProfile", joinplayer, { limit = { rate = 1, burst = 2 } })

	local events = serverstorage:WaitForChild("hitboxevents", 30)
	local damaged = events and events:FindFirstChild("damaged")
	if damaged and damaged:IsA("BindableEvent") then
		damaged.Event:Connect(function(attacker, model)
			local victim = model and players:GetPlayerFromCharacter(model)
			if attacker and attacker:IsA("Player") and victim then
				addrecent(attacker, victim, "Fought in PvP")
				addrecent(victim, attacker, "Fought in PvP")
			end
		end)
	end

	task.spawn(function()
		while true do
			for _, player in ipairs(players:GetPlayers()) do
				if serverdata.IsReady(player) then
					task.spawn(snapshot, player)
				end
			end
			task.wait(60)
		end
	end)
	pcall(function()
		require(serverstorage:WaitForChild("ServerSignals")).PlayerDataSaving():Connect(function(player)
			pcall(snapshot, player)
		end)
	end)
end
