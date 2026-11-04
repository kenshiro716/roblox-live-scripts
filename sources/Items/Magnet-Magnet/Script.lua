local players = game:GetService("Players")
local replicatedstorage = game:GetService("ReplicatedStorage")
local serverstorage = game:GetService("ServerStorage")
local runservice = game:GetService("RunService")
local debris = game:GetService("Debris")

local fruitkit = require(serverstorage:WaitForChild("fruitkit"))
local rigfit = require(serverstorage:WaitForChild("rigfit"))

local tool = script.Parent
local data = require(tool:WaitForChild("Data"))
local istransformed = tool:WaitForChild("IsTransformed")
local transformedrig = tool:WaitForChild("TransformedRigObject")
local rigtemplate = serverstorage:WaitForChild("Rigs"):WaitForChild("MagnetRig")

local combatutil = nil
pcall(function()
	combatutil = require(replicatedstorage.Modules.CombatUtil)
end)

local mechparts = { Arms = true, Head = true, Legs = true, Torso = true, RootPart = true }
local holdthreshold = 0.45
local flightthreshold = 0.5
local pulltiers = { [2] = { radius = 30, power = 12 }, [3] = { radius = 45, power = 18 } }
local scrapgain = 20
local scraplife = 35
local scrapmax = 14
local pickupradius = 7

local kit
local armfunctions, modeproxy = nil, nil
local combo, lastm1 = 0, 0
local transform = { accessory = nil, rig = nil, token = nil, hidden = {} }
local hold = nil
local flight = nil
local scraps = { bin = nil, nextid = 0, list = {}, lastspawn = 0 }
local healthconnection = nil
local lasthealth = nil

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

local function enemiesnear(character, position, radius, callback)
	kit:eachtarget(character, function(model, humanoid, root)
		if enemyof(character, model) and (root.Position - position).Magnitude <= radius then
			callback(model, humanoid, root)
		end
	end)
end

local function blast(character, position, radius, amount, stunfor)
	enemiesnear(character, position, radius, function(model, humanoid, root)
		kit:hit(humanoid, amount, root)
		if stunfor then
			stun(model, stunfor)
		end
	end)
end

local function pullnpc(root, toward, power)
	if not isnpc(root.Parent) or root.Anchored then
		return
	end
	local offset = toward - root.Position
	if offset.Magnitude < 4 then
		return
	end
	local velocity = offset.Unit * power
	root.AssemblyLinearVelocity = Vector3.new(velocity.X, root.AssemblyLinearVelocity.Y + velocity.Y * 0.3, velocity.Z)
end

local function pullnear(character, center, radius, power)
	enemiesnear(character, center, radius, function(_, _, root)
		pullnpc(root, center, power)
	end)
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

local function worldhit(character, from, to)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {
		character,
		workspace:FindFirstChild("_WorldOrigin"),
		workspace:FindFirstChild("Characters"),
		workspace:FindFirstChild("Enemies"),
	}
	local result = workspace:Raycast(from, to - from, params)
	return result and result.Position or to
end

local function gettier()
	return armfunctions and armfunctions:GetAttribute("CurrentTier") or 1
end

local function settier(tier)
	if armfunctions then
		armfunctions:SetAttribute("CurrentTier", math.clamp(tier, 1, 3))
	end
end

local function addpower(amount)
	local rage = kit:ragevalue()
	if not rage then
		return
	end
	local value = rage.Value + amount
	local tier = gettier()
	while value >= 100 and tier < 3 do
		value -= 100
		tier += 1
	end
	while value < 0 and tier > 1 do
		value += 100
		tier -= 1
	end
	settier(tier)
	rage.Value = math.clamp(value, 0, 100)
end

local function isswordtool(child)
	if not child:IsA("Tool") then
		return false
	end
	if child.ToolTip == "Sword" then
		return true
	end
	if combatutil then
		local ok, weapondata = pcall(function()
			return combatutil:GetWeaponData(combatutil:GetWeaponName(child))
		end)
		return ok and weapondata ~= nil and weapondata.WeaponType == "Sword"
	end
	return false
end

local function disablesword(model, duration)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local expiry = workspace:GetServerTimeNow() + duration
	local proxy = model:FindFirstChild("SwordDisableProxy")
	if not proxy then
		proxy = Instance.new("Folder")
		proxy.Name = "SwordDisableProxy"
		proxy.Parent = model
	end
	proxy:SetAttribute("Expiry", expiry)
	debris:AddItem(proxy, duration + 1)
	for _, child in ipairs(model:GetChildren()) do
		if isswordtool(child) then
			humanoid:UnequipTools()
			break
		end
	end
	local connection
	connection = model.ChildAdded:Connect(function(child)
		if not proxy.Parent or workspace:GetServerTimeNow() >= (proxy:GetAttribute("Expiry") or 0) then
			connection:Disconnect()
			return
		end
		if isswordtool(child) then
			task.defer(function()
				humanoid:UnequipTools()
			end)
		end
	end)
	task.delay(duration + 1, function()
		connection:Disconnect()
	end)
	local victim = players:GetPlayerFromCharacter(model)
	local origin = rootof(model) and rootof(model).Position or model:GetPivot().Position
	if victim then
		kit:play("Magnet.SwordDisableEffect", { Player = victim, Stage = 1, Expiry = expiry, Origin = origin })
	else
		kit:play("Magnet.SwordDisableEffect", { Character = model, Stage = 2, Expiry = expiry, Origin = origin })
	end
