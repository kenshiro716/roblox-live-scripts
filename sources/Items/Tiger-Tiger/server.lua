local players = game:GetService("Players")
local replicatedstorage = game:GetService("ReplicatedStorage")
local serverstorage = game:GetService("ServerStorage")
local runservice = game:GetService("RunService")
local debris = game:GetService("Debris")

local fruitkit = require(serverstorage:WaitForChild("fruitkit"))
local hitbox = require(serverstorage:WaitForChild("hitbox"))
local rigfit = require(serverstorage:WaitForChild("rigfit"))

local transformationaccessories = nil
pcall(function()
	transformationaccessories = require(replicatedstorage:WaitForChild("Util"):WaitForChild("TransformationAccessories"))
end)

local tool = script.Parent
local data = require(tool:WaitForChild("Data"))
local rigtemplate = serverstorage:WaitForChild("Rigs"):WaitForChild("TigerRig")
local fxfolder = replicatedstorage:WaitForChild("FX"):FindFirstChild("TigerEffects") or serverstorage:WaitForChild("FX"):WaitForChild("TigerEffects")

local function ensure(classname, name)
	local value = tool:FindFirstChild(name)
	if not value then
		value = Instance.new(classname)
		value.Name = name
		value.Parent = tool
	end
	return value
end

local istransformed = ensure("BoolValue", "IsTransformed")
local transformedrig = ensure("ObjectValue", "TransformedRigObject")

local blazingbones = {
	Back = "Torso3",
	Head = "Head",
	LHand = "Hand.L",
	RHand = "Hand.R",
	Mouth = "Jaw",
	TailTip = "Tail7",
	eyeL = "Eye.L",
	eyeR = "Eye.R",
	Tail1 = "Tail1",
	Tail2 = "Tail2",
	Tail3 = "Tail3",
	Tail4 = "Tail4",
	Tail5 = "Tail5",
	Tail6 = "Tail6",
}

local kit
local state = {
	form = 0,
	accessory = nil,
	rig = nil,
	character = nil,
	hidden = {},
	blazingstart = 0,
	overheatuntil = 0,
	overheatvalue = nil,
	token = nil,
	healthconnection = nil,
	lasthealth = nil,
	deathconnection = nil,
}
local combo, lastm1 = 0, 0
local hold = nil
local passiveloop = nil

local function isnpc(model)
	return players:GetPlayerFromCharacter(model) == nil
end

local function now()
	return workspace:GetServerTimeNow()
end

local function stun(model, duration)
	local value = model and model:FindFirstChild("Stun")
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

local function knock(root, velocity)
	if root and root.Parent and isnpc(root.Parent) and not root.Anchored then
		root.AssemblyLinearVelocity = velocity
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

local function blast(character, position, radius, amount, stunfor, push)
	local hits = hitbox.sphere(character, position, radius)
	for _, target in ipairs(hits) do
		kit:hit(target.humanoid, amount, target.root or target.part)
		if stunfor then
			stun(target.model, stunfor)
		end
		if push and target.root then
			local away = target.root.Position - position
			away = Vector3.new(away.X, 0, away.Z)
			away = away.Magnitude > 0.1 and away.Unit or Vector3.zero
			knock(target.root, away * push + Vector3.new(0, push * 0.6, 0))
		end
	end
	return hits
end

local function along(character, from, to, radius, amount, stunfor)
	local hits = hitbox.line(character, from, to, radius)
	for _, target in ipairs(hits) do
		kit:hit(target.humanoid, amount, target.root or target.part)
		if stunfor then
			stun(target.model, stunfor)
		end
	end
	return hits
end

local function rayparams(character)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {
		character,
		workspace:FindFirstChild("_WorldOrigin"),
		workspace:FindFirstChild("Characters"),
		workspace:FindFirstChild("Enemies"),
	}
	return params
end

local function grounded(character, root)
	return workspace:Raycast(root.Position, Vector3.new(0, -8, 0), rayparams(character)) ~= nil
end

local function clear(character, from, to)
	local result = workspace:Raycast(from, to - from, rayparams(character))
	if result then
		local back = (to - from).Magnitude > 0 and (to - from).Unit * 3 or Vector3.zero
		return result.Position - back, true
	end
	return to, false
end

local function groundcframe(character, position)
	local result = workspace:Raycast(position + Vector3.new(0, 4, 0), Vector3.new(0, -60, 0), rayparams(character))
	return CFrame.new(result and result.Position or position)
end

local function direction(origin, target, maxpitch)
	local offset = target - origin
	if offset.Magnitude < 0.5 then
		return nil
	end
	local unit = offset.Unit
	if maxpitch then
		local y = math.clamp(unit.Y, -maxpitch, maxpitch)
		local flat = Vector3.new(unit.X, 0, unit.Z)
		flat = flat.Magnitude > 0.01 and flat.Unit or Vector3.zAxis
		unit = (flat * math.sqrt(1 - y * y) + Vector3.new(0, y, 0)).Unit
	end
	return unit
end

local function aimdir(root, aim, maxpitch)
	return direction(root.Position, aim.target, maxpitch) or root.CFrame.LookVector
end

local function bone(rig, name)
	local rootpart = rig and rig:FindFirstChild("RootPart")
	return rootpart and rootpart:FindFirstChild(name, true)
