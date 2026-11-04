local players = game:GetService("Players")
local serverstorage = game:GetService("ServerStorage")
local runservice = game:GetService("RunService")
local debris = game:GetService("Debris")

local fruitkit = require(serverstorage:WaitForChild("fruitkit"))
local rigfit = require(serverstorage:WaitForChild("rigfit"))

local tool = script.Parent
local data = require(tool:WaitForChild("Data"))
local istransformed = tool:WaitForChild("IsTransformed")
local transformedrig = tool:WaitForChild("TransformedRigObject")
local numtails = tool:WaitForChild("NumTails")
local beamcharge = tool:WaitForChild("RED_BEAM_MAX_CHARGE_TIME")
local beamduration = tool:WaitForChild("MAX_Z_BEAM_DURATION")
local armtime = tool:WaitForChild("ARM_EXTEND_TIME")
local armradius = tool:WaitForChild("UNTRANSFORMED_ARM_MAX_EXTEND_RADIUS")
local armradiusfox = tool:WaitForChild("TRANSFORMED_ARM_MAX_EXTEND_RADIUS")
local rigtemplate = serverstorage:WaitForChild("Rigs"):WaitForChild("Empyrean"):WaitForChild("Kitsune")
local cutscenemodel = serverstorage:WaitForChild("FX"):WaitForChild("RedKitsune"):WaitForChild("Cutscene"):WaitForChild("UltimateModel")

local kit
local combo, lastm1 = 0, 0
local tails = 0
local holdstarted = {}
local transform = { accessory = nil, rig = nil, token = nil, hidden = {}, walkspeed = nil, unfit = nil }

local function tailids(count)
	local ids = {}
	for i = 1, count do
		table.insert(ids, i)
	end
	return ids
end

local function settails(count)
	local character = kit:getcharacter() or kit.passivecharacter
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not character:FindFirstChild("LowerTorso") then
		return
	end
	tails = count
	numtails.Value = count
	kit:play("Kitsune.Tail", { Root = root, Ids = tailids(count), Tool = tool })
end

local function tailsfor(amount)
	if amount >= 200 / 3 then
		return 3
	elseif amount >= 100 / 3 then
		return 2
	end
	return 1
end

local function setrage(amount)
	local rage = kit:ragevalue()
	if not rage then
		return
	end
	rage.Value = math.clamp(amount, 0, 100)
	if not istransformed.Value then
		local count = tailsfor(rage.Value)
		if count ~= tails then
			settails(count)
		end
	end
end

local function addrage(amount)
	local rage = kit:ragevalue()
	if rage then
		setrage(rage.Value + amount)
	end
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

local function isnpc(model)
	return players:GetPlayerFromCharacter(model) == nil
end

local function setbodyhidden(character, hidden)
	if hidden then
		for _, d in ipairs(character:GetDescendants()) do
			local partoffox = transform.accessory and d:IsDescendantOf(transform.accessory)
			if not partoffox and (d:IsA("BasePart") or d:IsA("Decal")) and d.Transparency < 1 then
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

local function buildrig()
	local accessory = rigtemplate:Clone()
	for _, d in ipairs(accessory:GetDescendants()) do
		if d:IsA("BasePart") and (d.Name:sub(1, 4) == "Seat" or d.Name:sub(1, 9) == "ProxyPart") then
			d:Destroy()
		end
	end
	for _, d in ipairs(accessory:GetDescendants()) do
		if d:IsA("Script") or d:IsA("TouchTransmitter") or d.Name == "OriginalSize" then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = false
			d.Massless = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
		end
	end
	return accessory, accessory:WaitForChild("Kitsune")
end

local function endtransform(player, skipeffect)
	local accessory = transform.accessory
	transform.token = nil
	if not accessory then
		return
	end

	local character = accessory.Parent
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	transformedrig.Value = nil
	istransformed.Value = false
	if transform.unfit then
		transform.unfit()
		transform.unfit = nil
	end
	if character then
		setbodyhidden(character, false)
	end
	if humanoid and transform.walkspeed then
		humanoid.WalkSpeed = transform.walkspeed
	end
	transform.walkspeed = nil
	accessory:Destroy()
	transform.accessory, transform.rig = nil, nil

	kit.lastused.V = os.clock()
	kit.busyuntil = os.clock() + 0.8

	if not skipeffect and root then
		kit:play("Kitsune.Untransform", { Root = root })
	end
	tails = 0
	setrage(0)