end

local function scrapbin(player)
	if scraps.bin and scraps.bin.Parent then
		return scraps.bin
	end
	local origin = workspace:FindFirstChild("_WorldOrigin")
	if not origin then
		return nil
	end
	local interactive = origin:FindFirstChild("InteractiveEffects")
	if not interactive then
		interactive = Instance.new("Folder")
		interactive.Name = "InteractiveEffects"
		interactive.Parent = origin
	end
	local folder = interactive:FindFirstChild("MagnetFruitScraps")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "MagnetFruitScraps"
		folder.Parent = interactive
	end
	local bin = folder:FindFirstChild(player.Name)
	if not bin then
		bin = Instance.new("Folder")
		bin.Name = player.Name
		bin.Parent = folder
	end
	scraps.bin = bin
	return bin
end

local function clearscraps()
	for part in pairs(scraps.list) do
		if part.Parent then
			part:Destroy()
		end
	end
	table.clear(scraps.list)
	if scraps.bin then
		scraps.bin:Destroy()
		scraps.bin = nil
	end
end

local function spawnscraps(player, character, origin, count)
	local bin = scrapbin(player)
	if not bin then
		return
	end
	local active = 0
	for _ in pairs(scraps.list) do
		active += 1
	end
	count = math.min(count, scrapmax - active)
	if count <= 0 then
		return
	end
	local entries = {}
	local radius = 14
	for _ = 1, count do
		scraps.nextid += 1
		local angle = math.random() * math.pi * 2
		local distance = 5 + math.random() * radius
		local flat = origin + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
		local surface = kit:groundbelow(flat, character)
		local hover = 1.5 + math.random()
		local part = Instance.new("Part")
		part.Name = "Scraps" .. scraps.nextid .. "_Server"
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Transparency = 1
		part.Size = Vector3.new(2, 2, 2)
		part.Position = surface + Vector3.new(0, hover, 0)
		part.Parent = bin
		scraps.list[part] = os.clock() + scraplife
		table.insert(entries, { serverId = scraps.nextid, surfacePos = surface, hoverHeight = hover, travelTime = 0.6 + math.random() * 0.3 })
	end
	kit:play("Magnet.Scraps", {
		Player = player,
		Root = rootof(character),
		Origin = origin,
		ScrapData = { scrapType = "Explode", origin = origin, r = radius, scraps = entries },
	})
end

local function absorbscrap(part, duration)
	if not scraps.list[part] then
		return
	end
	scraps.list[part] = nil
	part:SetAttribute("Absorbing", duration)
	part:Destroy()
	if not istransformed.Value then
		addpower(scrapgain)
	end
end

local function absorbwithin(position, radius)
	for part in pairs(scraps.list) do
		if part.Parent and (part.Position - position).Magnitude <= radius then
			absorbscrap(part, 0.35 + (part.Position - position).Magnitude / 120)
		end
	end
end

local function stripruntimeparts(model)
	for _, child in ipairs(model:GetChildren()) do
		if child:IsA("BasePart") and not mechparts[child.Name] then
			child:Destroy()
		end
	end
	return model
end

local function standalonerig(cframe)
	local model = stripruntimeparts(rigtemplate:WaitForChild("MagnetRig"):Clone())
	local scalefix = model:FindFirstChild("ScaleFix")
	if scalefix then
		scalefix:Destroy()
	end
	model:PivotTo(cframe)
	model.PrimaryPart.Anchored = true
	return model
end

local function setbodyhidden(character, hidden)
	if hidden then
		for _, d in ipairs(character:GetDescendants()) do
			local partofmech = transform.accessory and d:IsDescendantOf(transform.accessory)
			if not partofmech and (d:IsA("BasePart") or d:IsA("Decal")) and d.Transparency < 1 then
				transform.hidden[d] = d.Transparency
				d.Transparency = 1
			end
		end
	else
		for d, transparency in pairs(transform.hidden) do
			if d.Parent then
				d.Transparency = transparency
			end
		end
		table.clear(transform.hidden)
	end
end

local function endflight()
	local current = flight
	if not current then
		return
	end
	flight = nil
	if current.proxy and current.proxy.Parent then
		current.proxy:Destroy()
	end
end

local function startflight(player, character, root)
	endflight()
	local proxy = Instance.new("BoolValue")
	proxy.Name = "MagnetEnableFlight"
	proxy.Value = true
	proxy.Parent = root
	local current = { proxy = proxy, started = os.clock(), hits = 0, player = player }
	flight = current
	kit:play("Magnet.F_Tap", {
		Player = player,
		Root = root,
		hrp = root,
		Origin = root.Position,
		Stage = 3,
		Proxy = proxy,
		MagnetProxy = armfunctions,
	})
	task.delay(data.flight.duration, function()
		if flight == current then
			endflight()
			kit.lastused.F = os.clock()
		end
	end)