end

local function meter(character)
	return kit:ragevalue(character)
end

local function addmeter(character, amount)
	local value = meter(character)
	if value then
		value.Value = math.clamp(value.Value + amount, 0, 100)
	end
end

local function setform(form)
	state.form = form
	tool:SetAttribute("tigerform", form)
	kit.data.Cooldown = data.forms[form]
end

local function makeprojectile(cframe, size)
	local part = Instance.new("Part")
	part.Name = "TigerProjectile"
	part.Size = Vector3.one * (size or 4)
	part.Transparency = 1
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Anchored = false
	part.CFrame = cframe
	local attachment = Instance.new("Attachment")
	attachment.Parent = part
	local velocity = Instance.new("LinearVelocity")
	velocity.Name = "mover"
	velocity.Attachment0 = attachment
	velocity.MaxForce = math.huge
	velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.VectorVelocity = Vector3.zero
	velocity.Parent = part
	local gyro = Instance.new("AlignOrientation")
	gyro.Attachment0 = attachment
	gyro.Mode = Enum.OrientationAlignmentMode.OneAttachment
	gyro.RigidityEnabled = true
	gyro.CFrame = cframe.Rotation
	gyro.Parent = part
	part.Parent = workspace:FindFirstChild("_WorldOrigin") or workspace
	pcall(function()
		part:SetNetworkOwner(nil)
	end)
	return part, velocity
end

local function stopprojectile(part)
	local cframe = part.CFrame
	part.Anchored = true
	part.CFrame = cframe
	return cframe
end

local function base(player, root, extra)
	local params = {
		player = player,
		Player = player,
		hrp = root,
		Root = root,
		HRP = root,
		origin = root.Position,
		Origin = root.Position,
		RigModel = state.rig,
		Rig = state.rig,
		transformedRig = state.rig,
		transformed = state.form > 0,
		fury = false,
	}
	for k, v in pairs(extra or {}) do
		params[k] = v
	end
	return params
end

local function setbodyhidden(character, hidden)
	if hidden then
		for _, d in ipairs(character:GetDescendants()) do
			local ofrig = state.accessory and d:IsDescendantOf(state.accessory)
			if not ofrig and (d:IsA("BasePart") or d:IsA("Decal")) and d.Transparency < 1 and not d:GetAttribute("TigerAccessory") then
				state.hidden[d] = d.Transparency
				d.Transparency = 1
			end
		end
	else
		for d, transparency in pairs(state.hidden) do
			if d.Parent then
				d.Transparency = transparency
			end
		end
		table.clear(state.hidden)
	end
end

local function damagereduction(humanoid)
	if state.healthconnection then
		state.healthconnection:Disconnect()
	end
	state.lasthealth = humanoid.Health
	state.healthconnection = humanoid.HealthChanged:Connect(function(health)
		local last = state.lasthealth or health
		state.lasthealth = health
		local reduction = data.reduction[state.form]
		if reduction and health < last and health > 0 then
			local refund = (last - health) * reduction
			state.lasthealth = math.min(humanoid.MaxHealth, health + refund)
			humanoid.Health = state.lasthealth
		end
	end)
end

