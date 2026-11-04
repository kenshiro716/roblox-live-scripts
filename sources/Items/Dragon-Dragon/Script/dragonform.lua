local players = game:GetService("Players")
local replicatedstorage = game:GetService("ReplicatedStorage")
local serverstorage = game:GetService("ServerStorage")
local runservice = game:GetService("RunService")

local util = require(replicatedstorage:WaitForChild("Util"))
local masterclock = util.MasterClock

local dragonform = {}

local kit, data, tool, h
local getform, setform, getformbefore
local state = nil
local hold = nil
local breath = nil
local fuel = 1
local relayready = false
local trailing = nil

local rigs = serverstorage:WaitForChild("Rigs")

local function now()
	return workspace:GetServerTimeNow()
end

local function value(parent, class, name, initial)
	local existing = parent:FindFirstChild(name)
	if existing and existing.ClassName == class then
		if initial ~= nil then
			existing.Value = initial
		end
		return existing
	end
	if existing then
		existing:Destroy()
	end
	local v = Instance.new(class)
	v.Name = name
	if initial ~= nil then
		v.Value = initial
	end
	v.Parent = parent
	return v
end

local function buildstate()
	local folder = tool:FindFirstChild("EasternState")
	if folder then
		folder:Destroy()
	end
	folder = Instance.new("Folder")
	folder.Name = "EasternState"

	local x = value(folder, "BoolValue", "XSpiralActive", false)
	value(x, "NumberValue", "TIME_SPIRALLING", 1.6)
	value(x, "NumberValue", "TIME_UNTIL_IMPACT", 0.45)
	value(x, "Vector3Value", "Origin", Vector3.zero)
	value(x, "Vector3Value", "ImpactPosition", Vector3.zero)

	local v = value(folder, "BoolValue", "VActive", false)
	value(v, "NumberValue", "V_ANIMATION_LASTS_FOR", 2.2)
	value(v, "CFrameValue", "Origin", CFrame.new())
	value(v, "CFrameValue", "Impact", CFrame.new())
	value(v, "CFrameValue", "RootOrigin", CFrame.new())

	local c = value(folder, "BoolValue", "CActive", false)
	value(c, "NumberValue", "C_ANIMATION_LASTS_FOR", 3)
	value(c, "CFrameValue", "InitCF", CFrame.new())

	local f = value(folder, "BoolValue", "FDrillActive", false)
	value(f, "NumberValue", "FLIGHT_SPEED", 230)
	value(f, "NumberValue", "DOWNWARD_FLIGHT_SPEED", 320)
	value(f, "NumberValue", "DOWNWARD_ANGLE_MAX_OFFSET", 35)
	value(f, "Vector3Value", "CollisionPosition", Vector3.zero)

	local fe = value(folder, "BoolValue", "FMidAirEndActive", false)
	value(fe, "NumberValue", "F_MID_AIR_END_ANIMATION_LASTS_FOR", 0.8)
	value(fe, "CFrameValue", "MidAirEndInitCF", CFrame.new())

	local z = value(folder, "BoolValue", "ZActive", false)
	value(z, "BoolValue", "DespawnHalo", false)
	value(z, "BoolValue", "Shot", false)
	value(z, "BoolValue", "FullyEnded", true)
	value(z, "BoolValue", "ZActiveClient", false)

	value(folder, "BoolValue", "HeadAimModeActive", false)
	value(folder, "BoolValue", "HeadAimModeDisabling", false)
	value(folder, "ObjectValue", "ZRecoilAnim")
	value(folder, "ObjectValue", "MouthOpeningAnim")
	value(folder, "ObjectValue", "MouthOpenedLoopAnim")
	value(folder, "ObjectValue", "MouthClosingAnim")
	value(folder, "NumberValue", "AccumulatedInputTime", 0)

	folder.Parent = tool
	return folder
end

local function headaim()
	local aim = tool:FindFirstChild("HeadAim")
	if aim then
		value(aim, "NumberValue", "LastHeadAimUpdate")
		value(aim, "Vector3Value", "HeadAimClient")
	end
	return aim
end

local function ground(character, position, depth)
	local hitpos, normal, instance = h.worldhit(character, position + Vector3.new(0, 30, 0), position - Vector3.new(0, depth or 600, 0))
	return hitpos, normal, instance
end

local function setbusy(character, busy)
	local value = character:FindFirstChild("Busy")
	if value and value:IsA("BoolValue") then
		value.Value = busy
	end
end

