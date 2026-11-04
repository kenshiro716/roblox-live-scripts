local players = game:GetService("Players")
local replicatedstorage = game:GetService("ReplicatedStorage")
local serverstorage = game:GetService("ServerStorage")
local runservice = game:GetService("RunService")

local fruitkit = require(serverstorage:WaitForChild("fruitkit"))

local tool = script.Parent
local data = require(tool:WaitForChild("Data"))

local portalradius = 6
local portalreuse = 1.5
local leaprange = 75
local escapeduration = 4
local escaperadius = 18
local warpstartup = 2
local warpchainradius = 25
local riftpullradius = 45
local riftpulltime = 1.5
local riftdrain = 6
local riftexitradius = 18
local riftheight = 12000
local riftspacing = 8000
local riftmincooldown = 12
local riftmaxcooldown = 24
local riftfulltime = 20
local dashassistangle = math.rad(14)

local kit
local escape = { token = nil, hidden = {}, field = nil, walkspeed = nil, door = nil }
local rift = nil
local portalpairs = {}
local riftslots = 0

local function isnpc(model)
	return players:GetPlayerFromCharacter(model) == nil
end

local function rootof(model)
	return model and (model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart)
end

local function enemyof(character, model)
	if model == character then
		return false
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end
	if isnpc(model) then
		return true
	end
	return character:GetAttribute("PvpDisabled") == false and model:GetAttribute("PvpDisabled") == false
end

local function stun(model, duration)
	local value = model:FindFirstChild("Stun")
	if not value or not value:IsA("ValueBase") then
		return
	end
	value.Value = math.max(value.Value, duration)
	if isnpc(model) then
		task.delay(duration, function()
			if value.Parent and value.Value <= duration then
				value.Value = 0
			end
		end)
	end
end

local function spend(character, cost)
	local energy = character:FindFirstChild("Energy")
	if not energy or not cost or cost <= 0 then
		return true
	end
	if energy.Value < cost then
		return false
	end
	energy.Value -= cost
	return true
end

local function worldend(character, from, direction, distance)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {
		character,
		workspace:FindFirstChild("_WorldOrigin"),
		workspace:FindFirstChild("Characters"),
		workspace:FindFirstChild("Enemies"),
	}
	local result = workspace:Raycast(from, direction * distance, params)
	return result and result.Position or from + direction * distance
end

local function drivenpc(victimroot, duration, path, onfinish)
	local npc = isnpc(victimroot.Parent)
	local wasanchored = victimroot.Anchored
	if npc then
		victimroot.Anchored = true
	end
	local started = os.clock()
	local connection
	connection = runservice.Heartbeat:Connect(function()
		local elapsed = os.clock() - started
		if not victimroot.Parent or elapsed >= duration then
			connection:Disconnect()
			if victimroot.Parent then
				if npc then
					victimroot.CFrame = path(1)
					victimroot.Anchored = wasanchored
				end
				if onfinish then
					onfinish()
				end
			end
			return
		end
		if npc then
			victimroot.CFrame = path(elapsed / duration)
		end
	end)
end

local function setescapehidden(character, hidden)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if hidden then
		for _, d in ipairs(character:GetDescendants()) do
			if (d:IsA("BasePart") or d:IsA("Decal")) and d.Transparency < 1 and d.Name ~= "HumanoidRootPart" then
				escape.hidden[d] = d.Transparency
				d.Transparency = 1
			elseif d:IsA("BillboardGui") and d.Enabled then
				escape.hidden[d] = true
				d.Enabled = false
			end
		end
		if humanoid then
			escape.display = humanoid.DisplayDistanceType
			humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end
	else
		for d, value in pairs(escape.hidden) do
			if d.Parent then
				if d:IsA("BillboardGui") then
					d.Enabled = value
				else
					d.Transparency = value
				end
			end
		end
		table.clear(escape.hidden)
		if humanoid and escape.display then
			humanoid.DisplayDistanceType = escape.display
		end
		escape.display = nil
	end
end