local function attachrig(player, character, humanoid)
	local accessory = rigtemplate:Clone()
	local handle = accessory:WaitForChild("Handle")
	local stale = handle:FindFirstChild("AccessoryWeld")
	if stale then
		stale:Destroy()
	end
	local oldfolder = accessory:FindFirstChild("AccessoriesFolder")
	if oldfolder then
		oldfolder:Destroy()
	end
	local rig = accessory:WaitForChild("TigerRig")
	for _, d in ipairs(accessory:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.Massless = true
		end
	end
	local controller = rig:FindFirstChildOfClass("AnimationController")
	if controller and not controller:FindFirstChildOfClass("Animator") then
		Instance.new("Animator").Parent = controller
	end
	humanoid:AddAccessory(accessory)
	for _, d in ipairs(accessory:GetDescendants()) do
		if d:IsA("BasePart") then
			pcall(function()
				d:SetNetworkOwner(player)
			end)
		end
	end
	if transformationaccessories then
		pcall(transformationaccessories.attach, character, accessory:WaitForChild("ProxyHead"), player)
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root then
		state.unfit = rigfit.fit(character, humanoid, root, rig)
	end
	return accessory, rig
end

local function addblazingparts(rig)
	local folder = rig:FindFirstChild("VFX") and rig.VFX:FindFirstChild("Awakened") or rig
	local source = fxfolder:FindFirstChild("V_Awak")
	if not source then
		return
	end
	for name, bonename in pairs(blazingbones) do
		local template = source:FindFirstChild(name)
		local target = bone(rig, bonename)
		if template and target then
			local part = template:Clone()
			part.Anchored = false
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			part.Massless = true
			local constraint = part:FindFirstChild("RigidConstraint")
			if constraint then
				constraint.Attachment0 = part:FindFirstChild("Attachment") or part:FindFirstChildOfClass("Attachment")
				constraint.Attachment1 = target
			end
			part.CFrame = target.WorldCFrame
			part:SetAttribute("TigerBlazingPart", true)
			part.Parent = folder
		end
	end
	local bandage = source:FindFirstChild("NewBandage")
	local pants = rig:FindFirstChild("Pants + Bandages")
	if bandage and pants then
		local old = pants:FindFirstChildOfClass("SurfaceAppearance")
		if old then
			old.Name = "TigerBaseAppearance"
			old.Parent = nil
			pants:SetAttribute("TigerBaseAppearance", true)
		end
		bandage:Clone().Parent = pants
	end
end

local function setspeed(character, multiplier)
	character:SetAttribute("SpeedMultiplier", multiplier)
end

local function detach(character)
	local accessory = state.accessory
	state.token = nil
	if character then
		setbodyhidden(character, false)
	end
	if accessory then
		accessory:Destroy()
	end
	if state.unfit then
		state.unfit()
		state.unfit = nil
	end
	state.accessory, state.rig = nil, nil
	transformedrig.Value = nil
	istransformed.Value = false
	if character then
		local boost = character:FindFirstChild("LeopardBoost")
		if boost then
			boost:Destroy()
		end
	end
	setform(0)
end

local function startoverheat(character, duration)
	state.overheatuntil = os.clock() + duration
	if state.overheatvalue then
		state.overheatvalue:Destroy()
	end
	local value = Instance.new("BoolValue")
	value.Name = "TigerOverheating"
	value.Value = true
	value.Parent = character
	state.overheatvalue = value
	setspeed(character, data.speed.overheat)
	task.delay(duration, function()
		if state.overheatvalue == value then
			value:Destroy()
			state.overheatvalue = nil
			if character.Parent then
				setspeed(character, nil)
			end
		end
	end)
end

local function untransform(player, character, root, overheat)
	if state.form == 0 then
		return
	end
	local wasblazing = state.form == 2
	local duration = 0
	if wasblazing then
		duration = math.max((os.clock() - state.blazingstart) / 2, 2)
		setspeed(character, nil)
		startoverheat(character, duration)
	end
	kit:play("Tiger.Untransform", base(player, root, {
		isForTransformation = false,
		char = character,
		Awakened = wasblazing,
		AwakeningTimer = duration,
		overheating = state.overheatvalue,
	}))
	detach(character)
	local rage = meter(character)
	if rage then
		rage.Value = 0
	end
	kit:play("Tiger.TransformationSoundChanger", { hrp = root, transformedRig = nil })
	if overheat == nil and not wasblazing then
		state.overheatuntil = 0
	end
end

local function transform(player, character, root, humanoid)
	if os.clock() < state.overheatuntil then
		kit:play("Tiger.Untransform", base(player, root, { isForTransformation = true, char = character }))
		return false
	end
	local token = {}
	state.token = token
	kit.busyuntil = os.clock() + 1.1
	kit:play("Tiger.V", { player = player, hrp = root, isForTransformation = true })
	task.delay(0.6, function()
		if state.token ~= token or not character.Parent or humanoid.Health <= 0 then
			return
		end
		local accessory, rig = attachrig(player, character, humanoid)
		state.accessory, state.rig, state.character = accessory, rig, character
		setbodyhidden(character, true)
		transformedrig.Value = rig
		istransformed.Value = true
		setform(1)
		local rage = meter(character)
		if rage then
			rage.Value = 0
		end
		damagereduction(humanoid)
		kit:play("Tiger.TransformationSoundChanger", { hrp = root, transformedRig = rig })
		kit:play("Tiger.TransFloorFire", { player = player, hrp = root, char = character, stage = 1, transformedObject = transformedrig })
		blast(character, root.Position, data.v.radius, data.damage.vroar, 1.2, 60)
	end)
	return true
end

local function blaze(player, character, root, humanoid)
	local rig = state.rig
	if not rig then
		return false
	end
	kit.busyuntil = os.clock() + 1.4
	state.accessory:SetAttribute("Awakened", true)
	rig:SetAttribute("Awakened", true)
	kit:play("Tiger.Awakened.V", base(player, root, { Stage = 1, Rig = rig, wolf = false }))
	task.delay(1.2, function()
		if state.rig ~= rig or not character.Parent then
			return
		end
		addblazingparts(rig)
		setform(2)
		state.blazingstart = os.clock()
		setspeed(character, data.speed.blazing)
		humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + humanoid.MaxHealth * data.v.heal)
		state.lasthealth = humanoid.Health
		blast(character, root.Position, data.v.blazingradius, data.damage.vblazing, 1.5, 90)
	end)
	return true
end

local function m1(player, character, root)
	if state.form == 0 then
		return
	end
	if os.clock() - lastm1 > 1.2 then
		combo = 0
	end
	combo = combo % 4 + 1
	lastm1 = os.clock()
	local stage = combo
	local blazing = state.form == 2
	local mouse = kit.mousepos.Value
	kit:play(blazing and "Tiger.Awakened.M1Hit" or "Tiger.M1Hit", {
		player = player,
		plr = player,
		hrp = root,
		CFrame = root.CFrame,
		mouse = mouse,
		stage = stage,
	})
	if stage == 4 then
		kit.busyuntil = os.clock() + 0.75
	end
	task.delay(stage == 4 and 0.3 or 0.12, function()
		if not root.Parent then
			return
		end
		local amounts = blazing and data.damage.m1blazing or data.damage.m1
		local center = stage == 4 and root.Position or (root.CFrame * CFrame.new(0, 0, -6)).Position
		local radius = stage == 4 and (blazing and 20 or 16) or (blazing and 9 or 7)
		for _, target in ipairs(hitbox.sphere(character, center, radius)) do
			kit:hit(target.humanoid, amounts[stage], target.root)
			stun(target.model, stage == 4 and 1 or 0.6)
			if target.root then
				kit:play("Tiger.HitByM1", { player = player, hrp = root, enemyHrp = target.root, stage = stage, cf = target.root.CFrame })
				if stage == 4 then
					knock(target.root, root.CFrame.LookVector * 70 + Vector3.new(0, 30, 0))
				end
			end
		end
	end)