end

local function launchjetpack(player, character, root)
	local current = flight
	if not current then
		return
	end
	local ignore = Instance.new("BoolValue")
	ignore.Name = "MagnetJetpackIgnoreStage"
	ignore.Parent = root
	debris:AddItem(ignore, 3)
	flight = nil
	current.proxy:Destroy()
	kit.lastused.F = os.clock()

	local aim = kit:aim(root)
	local start = root.CFrame * CFrame.new(0, 1, 1.5)
	local direction = (aim.target - start.Position)
	direction = direction.Magnitude > 1 and direction.Unit or root.CFrame.LookVector
	local projectile = Instance.new("Part")
	projectile.Name = "magnetjetpack"
	projectile.Anchored = true
	projectile.CanCollide = false
	projectile.CanQuery = false
	projectile.CanTouch = false
	projectile.Transparency = 1
	projectile.Size = Vector3.one
	projectile.CFrame = CFrame.lookAt(start.Position, start.Position + direction)
	projectile.Parent = workspace:FindFirstChild("_WorldOrigin") or workspace
	debris:AddItem(projectile, 8)

	local flyup = 0.5
	kit:play("Magnet.F_Tap", {
		Player = player,
		Root = root,
		hrp = root,
		Origin = root.Position,
		Stage = 4,
		Proxy = projectile,
		FlyUpDur = flyup,
		Seed = math.random(1, 100000),
	})

	task.spawn(function()
		task.wait(0.15)
		local travelled = 0
		local speed = data.flight.launchspeed
		local victim = nil
		while travelled < data.flight.launchrange and projectile.Parent do
			local step = runservice.Heartbeat:Wait() * speed
			local from = projectile.Position
			local to = from + direction * step
			local blocked = worldhit(character, from, to)
			kit:eachtarget(character, function(model, _, candidate)
				if not victim and enemyof(character, model) and (candidate.Position - to).Magnitude <= 7 then
					victim = candidate
				end
			end)
			projectile.CFrame = CFrame.lookAt(blocked, blocked + direction)
			travelled += step
			if victim or blocked ~= to then
				break
			end
		end
		if not projectile.Parent then
			return
		end
		if victim then
			local endpos = victim.Position + Vector3.new(0, 75, 0)
			local marker = Instance.new("ObjectValue")
			marker.Name = "HitTarget"
			marker.Value = victim
			marker:SetAttribute("EndPos", endpos)
			marker.Parent = projectile
			local model = victim.Parent
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			stun(model, flyup + 1.5)
			local from = victim.Position
			drivenpc(victim, flyup, function(alpha)
				return CFrame.new(from:Lerp(endpos, alpha))
			end, function()
				if humanoid then
					kit:hit(humanoid, data.damage.flaunch, victim)
				end
				blast(character, endpos, 22, data.damage.flaunch * 0.5, 1)
			end)
		else
			local marker = Instance.new("Vector3Value")
			marker.Name = "MissExplode"
			marker.Value = projectile.Position
			marker.Parent = projectile
			blast(character, projectile.Position, 22, data.damage.flaunch, 1)
		end
	end)
end

local function endtransform(player, skipeffect)
	local accessory, rig = transform.accessory, transform.rig
	transform.token = nil
	if not accessory then
		return
	end

	local character = accessory.Parent
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local mechcframe = (rig and rig.PrimaryPart and rig:GetPivot()) or (root and root.CFrame)

	transformedrig.Value = nil
	istransformed.Value = false
	if transform.unfit then
		transform.unfit()
		transform.unfit = nil
	end
	if character then
		setbodyhidden(character, false)
	end
	accessory:Destroy()
	transform.accessory, transform.rig = nil, nil

	kit.lastused.V = os.clock()
	kit.busyuntil = os.clock() + 1.5
	settier(1)
	local rage = kit:ragevalue(character)
	if rage then
		rage.Value = 0
	end

	if not skipeffect and root and mechcframe then
		local eject = standalonerig(mechcframe)
		eject.Parent = workspace:FindFirstChild("_WorldOrigin") or workspace
		debris:AddItem(eject, 4)
		kit:play("Magnet.Transformed.Untransform", {
			Player = player,
			Root = root,
			hrp = root,
			Origin = root.Position,
			Rig = eject,
			MechCF = mechcframe,
		})
		local center = mechcframe.Position + Vector3.new(0, 10, 0)
		task.spawn(function()
			task.wait(0.15)
			local stop = os.clock() + 2.1
			while os.clock() < stop and character.Parent do
				pullnear(character, center, 60, 35)
				task.wait(0.1)
			end
			task.wait(0.35)
			if character.Parent then
				blast(character, center, 45, data.damage.eject, 1.5)
			end
		end)
	end
end