local function endescape(player)
	if not escape.token then
		return
	end
	escape.token = nil
	local character = player and player.Character
	local root = rootof(character)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if character then
		setescapehidden(character, false)
	end
	if escape.field then
		escape.field:Destroy()
		escape.field = nil
	end
	if escape.door then
		escape.door:Destroy()
		escape.door = nil
	end
	if humanoid and escape.walkspeed then
		humanoid.WalkSpeed = escape.walkspeed
	end
	escape.walkspeed = nil
	if root then
		kit:play("Portal.XEnd", { player = player, char = character, hrp = root, portalLastsFor = 1.5, origin = root.Position })
	end
end

local function parallelescape(player, character, root, humanoid)
	local origin = root.Position
	kit:play("Portal.XInit", { player = player, char = character, hrp = root, portalLastsFor = escapeduration, origin = origin })
	kit:eachtarget(character, function(model, victimhumanoid, victimroot)
		if enemyof(character, model) and (victimroot.Position - origin).Magnitude <= escaperadius then
			kit:play("Portal.XDamage", { player = player, origin = origin + Vector3.new(0, 3.5, 0), victimRoot = victimroot })
			kit:hit(victimhumanoid, data.damage.xentry, victimroot)
			stun(model, 1)
		end
	end)
	local token = {}
	escape.token = token
	local door = Instance.new("BoolValue")
	door.Name = "DoorMode"
	door.Value = true
	door.Parent = character
	escape.door = door
	task.delay(0.3, function()
		if escape.token ~= token then
			return
		end
		setescapehidden(character, true)
		escape.field = Instance.new("ForceField")
		escape.field.Visible = false
		escape.field.Parent = character
		escape.walkspeed = humanoid.WalkSpeed
		humanoid.WalkSpeed = humanoid.WalkSpeed * 1.4
	end)
	task.delay(escapeduration, function()
		if escape.token == token then
			endescape(player)
		end
	end)
end

local function portaldash(player, character, root, aim)
	local origin = root.Position
	local direction = aim.target - origin
	direction = Vector3.new(direction.X, math.max(direction.Y, 0), direction.Z)
	direction = direction.Magnitude > 1 and direction.Unit or aim.forward
	local length, radius, travel = 90, 7, 0.35
	local finish = worldend(character, origin, direction, length)
	local victimroot = nil
	kit:eachtarget(character, function(model, _, candidate)
		if victimroot or not enemyof(character, model) then
			return
		end
		local t = (candidate.Position - origin):Dot(direction)
		if t >= 0 and t <= (finish - origin).Magnitude and (origin + direction * t - candidate.Position).Magnitude <= radius then
			victimroot = candidate
		end
	end)
	if not victimroot then
		local best = dashassistangle
		kit:eachtarget(character, function(model, _, candidate)
			if not enemyof(character, model) then
				return
			end
			local offset = candidate.Position - origin
			local distance = offset.Magnitude
			if distance < 1 or distance > length then
				return
			end
			local angle = math.acos(math.clamp(offset.Unit:Dot(direction), -1, 1))
			if angle <= best then
				best = angle
				victimroot = candidate
			end
		end)
		if victimroot then
			direction = (victimroot.Position - origin).Unit
		end
	end
	if victimroot then
		finish = victimroot.Position - direction * 4
	end

	kit:play("Portal.ZDash", {
		player = player,
		hrp = root,
		origin = origin,
		fireDir = direction,
		forwardCylinderRadius = radius,
		timeUntilReachedEndPoint = travel,
		victimExists = victimroot ~= nil,
		endPoint = finish,
		forwardCylinderLength = (finish - origin).Magnitude,
	})
	kit.busyuntil = os.clock() + travel + 0.2
	if not victimroot then
		return
	end

	task.delay(travel, function()
		local model = victimroot.Parent
		local humanoid = model and model:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			return
		end
		kit:hit(humanoid, data.damage.zdash, victimroot)
		stun(model, 2)
		local flat = Vector3.new(direction.X, 0, direction.Z)
		flat = flat.Magnitude > 0.01 and flat.Unit or root.CFrame.LookVector
		local impact = kit:groundbelow(victimroot.Position + flat * 37, character)
		local looptime, falltime = 1, 0.4
		kit:play("Portal.ZVictim", {
			player = player,
			origin = victimroot.Position,
			impactPos = impact,
			fireDir = flat,
			enemyRoot = victimroot,
			syncedEndTime = workspace:GetServerTimeNow() + 0.2 + looptime + falltime,
			portalLoopTime = looptime,
			timeUntilImpactAfterFinalPortal = falltime,
		})
		local start = victimroot.Position
		local entry = start + flat * 37 + Vector3.new(0, 3, 0)
		local above = impact + Vector3.new(0, 30, 0)
		local drop = impact + Vector3.new(0, 42, 0)
		local land = impact + Vector3.new(0, 3, 0)
		local total = 0.2 + looptime + falltime
		drivenpc(victimroot, total, function(alpha)
			local t = alpha * total
			if t < 0.2 then
				return CFrame.new(start:Lerp(entry, t / 0.2))
			elseif t < 0.2 + looptime then
				local spin = (t - 0.2) / looptime * math.pi * 6
				return CFrame.new(above + Vector3.new(math.cos(spin) * 20, math.sin(spin * 0.5) * 8, math.sin(spin) * 20))
			end
			return CFrame.new(drop:Lerp(land, (t - 0.2 - looptime) / falltime))
		end, function()
			kit:hit(humanoid, data.damage.zimpact, victimroot)
			stun(model, 1)
		end)
	end)