end

local function starttransform(player, character, root, humanoid)
	if transform.accessory or not kit:canuse(character, "V") then
		return
	end
	local rage = kit:ragevalue(character)
	if not rage or rage.Value < 100 then
		return
	end
	kit.busyuntil = os.clock() + 1

	kit:play("Kitsune.V", { Player = player, Root = root, Toggle = true, Tool = tool })
	kit:play("Kitsune.Tail", { Root = root, Ids = {}, Tool = tool })

	local accessory, rig = buildrig()
	local handle = accessory:FindFirstChild("Handle")
	local attachment = handle and handle:FindFirstChild("RootRigAttachment")
	if attachment then
		local bounds, size = rig:GetBoundingBox()
		local bottomoffset = (bounds.Position - rig:GetPivot().Position).Y - size.Y / 2
		local current = attachment.Position
		attachment.Position = Vector3.new(current.X, humanoid.HipHeight + root.Size.Y / 2 + bottomoffset, current.Z)
	end
	humanoid:AddAccessory(accessory)
	transform.accessory, transform.rig = accessory, rig
	transformedrig.Value = rig
	transform.unfit = rigfit.fit(character, humanoid, root, rig)
	istransformed.Value = true
	setbodyhidden(character, true)
	transform.walkspeed = humanoid.WalkSpeed
	humanoid.WalkSpeed = humanoid.WalkSpeed * 1.35

	kit:play("Kitsune.RedEmbers", { Root = root, Holding = kit.effectholding, Special = true, Tool = tool })
	task.delay(0.15, function()
		kit:damageradius(character, root.Position, 30, data.damage.v)
	end)

	local token = {}
	transform.token = token
	task.delay(data.transformduration or 40, function()
		if transform.token == token then
			endtransform(player)
		end
	end)
end

local function firebeam(player, character, root, aim)
	local fox = istransformed.Value
	local chargealpha = math.clamp((os.clock() - (holdstarted.Z or os.clock())) / beamcharge.Value, 0, 1)
	local full = chargealpha >= 1
	local duration = full and beamduration.Value or 0.2
	local distance = fox and 260 or 200
	local aimcframe = CFrame.lookAt(root.Position, aim.target)
	if (aim.target - root.Position).Magnitude < 1 then
		aimcframe = aim.facing
	end

	kit:play("Kitsune.RedBeam", {
		player = player,
		State = "Fire",
		Character = character,
		CF = aimcframe,
		Mouse = kit.mousepos,
		chargeAlpha = chargealpha,
		distance = distance,
		Tool = tool,
		transformed = fox,
		duration = duration,
	})
	kit.busyuntil = os.clock() + duration + 0.4

	task.spawn(function()
		task.wait(0.2)
		local ends = os.clock() + duration
		local hits = {}
		local finish = root.Position
		repeat
			local from = root.Position
			local direction = full and (kit.mousepos.Value - from) or aimcframe.LookVector
			if direction.Magnitude < 0.01 then
				direction = root.CFrame.LookVector
			end
			direction = direction.Unit
			if fox then
				from = (CFrame.lookAt(from, from + direction) * CFrame.new(0, 5, -15)).Position
			end
			finish = worldend(character, from, direction, distance)
			local length = (finish - from).Magnitude
			kit:eachtarget(character, function(_, humanoid, victimroot)
				local t = math.clamp((victimroot.Position - from):Dot(direction), 0, length)
				if (from + direction * t - victimroot.Position).Magnitude <= (fox and 12 or 8) and os.clock() - (hits[humanoid] or 0) >= 0.25 then
					hits[humanoid] = os.clock()
					kit:hit(humanoid, full and data.damage.zbeam or data.damage.ztap, victimroot)
				end
			end)
			task.wait(0.1)
		until os.clock() >= ends or not root.Parent
		kit:damageradius(character, finish, 16, data.damage.zexplode)
	end)
end