end

local function handorigin(root)
	return (root.CFrame * CFrame.new(1.5, 0.8, -2.5)).Position
end

local function airbullet(player, character, root)
	local aim = kit:aim(root)
	local origin = handorigin(root)
	local dir = direction(origin, aim.target) or root.CFrame.LookVector
	local speed = data.z.bulletspeed
	local flight = data.z.bulletflight
	kit:play("Tiger.ZAirBullet", {
		player = player,
		hrp = root,
		origin = origin,
		velocity = dir * speed,
		fliesFor = flight,
		airBulletSizeMult = state.form == 1 and 1.3 or 1,
		transformed = state.form == 1,
		Awakened = false,
	})
	local amount = state.form == 1 and data.damage.zbullettransformed or data.damage.zbullet
	task.delay(flight * 0.6, function()
		if character.Parent then
			along(character, origin, origin + dir * speed * flight, 4, amount, 0.5)
		end
	end)
end

local function firebullet(player, character, root, aim)
	local transformed = state.form == 1
	local origin = handorigin(root)
	local dir = direction(origin, aim.target, 0.6) or root.CFrame.LookVector
	local part, mover = makeprojectile(CFrame.lookAt(origin, origin + dir), 4)
	local explodesafter = data.z.explodesafter + (transformed and 0.05 or 0)
	local sizemult = transformed and data.z.sizemulttransformed or data.z.sizemult
	kit:play("Tiger.ZFireBullet", {
		player = player,
		hrp = root,
		projectilePart = part,
		explodesAfter = explodesafter,
		fieryBulletSizeMult = sizemult,
		transformed = transformed,
		fury = false,
	})
	mover.VectorVelocity = dir * data.z.firespeed
	debris:AddItem(part, explodesafter + 6)
	task.spawn(function()
		local started = os.clock()
		local stopped = false
		while part.Parent and os.clock() - started < explodesafter do
			if not stopped then
				local position = part.Position
				local blocked = workspace:Raycast(position, dir * 4, rayparams(character))
				local victim = hitbox.sphere(character, position, 4 * sizemult)[1]
				if blocked or victim then
					stopped = true
					mover.VectorVelocity = Vector3.zero
					stopprojectile(part)
					if victim then
						stun(victim.model, explodesafter - (os.clock() - started) + 0.5)
					end
				end
			end
			runservice.Heartbeat:Wait()
		end
		if not part.Parent then
			return
		end
		mover.VectorVelocity = Vector3.zero
		local cframe = stopprojectile(part)
		local stoppedvalue = Instance.new("CFrameValue")
		stoppedvalue.Name = "Stopped"
		stoppedvalue.Value = cframe
		stoppedvalue.Parent = part
		task.wait(0.125)
		if character.Parent then
			blast(character, cframe.Position, data.z.radius * sizemult, transformed and data.damage.zfiretransformed or data.damage.zfire, 1.2, 80)
		end
	end)
end

local function blazingz(player, character, root, aim)
	local rig = state.rig
	local dir = aimdir(root, aim, 0.35)
	local origin = root.Position
	local target = hitbox.first(character, origin, origin + dir * data.z.rushrange, 6)
	local endpoint
	if target and target.root then
		endpoint = target.root.Position - dir * 5
	else
		endpoint = clear(character, origin, origin + dir * (data.z.rushrange * 0.6))
	end
	local startcframe = CFrame.lookAt(origin, origin + dir)
	kit.busyuntil = os.clock() + data.z.rushtime + data.z.barrage + 1
	kit:play("Tiger.Awakened.Z", base(player, root, {
		Stage = 2,
		StartCFrame = startcframe,
		endPoint = endpoint,
		timeUntilReachedEndPoint = data.z.rushtime,
		Rig = rig,
	}))
	along(character, origin, endpoint, 6, data.damage.zblazingrush, 1)
	task.delay(data.z.rushtime, function()
		if not root.Parent then
			return
		end
		local face = CFrame.lookAt(endpoint, endpoint + dir)
		kit:play("Tiger.Awakened.Z", base(player, root, {
			Stage = 3,
			StartCFrame = face,
			GrabDur = data.z.barrage,
			WindUp = 0.1,
			Rig = rig,
		}))
		local ticks = math.floor(data.z.barrage / 0.1)
		for _ = 1, ticks do
			if not root.Parent then
				return
			end
			for _, hit in ipairs(hitbox.sphere(character, (root.CFrame * CFrame.new(0, 0, -7)).Position, 9)) do
				kit:hit(hit.humanoid, data.damage.zblazingjab, hit.root)
				stun(hit.model, 0.5)
			end
			task.wait(0.1)
		end
		kit:play("Tiger.Awakened.Z", base(player, root, { Stage = 4, Rig = rig }))
		task.wait(0.2)
		if root.Parent then
			blast(character, (root.CFrame * CFrame.new(0, 0, -8)).Position, 16, data.damage.zblazingshove, 1.2, 0)
			for _, hit in ipairs(hitbox.sphere(character, (root.CFrame * CFrame.new(0, 0, -8)).Position, 16)) do
				knock(hit.root, root.CFrame.LookVector * 110 + Vector3.new(0, 35, 0))
			end
		end
	end)