end

local function openpair(player, a, b, lookdir, lasts, damage)
	local pair = {
		player = player,
		ends = { a, b },
		lookdir = lookdir,
		expires = os.clock() + lasts,
		used = {},
		damage = damage,
	}
	table.insert(portalpairs, pair)
	return pair
end

local function passthrough(pair, model, root, from, to)
	local now = os.clock()
	if (pair.used[model] or 0) > now then
		return
	end
	local owner = pair.player
	local character = owner and owner.Character
	local isowner = model == character
	if not isowner and not isnpc(model) and model:GetAttribute("PvpDisabled") ~= false then
		return
	end
	pair.used[model] = now + portalreuse
	local exit = CFrame.lookAt(to, to + pair.lookdir) * CFrame.new(0, 0, -portalradius - 2)
	local damaged = false
	if not isowner and character and enemyof(character, model) then
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		kit:hit(humanoid, pair.damage, root)
		stun(model, 0.6)
		damaged = true
	end
	if isnpc(model) and root.Anchored then
		root.CFrame = exit
	else
		model:PivotTo(exit)
	end
	kit:play("Portal.FPortalTeleport", { player = owner, rootTeleported = root, teleportCFrame = exit, wasDamagedByTeleport = damaged })
end

runservice.Heartbeat:Connect(function()
	if #portalpairs == 0 then
		return
	end
	local now = os.clock()
	for index = #portalpairs, 1, -1 do
		local pair = portalpairs[index]
		if now > pair.expires then
			table.remove(portalpairs, index)
		else
			for _, foldername in ipairs({ "Characters", "Enemies" }) do
				local folder = workspace:FindFirstChild(foldername)
				for _, model in ipairs(folder and folder:GetChildren() or {}) do
					local root = rootof(model)
					local humanoid = model:FindFirstChildOfClass("Humanoid")
					if root and humanoid and humanoid.Health > 0 then
						if (root.Position - pair.ends[1]).Magnitude <= portalradius then
							passthrough(pair, model, root, pair.ends[1], pair.ends[2])
						elseif (root.Position - pair.ends[2]).Magnitude <= portalradius then
							passthrough(pair, model, root, pair.ends[2], pair.ends[1])
						end
					end
				end
			end
		end
	end
end)

local function quantumleap(player, character, root, aim)
	local origin = root.Position
	local target = kit:clamprange(origin, aim.target, leaprange)
	target = kit:groundbelow(target, character) + Vector3.new(0, 3, 0)
	local forward = aim.forward
	local lasts = 12
	local here = origin + Vector3.new(0, 0.5, 0)
	local there = target + Vector3.new(0, 0.5, 0)
	kit:play("Portal.CreatePortal", { player = player, origin = here, lookDir = forward, lastsFor = lasts, emitLightShockwave = true })
	kit:play("Portal.CreatePortal", { player = player, origin = there, lookDir = forward, lastsFor = lasts, emitDarkShockwave = true })
	local pair = openpair(player, here, there, forward, lasts, data.damage.fportal)
	pair.used[character] = os.clock() + portalreuse
	local arrival = CFrame.lookAt(target, target + forward)
	character:PivotTo(arrival)
	kit:play("Portal.PortalJump", { player = player, hrp = root })
	kit:play("Portal.FPortalTeleport", { player = player, rootTeleported = root, teleportCFrame = arrival, wasDamagedByTeleport = false })
	kit.busyuntil = os.clock() + 0.4