local function hidebody(character, hidden)
	if hidden then
		state.hidden = {}
		for _, d in ipairs(character:GetDescendants()) do
			local ofdragon = (state.rig and d:IsDescendantOf(state.rig)) or (state.model and d:IsDescendantOf(state.model)) or (state.mover and d:IsDescendantOf(state.mover))
			if not ofdragon and (d:IsA("BasePart") or d:IsA("Decal")) and d.Transparency < 1 and d.Name ~= "HumanoidRootPart" then
				state.hidden[d] = d.Transparency
				d.Transparency = 1
			end
		end
	else
		for d, t in pairs(state.hidden or {}) do
			if d.Parent then
				d.Transparency = t
			end
		end
		state.hidden = {}
	end
end

local function connectrelay()
	if relayready then
		return
	end
	relayready = true
	local function owner(player)
		return state and state.player == player
	end
	local function others(player, remote, ...)
		for _, other in ipairs(players:GetPlayers()) do
			if other ~= player then
				remote:FireClient(other, ...)
			end
		end
	end
	local cframevalue = tool:WaitForChild("DragonCFrameWithoutOffset")
	tool:WaitForChild("DragonCFrameRemote").OnServerEvent:Connect(function(player, cf)
		if not owner(player) or typeof(cf) ~= "CFrame" then
			return
		end
		cframevalue.Value = cf
		others(player, tool.DragonCFrameRemote, cf)
	end)
	tool:WaitForChild("DragonTrailingPositionsRemote").OnServerEvent:Connect(function(player, first, buffered)
		if not owner(player) or typeof(first) ~= "Vector3" or typeof(buffered) ~= "buffer" then
			return
		end
		trailing = { first, buffered }
		others(player, tool.DragonTrailingPositionsRemote, first, buffered)
	end)
	tool:WaitForChild("DragonSetupRemote").OnServerEvent:Connect(function(player, setup)
		if setup ~= true or not state or state.kind ~= "East" then
			return
		end
		local first = trailing and trailing[1] or (state.mover and state.mover.Handle.Position) or Vector3.zero
		local buffered = trailing and trailing[2] or buffer.create(29 * 6)
		tool.DragonTrailingPositionsRemote:FireClient(player, first, buffered)
	end)
	tool:WaitForChild("DragonIdleRemote").OnServerEvent:Connect(function(player, idle)
		if owner(player) and type(idle) == "boolean" then
			tool.IsIdle.Value = idle
		end
	end)
	tool:WaitForChild("DragonHaloCurrentSpeed").OnServerEvent:Connect(function(player, speed)
		if owner(player) and type(speed) == "number" then
			tool.HaloCurrentSpeed.Value = speed
		end
	end)
	tool:WaitForChild("DragonHeadAimRemote").OnServerEvent:Connect(function(player, direction)
		if typeof(direction) ~= "Vector3" or player ~= kit:getowner() then
			return
		end
		local aim = headaim()
		if aim then
			aim.Value = direction
			aim.LastHeadAimUpdate.Value = now()
		end
	end)
	tool:WaitForChild("AccumulatedInputTimeRemote").OnServerEvent:Connect(function(player, amount)
		if owner(player) and type(amount) == "number" and state.script then
			state.script.AccumulatedInputTime.Value = amount
		end
	end)
	tool:WaitForChild("DragonCollisionVFXRemote").OnServerEvent:Connect(function(player, cf)
		if owner(player) and typeof(cf) == "CFrame" then
			kit:play("Dragon2.TransformedEastern.WallCollision", { player = player, cf = cf })
		end
	end)
	local camera = tool:FindFirstChild("CameraCFrameRemote")
	if camera then
		camera.OnServerEvent:Connect(function(player, cf)
			if owner(player) and typeof(cf) == "CFrame" then
				tool.CameraCFrame.Value = cf
			end
		end)
	end
	pcall(function()
		require(replicatedstorage.EffectContainer.Dragon2.Controllers.DragonFlight)
	end)
	pcall(function()
		require(replicatedstorage:WaitForChild("DragonAim"))
	end)
end

local function headpart()
	if not state then
		return nil
	end
	if state.kind == "West" then
		return state.rig and (state.rig:FindFirstChild("HeadProxy") or state.rig.RootPart)
	end
	return state.model and (state.model:FindFirstChild("HeadProxy") or state.model.RootPart)
end

local function dragonmodel()
	if state and state.kind == "East" then
		return state.model
	end
	return nil
end

local function aimdirection(root)
	local aim = tool:FindFirstChild("HeadAim")
	if aim and aim:FindFirstChild("LastHeadAimUpdate") and now() - aim.LastHeadAimUpdate.Value < 1 and aim.Value.Magnitude > 0.1 then
		return aim.Value.Unit
	end
	local origin = (headpart() or root).Position
	local target = kit.mousepos.Value
	if (target - origin).Magnitude < 1 then
		return root.CFrame.LookVector
	end
	return (target - origin).Unit