local function tailsgrab(player, character, root)
	local fox = istransformed.Value
	local radius = fox and armradiusfox.Value or armradius.Value
	local victims, list = {}, {}
	kit:eachtarget(character, function(model, humanoid, victimroot)
		if kit:canhit(model) and (victimroot.Position - root.Position).Magnitude <= radius + 10 then
			table.insert(victims, { model = model, humanoid = humanoid, root = victimroot })
			table.insert(list, { root = victimroot, inRange = true })
		end
	end)

	kit:play("Kitsune.RedM1Arm", {
		player = player,
		hrp = root,
		Tool = tool,
		armMaxExtendRadius = radius,
		armExtendTime = armtime.Value,
		victimHrpsBindableOrTable = list,
	})
	kit.busyuntil = os.clock() + armtime.Value * 2 + 0.2

	task.delay(armtime.Value, function()
		for _, victim in ipairs(victims) do
			if victim.root.Parent then
				kit:hit(victim.humanoid, data.damage.x, victim.root)
				if isnpc(victim.model) and not victim.root.Anchored then
					local offset = victim.root.Position - root.Position
					local flat = Vector3.new(offset.X, 0, offset.Z)
					local pull = flat.Magnitude > 0.1 and flat.Unit or root.CFrame.LookVector
					victim.root.CFrame = CFrame.new(root.Position + pull * (fox and 16 or 7)) * victim.root.CFrame.Rotation
				end
			end
		end
	end)
end

local function firecannon(player, character, root, aim)
	local origin = root.Position + aim.forward * 4 + Vector3.new(0, 1, 0)
	local direction = aim.target - origin
	if direction.Magnitude < 1 then
		direction = aim.forward
	end
	direction = direction.Unit
	local speed, range = 160, 200
	local finish = worldend(character, origin, direction, range)
	local fliesfor = math.max((finish - origin).Magnitude / speed, 0.15)

	local projectile = Instance.new("Part")
	projectile.Name = "empyreanorb"
	projectile.Anchored = true
	projectile.CanCollide = false
	projectile.CanQuery = false
	projectile.CanTouch = false
	projectile.Transparency = 1
	projectile.Size = Vector3.new(4, 4, 8)
	projectile.CFrame = CFrame.lookAt(origin, origin + direction)
	projectile.Parent = workspace:FindFirstChild("_WorldOrigin") or workspace
	debris:AddItem(projectile, fliesfor + 3)

	kit:play("Kitsune.RedOrb", {
		player = player,
		hrp = root,
		origin = origin,
		fireDir = direction,
		projectilePart = projectile,
		fliesFor = fliesfor,
		projectileSpeed = speed,
	})
	kit.busyuntil = os.clock() + 0.5

	local dragged = {}
	local started = os.clock()
	local connection
	connection = runservice.Heartbeat:Connect(function()
		local elapsed = os.clock() - started
		local alpha = math.min(elapsed / fliesfor, 1)
		local position = origin + (finish - origin) * alpha
		projectile.CFrame = CFrame.lookAt(position, position + direction)

		kit:eachtarget(character, function(model, humanoid, victimroot)
			if kit:canhit(model) and not dragged[victimroot] and (victimroot.Position - position).Magnitude <= 7 then
				dragged[victimroot] = { npc = isnpc(model), anchored = victimroot.Anchored }
				kit:hit(humanoid, data.damage.cgrab, victimroot)
				kit:play("Kitsune.RedCProjectileDrag", {
					enemyRoot = victimroot,
					projectilePart = projectile,
					victimRootParts = {},
					syncedEndTime = workspace:GetServerTimeNow() + (fliesfor - elapsed),
					initVec = direction,
					rotPerFrame = 0,
				})
			end
		end)

		for victimroot, info in pairs(dragged) do
			if info.npc and victimroot.Parent then
				victimroot.Anchored = true
				victimroot.CFrame = CFrame.lookAt(Vector3.zero, direction) * CFrame.Angles(7 * elapsed, 5 * elapsed, 5 * elapsed) + position + direction * 4 + Vector3.new(0, 3, 0)
			end
		end

		if alpha >= 1 then
			connection:Disconnect()
			for victimroot, info in pairs(dragged) do
				if info.npc and victimroot.Parent then
					victimroot.Anchored = info.anchored
				end
			end
			kit:damageradius(character, finish, 18, data.damage.cexplode)
		end
	end)
