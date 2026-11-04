local players = game:GetService("Players")
local serverstorage = game:GetService("ServerStorage")
local runservice = game:GetService("RunService")
local debris = game:GetService("Debris")

local fruitkit = require(serverstorage:WaitForChild("fruitkit"))
local meleekit = require(serverstorage:WaitForChild("meleekit"))

local tool = script.Parent
local data = require(tool:WaitForChild("Data"))

local function ensure(classname, name)
	local value = tool:FindFirstChild(name)
	if not value then
		value = Instance.new(classname)
		value.Name = name
		value.Parent = tool
	end
	return value
end

local cremote = ensure("RemoteEvent", "DoughCRemote")
local wheelremote = ensure("RemoteEvent", "DoughWheelRemote")

local kit
local combo, lastm1 = 0, 0
local hold = nil
local wheel = nil
local grab = nil
local tapsides = { "Right", "Left", "Both" }

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

local function holdnpc(root, path, duration)
	if not isnpc(root.Parent) then
		return function() end
	end
	local wasanchored = root.Anchored
	root.Anchored = true
	local started = os.clock()
	local released = false
	local connection
	local function release()
		if released then
			return
		end
		released = true
		if connection then
			connection:Disconnect()
		end
		if root.Parent then
			root.Anchored = wasanchored
		end
	end
	connection = runservice.Heartbeat:Connect(function()
		if not root.Parent or os.clock() - started >= duration then
			release()
			return
		end
		local cframe = path(os.clock() - started)
		if cframe then
			root.CFrame = cframe
		end
	end)
	return release
end

local function worldorigin()
	return workspace:FindFirstChild("_WorldOrigin") or workspace
end

local function rayparams(character)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore = { character, worldorigin() }
	for _, name in ipairs({ "Characters", "Enemies" }) do
		local folder = workspace:FindFirstChild(name)
		if folder then
			table.insert(ignore, folder)
		end
	end
	params.FilterDescendantsInstances = ignore
	return params
end

local function worldhit(character, from, to)
	local result = workspace:Raycast(from, to - from, rayparams(character))
	if result then
		return result.Position, result.Normal, true
	end
	return to, Vector3.yAxis, false
end

local function ground(character, position, depth)
	local result = workspace:Raycast(position + Vector3.new(0, 4, 0), Vector3.new(0, -(depth or 200), 0), rayparams(character))
	if result then
		return result.Position, result.Normal
	end
	return nil
end

local function buso(character, player)
	if not character:FindFirstChild("HasBuso") then
		return nil
	end
	local value = player and player:FindFirstChild("BusoColor")
	return value and value.Value or Color3.new(0.1, 0.1, 0.1)
end