end

local function warpdestination(name)
	local origin = workspace:FindFirstChild("_WorldOrigin")
	local locations = origin and origin:FindFirstChild("Locations")
	local part = locations and locations:FindFirstChild(name)
	if not part or not part:IsA("BasePart") or name == "Sea" then
		return nil
	end
	return part.Position
end

local function worldwarp(player, character, root, aim, name)
	local destination = type(name) == "string" and warpdestination(name)
	if not destination then
		return false
	end
	local forward = aim.forward
	local lasts = 14
	local portalpos = root.Position + forward * 8 + Vector3.new(0, 0.5, 0)
	local landing = kit:groundbelow(destination + Vector3.new(0, 300, 0), character) + Vector3.new(0, 3, 0)
	kit:play("Portal.CPortal", {
		player = player,
		origin = portalpos,
		lookDir = -forward,
		lastsFor = lasts,
		delayPortalSpawnBy = warpstartup,
		targetPos = landing,
	})
	kit:play("Portal.CreatePortal", { player = player, origin = landing + Vector3.new(0, 0.5, 0), lookDir = forward, lastsFor = lasts, delayPortalSpawnBy = warpstartup, emitDarkShockwave = true })
	kit.busyuntil = os.clock() + warpstartup + 0.2
	local start = root.Position
	local chained = { [character] = "self" }
	kit:eachtarget(character, function(model, _, victimroot)
		if model ~= character and (victimroot.Position - start).Magnitude <= warpchainradius then
			chained[model] = enemyof(character, model) and "enemy" or "ally"
		end
	end)
	for model, kind in pairs(chained) do
		kit:play("Portal.CChains", { player = player, origin = portalpos, createOrDelete = "Create", lastsFor = warpstartup, lookDir = forward, character = model })
		if kind == "enemy" then
			stun(model, warpstartup + 0.5)
			local victimroot = rootof(model)
			local hold = victimroot and victimroot.CFrame
			if hold then
				drivenpc(victimroot, warpstartup, function()
					return hold
				end)
			end
		end
	end
	task.delay(warpstartup, function()
		if not root.Parent or not rootof(character) then
			return
		end
		local now = workspace:GetServerTimeNow()
		local slot = 0
		for model, kind in pairs(chained) do
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			local victimroot = rootof(model)
			if humanoid and victimroot and humanoid.Health > 0 then
				if kind == "enemy" then
					kit:play("Portal.CChains", { player = player, origin = portalpos, createOrDelete = "Delete", lastsFor = 0, lookDir = forward, character = model })
					kit:hit(humanoid, data.damage.cchains, victimroot)
					stun(model, 1.5)
				elseif (rootof(character).Position - portalpos).Magnitude > warpchainradius or (victimroot.Position - portalpos).Magnitude > warpchainradius then
					kit:play("Portal.CChains", { player = player, origin = portalpos, createOrDelete = "Delete", lastsFor = 0, lookDir = forward, character = model })
				else
					humanoid:SetAttribute("LastCPortalUseTime", now)
					local offset = kind == "self" and Vector3.zero or Vector3.new(math.cos(slot) * 6, 0, math.sin(slot) * 6)
					slot += 1.3
					local arrival = CFrame.lookAt(landing + offset, landing + offset + forward)
					model:PivotTo(arrival)
					kit:play("Portal.FPortalTeleport", { player = player, rootTeleported = victimroot, teleportCFrame = arrival, wasDamagedByTeleport = false })
				end
			end
		end
		local pair = openpair(player, portalpos, landing + Vector3.new(0, 0.5, 0), forward, lasts - warpstartup, data.damage.fportal)
		pair.used[character] = os.clock() + portalreuse
	end)
	return true
end