end

local function cone(character, origin, direction, range, width, amount)
	local hits = {}
	kit:eachtarget(character, function(model, humanoid, root)
		if not h.enemyof(character, model) then
			return
		end
		local offset = root.Position - origin
		local t = offset:Dot(direction)
		if t < 0 or t > range then
			return
		end
		local spread = width * (0.35 + 0.65 * t / range)
		if (origin + direction * t - root.Position).Magnitude <= spread then
			if kit:hit(humanoid, amount, root) then
				table.insert(hits, model)
			end
		end
	end)
	return hits
end

local function buildwest(player, character, root, humanoid)
	local holder = Instance.new("Model")
	holder.Name = "WesternDragonRig"
	local rig = rigs.WesternDragon:Clone()
	rig.Name = "Rig"
	for _, d in ipairs(rig:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.Massless = true
		end
	end
	rig.Parent = holder
	rig:PivotTo(root.CFrame)
	local weld = Instance.new("Weld")
	weld.Name = "DragonWeld"
	weld.Part0 = root
	weld.Part1 = rig.RootPart
	weld.Parent = rig.RootPart
	rig:SetAttribute("Loaded", true)
	holder.Parent = character
	state.rig = rig
	state.holder = holder
	state.hipheight = humanoid.HipHeight
	state.walkspeed = humanoid.WalkSpeed
	state.jumppower = humanoid.JumpPower
	humanoid.HipHeight = 42.5 - root.Size.Y / 2
	humanoid.WalkSpeed = 40
	tool.TransformedRigObject.Value = rig
end

local function buildeast(player, character, root, humanoid)
	state.script = buildstate()
	local mover = rigs.DragonMover:Clone()
	mover.Name = "DragonMover"
	local goal = Instance.new("Attachment")
	goal.Name = "DragonGoal" .. player.UserId
	goal.WorldCFrame = root.CFrame
	goal.Parent = workspace.Terrain
	local handle = mover.Handle
	handle.AlignPosition.Attachment1 = goal
	handle.AlignOrientation.Attachment1 = goal
	handle.GoalAttach.Value = goal
	humanoid:AddAccessory(mover)
	local headbox = Instance.new("Part")
	headbox.Name = "DragonDamageHeadPart"
	headbox.Size = Vector3.new(18, 18, 18)
	headbox.Transparency = 1
	headbox.CanCollide = false
	headbox.CanTouch = false
	headbox.CanQuery = true
	headbox.Massless = true
	headbox.CFrame = handle.CFrame
	local headweld = Instance.new("WeldConstraint")
	headweld.Part0 = handle
	headweld.Part1 = headbox
	headweld.Parent = headbox
	headbox.Parent = character
	state.headbox = headbox
	local model = rigs.EasternBloxfruitsDragon:Clone()
	model.Name = "EasternBloxfruitsDragon"
	model:PivotTo(root.CFrame)
	model.Parent = character
	state.mover = mover
	state.goal = goal
	state.model = model
	state.walkspeed = humanoid.WalkSpeed
	trailing = nil
	tool.TransformedRigObject.Value = model
	tool.IsIdle.Value = true
	tool.DragonCFrameWithoutOffset.Value = root.CFrame
	return handle
end

function dragonform.transform(player, character, root, humanoid, kind)
	if state or not humanoid or humanoid.Health <= 0 then
		return false
	end
	connectrelay()
	state = { kind = kind, player = player, character = character, root = root, humanoid = humanoid, hidden = {} }
	setform("dragon")
	fuel = 1
	h.setcooldowns(kind)
	local marker = Instance.new("Folder")
	marker.Name = "Dragon"
	marker.Parent = character
	state.marker = marker
	tool.IsTransformed.Value = true
	kit.busyuntil = os.clock() + 1.6

	if kind == "West" then
		kit:play("Dragon2.V", { player = player, hrp = root, Character = character, SizeMultiplier = 1.5 })
		task.delay(0.25, function()
			if not state or state.player ~= player then
				return
			end
			buildwest(player, character, root, humanoid)
			hidebody(character, true)
		end)
		task.delay(0.35, function()
			h.blast(character, root.Position, 45, data.damage.transformwest, 1)
		end)
	else
		local origin = root.CFrame
		local flyup = 100
		local handle = buildeast(player, character, root, humanoid)
		local impactpos = ground(character, origin.Position + origin.LookVector * 60)
		local s = state.script
		s.VActive.Origin.Value = origin + Vector3.new(0, flyup, 0)
		s.VActive.Impact.Value = CFrame.new(impactpos)
		s.VActive.RootOrigin.Value = origin
		hidebody(character, true)
		kit:play("Dragon2.TransformedEastern.Transform", { player = player, hrp = root, flyUpBy = flyup })
		kit:play("Dragon2.TransformedEastern.ReplicateBody", {
			player = player,
			hrp = root,
			dragonPart = handle,
			collisionPart = state.mover.CylinderCollision,
			easternDragon = state.model,
			scriptInstance = s,
		})
		s.VActive.Value = true
		task.delay(s.VActive.V_ANIMATION_LASTS_FOR.Value, function()
			if not state or state.script ~= s then
				return
			end
			s.VActive.Value = false
			local fe = s.FMidAirEndActive
			fe.MidAirEndInitCF.Value = CFrame.lookAlong(impactpos + Vector3.new(0, 8, 0), Vector3.new(origin.LookVector.X, 0, origin.LookVector.Z))
			fe:SetAttribute("FromTransformation", true)
			fe.Value = true
			task.delay(fe.F_MID_AIR_END_ANIMATION_LASTS_FOR.Value, function()
				if state and state.script == s then
					fe.Value = false
					fe:SetAttribute("FromTransformation", nil)
				end
			end)
		end)
		task.spawn(function()
			for _ = 1, 5 do
				task.wait(0.3)
				if not state or state.player ~= player then
					return
				end
				local strike = impactpos + Vector3.new(math.random(-40, 40), 0, math.random(-40, 40))
				h.blast(character, strike, 16, data.damage.transformeast, 0.4)
			end
		end)
	end
	return true
end

function dragonform.untransform(silent)
	local current = state
	if not current then
		return
	end
	dragonform.m1end()
	hold = nil
	local player, character, root, humanoid = current.player, current.character, current.root, current.humanoid
	setbusy(character, false)
	character:SetAttribute("CastingFlamethrower", nil)
	character:SetAttribute("DragonFlightModifier", nil)
	if not silent and root and root.Parent then
		if current.kind == "East" then
			kit:play("Dragon2.TransformedEastern.Untransform", { player = player, hrp = root, Character = character, easternDragon = current.model })
		else
			kit:play("Dragon2.Hybrid.Untransform", { ID = 1, Root = root, player = player })
		end
	end
	tool.IsTransformed.Value = false
	tool.TransformedRigObject.Value = nil
	local delay = current.kind == "East" and not silent and 0.6 or 0
	task.delay(delay, function()
		if current.holder then
			current.holder:Destroy()
		end
		if current.mover then
			current.mover:Destroy()
		end
		if current.model then
			current.model:Destroy()
		end
		if current.goal then
			current.goal:Destroy()
		end
		if current.headbox then
			current.headbox:Destroy()
		end
		if current.script then
			current.script:Destroy()
		end
	end)
	if current.marker then
		current.marker:Destroy()
	end
	if humanoid and humanoid.Parent then
		if current.hipheight then
			humanoid.HipHeight = current.hipheight
		end
		if current.walkspeed then
			humanoid.WalkSpeed = current.walkspeed
		end
		humanoid.PlatformStand = false
	end
	if character and character.Parent then
		hidebody(character, false)
	end
	if root and root.Parent then
		root.CFrame = CFrame.new(root.Position + Vector3.new(0, 4, 0)) * root.CFrame.Rotation
	end
	state = nil
	h.setcooldowns(nil)
	local back = getformbefore()
	if back == "hybrid" and character and character.Parent and root and root.Parent then
		h.sethybrid(character, root, player, true)
	else
		setform("base")
	end
	kit.lastused.V = os.clock()
end

function dragonform.canhold(key)
	if not state or not state.character then
		return false
	end
	if key == "C" and state.kind == "West" and state.cbusy then
		return false
	end
	return h.spend(state.character, data.Cost[key])
end

local function westz(token)
	local player, character, root = token.player, token.character, token.root
	local humanoid = state.humanoid
	setbusy(character, true)
	token.zclock = os.clock()
	kit:play("Dragon2.Z", {
		player = player,
		ID = 1,
		Head = headpart(),
		HoldValue = kit.effectholding,
		Humanoid = humanoid,
		Start = masterclock:GetTime(),
		Charge = data.z.charge,
		WindUp = data.z.windup,
		Offset = CFrame.new(0, 0, -2),
		dragonModel = dragonmodel(),
	})
	if state.kind == "East" then
		state.script.ZActive.FullyEnded.Value = false
		state.script.ZActive.Shot.Value = false
		state.script.ZActive.DespawnHalo.Value = false
		state.script.ZActive.ZActiveClient.Value = true
		state.script.ZActive.Value = true
		state.script.HeadAimModeActive.Value = true
	end
end

local function westzfire(token)
	local player, character, root = token.player, token.character, token.root
	local held = math.clamp((os.clock() - (token.zclock or os.clock())) / data.z.charge, 0, 1)
	local head = headpart() or root
	local origin = head.Position
	local direction = aimdirection(root)
	local range = 450 * (1 + held)
	local hitpos, normal, instance = h.worldhit(character, origin, origin + direction * range)
	local victim = kit:firstalong(character, origin, hitpos, 12)
	local explosion = victim and victim.Position or hitpos
	local life = 0.55
	kit:play("Dragon2.Z", {
		player = player,
		ID = 2,
		Head = head,
		Character = character,
		CFrame = head.CFrame,
		ExplosionPosition = explosion,
		Offset = CFrame.new(0, 0, -2),
		Scale = 2 + held * 2,
		chargeTime = held,
		SpawnTime = masterclock:GetTime(),
		Life = life,
		Distance = range,
		RayData = { Hit = victim or instance, Norm = normal },
		SuperCharge = held >= 1 and 2 or nil,
		dragonModel = dragonmodel(),
	})
	if state.kind == "East" then
		state.script.ZActive.Shot.Value = true
	end
	h.addrage(-data.fury.dragonz * (0.5 + held))
	local amount = data.damage.dragonz + (data.damage.dragonzheld - data.damage.dragonz) * held
	local travel = (explosion - origin).Magnitude / math.max(range, 1) * life
	task.delay(travel, function()
		kit:damagealong(character, origin, explosion, 14, amount * 0.2)
		for _, model in ipairs(h.blast(character, explosion, 40 + held * 25, amount * 0.8, 0.6)) do
			local victimroot = h.rootof(model)
			if victimroot and h.isnpc(model) and not victimroot.Anchored then
				victimroot.AssemblyLinearVelocity = (victimroot.Position - explosion).Unit * 120 + Vector3.new(0, 60, 0)
			end
		end
	end)
	task.delay(0.6, function()
		if state and state.character == character then
			setbusy(character, false)
			if state.kind == "East" then
				state.script.ZActive.FullyEnded.Value = true
				state.script.ZActive.DespawnHalo.Value = true
				state.script.ZActive.ZActiveClient.Value = false
				state.script.ZActive.Value = false
				state.script.HeadAimModeActive.Value = false
			end
		end
	end)
	kit.busyuntil = os.clock() + 0.6
end

local function westx(token, aim)
	local player, character, root = token.player, token.character, token.root
	local origin = root.Position
	local target = kit:clamprange(origin, aim.target, 300)
	if (target - origin).Magnitude < 5 then
		target = origin + root.CFrame.LookVector * 200
	end
	local endpos = h.worldhit(character, origin, target)
	kit:play("Dragon2.Transformed.X", { Player = player, player = player, Root = root, EndPosition = endpos })
	h.addrage(-data.fury.dragonx)
	kit.busyuntil = os.clock() + 0.8
	local start = (CFrame.lookAt(origin, endpos) * CFrame.new(0, 25, -25)).Position
	task.spawn(function()
		task.wait(0.35)
		for i = 1, 5 do
			local from = start:Lerp(endpos, (i - 1) / 5)
			local to = start:Lerp(endpos, i / 5)
			for _, model in ipairs(h.blast(character, to, 22, data.damage.westx, 0.5)) do
				h.burn(model, 2, data.damage.xburn)
			end
			kit:damagealong(character, from, to, 16, data.damage.westx * 0.4)
			task.wait(0.07)
		end
	end)
end

local function eastx(token, aim)
	local player, character, root = token.player, token.character, token.root
	local s = state.script
	local origin = root.Position
	local target = kit:clamprange(origin, aim.target, 220)
	local impact = ground(character, target, 700)
	s.XSpiralActive.Origin.Value = origin
	s.XSpiralActive.ImpactPosition.Value = impact
	local spiral, untilimpact = s.XSpiralActive.TIME_SPIRALLING.Value, s.XSpiralActive.TIME_UNTIL_IMPACT.Value
	s.XSpiralActive.Value = true
	kit:play("Dragon2.TransformedEastern.X", {
		player = player,
		hrp = root,
		TIME_UNTIL_IMPACT = untilimpact,
		TIME_SPIRALLING = spiral,
		originCF = CFrame.new(origin),
		impactPosition = impact,
		RAYCAST_DOWN_BY = 70,
	})
	h.addrage(-data.fury.dragonx)
	kit.busyuntil = os.clock() + spiral + untilimpact + 0.3
	local caught = {}
	task.spawn(function()
		local started = os.clock()
		while os.clock() - started < spiral and state and state.script == s do
			local alpha = (os.clock() - started) / spiral
			local center = origin + Vector3.new(0, 140 * alpha, 0)
			h.enemiesnear(character, center, 90, function(model, humanoid, victimroot)
				if not caught[model] then
					caught[model] = true
					h.stun(model, spiral + untilimpact + 0.8)
				end
				kit:hit(humanoid, data.damage.eastxspin, victimroot)
			end)
			task.wait(0.2)
		end
		if state and state.script == s then
			s.XSpiralActive.Value = false
		end
		task.wait(untilimpact)
		for _, model in ipairs(h.blast(character, impact, 60, data.damage.eastxslam, 1)) do
			h.burn(model, 2, data.damage.xburn)
		end
		for model in pairs(caught) do
			local victimroot = h.rootof(model)
			if victimroot and victimroot.Parent and h.isnpc(model) then
				victimroot.CFrame = CFrame.new(impact + Vector3.new(math.random(-12, 12), 4, math.random(-12, 12)))
			end
		end
	end)
end

local function westcstart(token)
	local player, character, root = token.player, token.character, token.root
	local folder = Instance.new("Folder")
	folder.Name = "WesternCState"
	folder.Parent = tool
	token.cstate = folder
	state.cbusy = true
	kit:play("Dragon2.Transformed.C", {
		player = player,
		Root = root,
		Holding = kit.effectholding,
		State = folder,
		Duration = 1,
		GroundBurnDuration = 3,
		DownRayRange = 700,
		AoeRange = 180,
		ExplosionDelay = 0.3,
		Seed = math.random(1, 1000000),
		ProjectileCount = 24,
	})
	h.addrage(-data.fury.dragonc * 0.5)
end

local function westcfire(token, aim)
	local player, character, root = token.player, token.character, token.root
	local folder = token.cstate
	local target = kit:clamprange(root.Position, aim.target, 350)
	local landing = ground(character, target, 700)
	local skypoint = landing + Vector3.new(0, 150, 0)
	if folder then
		folder:SetAttribute("EndPosition", skypoint)
	end
	h.addrage(-data.fury.dragonc * 0.5)
	kit.busyuntil = os.clock() + 1
	task.spawn(function()
		task.wait(1.2)
		local stop = os.clock() + 3
		while os.clock() < stop do
			local strike = landing + Vector3.new(math.random(-140, 140), 0, math.random(-140, 140))
			h.blast(character, strike, 30, data.damage.westcmeteor)
			h.blast(character, landing, 180, data.damage.westcmeteor * 0.25)
			task.wait(0.25)
		end
		h.blast(character, landing, 70, data.damage.westcfinal, 1)
		if folder then
			folder:Destroy()
		end
		if state then
			state.cbusy = false
		end
	end)
end

local function eastcstart(token)
	local player, character, root = token.player, token.character, token.root
	local s = state.script
	local duration = 4
	s.CActive.C_ANIMATION_LASTS_FOR.Value = duration
	s.CActive.InitCF.Value = tool.DragonCFrameWithoutOffset.Value
	s.CActive.Value = true
	kit:play("Dragon2.TransformedEastern.C", {
		player = player,
		Character = character,
		Duration = duration,
		dragonModel = state.model,
		Holding = kit.effectholding,
		DownRayRange = 500,
		AoeRange = 110,
	})
	h.addrage(-data.fury.dragonc)
	token.cstarted = os.clock()
	task.spawn(function()
		local started = os.clock()
		while state and state.script == s and os.clock() - started < duration and (os.clock() - started < 1 or kit.effectholding.Value) do
			local center = tool.DragonCFrameWithoutOffset.Value.Position
			h.blast(character, center, 110, data.damage.eastcstorm)
			task.wait(0.3)
		end
		if state and state.script == s then
			local center = tool.DragonCFrameWithoutOffset.Value.Position
			h.blast(character, center, 90, data.damage.eastcfinal, 1)
			s.CActive.Value = false
		end
	end)
end

local function westfstart(token)
	local player, character, root = token.player, token.character, token.root
	local proxy = Instance.new("NumberValue")
	proxy.Name = "WesternFProxy"
	proxy.Value = 0
	proxy.Parent = tool
	token.proxy = proxy
	token.grabbed = false
	local timestamp = now()
	setbusy(character, true)
	character:SetAttribute("DragonFlightModifier", 2.6)
	kit:play("Dragon2.Transformed.F", {
		player = player,
		Root = root,
		Stage = 1,
		Position = kit.mousepos.Value,
		Proxy = proxy,
		Timestamp = timestamp,
	})
	h.addrage(-data.fury.dragonf)
	task.spawn(function()
		local started = os.clock()
		while hold == token and os.clock() - started < 2 and not token.grabbed and root.Parent do
			local front = root.Position + root.CFrame.LookVector * 30
			local found
			h.enemiesnear(character, front, 26, function(model, humanoid, victimroot)
				if not found then
					found = { model, humanoid, victimroot }
				end
			end)
			if found then
				token.grabbed = true
				dragonform.westfgrab(token, found[1], found[2], found[3])
				return
			end
			task.wait(0.05)
		end
	end)
end

function dragonform.westfgrab(token, model, humanoid, victimroot)
	local player, character, root = token.player, token.character, token.root
	if token.proxy then
		token.proxy.Value = 2
	end
	h.stun(model, 2.5)
	kit:hit(humanoid, data.damage.westf, victimroot)
	kit:play("Dragon2.Transformed.F", { player = player, Root = root, Stage = 2, Timestamp = now() })
	task.delay(0.45, function()
		local landing, normal = ground(character, victimroot.Position, 400)
		local duration = 0.6
		kit:play("Dragon2.Transformed.F", {
			player = player,
			Root = root,
			Stage = 3,
			Position = landing,
			Normal = normal,
			Height = state and state.humanoid and (state.humanoid.HipHeight + root.Size.Y / 2) or 40,
			Duration = duration,
			Timestamp = now(),
		})
		local start = victimroot.Position
		h.drivenpc(victimroot, duration, function(alpha)
			return CFrame.new(start:Lerp(landing + Vector3.new(0, 3, 0), alpha))
		end)
		task.wait(duration)
		h.blast(character, landing, 45, data.damage.westfslam, 1)
		dragonform.westfend(token)
	end)
end

function dragonform.westfend(token)
	if token.ended then
		return
	end
	token.ended = true
	if token.proxy then
		token.proxy.Value = 2
		local proxy = token.proxy
		task.delay(1, function()
			proxy:Destroy()
		end)
	end
	if state and state.character then
		setbusy(state.character, false)
		state.character:SetAttribute("DragonFlightModifier", nil)
	end
end

local function eastfstart(token)
	local player, character, root = token.player, token.character, token.root
	local s = state.script
	s.FDrillActive.Value = true
	s.FDrillActive:SetAttribute("Ending", nil)
	kit:play("Dragon2.TransformedEastern.F", {
		player = player,
		hrp = root,
		dragonCF = tool.DragonCFrameWithoutOffset,
		FActive = s.FDrillActive,
		DOWNWARD_ANGLE_MAX_OFFSET = s.FDrillActive.DOWNWARD_ANGLE_MAX_OFFSET.Value,
	})
	h.addrage(-data.fury.dragonf)
	token.fstarted = os.clock()
	task.spawn(function()
		local hit = {}
		while hold == token and state and state.script == s and s.FDrillActive.Value and os.clock() - token.fstarted < 4 do
			local cf = tool.DragonCFrameWithoutOffset.Value
			local result = workspace:Raycast(cf.Position, cf.LookVector * 40, (function()
				local params = RaycastParams.new()
				params.FilterType = Enum.RaycastFilterType.Exclude
				params.FilterDescendantsInstances = { character, workspace:FindFirstChild("_WorldOrigin"), workspace:FindFirstChild("Characters"), workspace:FindFirstChild("Enemies") }
				return params
			end)())
			h.enemiesnear(character, cf.Position, 30, function(model, humanoid, victimroot)
				if not hit[model] or os.clock() - hit[model] > 0.4 then
					hit[model] = os.clock()
					kit:hit(humanoid, data.damage.eastf * 0.35, victimroot)
				end
			end)
			if result and os.clock() - token.fstarted > 0.25 then
				token.fcollided = true
				s.FDrillActive.CollisionPosition.Value = result.Position + result.Normal
				s.FDrillActive:SetAttribute("Ending", now())
				s.FDrillActive.Value = false
				kit:play("Dragon2.TransformedEastern.FImpact", {
					collision = true,
					player = player,
					hrp = root,
					dragonCF = tool.DragonCFrameWithoutOffset,
					rayPosition = result.Position,
					rayNormal = result.Normal,
					rayInstance = result.Instance,
					rayMaterial = result.Material,
				})
				h.blast(character, result.Position, 50, data.damage.eastfcrash, 1)
				return
			end
			task.wait(0.05)
		end
	end)
end

local function eastfend(token)
	if not state or state.kind ~= "East" then
		return
	end
	local s = state.script
	if token.fcollided or not s.FDrillActive.Value then
		return
	end
	s.FMidAirEndActive.MidAirEndInitCF.Value = tool.DragonCFrameWithoutOffset.Value
	s.FMidAirEndActive:SetAttribute("FromTransformation", nil)
	s.FDrillActive.Value = false
	s.FMidAirEndActive.Value = true
	local center = tool.DragonCFrameWithoutOffset.Value.Position
	task.delay(0.2, function()
		h.blast(state and state.character or token.character, center, 45, data.damage.eastf, 1)
	end)
	task.delay(s.FMidAirEndActive.F_MID_AIR_END_ANIMATION_LASTS_FOR.Value, function()
		if state and state.script == s then
			s.FMidAirEndActive.Value = false
		end
	end)
end

function dragonform.holdstart(player, character, root, key)
	if not state then
		return
	end
	local token = { key = key, player = player, character = character, root = root }
	hold = token
	if key == "Z" then
		westz(token)
	elseif key == "C" then
		if state.kind == "West" then
			westcstart(token)
		else
			eastcstart(token)
		end
	elseif key == "F" then
		if state.kind == "West" then
			westfstart(token)
		else
			eastfstart(token)
		end
	end
	local limits = { Z = data.z.maxhold, X = 2, C = state.kind == "West" and 3 or 4, F = state.kind == "West" and 2 or 4 }
	task.delay(limits[key] or 3, function()
		if hold == token and kit.active and kit.active.key == key then
			kit:release(player, character, root, key)
		end
	end)
end

function dragonform.release(player, character, root, key, aim)
	local token = hold
	hold = nil
	if not state or not token or token.key ~= key then
		return
	end
	if key == "Z" then
		westzfire(token)
	elseif key == "X" then
		if state.kind == "West" then
			westx(token, aim)
		else
			eastx(token, aim)
		end
	elseif key == "C" then
		if state.kind == "West" then
			westcfire(token, aim)
		else
			kit.busyuntil = os.clock() + 0.3
		end
	elseif key == "F" then
		if state.kind == "West" then
			if not token.grabbed then
				dragonform.westfend(token)
			end
		else
			eastfend(token)
		end
	end
end

local breathvalue = nil

function dragonform.m1(player, character, root)
	if not state or breath then
		return
	end
	if fuel < 0.1 then
		return
	end
	if not breathvalue or not breathvalue.Parent then
		breathvalue = Instance.new("BoolValue")
		breathvalue.Name = "BreathHolding"
		breathvalue.Parent = tool
	end
	breathvalue.Value = true
	local current = { started = os.clock(), startfuel = fuel }
	breath = current
	character:SetAttribute("CastingFlamethrower", true)
	if state.kind == "East" then
		state.script.HeadAimModeActive.Value = true
	end
	local head = headpart() or root
	kit:play("Dragon2.Transformed.M1", {
		position = head.Position,
		MaxDistance = 100,
		Character = character,
		player = player,
		dragonModel = dragonmodel(),
		Head = head,
		Mouse = kit.mousepos,
		headAim = headaim(),
		FadeIn = 0.25,
		Lifetime = 2 * fuel,
		FadeOut = 1.5,
		percentageofMax = fuel,
		realMaxDistance = 100,
		Holding = breathvalue,
	})
	task.spawn(function()
		while breath == current and state and root.Parent do
			local elapsed = os.clock() - current.started
			fuel = math.max(0, current.startfuel - elapsed / 2)
			local strength = fuel > 0 and 1 or math.max(0.2, 1 - (elapsed - current.startfuel * 2) / 1.5)
			local origin = (headpart() or root).Position
			local direction = aimdirection(root)
			local hits = cone(character, origin, direction, 100 * strength, 14, data.damage.breath)
			if #hits == 0 then
				h.addrage(-data.fury.breathpersecond * 0.15)
			end
			if strength <= 0.2 and elapsed > 4 then
				break
			end
			task.wait(0.15)
		end
		if breath == current then
			dragonform.m1end()
		end
	end)
end

function dragonform.m1end()
	if not breath then
		return
	end
	breath = nil
	if breathvalue then
		breathvalue.Value = false
	end
	if state then
		if state.character then
			state.character:SetAttribute("CastingFlamethrower", nil)
		end
		if state.kind == "East" and state.script then
			state.script.HeadAimModeActive.Value = false
		end
	end
end

function dragonform.init(context)
	kit = context.kit
	data = context.data
	tool = context.tool
	h = context.helpers
	getform = context.getform
	setform = context.setform
	getformbefore = context.getformbefore
	headaim()
	task.spawn(function()
		while true do
			task.wait(0.25)
			if not breath and fuel < 1 then
				fuel = math.min(1, fuel + 0.25 * 0.25)
			end
			if state and state.humanoid and state.humanoid.Health <= 0 then
				dragonform.untransform(true)
			end
		end
	end)
end

return dragonform