local function grounded(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.FloorMaterial ~= Enum.Material.Air
end

local function servertime()
	return meleekit.now()
end

local function indicator(root, lifetime)
	local value = Instance.new("BoolValue")
	value.Name = "DoughIndicator"
	value:SetAttribute("Holding", true)
	value:SetAttribute("Scale", 1)
	value.Parent = root
	debris:AddItem(value, lifetime)
	return value
end

local function punch(player, character, root, side, target, charged)
	local playerbuso = buso(character, player)
	local marker = indicator(root, 3)
	local offset = side == "Left" and -1.6 or 1.6
	kit:play("Dough.TAP", {
		Stage = 1,
		Anchor = root,
		Side = side,
		CFrame = CFrame.new(offset, 1.2, -1),
		Scale = { 0, charged and 1.6 or 1 },
		Lifetime = marker,
		FadeIn = 0.15,
		FadeOut = 0.4,
		Mouse = kit.mousepos,
	})
	task.wait(0.15)
	if not root.Parent then
		return
	end
	local origin = (root.CFrame * CFrame.new(offset, 1.2, -1)).Position
	local range = charged and data.tap.chargedrange or data.tap.range
	local endpoint, normal, hit = worldhit(character, origin, origin + (target - origin).Unit * range)
	marker:SetAttribute("Holding", false)
	kit:play("Dough.TAP", {
		Stage = 2,
		Root = root,
		Side = side,
		Indicator = marker,
		CFrame = CFrame.lookAt(origin, endpoint),
		Scale = Vector2.new(data.tap.width * (charged and 1.4 or 1), (endpoint - origin).Magnitude),
		ExtendDuration = 0.12,
		FreezeDuration = 0.05,
		RetractDuration = 0.3,
		Buso = playerbuso,
		MaximumFloorMultiplier = charged and 2 or 1,
		RayCastResult = hit and { Position = endpoint, Normal = normal } or nil,
	})
	task.wait(0.1)
	local amount = charged and data.damage.tapcharged or data.damage.tap
	enemiesnear(character, origin, range + 4, function(model, humanoid, victimroot)
		local along = victimroot.Position - origin
		local direction = (endpoint - origin).Unit
		local distance = along:Dot(direction)
		if distance >= 0 and distance <= range + 2 and (along - direction * distance).Magnitude <= 5 then
			kit:hit(humanoid, amount, victimroot)
			stun(model, 0.6)
			meleekit.push(victimroot, direction, 45, 8)
		end
	end)
end

local function onm1(player, character, root)
	if os.clock() - lastm1 > data.tap.reset then
		combo = 0
	end
	lastm1 = os.clock()
	combo = combo % #tapsides + 1
	local side = tapsides[combo]
	local target = kit.mousepos.Value
	kit.busyuntil = os.clock() + 0.3
	if side == "Both" then
		task.spawn(punch, player, character, root, "Left", target, true)
		task.spawn(punch, player, character, root, "Right", target, true)
	else
		task.spawn(punch, player, character, root, side, target, false)
	end
end

local function missile(player, character, root, aim, held)
	local power = math.clamp(held / data.z.holdfull, 0, 1)
	local full = held >= data.z.holdfull
	local speed = data.z.speed
	local range = full and data.z.heldrange or data.z.range
	local scale = 1 + power * 0.8
	local origin = (root.CFrame * CFrame.new(1.5, 1, -2)).Position
	local direction = (aim.target - origin).Unit
	if direction ~= direction then
		direction = root.CFrame.LookVector
	end
	local part = Instance.new("Part")
	part.Name = "DoughMissile"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Transparency = 1
	part.Size = Vector3.new(2, 2, 6) * scale
	part.CFrame = CFrame.lookAt(origin, origin + direction)
	part.Parent = worldorigin()
	debris:AddItem(part, range / speed + 4)
	task.wait()
	kit:play("Dough.Misc.Projectile", {
		Method = "Create",
		Anchor = part,
		Scale = scale,
		Data = { Speed = speed, Timestamp = workspace:GetServerTimeNow() },
	})
	kit:play("Dough.Misc.Projectile", { Method = "Ignite", Anchor = part, Enabled = true })
	if held > 0.2 then
		meleekit.push(root, -direction, data.z.recoil * power, 10 * power)
	end
	kit.busyuntil = os.clock() + 0.4
	local travelled = 0
	local dragged = {}
	local position = origin
	local impact, grounded_ = nil, false
	while travelled < range and part.Parent do
		local dt = runservice.Heartbeat:Wait()
		local step = speed * dt
		local nextposition = position + direction * step
		local result = workspace:Raycast(position, nextposition - position, rayparams(character))
		if result then
			impact = result.Position
			grounded_ = result.Normal.Y > 0.5
			break
		end
		position = nextposition
		travelled += step
		part.CFrame = CFrame.lookAt(position, position + direction)
		enemiesnear(character, position, data.z.radius * scale, function(model, humanoid, victimroot)
			if not dragged[model] then
				dragged[model] = victimroot
				kit:hit(humanoid, data.damage.zdrag, victimroot)
				stun(model, 1)
			end
		end)
		for model, victimroot in pairs(dragged) do
			if victimroot.Parent and isnpc(model) then
				victimroot.CFrame = CFrame.new(position + direction * 2)
				victimroot.AssemblyLinearVelocity = Vector3.zero
			end
		end
	end
	impact = impact or position
	kit:play("Dough.Misc.Projectile", {
		Method = "Destroy",
		Anchor = part,
		Data = { FadeOut = 0.5, CFrame = CFrame.lookAt(impact, impact + direction) },
	})
	local radius = full and data.z.heldexplosion or data.z.explosion
	kit:play("Dough.Explosions.Generic", {
		CFrame = CFrame.new(impact),
		Scale = radius,
		Duration = 0.6,
		Lifetime = 1.5,
		Grounded = grounded_,
	})
	local amount = full and data.damage.zheld or data.damage.z
	enemiesnear(character, impact, radius, function(model, humanoid, victimroot)
		kit:hit(humanoid, amount, victimroot)
		stun(model, 0.8)
		meleekit.push(victimroot, (victimroot.Position - impact), 60, 30)
	end)
	debris:AddItem(part, 2)
end

local function pastryground(player, character, root, aim, held)
	local power = math.clamp(held / data.x.holdfull, 0, 1)
	local scale = 1 + power
	local target = kit:clamprange(root.Position, aim.target, data.x.range)
	local spot, normal = ground(character, target, 300)
	spot = spot or target
	normal = normal or Vector3.yAxis
	local cframe = CFrame.lookAt(spot, spot + root.CFrame.LookVector * Vector3.new(1, 0, 1))
	kit:play("Dough.X.Ground", {
		CFrame = cframe,
		Scale = scale,
		EruptDelay = data.x.eruptdelay,
		Lifetime = data.x.holdup + 0.6,
		FadeIn = 0.2,
		FadeOut = 0.5,
		FloorLifetime = 3,
		AnimationSpeed = 1,
		PulsateInfluence = 1,
		Buso = buso(character, player),
	})
	kit.busyuntil = os.clock() + 0.6
	task.wait(data.x.eruptdelay)
	local radius = data.x.radius * scale
	enemiesnear(character, spot, radius, function(model, humanoid, victimroot)
		kit:hit(humanoid, data.damage.xground * (0.8 + power * 0.4), victimroot)
		stun(model, data.x.holdup + 1)
		local from = victimroot.Position
		local top = from + Vector3.new(0, data.x.lift * scale, 0)
		holdnpc(victimroot, function(elapsed)
			local alpha = math.clamp(elapsed / 0.25, 0, 1)
			if elapsed > data.x.holdup then
				alpha = 1 - math.clamp((elapsed - data.x.holdup) / 0.25, 0, 1)
			end
			return CFrame.new(from:Lerp(top, alpha))
		end, data.x.holdup + 0.3)
		task.delay(data.x.holdup + 0.25, function()
			if humanoid.Parent and humanoid.Health > 0 then
				kit:hit(humanoid, data.damage.xgroundslam, victimroot)
			end
		end)
	end)
end

local function pastryair(player, character, root, aim, held)
	local power = math.clamp(held / data.x.holdfull, 0, 1)
	local length = data.x.airrange + (data.x.airheldrange - data.x.airrange) * power
	local upperarm = character:FindFirstChild("RightUpperArm")
	local shoulder = upperarm and upperarm:FindFirstChild("RightShoulder")
	local lowerarm = character:FindFirstChild("RightLowerArm")
	local elbow = lowerarm and lowerarm:FindFirstChild("RightElbow")
	local hand = character:FindFirstChild("RightHand")
	local wrist = hand and hand:FindFirstChild("RightWrist")
	local origin = upperarm and upperarm.Position or root.Position
	local direction = (aim.target - origin).Unit
	if direction ~= direction then
		direction = root.CFrame.LookVector
	end
	local point, normal, hitworld = worldhit(character, origin, origin + direction * length)
	if shoulder and elbow and wrist then
		kit:play("Dough.X.Aerial.Arm", {
			Root = root,
			HRP = root,
			Anchor = upperarm,
			AnchorJoint = shoulder,
			AnchorJoint2 = elbow,
			AnchorJoint3 = wrist,
			Point = point,
			Length = (point - origin).Magnitude,
			Size = Vector3.new(1, 1, 1) * (1 + power * 0.5),
			ExtendDuration = 0.25,
			RetractDuration = 0.35,
			RayCastResult = hitworld and { Position = point, Normal = normal } or nil,
		})
	end
	kit.busyuntil = os.clock() + 0.7
	local target = meleekit.firstline(character, origin, point, 5 + power * 3)
	if not target then
		return
	end
	task.wait(0.25)
	if not meleekit.alive(target.model) then
		return
	end
	stun(target.model, data.x.barrage + 1.2)
	local effectid = player.UserId .. "_" .. math.floor(os.clock() * 1000)
	local holdat = root.CFrame * CFrame.new(0, 2, -8)
	local release = holdnpc(target.root, function()
		return holdat
	end, data.x.barrage + 0.6)
	local landing = ground(character, root.Position + root.CFrame.LookVector * 14, 300) or (root.Position - Vector3.new(0, 10, 0))
	local reach = CFrame.new(landing)
	kit:play("Dough.X.Aerial.Ball", {
		EffectId = effectid,
		Stage = 1,
		CFrame = holdat,
		ReachCFrame = holdat,
		Scale = 3,
		Duration = data.x.barrage,
		FadeIn = 0.2,
		FadeOut = 0.4,
	})
	kit.busyuntil = os.clock() + data.x.barrage + 0.8
	local stop = os.clock() + data.x.barrage
	while os.clock() < stop and meleekit.alive(target.model) and root.Parent do
		kit:hit(target.humanoid, data.damage.xairbarrage, target.root)
		task.wait(data.x.barragetick)
	end
	kit:play("Dough.X.Aerial.Ball", {
		EffectId = effectid,
		Stage = 2,
		CFrame = holdat,
		ReachCFrame = reach,
		Scale = 3,
		Duration = 0.3,
	})
	release()
	if target.root.Parent and isnpc(target.model) then
		target.root.CFrame = reach + Vector3.new(0, 3, 0)
	end
	task.wait(0.3)
	kit:play("Dough.X.Aerial.Explosion", { CFrame = reach, Scale = 18, Duration = 0.5, Lifetime = 1.5 })
	if meleekit.alive(target.model) then
		kit:hit(target.humanoid, data.damage.xairslam, target.root)
		stun(target.model, 0.8)
	end
	blast(character, landing, 16, data.damage.xairslam * 0.4, 0.5)
end

local function hidebody(character, hidden)
	local model = wheel and wheel.model
	for _, d in ipairs(character:GetDescendants()) do
		if (d:IsA("BasePart") or d:IsA("Decal")) and d.Name ~= "HumanoidRootPart" and not (model and d:IsDescendantOf(model)) then
			if hidden then
				if d.Transparency < 1 then
					d:SetAttribute("doughhidden", d.Transparency)
					d.Transparency = 1
				end
			elseif d:GetAttribute("doughhidden") ~= nil then
				d.Transparency = d:GetAttribute("doughhidden")
				d:SetAttribute("doughhidden", nil)
			end
		end
	end
end

local function stopwheel(skipeffect)
	local current = wheel
	if not current then
		return
	end
	wheel = nil
	current.token = nil
	if current.connection then
		current.connection:Disconnect()
	end
	local character = current.character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if current.collision and current.collision.Parent then
		current.collision:SetAttribute("Destroy", true)
	end
	if current.model then
		debris:AddItem(current.model, skipeffect and 0 or 0.4)
	end
	if humanoid and humanoid.Parent then
		humanoid.PlatformStand = false
	end
	if character then
		hidebody(character, false)
	end
	tool:SetAttribute("doughwheel", false)
end

local function startwheel(player, character, root, maxspeed, duration, oncontact)
	stopwheel(true)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local model = Instance.new("Model")
	model.Name = "DoughWheel"
	local wheelpart = Instance.new("Part")
	wheelpart.Name = "WheelPart"
	wheelpart.Size = data.f.size
	wheelpart.Shape = Enum.PartType.Ball
	wheelpart.Transparency = 1
	wheelpart.CanCollide = true
	wheelpart.CanQuery = false
	wheelpart.CanTouch = false
	wheelpart.CFrame = root.CFrame
	wheelpart:SetAttribute("MaxSpeed", maxspeed)
	wheelpart:SetAttribute("MaxInputTurnPower", 1)
	wheelpart:SetAttribute("MaxCameraTurnPower", 0.6)
	wheelpart:SetAttribute("TurnSpeedNudgeInterpolate", 4)
	wheelpart:SetAttribute("DriftAboveTurnPower", 0.8)
	wheelpart:SetAttribute("MaxTurnSpeed", 2.5)
	wheelpart:SetAttribute("MaxTiltAngle", 0.35)
	wheelpart.Parent = model
	local collision = Instance.new("Part")
	collision.Name = "Wheel"
	collision.Size = Vector3.new(data.f.size.X, data.f.size.Y, data.f.size.Z * 0.4)
	collision.Transparency = 1
	collision.CanCollide = false
	collision.CanQuery = false
	collision.CanTouch = false
	collision.Massless = true
	collision.CFrame = wheelpart.CFrame
	collision.Parent = wheelpart
	local joint = Instance.new("Motor6D")
	joint.Name = "Motor6D"
	joint.Part0 = wheelpart
	joint.Part1 = collision
	joint.Parent = collision
	local attachment = Instance.new("Attachment")
	attachment.Name = "WheelAttachment"
	attachment.Parent = collision
	local velocity = Instance.new("BodyVelocity")
	velocity.MaxForce = Vector3.zero
	velocity.Velocity = Vector3.zero
	velocity.Parent = wheelpart
	local gyro = Instance.new("BodyGyro")
	gyro.MaxTorque = Vector3.new(1, 1, 1) * 4e5
	gyro.P = 3000
	gyro.CFrame = CFrame.lookAt(Vector3.zero, root.CFrame.LookVector * Vector3.new(1, 0, 1))
	gyro.Parent = wheelpart
	local position = Instance.new("BodyPosition")
	position.MaxForce = Vector3.zero
	position.Parent = wheelpart
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = wheelpart
	weld.Part1 = root
	weld.Parent = wheelpart
	model.PrimaryPart = wheelpart
	model.Parent = character
	for _, part in ipairs({ wheelpart, collision }) do
		pcall(function()
			part:SetNetworkOwner(player)
		end)
	end
	if humanoid then
		humanoid.PlatformStand = true
	end
	local token = {}
	wheel = { model = model, part = wheelpart, collision = collision, character = character, player = player, token = token }
	hidebody(character, true)
	tool:SetAttribute("doughwheel", true)
	kit:play("Dough.F", {
		Character = character,
		Wheel = collision,
		Scale = 1,
		FadeIn = 0.5,
		FadeOut = 0.25,
		Buso = buso(character, player),
	})
	local hitcooldown = {}
	local started = os.clock()
	wheel.connection = runservice.Heartbeat:Connect(function()
		if wheel == nil or wheel.token ~= token then
			return
		end
		if not root.Parent or not humanoid or humanoid.Health <= 0 or os.clock() - started > duration then
			stopwheel()
			return
		end
		if wheelpart.AssemblyLinearVelocity.Magnitude < 12 then
			return
		end
		enemiesnear(character, wheelpart.Position, data.f.radius, function(model_, humanoid_, victimroot)
			if oncontact then
				if oncontact(model_, humanoid_, victimroot) then
					return
				end
			end
			if os.clock() - (hitcooldown[model_] or 0) >= data.f.tick then
				hitcooldown[model_] = os.clock()
				kit:hit(humanoid_, data.damage.f, victimroot)
				stun(model_, 0.35)
			end
		end)
	end)
	return token
end

wheelremote.OnServerEvent:Connect(function(player, info)
	if not wheel or wheel.player ~= player or type(info) ~= "table" then
		return
	end
	if info.Wheel ~= wheel.collision or type(info.Attributes) ~= "table" then
		return
	end
	local turn = tonumber(info.Attributes.CurrentTurnSpeed)
	if turn then
		wheel.collision:SetAttribute("CurrentTurnSpeed", math.clamp(turn, -5, 5))
	end
end)

cremote.OnServerEvent:Connect(function(player, info)
	if not grab or grab.player ~= player or type(info) ~= "table" then
		return
	end
	if info.Weld ~= grab.weld or typeof(info.C0) ~= "CFrame" then
		return
	end
	if info.C0.Position.Magnitude <= data.c.raise * 3 then
		grab.weld.C0 = info.C0
	end
end)

local function setcstage(character, stage)
	character:SetAttribute("DoughAwakenedCStage", stage)
end

local function clothesline(player, character, root, target)
	local c = data.c
	local hitbox = Instance.new("Part")
	hitbox.Name = "DoughCHitbox"
	hitbox.Size = Vector3.new(5, 5, 5)
	hitbox.Transparency = 1
	hitbox.CanCollide = false
	hitbox.CanQuery = false
	hitbox.CanTouch = false
	hitbox.Massless = true
	hitbox.CFrame = root.CFrame * CFrame.new(0, 0, -6)
	local weld = Instance.new("Weld")
	weld.Name = "Weld"
	weld.Part0 = root
	weld.Part1 = hitbox
	weld.C0 = CFrame.new(0, 0, -6)
	weld.Parent = hitbox
	hitbox.Parent = character
	pcall(function()
		hitbox:SetNetworkOwner(player)
	end)
	grab = { player = player, weld = weld, hitbox = hitbox }

	local center = CFrame.new(root.Position) * root.CFrame.Rotation
	local slamspot = ground(character, root.Position + root.CFrame.LookVector * c.slamdistance, 300) or (root.Position + root.CFrame.LookVector * c.slamdistance)
	local slamcframe = CFrame.new(slamspot)
	local total = c.windup + c.spin + c.slam + c.slamhold + c.retract
	local victims = {}
	if target then
		victims[target.model] = target
	end
	local function holdvictims(duration)
		for model, victim in pairs(victims) do
			stun(model, duration + 0.3)
			holdnpc(victim.root, function()
				return hitbox.Parent and hitbox.CFrame or nil
			end, duration)
		end
	end

	kit.busyuntil = os.clock() + total + 0.3
	local playerbuso = buso(character, player)
	setcstage(character, 1)
	kit:play("Dough.C", {
		Stage = 1,
		Character = character,
		Hitbox = hitbox,
		Remote = cremote,
		Buso = playerbuso,
		CFrame = center,
		SlamCFrame = slamcframe,
		RaiseHeight = c.raise,
		TotalSpins = c.spins,
		WindUpDuration = c.windup,
		SpinDuration = c.spin,
		SlamDuration = c.slam,
		SlamHoldDuration = c.slamhold,
		RetractDuration = c.retract,
		Timestamp = servertime(),
	})
	holdvictims(total)
	task.wait(c.windup)
	if not root.Parent then
		return
	end
	setcstage(character, 2)
	kit:play("Dough.C", { Stage = 2, Character = character, Timestamp = servertime() })
	local spinend = os.clock() + c.spin
	while os.clock() < spinend and root.Parent do
		enemiesnear(character, hitbox.Position, 10, function(model, humanoid, victimroot)
			if not victims[model] then
				victims[model] = { model = model, humanoid = humanoid, root = victimroot }
				stun(model, spinend - os.clock() + c.slam + c.slamhold + 0.5)
				holdnpc(victimroot, function()
					return hitbox.Parent and hitbox.CFrame or nil
				end, spinend - os.clock() + c.slam)
			end
			kit:hit(humanoid, data.damage.cspin, victimroot)
		end)
		task.wait(0.2)
	end
	setcstage(character, 3)
	kit:play("Dough.C", { Stage = 3, Character = character, Timestamp = servertime() })
	task.wait(c.slam)
	for model, victim in pairs(victims) do
		if victim.root.Parent and isnpc(model) then
			victim.root.CFrame = slamcframe + Vector3.new(0, 3, 0)
		end
	end
	blast(character, slamspot, c.slamradius, data.damage.cslam, 0.9)
	for model, victim in pairs(victims) do
		if victim.root.Parent then
			meleekit.push(victim.root, Vector3.zero, 0, 55)
		end
	end
	meleekit.push(root, Vector3.zero, 0, 40)
	task.wait(c.slamhold)
	setcstage(character, 4)
	kit:play("Dough.C", { Stage = 4, Character = character, Timestamp = servertime() })
	task.wait(c.retract)
	kit:play("Dough.C", { Stage = -1, Character = character, Timestamp = servertime() })
	setcstage(character, nil)
	grab = nil
	hitbox:Destroy()
end

local function clothesroll(player, character, root)
	local hit = nil
	local token
	token = startwheel(player, character, root, data.c.rollspeed, data.c.maxroll, function(model, humanoid, victimroot)
		if hit then
			return true
		end
		hit = { model = model, humanoid = humanoid, root = victimroot }
		kit:hit(humanoid, data.damage.croll, victimroot)
		task.defer(function()
			if wheel and wheel.token == token then
				stopwheel()
				clothesline(player, character, root, hit)
			end
		end)
		return true
	end)
	hold.ctoken = token
end

local function fusillade(player, character, root)
	local v = data.v
	local center = root.CFrame * CFrame.new(0, 2, 2)
	local holding = kit.effectholding
	kit:play("Dough.V", {
		CFrame = center,
		Mouse = kit.mousepos,
		Holding = holding,
		ZoneRadius = v.zone,
		Lengths = v.lengths,
		Scales = v.scales,
		Width = v.width,
		WidthMultiplier = 1,
		MinDuration = v.mintime,
		MaxDuration = v.maxtime,
		StartLag = v.startlag,
		Timestamp = servertime(),
		Delay = 0,
		DragSpeed = v.drag,
		Buso = buso(character, player),
	})
	task.spawn(function()
		local function zonepoint(mouse)
			local offset = mouse - center.Position
			local distance = math.min(offset.Magnitude, v.zone)
			return center.Position + (offset.Magnitude > 0 and offset.Unit or Vector3.zero) * distance
		end
		local point = zonepoint(kit.mousepos.Value)
		local started = os.clock()
		local released = false
		task.wait(v.startlag)
		while root.Parent do
			local elapsed = os.clock() - started
			if not holding.Value then
				released = true
			end
			if (released and elapsed > v.mintime) or elapsed > v.maxtime then
				break
			end
			local mouse = kit.mousepos.Value
			local toward = mouse - point
			point += (toward.Magnitude > 0 and toward.Unit or Vector3.zero) * v.drag * v.tick * 1.5
			if (point - center.Position).Magnitude > v.zone then
				point = center.Position + (point - center.Position).Unit * v.zone
			end
			local spot = point
			enemiesnear(character, spot, v.radius, function(model, humanoid, victimroot)
				kit:hit(humanoid, data.damage.v, victimroot)
				stun(model, 0.5)
				if isnpc(model) and not victimroot.Anchored then
					victimroot.CFrame = victimroot.CFrame:Lerp(CFrame.new(spot) * victimroot.CFrame.Rotation, 0.5)
					victimroot.AssemblyLinearVelocity = Vector3.zero
				end
			end)
			task.wait(v.tick)
		end
	end)
end

local function onholdstart(player, character, root, key)
	hold = { key = key, started = os.clock(), player = player }
	if key == "C" then
		clothesroll(player, character, root)
	elseif key == "V" then
		kit.busyuntil = os.clock() + data.v.mintime
		fusillade(player, character, root)
	end
end

local function onrelease(player, character, root, key, aim)
	local token = hold
	hold = nil
	if not token or token.key ~= key then
		return
	end
	local held = os.clock() - token.started
	if key == "Z" then
		missile(player, character, root, aim, held)
	elseif key == "X" then
		if grounded(character) then
			pastryground(player, character, root, aim, held)
		else
			pastryair(player, character, root, aim, held)
		end
	elseif key == "C" then
		if wheel and token.ctoken and wheel.token == token.ctoken then
			stopwheel()
			clothesline(player, character, root, nil)
		end
	end
end

local function onkey(player, character, root, humanoid, key)
	if key ~= "F" then
		return
	end
	if wheel and not grab then
		stopwheel()
		kit.lastused.F = os.clock()
		return
	end
	if not kit:canuse(character, "F") or not spend(character, data.Cost.F) then
		return
	end
	kit.lastused.F = os.clock()
	startwheel(player, character, root, data.f.maxspeed, data.f.duration)
end

kit = fruitkit.new(tool, {
	holdkeys = { Z = true, X = true, C = true, V = true },
	maxhold = data.v.maxtime,
	canhold = function(player, character, root, key)
		if wheel then
			return false
		end
		return spend(character, data.Cost[key])
	end,
	onholdstart = onholdstart,
	onrelease = onrelease,
	onm1 = function(player, character, root)
		if wheel then
			return
		end
		onm1(player, character, root)
	end,
	onkey = onkey,
	onunequip = function()
		hold = nil
		stopwheel()
	end,
	onpassiveend = function(character)
		stopwheel(true)
		if character then
			setcstage(character, nil)
		end
	end,
})