end

local function victimcframe(dashend)
	local ok, offset = pcall(function()
		return cutscenemodel:GetPivot():ToObjectSpace(cutscenemodel.VictimCF.CFrame)
	end)
	return dashend * CFrame.new(0, -7.297, 0) * (ok and offset or CFrame.new(0, 0, -20))
end

local function pounce(player, character, root, aim)
	local length, endsafter = 60, 0.45
	local startpos = root.Position
	local endpos = startpos + aim.forward * length
	local victimroot = kit:firstalong(character, startpos, endpos, 12)
	local victimmodel = victimroot and victimroot.Parent
	if victimroot then
		endpos = victimroot.Position - aim.forward * 10
		endpos = Vector3.new(endpos.X, startpos.Y, endpos.Z)
	end

	kit:play("Kitsune.Red_Cutscene", {
		Stage = "POUNCE",
		player = player,
		Player = player,
		Root = root,
		hrp = root,
		origin = startpos,
		Origin = startpos,
		fireDir = aim.forward,
		forwardCylinderLength = (endpos - startpos).Magnitude,
		endsAfter = endsafter,
		pounceStartPos = startpos,
		pounceEndPos = endpos,
		Tool = tool,
	})

	local rig = transform.rig
	if not victimroot or not rig then
		kit.busyuntil = os.clock() + endsafter + 0.4
		task.delay(endsafter, function()
			kit:damagealong(character, startpos, endpos, 12, data.damage.cpounce)
		end)
		return
	end

	kit.busyuntil = os.clock() + endsafter + 3.2
	local humanoid = victimmodel:FindFirstChildOfClass("Humanoid")
	local wasanchored = victimroot.Anchored

	task.delay(endsafter, function()
		if not victimroot.Parent or not humanoid or humanoid.Health <= 0 then
			return
		end
		local dashend = CFrame.lookAt(endpos, endpos + aim.forward)
		local projectileend = kit:groundbelow(endpos + aim.forward * 90, character) + Vector3.new(0, 3, 0)
		local holdat = victimcframe(dashend)

		kit:hit(humanoid, data.damage.cpounce, victimroot)
		kit:play("Kitsune.Red_Cutscene", {
			Stage = 2,
			Player = player,
			player = player,
			Root = root,
			hrp = root,
			Character = character,
			Rig = rig,
			EnemyChar = victimmodel,
			dashEndCF = dashend,
			ProjectileEndPos = projectileend,
			Origin = endpos,
			Tool = tool,
		})

		victimroot.Anchored = true
		local started = os.clock()
		local connection
		connection = runservice.Heartbeat:Connect(function()
			local elapsed = os.clock() - started
			if not victimroot.Parent then
				connection:Disconnect()
				return
			end
			if elapsed < 131 / 60 then
				victimroot.CFrame = holdat
			elseif elapsed < 165 / 60 then
				local alpha = math.clamp((elapsed - 131 / 60) / (34 / 60), 0, 1)
				victimroot.CFrame = CFrame.new(holdat.Position:Lerp(projectileend, alpha)) * holdat.Rotation
			else
				connection:Disconnect()
				victimroot.CFrame = CFrame.new(projectileend) * holdat.Rotation
				victimroot.Anchored = wasanchored
				kit:hit(humanoid, data.damage.cultimate, victimroot)
				kit:damageradius(character, projectileend, 20, data.damage.cexplode)
			end
		end)
	end)
end

local function wildassault(player, character, root, aim)
	local fox = istransformed.Value
	local total = fox and 90 or 70
	local sway = fox and 14 or 10
	local perdash = 0.14
	local points = { root.Position }
	for i = 1, 3 do
		local along = aim.origin + aim.forward * total * (i / 3)
		local side = i == 3 and 0 or ((i % 2 == 1) and sway or -sway)
		points[i + 1] = along + aim.right * side
	end

	kit.lastused.F = os.clock()
	kit.busyuntil = os.clock() + perdash * 3 + 0.3
	for i = 1, 3 do
		task.delay((i - 1) * perdash, function()
			local from, to = points[i], points[i + 1]
			kit:play("Kitsune.ZigzagDash", { player = player, hrp = root, originPos = from, goalPos = to, index = i })
			kit:play("Kitsune.ClientDash", { Root = root, CFrame = CFrame.lookAt(to, to + aim.forward), Duration = perdash, Linear = true })
			task.delay(perdash, function()
				kit:damagealong(character, from, to, fox and 12 or 8, data.damage.f)
			end)
		end)
	end