end

local function spiral(player, character, root, aim)
	local transformed = state.form == 1
	local onground = grounded(character, root)
	local dir
	if onground then
		dir = aim.forward
	else
		dir = aimdir(root, aim, 0.8)
	end
	local speed = transformed and data.x.speedtransformed or data.x.speed
	local sizemult = transformed and 1.25 or 1
	local flight = data.x.flight
	local start = root.Position + dir * 4 + (onground and Vector3.new(0, -1.5, 0) or Vector3.zero)
	local part, mover = makeprojectile(CFrame.lookAt(start, start + dir), 6 * sizemult)
	kit:play("Tiger.XSpiral", base(player, root, {
		origin = root.Position,
		projectilePart = part,
		rotPerFrame = data.x.rot,
		fliesFor = flight,
		projectileSizeMult = sizemult,
		stage = 2,
		Grounded = onground,
		wolf = false,
	}))
	mover.VectorVelocity = dir * speed
	debris:AddItem(part, flight + data.x.drag + 3)
	local multiplier = transformed and data.damage.xtransformed or 1
	local victims = {}
	task.spawn(function()
		local started = os.clock()
		while part.Parent and os.clock() - started < flight do
			local position = part.Position
			if workspace:Raycast(position, dir * 4, rayparams(character)) then
				break
			end
			for _, hit in ipairs(hitbox.sphere(character, position, data.x.radius * sizemult)) do
				if hit.root and not victims[hit.model] then
					victims[hit.model] = hit
					kit:hit(hit.humanoid, data.damage.xhit * multiplier, hit.root)
					stun(hit.model, flight + data.x.drag)
					local initvec = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5)
					initvec = initvec.Magnitude > 0.01 and initvec.Unit or Vector3.xAxis
					local endtime = now() + (flight - (os.clock() - started)) + data.x.drag
					local roots = {}
					for _, v in pairs(victims) do
						table.insert(roots, v.root)
					end
					kit:play("Tiger.XProjectileDrag", {
						enemyRoot = hit.root,
						projectilePart = part,
						victimRootParts = roots,
						syncedEndTime = endtime,
						initVec = initvec,
						rotPerFrame = data.x.rot,
					})
					if isnpc(hit.model) then
						local victimroot = hit.root
						task.spawn(function()
							local orbit = initvec
							local t0 = os.clock()
							victimroot.Anchored = true
							while now() < endtime and part.Parent and victimroot.Parent do
								orbit = CFrame.Angles(0, data.x.rot, 0) * orbit
								local t = os.clock() - t0
								victimroot.CFrame = CFrame.lookAt(Vector3.zero, orbit) * CFrame.Angles(7 * t, 5 * t, 5 * t) + part.Position + orbit * part.Size.Z * 0.5 + Vector3.new(0, 3, 0)
								runservice.Heartbeat:Wait()
							end
							if victimroot.Parent then
								victimroot.Anchored = false
							end
						end)
					end
				end
			end
			runservice.Heartbeat:Wait()
		end
		if not part.Parent then
			return
		end
		local dragend = os.clock() + (next(victims) and data.x.drag or 0)
		local lastdrag = 0
		while os.clock() < dragend and part.Parent do
			if os.clock() - lastdrag > 0.15 then
				lastdrag = os.clock()
				for model, hit in pairs(victims) do
					if model.Parent then
						kit:hit(hit.humanoid, data.damage.xdrag * multiplier, hit.root)
					end
				end
			end
			runservice.Heartbeat:Wait()
		end
		mover.VectorVelocity = Vector3.zero
		stopprojectile(part)
		task.wait(0.05)
		for model, hit in pairs(victims) do
			if model.Parent and hit.root then
				kit:hit(hit.humanoid, data.damage.xlaunch * multiplier, hit.root)
				knock(hit.root, dir * 25 + Vector3.new(0, 95, 0))
			end
		end
	end)
end

local function blazingx(player, character, root, aim)
	local dir = aimdir(root, aim, 0.5)
	local origin = root.Position + Vector3.new(0, 2, 0)
	local speed = data.x.blazingspeed
	local life = data.x.blazinglife
	local endposition = clear(character, origin, origin + dir * speed * life)
	local startcframe = CFrame.lookAt(origin, origin + dir)
	kit.busyuntil = os.clock() + 0.6
	kit:play("Tiger.Awakened.X", base(player, root, {
		Stage = 2,
		Speed = speed,
		Lifetime = life,
		ExplosionDur = 0.5,
		EndPosition = endposition,
		StartCFrame = startcframe,
		Character = character,
	}))
	task.spawn(function()
		local started = os.clock()
		local total = (endposition - origin).Magnitude / speed
		local position = origin
		while os.clock() - started < total do
			position = origin + dir * speed * (os.clock() - started)
			local hits = hitbox.sphere(character, position, 8)
			if #hits > 0 then
				break
			end
			runservice.Heartbeat:Wait()
		end
		if character.Parent then
			blast(character, position, data.x.blazingradius, data.damage.xblazing, 1.5, 100)
		end
	end)