local function closerift(normalexit)
	local current = rift
	if not current then
		return
	end
	rift = nil
	for model in pairs(current.members) do
		local member = players:GetPlayerFromCharacter(model)
		if member then
			member:SetAttribute("NormalExit", normalexit == true)
		end
	end
	current.owner:SetAttribute("DimensionCancel", true)
	local function sendback()
		for model, info in pairs(current.members) do
			local root = rootof(model)
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			if root then
				root:SetAttribute("PortaledToAnotherDimension", nil)
			end
			if root and humanoid and humanoid.Health > 0 then
				model:PivotTo(info.returnto)
			end
		end
	end
	if normalexit then
		sendback()
	else
		task.delay(1.33, sendback)
	end
	task.delay(3, function()
		for model in pairs(current.members) do
			local member = players:GetPlayerFromCharacter(model)
			if member then
				member:SetAttribute("NormalExit", nil)
			end
		end
	end)
	task.delay(2, function()
		current.owner:Destroy()
		current.floor:Destroy()
	end)
	local inside = math.clamp((os.clock() - current.opened) / riftfulltime, 0, 1)
	local cooldown = riftmincooldown + (riftmaxcooldown - riftmincooldown) * inside
	kit.lastused.V = os.clock() - ((data.Cooldown.V or riftmaxcooldown) - cooldown)
end

local function dimensionalrift(player, character, root)
	if rift then
		closerift()
		return
	end
	local center = kit:groundbelow(root.Position, character)
	riftslots = riftslots % 4 + 1
	local arena = Vector3.new(riftspacing * riftslots, riftheight, -riftspacing)
	local template = replicatedstorage.FX.PortalEffects.VArenaDimension
	local pivot = template:GetPivot().Position
	local floor = Instance.new("Model")
	floor.Name = "riftfloor"
	for _, partname in ipairs({ "StagePart", "InvisWall" }) do
		local source = template:FindFirstChild(partname)
		if source then
			local clone = source:Clone()
			local parts = clone:IsA("BasePart") and { clone } or {}
			for _, d in ipairs(clone:GetDescendants()) do
				if d:IsA("BasePart") then
					table.insert(parts, d)
				elseif not d:IsA("Model") and not d:IsA("Folder") then
					d:Destroy()
				end
			end
			for _, part in ipairs(parts) do
				part.Anchored = true
				part.Transparency = 1
				part.CanCollide = true
				part.CFrame = part.CFrame - pivot + arena
			end
			clone.Parent = floor
		end
	end
	floor.Parent = workspace
	local owner = Instance.new("Part")
	owner.Name = "riftowner"
	owner.Anchored = true
	owner.CanCollide = false
	owner.CanQuery = false
	owner.CanTouch = false
	owner.Transparency = 1
	owner.Size = Vector3.one
	owner.Position = arena
	owner.Parent = workspace:FindFirstChild("_WorldOrigin") or workspace

	local members = {}
	members[character] = { returnto = character:GetPivot(), npc = false }
	kit:play("Portal.VPortal", { player = player, origin = center, upVector = Vector3.yAxis, lastsFor = riftpulltime })
	kit:eachtarget(character, function(model, _, victimroot)
		if enemyof(character, model) and (victimroot.Position - center).Magnitude <= riftpullradius then
			members[model] = { returnto = model:GetPivot(), npc = isnpc(model) }
			local from = victimroot.Position
			local to = center + Vector3.new(0, 4, 0)
			kit:play("Portal.VSuckedIn", {
				player = player,
				origin = from,
				endPos = to,
				root = victimroot,
				syncedEndTime = workspace:GetServerTimeNow() + riftpulltime,
				receivingPlayer = players:GetPlayerFromCharacter(model),
			})
			stun(model, riftpulltime + 0.5)
			local rotation = victimroot.CFrame.Rotation
			drivenpc(victimroot, riftpulltime, function(alpha)
				return rotation + from:Lerp(to, alpha)
			end)
		end
	end)
	rift = { owner = owner, floor = floor, members = members, arena = arena, character = character, player = player, opened = os.clock() }
	kit.busyuntil = os.clock() + riftpulltime + 0.3

	for model in pairs(members) do
		local member = players:GetPlayerFromCharacter(model)
		if member then
			kit:play("Portal.VLoadDimension", { player = player, createForPlayer = member, origin = arena, owner = owner, delayUntilTeleport = riftpulltime })
		end
	end

	task.delay(riftpulltime, function()
		if not rift or rift.owner ~= owner then
			return
		end
		local index = 0
		for model, info in pairs(members) do
			local root2 = rootof(model)
			if root2 and model.Parent then
				index += 1
				local angle = index * 2.3
				local spot = arena + Vector3.new(math.cos(angle) * 20, 8, math.sin(angle) * 20)
				root2:SetAttribute("PortaledToAnotherDimension", true)
				model:PivotTo(CFrame.new(spot))
			end
		end
		for model in pairs(members) do
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			if model ~= character and humanoid then
				kit:hit(humanoid, data.damage.vpull, rootof(model))
			end
		end
	end)

	task.spawn(function()
		local step = 0.25
		local exited = false
		task.wait(riftpulltime + 0.5)
		while rift and rift.owner == owner do
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local root2 = rootof(character)
			if not humanoid or humanoid.Health <= 0 or not root2 or not character.Parent then
				break
			end
			local energy = character:FindFirstChild("Energy")
			if energy then
				energy.Value = math.max(0, energy.Value - math.ceil(riftdrain * step))
				if energy.Value <= 0 then
					break
				end
			end
			if (root2.Position - (arena + Vector3.new(0, 192, 0))).Magnitude <= riftexitradius then
				exited = true
				break
			end
			task.wait(step)
		end
		if rift and rift.owner == owner then
			closerift(exited)
		end
	end)