local function starttransform(player, character, root, humanoid)
	if transform.accessory or not kit:canuse(character, "V") then
		return
	end
	local rage = kit:ragevalue(character)
	if gettier() < 3 or not rage or rage.Value < 100 then
		return
	end
	if not spend(character, data.Cost.V) then
		return
	end
	endflight()
	kit.busyuntil = os.clock() + 4

	local accessory = rigtemplate:Clone()
	local rig = stripruntimeparts(accessory:WaitForChild("MagnetRig"))
	for _, part in ipairs(rig:GetChildren()) do
		if part:IsA("BasePart") and part ~= rig.PrimaryPart then
			part.Transparency = 1
		end
	end
	humanoid:AddAccessory(accessory)
	transform.accessory, transform.rig = accessory, rig
	istransformed.Value = true

	local fakerig = standalonerig(root.CFrame)
	fakerig.Parent = replicatedstorage
	debris:AddItem(fakerig, 12)

	kit:play("Magnet.Transformed.V", {
		Player = player,
		Root = root,
		hrp = root,
		Origin = root.Position,
		Rig = rig,
		FakeRig = fakerig,
		UpDist = 100,
		DownDist = 100,
		IsNpc = false,
	})

	local token = {}
	transform.token = token
	local startposition = root.Position

	task.delay(3.4, function()
		if transform.token ~= token then
			return
		end
		for _, part in ipairs(rig:GetChildren()) do
			if part:IsA("BasePart") and part ~= rig.PrimaryPart then
				part.Transparency = 0
			end
		end
		setbodyhidden(character, true)
		transformedrig.Value = rig
		transform.unfit = rigfit.fit(character, humanoid, root, rig)
	end)
	task.delay(3.7, function()
		if transform.token == token then
			blast(character, startposition, 32, data.damage.v, 1)
		end
	end)
end

local function base(player, root, extra)
	local params = { Player = player, Root = root, hrp = root, Origin = root.Position }
	for k, v in pairs(extra) do
		params[k] = v
	end
	return params
end

local function forcerelease(token, after)
	task.delay(after, function()
		if hold == token and kit.active and kit.active.key == token.key then
			kit:release(token.player, token.character, token.root, token.key)
		end
	end)
end

local function zbeam(token)
	local player, character, root = token.player, token.character, token.root
	local proxy = Instance.new("Vector3Value")
	proxy.Name = "magnetzbeam"
	local function endpoint()
		local origin = root.Position + Vector3.new(0, 1.5, 0)
		local target = kit:clamprange(origin, kit.mousepos.Value, 100)
		return worldhit(character, origin, target)
	end
	proxy.Value = endpoint()
	proxy.Parent = root
	debris:AddItem(proxy, 4)
	kit:play("Magnet.Z_Attract_Held", base(player, root, {
		MousePos = kit.mousepos,
		Holding = kit.effectholding,
		Proxy = proxy,
		StartCFrame = root.CFrame * CFrame.new(-1.5, 1, -2),
	}))
	kit.busyuntil = os.clock() + 3
	forcerelease(token, 2)
	task.spawn(function()
		local started = os.clock()
		while proxy.Parent and root.Parent and os.clock() - started < 2 and (kit.effectholding.Value or os.clock() - started < 1) do
			proxy.Value = endpoint()
			kit:damagealong(character, root.Position, proxy.Value, 5, data.damage.zbeam)
			pullnear(character, proxy.Value, 20, 20)
			task.wait(0.2)
		end
		local burst = proxy.Value
		task.wait(0.65)
		blast(character, burst, 18, data.damage.zburst, 1)
		kit.busyuntil = os.clock() + 0.2
		proxy:Destroy()
	end)
end

local function cheld(token)
	local player, character, root = token.player, token.character, token.root
	local trigger = Instance.new("BoolValue")
	trigger.Name = "MagnetCHeldTrigger"
	trigger.Parent = root
	token.trigger = trigger
	kit:play("Magnet.C_Attract_Held", base(player, root, { Stage = 1, Holding = kit.effectholding }))
	forcerelease(token, 3)
	task.spawn(function()
		while hold == token and root.Parent do
			pullnear(character, root.Position, 45, 30)
			absorbwithin(root.Position, 60)
			task.wait(0.15)
		end
	end)
end