end

local function cpath(player, character, root, aim, multiplier, module, extra)
	local dir = aimdir(root, aim, 0.45)
	local origin = root.Position
	local length = data.c.length * (state.form == 1 and 1.2 or 1)
	local endsafter = data.c.endsafter
	local finalblast = data.c.finalblast
	local pathend = clear(character, origin, origin + dir * length)
	kit.busyuntil = os.clock() + endsafter + finalblast + 0.3
	local params = base(player, root, {
		fireDir = dir,
		forwardCylinderRadius = data.c.radius,
		forwardCylinderLength = (pathend - origin).Magnitude,
		endsAfter = endsafter,
		timeUntilFinalBlast = finalblast,
		impactCF = groundcframe(character, pathend),
		willExecute = false,
		Stage = 2,
	})
	for k, v in pairs(extra or {}) do
		params[k] = v
	end
	kit:play(module, params)
	task.spawn(function()
		local hitset = {}
		local started = os.clock()
		while os.clock() - started < endsafter and root.Parent do
			local progress = (os.clock() - started) / endsafter
			local point = origin + (pathend - origin) * progress
			for _, hit in ipairs(hitbox.sphere(character, point, data.c.radius)) do
				if not hitset[hit.model] then
					hitset[hit.model] = true
					kit:hit(hit.humanoid, data.damage.cpath * multiplier, hit.root)
					stun(hit.model, endsafter + finalblast + 0.4)
				end
			end
			runservice.Heartbeat:Wait()
		end
		task.wait(finalblast)
		if root.Parent then
			blast(character, root.Position, data.c.blastradius, data.damage.cblast * multiplier, 1.2, 85)
		end
	end)
end

local function speedboost(player, character, root)
	local old = character:FindFirstChild("LeopardBoost")
	if old then
		old:Destroy()
	end
	local boost = Instance.new("BoolValue")
	boost.Name = "LeopardBoost"
	boost.Parent = character
	debris:AddItem(boost, data.speed.cboost)
	kit:play("Tiger.CTransformedSpeedUp", base(player, root, { timeSpedUp = data.speed.cboost, speedMult = 1.4 }))
	kit:play("Tiger.C", base(player, root, { Stage = 3, Awakened = state.form == 2 }))
end

local function cexecute(player, character, root, aim)
	local rig = state.rig
	local rage = meter(character)
	if rage then
		rage.Value = math.max(0, rage.Value - data.meter.executecost)
	end
	local dir = aimdir(root, aim, 0.3)
	local origin = root.Position
	local target = hitbox.first(character, origin, origin + dir * data.c.executerange, 7)
	local endpoint
	if target and target.root then
		endpoint = target.root.Position - dir * 5
	else
		endpoint = clear(character, origin, origin + dir * data.c.executerange * 0.6)
	end
	local startcframe = CFrame.lookAt(origin, origin + dir)
	kit.busyuntil = os.clock() + 0.6
	kit:play("Tiger.Awakened.C_Execute", base(player, root, {
		Stage = 2,
		StartCFrame = startcframe,
		endPoint = endpoint,
		timeUntilReachedEndPoint = 0.25,
		Rig = rig,
	}))
	if not target or not target.root then
		task.delay(0.3, function()
			if root.Parent then
				blast(character, endpoint, 14, data.damage.cpath * data.damage.ctransformed, 0.8, 50)
			end
		end)
		return
	end
	local victim = target
	kit.busyuntil = os.clock() + 0.3 + data.c.cutscene
	task.delay(0.3, function()
		if not root.Parent or not victim.root.Parent then
			return
		end
		local face = CFrame.lookAt(root.Position, Vector3.new(victim.root.Position.X, root.Position.Y, victim.root.Position.Z))
		kit:play("Tiger.Awakened.C_Execute", base(player, root, {
			Stage = 3,
			EnemyRoot = victim.root,
			StartCFrame = face,
			Attacker = player,
			Rig = rig,
		}))
		stun(victim.model, data.c.cutscene + 0.5)
		local hold = isnpc(victim.model) and victim.root or nil
		local holdcframe = hold and hold.CFrame
		if hold then
			hold.Anchored = true
		end
		local ticks = 12
		for _ = 1, ticks do
			task.wait((data.c.cutscene - 0.4) / ticks)
			if not victim.model.Parent then
				break
			end
			kit:hit(victim.humanoid, data.damage.cexecute, victim.root)
		end
		task.wait(0.4)
		if hold and hold.Parent then
			hold.Anchored = false
			hold.CFrame = holdcframe
		end
		if victim.model.Parent then
			kit:play("Tiger.Awakened.C_Execute", base(player, root, { Stage = 4, Origin = victim.root.Position }))
			kit:hit(victim.humanoid, data.damage.cexecutefinal, victim.root)
			knock(victim.root, root.CFrame.LookVector * 120 + Vector3.new(0, 40, 0))
		end
	end)