end

local function onm1(player, character, root)
	if escape.token then
		endescape(player)
	end
	kit:play("Portal.PortalJump", { player = player, hrp = root })
end

local warpexcluded = { Sea = true, Sewers = true, ["Underwater City"] = true, ["Volcano Cave"] = true }
local gatewayopen = false

local function islandlist()
	local list = {}
	local origin = workspace:FindFirstChild("_WorldOrigin")
	local locations = origin and origin:FindFirstChild("Locations")
	for _, part in ipairs(locations and locations:GetChildren() or {}) do
		if part:IsA("BasePart") and not warpexcluded[part.Name] then
			list[part.Name] = true
		end
	end
	return list
end

local function opengateway(player, character, root, humanoid)
	if gatewayopen or not kit:canuse(character, "C") then
		return
	end
	local remotes = replicatedstorage:FindFirstChild("Remotes")
	local gateway = remotes and remotes:FindFirstChild("RequestGateway")
	if not gateway then
		return
	end
	gatewayopen = true
	task.spawn(function()
		local ok, choice = pcall(function()
			return gateway:InvokeClient(player, islandlist())
		end)
		gatewayopen = false
		if ok and type(choice) == "string" and character.Parent and tool.Parent == character and humanoid.Health > 0 then
			kit.options.onkey(player, character, root, humanoid, "C", choice)
		end
	end)
end

kit = fruitkit.new(tool, {
	holdkeys = {},
	onm1 = onm1,
	onkey = function(player, character, root, humanoid, key, argument)
		if key == "C" and type(argument) ~= "string" then
			opengateway(player, character, root, humanoid)
			return
		end
		if key == "V" and rift and rift.player == player then
			closerift()
			return
		end
		if not kit:canuse(character, key) then
			return
		end
		if escape.token then
			endescape(player)
		end
		if key == "C" and not (type(argument) == "string" and warpdestination(argument)) then
			return
		end
		if not spend(character, data.Cost[key]) then
			return
		end
		local aim = kit:aim(root)
		if key == "Z" then
			kit.lastused.Z = os.clock()
			portaldash(player, character, root, aim)
		elseif key == "X" then
			kit.lastused.X = os.clock()
			parallelescape(player, character, root, humanoid)
		elseif key == "F" then
			kit.lastused.F = os.clock()
			quantumleap(player, character, root, aim)
		elseif key == "C" then
			if worldwarp(player, character, root, aim, argument) then
				kit.lastused.C = os.clock()
			end
		elseif key == "V" then
			kit.lastused.V = os.clock()
			dimensionalrift(player, character, root)
		end
	end,
	onunequip = function(owner)
		endescape(owner)
	end,
})