local function transformedheld(token)
	local player, character, root, key = token.player, token.character, token.root, token.key
	local rig = transform.rig
	if key == "Z" then
		local transition = Instance.new("BoolValue")
		transition.Name = "MagnetZHeldTransition"
		transition.Parent = root
		debris:AddItem(transition, 3)
		kit:play("Magnet.Transformed.Z_Attract_Held", base(player, root, {
			Stage = 2,
			Holding = kit.effectholding,
			Rig = rig,
			MousePos = kit.mousepos,
			StartCFrame = root.CFrame,
		}))
		forcerelease(token, 0.1)
		kit.busyuntil = os.clock() + 2.2
		task.spawn(function()
			task.wait(0.5)
			local stop = os.clock() + 1.5
			while os.clock() < stop and root.Parent do
				local origin = root.Position + Vector3.new(0, 6, 0)
				local target = worldhit(character, origin, kit:clamprange(origin, kit.mousepos.Value, 160))
				kit:damagealong(character, origin, target, 7, data.damage.mechzbeam)
				blast(character, target, 10, data.damage.mechzbeam * 0.5)
				task.wait(0.15)
			end
		end)
	elseif key == "X" then
		local trigger = Instance.new("BoolValue")
		trigger.Name = "MagnetXTransformedTrigger"
		trigger.Parent = root
		debris:AddItem(trigger, 2)
		local duration = data.mech.roomduration
		kit:play("Magnet.Transformed.X_Attract_Held", base(player, root, { FieldDuration = duration }))
		forcerelease(token, 0.1)
		kit.busyuntil = os.clock() + 1
		local center = root.Position
		task.spawn(function()
			task.wait(0.25)
			local stop = os.clock() + duration
			while os.clock() < stop and character.Parent do
				pullnear(character, center, 55, 40)
				enemiesnear(character, center, 55, function(model, humanoid, victimroot)
					kit:hit(humanoid, data.damage.mechroom, victimroot)
					stun(model, 0.6)
				end)
				task.wait(0.5)
			end
			blast(character, center, 55, data.damage.mechroomfinal, 1)
		end)
	elseif key == "C" then
		local trigger = Instance.new("BoolValue")
		trigger.Name = "MagnetCHeldTrigger"
		trigger.Parent = root
		token.trigger = trigger
		kit:play("Magnet.Transformed.C_Attract", base(player, root, {
			Stage = 3,
			Holding = kit.effectholding,
			Rig = rig,
			MousePos = kit.mousepos,
		}))
		forcerelease(token, 4)
		task.spawn(function()
			while hold == token and root.Parent do
				blast(character, root.Position, 22, data.damage.mechcspin, 0.4)
				task.wait(0.3)
			end
		end)
	elseif key == "F" then
		token.flying = true
		kit:play("Magnet.Transformed.Flight", base(player, root, {
			Holding = kit.effectholding,
			Rig = rig,
			MousePos = kit.mousepos,
		}))
		forcerelease(token, data.mech.flightduration)
	end
end

local function onholdstart(player, character, root, key)
	local token = { key = key, started = os.clock(), player = player, character = character, root = root, transformed = istransformed.Value }
	hold = token
	if token.transformed then
		local rig = transform.rig
		if key == "Z" then
			kit:play("Magnet.Transformed.Z_Attract", base(player, root, { Stage = 1, Holding = kit.effectholding, Rig = rig }))
		elseif key == "X" then
			kit:play("Magnet.Transformed.X_Attract", base(player, root, { Stage = 1, Holding = kit.effectholding, Windup = data.mech.xwindup }))
		elseif key == "C" then
			kit:play("Magnet.Transformed.C_Attract", base(player, root, { Stage = 1, Holding = kit.effectholding, Rig = rig, MousePos = kit.mousepos }))
		end
		local threshold = key == "F" and 0.3 or (key == "X" and data.mech.xwindup + 0.1 or holdthreshold)
		task.delay(threshold, function()
			if hold == token and kit.active and kit.active.key == key and kit.effectholding.Value then
				token.held = true
				transformedheld(token)
			end
		end)
		return
	end

	if key == "Z" then
		kit:play("Magnet.Z_Attract", base(player, root, { Stage = 1, Holding = kit.effectholding }))
	elseif key == "X" then
		kit:play("Magnet.X_Attract", base(player, root, { Stage = 1, Holding = kit.effectholding }))
	elseif key == "C" then
		kit:play("Magnet.C_Attract", base(player, root, { Stage = 1, Holding = kit.effectholding }))
	elseif key == "F" then
		kit:play("Magnet.F_Tap", base(player, root, { Stage = 1, Holding = kit.effectholding }))
	end
	local threshold = key == "F" and flightthreshold or holdthreshold
	task.delay(threshold, function()
		if hold ~= token or not kit.active or kit.active.key ~= key or not kit.effectholding.Value then
			return
		end
		token.held = true
		if key == "Z" then
			zbeam(token)
		elseif key == "C" then
			cheld(token)
		elseif key == "F" then
			token.flying = true
			hold = nil
			kit.active = nil
			kit.effectholding.Value = false
			startflight(player, character, root)
		end
	end)
end