end

local function onholdstart(player, character, root, key)
	holdstarted[key] = os.clock()
	local fox = istransformed.Value
	if key == "Z" then
		kit:play("Kitsune.RedZCharge", {
			player = player,
			hrp = root,
			holding = kit.effectholding,
			maxChargeTime = beamcharge.Value,
		})
	elseif key == "C" then
		kit:play("Kitsune.CCharge", {
			player = player,
			hrp = root,
			holding = kit.effectholding,
			transformed = fox,
			mutated = true,
			cutsceneTransition = false,
		})
	end
end

local function onrelease(player, character, root, key, aim)
	if key == "Z" then
		firebeam(player, character, root, aim)
	elseif key == "X" then
		tailsgrab(player, character, root)
	elseif key == "C" then
		if istransformed.Value then
			pounce(player, character, root, aim)
		else
			firecannon(player, character, root, aim)
		end
	end
end

local function onm1(player, character, root, humanoid)
	if os.clock() - lastm1 > 1.2 then
		combo = 0
	end
	lastm1 = os.clock()
	combo = combo % 5 + 1
	local final = combo == 5
	local fox = istransformed.Value
	local aim = kit:aim(root)

	kit:play("Kitsune.RedM1Combo", {
		player = player,
		hrp = root,
		transformed = fox,
		index = combo,
		damageDir = aim.forward,
		playerOnGround = humanoid.FloorMaterial ~= Enum.Material.Air,
	})

	if final then
		kit.busyuntil = os.clock() + 0.5
	end
	local reach = fox and 14 or 6
	local center = root.Position + aim.forward * reach
	local radius = (fox and 14 or 8) + (final and 4 or 0)
	task.delay(0.12, function()
		kit:damageradius(character, center, radius, final and data.damage.m1final or data.damage.m1)
	end)
end

kit = fruitkit.new(tool, {
	holdkeys = { Z = true, X = true, C = true },
	canhold = function()
		if istransformed.Value then
			addrage(-data.rage.skillcosttransformed)
		end
		return true
	end,
	onholdstart = onholdstart,
	onrelease = onrelease,
	onm1 = onm1,
	onkey = function(player, character, root, humanoid, key)
		if key == "V" then
			if istransformed.Value then
				if os.clock() >= kit.busyuntil then
					endtransform(player)
				end
			else
				starttransform(player, character, root, humanoid)
			end
		elseif key == "F" then
			if kit:canuse(character, "F") then
				if istransformed.Value then
					addrage(-data.rage.skillcosttransformed)
				end
				wildassault(player, character, root, kit:aim(root))
			end
		end
	end,
	onhit = function(amount)
		if not istransformed.Value then
			addrage(amount * data.rage.gainperdamage)
		end
	end,
	onpassivestart = function(player, character)
		tails = 0
		local rage = kit:ragevalue(character)
		setrage(rage and rage.Value or 0)
	end,
	onpassiveend = function(character)
		endtransform(kit:getowner(), true)
		local root = character:FindFirstChild("HumanoidRootPart")
		if root then
			kit:play("Kitsune.Tail", { Root = root, Ids = {}, Tool = tool })
		end
		tails = 0
	end,
})

task.spawn(function()
	local step = 0.25
	while true do
		task.wait(step)
		local character = kit:getcharacter() or (kit.passivecharacter and kit.passivecharacter.Parent and kit.passivecharacter)
		local rage = character and character:FindFirstChild("Rage")
		if rage then
			if istransformed.Value and transform.token then
				setrage(rage.Value - data.rage.transformdrainpersecond * step)
				if rage.Value <= 0 then
					endtransform(kit:getowner())
				end
			elseif not istransformed.Value and rage.Value < 100 then
				setrage(rage.Value + 100 * step / 300)
			end
		end
	end
end)