end

local function flicker(player, character, root, aim)
	local form = state.form
	local dir = aim.forward
	local origin = root.Position
	local length = form == 2 and data.f.lengthblazing or form == 1 and data.f.lengthtransformed or data.f.length
	local radius = data.f.radius * (form > 0 and 1.3 or 1)
	local target = hitbox.first(character, origin, origin + dir * length, radius)
	local endpoint, travelled
	local victimexists = target ~= nil and target.root ~= nil
	if victimexists then
		travelled = math.max(2, (target.root.Position - origin):Dot(dir) - 4)
		endpoint = origin + dir * travelled
	else
		endpoint = clear(character, origin, origin + dir * length)
		travelled = (endpoint - origin).Magnitude
	end
	local params = base(player, root, {
		fireDir = dir,
		forwardCylinderRadius = radius,
		forwardCylinderLength = length,
		timeUntilReachedEndPoint = data.f.travel,
		victimExists = victimexists,
		endPoint = endpoint,
		distTravelledForward = travelled,
		werewolf = false,
		Holding = nil,
	})
	kit:play(form == 2 and "Tiger.Awakened.FDash" or "Tiger.F", params)
	if not victimexists then
		kit.busyuntil = os.clock() + data.f.travel + 0.2
		return
	end
	local victim = target
	stun(victim.model, 2)
	if form == 2 then
		kit.busyuntil = os.clock() + 4.4
		task.delay(data.f.travel + 0.05, function()
			if not root.Parent or not victim.model.Parent then
				return
			end
			local grab = Instance.new("CFrameValue")
			grab.Name = "TigerGrab"
			grab.Value = victim.root.CFrame
			grab.Parent = root
			debris:AddItem(grab, 5)
			local start = root.CFrame
			local up = Vector3.new(0, 1, 0)
			local c1 = start + up * 14
			local c2 = start + up * 28 + start.LookVector * 4
			local c3 = start + up * 40 + start.LookVector * 8
			kit:play("Tiger.Awakened.F", base(player, root, {
				Stage = 2,
				StartCFrame = start,
				Timeout = 4.2,
				WindUp = 0.1,
				GrabExists = grab,
				AttackerChar = character,
				AttackerHum = character:FindFirstChildOfClass("Humanoid"),
				VictimChar = victim.model,
				VictimHum = victim.humanoid,
				CFrame1 = c1,
				CFrame2 = c2,
				CFrame3 = c3,
			}))
			stun(victim.model, 4.5)
			local npcroot = isnpc(victim.model) and victim.root or nil
			if npcroot then
				npcroot.Anchored = true
			end
			local started = os.clock()
			local lasthit = 0
			while os.clock() - started < 3.85 and root.Parent and victim.model.Parent do
				if npcroot then
					npcroot.CFrame = CFrame.lookAt(root.Position, root.Position - root.CFrame.LookVector) * CFrame.new(0, 0, 4)
				end
				if os.clock() - lasthit > 0.3 then
					lasthit = os.clock()
					kit:hit(victim.humanoid, data.damage.fblazingslash, victim.root)
				end
				runservice.Heartbeat:Wait()
			end
			if npcroot and npcroot.Parent then
				npcroot.Anchored = false
				knock(npcroot, Vector3.new(0, -140, 0))
			end
			if victim.model.Parent then
				kit:hit(victim.humanoid, data.damage.fblazingslam, victim.root)
			end
			grab:Destroy()
		end)
		return
	end
	kit.busyuntil = os.clock() + data.f.travel + data.f.kickdelay + 0.3
	local npcroot = isnpc(victim.model) and victim.root or nil
	if npcroot then
		npcroot.Anchored = true
	end
	task.delay(data.f.travel + data.f.kickdelay, function()
		if npcroot and npcroot.Parent then
			npcroot.Anchored = false
		end
		if not root.Parent or not victim.model.Parent then
			return
		end
		local multiplier = form == 1 and data.damage.ftransformed or 1
		kit:hit(victim.humanoid, data.damage.fkick * multiplier, victim.root)
		knock(victim.root, dir * 120 + Vector3.new(0, 30, 0))
		blast(character, victim.root.Position, 10, data.damage.froar * multiplier * 0.5, 0.8)
	end)
end

local function onholdstart(player, character, root, key)
	local form = state.form
	local token = { key = key, player = player, character = character, root = root, started = os.clock() }
	hold = token
	if key == "Z" then
		if form == 2 then
			kit:play("Tiger.Awakened.Z", base(player, root, { Stage = 1, Holding = kit.effectholding }))
			return
		end
		kit:play(form == 1 and "Tiger.ZFireChargeRed" or "Tiger.ZFireCharge", { player = player, hrp = root, amount = 3 })
		task.spawn(function()
			task.wait(data.z.chargetime)
			while hold == token and kit.active and kit.active.key == "Z" and root.Parent do
				airbullet(player, character, root)
				task.wait(data.z.interval)
			end
		end)
	elseif key == "X" then
		if form == 2 then
			kit:play("Tiger.Awakened.X", base(player, root, { Stage = 1, Holding = kit.effectholding }))
			return
		end
		kit:play("Tiger.XSpiral", base(player, root, {
			Holding = kit.effectholding,
			Grounded = grounded(character, root),
			wolf = false,
			stage = 1,
		}))
	elseif key == "C" then
		if form == 1 then
			kit:play("Tiger.C", base(player, root, { Stage = 1, Holding = kit.effectholding }))
		elseif form == 2 then
			kit:play("Tiger.Awakened.C", base(player, root, { Stage = 1, Holding = kit.effectholding }))
		end
	elseif key == "F" then
		kit:play(form == 2 and "Tiger.Awakened.FDash" or "Tiger.F", base(player, root, { Holding = kit.effectholding }))
	end