local function basetap(player, character, root, key, aim, held)
	local origin, target, flat, facing = aim.origin, aim.target, aim.flat, aim.facing
	local holding, mousepos = kit.effectholding, kit.mousepos

	if key == "Z" then
		if held then
			return
		end
		local aimcframe = CFrame.lookAt(origin, target)
		local starts = {
			aimcframe * CFrame.new(-2.4, 1.4, -1),
			aimcframe * CFrame.new(2.4, 1.4, -1),
			aimcframe * CFrame.new(-2.8, 0.4, -1.2),
			aimcframe * CFrame.new(2.8, 0.4, -1.2),
		}
		kit:play("Magnet.Z_Attract", base(player, root, { Stage = 2, Holding = holding, StartCFrame = starts, MousePos = mousepos }))
		kit.busyuntil = os.clock() + 0.7
		task.spawn(function()
			for i = 1, 4 do
				task.wait(0.15)
				local from = (CFrame.lookAt(starts[i].Position, mousepos.Value) * CFrame.new(0, 0, -3)).Position
				local to = worldhit(character, from, from + (mousepos.Value - from).Unit * 200)
				local victim = kit:firstalong(character, from, to, 4)
				local impact = victim and victim.Position or to
				task.delay((impact - from).Magnitude / 333.33, function()
					blast(character, impact, 8 + i, data.damage.z, 0.5)
					pullnear(character, impact, 18, 25)
				end)
			end
		end)
	elseif key == "X" then
		local maxrange = held and 150 or 120
		target = kit:clamprange(origin, target, maxrange)
		target = kit:groundbelow(target, character)
		local startcframe = CFrame.lookAt(root.Position + Vector3.new(0, 7, 0), target)
		if held then
			local travel = math.clamp(math.clamp((origin - target).Magnitude, 6, maxrange) / maxrange, 0, 1) ^ 0.8 * 0.25 + 0.1
			kit:play("Magnet.X_Attract_Held", base(player, root, { Stage = 2, StartCFrame = startcframe, MaxRange = maxrange, TargetPosition = target }))
			kit.busyuntil = os.clock() + 0.6
			task.delay(travel, function()
				local caged = {}
				enemiesnear(character, target, 26, function(model, humanoid, victimroot)
					caged[model] = humanoid
					kit:hit(humanoid, data.damage.xheld * 0.3, victimroot)
					stun(model, 3.4)
					local hold2 = victimroot.CFrame
					drivenpc(victimroot, 3.35, function()
						return hold2
					end)
				end)
				task.wait(1.85)
				blast(character, target, 26, data.damage.xheld * 0.2)
				task.wait(1.5)
				blast(character, target + Vector3.new(0, 10, 0), 32, data.damage.xheld * 0.5, 1)
			end)
		else
			local traveltime = 0.35 + 0.4 * math.clamp((target - origin).Magnitude / maxrange, 0, 1)
			kit:play("Magnet.X_Attract", base(player, root, {
				Stage = 2,
				Holding = holding,
				StartCFrame = startcframe,
				MaxRange = maxrange,
				TargetPosition = target,
				TravelTime = traveltime,
			}))
			kit.busyuntil = os.clock() + 0.6
			task.delay(traveltime, function()
				enemiesnear(character, target, 16, function(model, humanoid, victimroot)
					kit:hit(humanoid, data.damage.x * 0.3, victimroot)
					stun(model, 1.6)
					local hold2 = victimroot.CFrame
					drivenpc(victimroot, 1.425, function()
						return hold2
					end)
				end)
				task.wait(1.425)
				blast(character, target, 20, data.damage.x * 0.7, 0.8)
			end)
		end
	elseif key == "C" then
		if held then
			local startcframe = root.CFrame
			local updist = 25
			kit:play("Magnet.C_Attract_Held", base(player, root, {
				Stage = 2,
				StartCFrame = startcframe,
				UpDist = updist,
				UpCFrame = startcframe + Vector3.new(0, updist, 0),
			}))
			kit.busyuntil = os.clock() + 1.8
			absorbwithin(root.Position, 60)
			local slam = kit:groundbelow(startcframe.Position, character)
			task.delay(1.3, function()
				blast(character, slam, 35, data.damage.cheld, 1.2)
			end)
			return
		end
		local landingflat = kit:clamprange(origin, flat, 60)
		local landing = kit:groundbelow(landingflat, character) + Vector3.new(0, 3, 0)
		kit:play("Magnet.C_Attract", base(player, root, {
			Stage = 2,
			Holding = holding,
			StartCFrame = facing,
			UpCFrame = facing + Vector3.new(0, 25, 0),
			EndCFrame = CFrame.lookAt(landing, landing + facing.LookVector),
		}))
		kit.busyuntil = os.clock() + 1.3
		local grabbed = kit:firstalong(character, origin, origin + facing.LookVector * 30, 8)
		if grabbed then
			local model = grabbed.Parent
			stun(model, 1.6)
			local from = grabbed.Position
			drivenpc(grabbed, 0.6, function(alpha)
				local lift = from:Lerp(landing, alpha) + Vector3.new(0, math.sin(alpha * math.pi) * 25, 0)
				return CFrame.new(lift)
			end)
		end
		task.delay(0.6, function()
			blast(character, landing, 22, data.damage.c, 1)
		end)
	elseif key == "F" then
		if held then
			return
		end
		local dashdist, dashtime = 55, 0.3
		local victim = kit:firstalong(character, origin, origin + facing.LookVector * dashdist, 9)
		kit:play("Magnet.F_Tap", base(player, root, {
			Stage = 2,
			Holding = holding,
			StartCFrame = facing,
			DashSpeed = dashtime,
			DashDist = dashdist,
			HitTarget = victim ~= nil,
		}))
		kit.busyuntil = os.clock() + dashtime + 0.3
		task.delay(dashtime, function()
			kit:damagealong(character, origin, origin + facing.LookVector * dashdist, 9, data.damage.f)
			if victim and victim.Parent then
				stun(victim.Parent, 1)
				disablesword(victim.Parent, data.swordlock)
			end
		end)
	end
end

local function mechtap(player, character, root, key, aim)
	local rig = transform.rig
	local origin, target = aim.origin, aim.target
	if key == "Z" then
		local range, speed = 250, 180
		kit:play("Magnet.Transformed.Z_Attract", base(player, root, {
			Stage = 2,
			Rig = rig,
			MousePos = kit.mousepos,
			Range = range,
			Speed = speed,
			Seed = math.random(1, 100000),
		}))
		kit.busyuntil = os.clock() + 0.6
		local impact = worldhit(character, origin, kit:clamprange(origin, target, range))
		task.delay(0.4 + (impact - origin).Magnitude / speed, function()
			blast(character, impact, 20, data.damage.mechz, 0.5)
		end)
	elseif key == "X" then
		local maxrange = 200
		target = kit:groundbelow(kit:clamprange(origin, target, maxrange), character)
		local traveltime = 0.35 + 0.45 * math.clamp((target - origin).Magnitude / maxrange, 0, 1)
		local windup = 1
		kit:play("Magnet.Transformed.X_Attract", base(player, root, {
			Stage = 2,
			StartCFrame = CFrame.lookAt(root.Position + Vector3.new(0, 4, 0), target) * CFrame.new(0, 0, -12),
			TargetPosition = target,
			TravelTime = traveltime,
			ExplosionWindup = windup,
		}))
		kit.busyuntil = os.clock() + 0.6
		task.delay(traveltime, function()
			pullnear(character, target, 45, 35)
			task.wait(windup)
			blast(character, target, 45, data.damage.mechx, 1)
		end)
	elseif key == "C" then
		local center = root.Position + root.CFrame.LookVector * 18
		kit:play("Magnet.Transformed.C_Attract", base(player, root, {
			Stage = 2,
			Rig = rig,
			MousePos = kit.mousepos,
			StartCFrame = root.CFrame,
			Seed = math.random(1, 100000),
		}))
		kit.busyuntil = os.clock() + 1.2
		task.spawn(function()
			local stop = os.clock() + 0.6
			while os.clock() < stop do
				pullnear(character, center, 40, 40)
				task.wait(0.1)
			end
			blast(character, center, 32, data.damage.mechc, 1.2)
		end)
	elseif key == "F" then
		local dashdist, dashtime = 70, 0.35
		local flatlook = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
		flatlook = flatlook.Magnitude > 0.01 and flatlook.Unit or Vector3.zAxis
		local endpos = worldhit(character, root.Position, root.Position + flatlook * dashdist)
		kit:play("Magnet.Transformed.F_Repel", base(player, root, {
			Stage = 2,
			Rig = rig,
			StartCFrame = CFrame.lookAt(root.Position, root.Position + flatlook),
			DashSpeed = dashtime,
			DashDist = (endpos - root.Position).Magnitude,
			EndPos = endpos,
		}))
		kit.busyuntil = os.clock() + dashtime + 0.3
		local from = root.Position
		task.delay(dashtime, function()
			enemiesnear(character, endpos, 30, function(model, humanoid, victimroot)
				kit:hit(humanoid, data.damage.mechf, victimroot)
				stun(model, 1)
				disablesword(model, data.swordlock)
			end)
			kit:damagealong(character, from, endpos, 10, data.damage.mechf * 0.4)
		end)
	end
end

local function onrelease(player, character, root, key, aim)
	local token = hold
	hold = nil
	if not token or token.key ~= key then
		return
	end
	if token.trigger then
		token.trigger:Destroy()
	end
	if token.flying then
		return
	end
	if token.transformed then
		if token.held then
			return
		end
		mechtap(player, character, root, key, aim)
		return
	end
	basetap(player, character, root, key, aim, token.held)
end

local function onm1(player, character, root, humanoid)
	if os.clock() - lastm1 > 1.2 then
		combo = 0
	end
	lastm1 = os.clock()

	if istransformed.Value then
		combo = combo % 4 + 1
		kit:play("Magnet.Transformed.M1", base(player, root, { Stage = combo, Rig = transform.rig }))
		local center = root.Position + root.CFrame.LookVector * 14
		task.delay(0.2, function()
			blast(character, center, 16, data.damage.mechm1, 0.4)
		end)
		return
	end

	local tier = gettier()
	local length = tier + 2
	combo = combo % length + 1
	local slam = tier == 3 and combo == 5
	local prefix
	if combo == 1 then
		prefix = "MagnetM1Tier" .. tier
	elseif slam then
		prefix = "MagnetSlamTier" .. tier
	else
		prefix = "MagnetM" .. combo .. "Default"
	end

	kit:play("Magnet.M1", base(player, root, {
		Stage = combo,
		CurrentTier = tier,
		Slam = slam,
		TieredPrefix = prefix,
	}))
	if slam then
		kit.busyuntil = os.clock() + 0.6
	end
	local scale = tier == 3 and 1.5 or (tier == 2 and 1.15 or 1)
	local center = root.Position + root.CFrame.LookVector * (slam and 4 or 5) * scale
	task.delay(0.15, function()
		blast(character, center, (slam and 13 or 9) * scale, (slam and data.damage.slam or data.damage.m1) * scale, 0.35)
	end)