end

local function onrelease(player, character, root, key, aim)
	local token = hold
	hold = nil
	local held = token and os.clock() - token.started or 0
	local form = state.form
	if not spend(character, data.Cost[key]) then
		return
	end
	if key == "Z" then
		if form == 2 then
			blazingz(player, character, root, aim)
		else
			kit.busyuntil = os.clock() + 0.35
			firebullet(player, character, root, aim)
		end
	elseif key == "X" then
		if form == 2 then
			blazingx(player, character, root, aim)
		else
			kit.busyuntil = os.clock() + 0.35
			spiral(player, character, root, aim)
		end
	elseif key == "C" then
		if form == 0 then
			cpath(player, character, root, aim, 1, "Tiger.C_Old", {})
		elseif form == 1 then
			local rage = meter(character)
			if held >= data.c.executehold and rage and rage.Value >= data.meter.executecost then
				cexecute(player, character, root, aim)
			else
				cpath(player, character, root, aim, data.damage.ctransformed, "Tiger.C", {})
				task.delay(data.c.endsafter + data.c.finalblast, function()
					if root.Parent then
						speedboost(player, character, root)
					end
				end)
			end
		else
			cpath(player, character, root, aim, data.damage.cblazing, "Tiger.Awakened.C", {})
			task.delay(data.c.endsafter + data.c.finalblast, function()
				if root.Parent then
					speedboost(player, character, root)
				end
			end)
		end
	elseif key == "F" then
		flicker(player, character, root, aim)
	end
end

local function onkey(player, character, root, humanoid, key)
	if key ~= "V" or not kit:canuse(character, "V") then
		return
	end
	local form = state.form
	if form == 0 then
		if os.clock() < state.overheatuntil then
			return
		end
		if not spend(character, data.Cost.V) then
			return
		end
		if transform(player, character, root, humanoid) then
			kit.lastused.V = os.clock()
		end
	elseif form == 1 then
		local rage = meter(character)
		kit.lastused.V = os.clock()
		if rage and rage.Value >= 100 then
			if not spend(character, data.Cost.V) then
				return
			end
			blaze(player, character, root, humanoid)
		else
			untransform(player, character, root)
		end
	else
		kit.lastused.V = os.clock()
		untransform(player, character, root, true)
	end
end

local function passivestart(player, character)
	local token = {}
	passiveloop = token
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		if state.deathconnection then
			state.deathconnection:Disconnect()
		end
		state.deathconnection = humanoid.Died:Connect(function()
			detach(nil)
			state.overheatuntil = 0
		end)
	end
	meter(character)
	task.spawn(function()
		while passiveloop == token and character.Parent do
			local rage = character:FindFirstChild("Rage")
			if rage then
				if state.form == 1 then
					rage.Value = math.min(100, rage.Value + data.meter.passive * 0.25)
				elseif state.form == 2 then
					rage.Value = math.max(0, rage.Value - 100 / data.meter.blazingtime * 0.25)
					if rage.Value <= 0 then
						local root = character:FindFirstChild("HumanoidRootPart")
						if root then
							untransform(player, character, root, true)
						end
					end
				end
			end
			task.wait(0.25)
		end
	end)
end

local function passiveend(character)
	passiveloop = nil
	if state.form > 0 then
		local player = players:GetPlayerFromCharacter(character)
		local root = character:FindFirstChild("HumanoidRootPart")
		if player and root then
			untransform(player, character, root)
		else
			detach(character)
		end
	end
	if state.healthconnection then
		state.healthconnection:Disconnect()
		state.healthconnection = nil
	end
	if state.deathconnection then
		state.deathconnection:Disconnect()
		state.deathconnection = nil
	end
	character:SetAttribute("SpeedMultiplier", nil)
end

kit = fruitkit.new(tool, {
	holdkeys = { Z = true, X = true, C = true, F = true },
	maxhold = 3,
	onholdstart = onholdstart,
	onrelease = onrelease,
	onm1 = function(player, character, root)
		m1(player, character, root)
	end,
	onkey = onkey,
	onpassivestart = passivestart,
	onpassiveend = passiveend,
	onhit = function(amount)
		local character = kit:getcharacter() or kit.passivecharacter
		if character and state.form == 1 then
			addmeter(character, math.min(data.meter.maxperhit, amount * data.meter.perhit))
		end
	end,
	canhold = function(_, character, _, key)
		local energy = character:FindFirstChild("Energy")
		return not energy or energy.Value >= (data.Cost[key] or 0)
	end,
})

kit.data = { Lvl = data.Lvl, Cooldown = data.forms[0], Cost = data.Cost }
setform(0)