end

local function watchhealth(character)
	if healthconnection then
		healthconnection:Disconnect()
		healthconnection = nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	lasthealth = humanoid.Health
	healthconnection = humanoid.HealthChanged:Connect(function(health)
		local loss = (lasthealth or health) - health
		lasthealth = health
		if loss <= 0 or health <= 0 then
			return
		end
		if istransformed.Value then
			humanoid.Health = math.min(humanoid.MaxHealth, health + loss * data.mech.damagereduction)
			lasthealth = humanoid.Health
			return
		end
		if gettier() >= 3 then
			humanoid.Health = math.min(humanoid.MaxHealth, health + loss * data.passive.tierthreedefense)
			lasthealth = humanoid.Health
		end
		addpower(-(loss / math.max(humanoid.MaxHealth, 1)) * 100 * data.passive.drainperhealth)
		if flight then
			if os.clock() - flight.started <= 10 then
				flight.hits += 1
				if flight.hits >= data.flight.hitstocancel then
					endflight()
					kit.lastused.F = os.clock()
				end
			end
		end
	end)
end

kit = fruitkit.new(tool, {
	holdkeys = { Z = true, X = true, C = true, F = true },
	maxhold = 15,
	canhold = function(player, character, root, key)
		if key == "F" and flight and not istransformed.Value then
			launchjetpack(player, character, root)
			return false
		end
		return spend(character, data.Cost[key])
	end,
	onholdstart = onholdstart,
	onrelease = onrelease,
	onm1 = onm1,
	onkey = function(player, character, root, humanoid, key)
		if key ~= "V" then
			return
		end
		if istransformed.Value then
			if os.clock() >= kit.busyuntil then
				endtransform(player)
			end
		else
			starttransform(player, character, root, humanoid)
		end
	end,
	onhit = function(amount, humanoid, root)
		if not root then
			return
		end
		kit:play("Magnet.Passive", { root, 1 })
		root:SetAttribute("LastHitMagnet", tick() + 0.5)
		local owner = kit:getowner()
		local character = kit:getcharacter()
		if owner and character and not istransformed.Value and os.clock() - scraps.lastspawn > data.passive.scrapcooldown then
			scraps.lastspawn = os.clock()
			spawnscraps(owner, character, root.Position, math.random(1, 2))
		end
	end,
	onpassivestart = function(player, character)
		if armfunctions then
			armfunctions:Destroy()
		end
		armfunctions = Instance.new("Folder")
		armfunctions.Name = "MagnetArmFunctions"
		armfunctions:SetAttribute("CurrentTier", 1)
		armfunctions.Parent = character
		kit:ragevalue(character)

		modeproxy = character:FindFirstChild("MagnetModeProxy")
		if not modeproxy then
			modeproxy = Instance.new("StringValue")
			modeproxy.Name = "MagnetModeProxy"
			modeproxy.Parent = character
		end
		modeproxy.Value = "Attract"

		kit:play("Magnet.Passive", {
			Character = character,
			Player = player,
			Proxy = armfunctions,
			TransformedProxy = transformedrig,
		})
		watchhealth(character)
	end,
	onunequip = function()
		endflight()
	end,
	onpassiveend = function()
		endtransform(kit:getowner(), true)
		endflight()
		clearscraps()
		if healthconnection then
			healthconnection:Disconnect()
			healthconnection = nil
		end
		if armfunctions then
			armfunctions:Destroy()
			armfunctions = nil
		end
		if modeproxy then
			modeproxy:Destroy()
			modeproxy = nil
		end
	end,
})

task.spawn(function()
	local step = 0.1
	local elapsed = 0
	while true do
		task.wait(step)
		elapsed += step
		local character = kit:getcharacter() or (kit.passivecharacter and kit.passivecharacter.Parent and kit.passivecharacter)
		local root = rootof(character)
		local rage = character and character:FindFirstChild("Rage")
		if character and root and armfunctions then
			local now = os.clock()
			for part, expires in pairs(scraps.list) do
				if not part.Parent or now > expires then
					scraps.list[part] = nil
					if part.Parent then
						part:Destroy()
					end
				elseif (part.Position - root.Position).Magnitude <= pickupradius then
					absorbscrap(part, 0.3)
				end
			end

			local tier = gettier()
			local pull = pulltiers[tier]
			if pull and not istransformed.Value then
				enemiesnear(character, root.Position, pull.radius, function(_, _, victimroot)
					if (victimroot:GetAttribute("LastHitMagnet") or 0) <= tick() then
						pullnpc(victimroot, root.Position, pull.power)
					end
				end)
			end

			if rage and elapsed >= 0.25 then
				if istransformed.Value and transform.token then
					rage.Value = math.max(0, rage.Value - data.rage.transformdrainpersecond * elapsed)
					if rage.Value <= 0 then
						endtransform(kit:getowner())
					end
				end
				elapsed = 0
			end
		end
	end
end)
