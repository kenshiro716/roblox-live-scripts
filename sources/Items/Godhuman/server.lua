local serverstorage = game:GetService("ServerStorage")
local replicatedstorage = game:GetService("ReplicatedStorage")
local runservice = game:GetService("RunService")
local players = game:GetService("Players")
local fruitkit = require(serverstorage:WaitForChild("fruitkit"))
local hitbox = require(serverstorage:WaitForChild("hitbox"))
local weapondata = require(replicatedstorage:WaitForChild("Modules"):WaitForChild("WeaponData")).godhuman
local util = require(replicatedstorage:WaitForChild("Util"))
local tool = script.Parent
local data = require(tool:WaitForChild("Data"))
local masterclock = util.MasterClock
local kit
local holdstarted = {}

local function now()
	return masterclock:GetTime()
end

local function alive(model)
	local humanoid = model and model.Parent and model:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

local function firstline(character, from, to, radius)
	local best
	local bestdistance = math.huge
	for _, target in ipairs(hitbox.line(character, from, to, radius)) do
		local root = target.root
		if root and alive(target.model) then
			local distance = (root.Position - from).Magnitude
			if distance < bestdistance then
				best = target
				bestdistance = distance
			end
		end
	end
	return best
end

local function firstnear(character, position, radius)
	local best
	local bestdistance = math.huge
	for _, target in ipairs(hitbox.sphere(character, position, radius)) do
		local root = target.root
		if root and alive(target.model) then
			local distance = (root.Position - position).Magnitude
			if distance < bestdistance then
				best = target
				bestdistance = distance
			end
		end
	end
	return best
end

local function stun(model, duration)
	local value = model and model:FindFirstChild("Stun")
	if not value or not (value:IsA("NumberValue") or value:IsA("IntValue")) then
		return
	end
	value.Value = math.max(value.Value, duration)
end

local function push(root, direction, force, lift)
	if not root or not root.Parent then
		return
	end
	local flat = Vector3.new(direction.X, 0, direction.Z)
	if flat.Magnitude < 0.05 then
		flat = Vector3.new(0, 0, -1)
	end
	root.AssemblyLinearVelocity = flat.Unit * force + Vector3.new(0, lift, 0)
end

local function damagearea(character, position, radius, amount, excluded)
	for _, target in ipairs(hitbox.sphere(character, position, radius)) do
		if target.model ~= excluded and target.humanoid and alive(target.model) then
			dealdamage(character, target.humanoid, amount, target.root)
		end
	end
end

local function spend(character, amount)
	local energy = character:FindFirstChild("Energy")
	if not energy or not amount or amount <= 0 then
		return true
	end
	if energy.Value < amount then
		return false
	end
	energy.Value -= amount
	return true
end

local function scaledamage(character, amount)
 if character and character:FindFirstChild("HasBuso") then
  amount *= 1.25
 end
 return amount
end

local function dealdamage(character, humanoid, amount, root)
 return kit:hit(humanoid, scaledamage(character, amount), root)
end

local function protect(character)
 local forcefield = Instance.new("ForceField")
 forcefield.Name = "godhuman_invulnerability"
 forcefield.Visible = false
 forcefield.Parent = character
 game:GetService("Debris"):AddItem(forcefield, 8)
 return forcefield
end

local function unprotect(forcefield)
 if forcefield and forcefield.Parent then
  forcefield:Destroy()
 end
end

local function rayimpact(character, origin, direction, distance)
	local ignored = { character }
	for _, name in ipairs({ "Characters", "Enemies" }) do
		local folder = workspace:FindFirstChild(name)
		if folder then
			table.insert(ignored, folder)
		end
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignored
	local result = workspace:Raycast(origin, direction * distance, params)
	return result and result.Position or origin + direction * distance
end

local function dash(character, root, direction, speed, duration)
 local mover = Instance.new("BodyVelocity")
 mover.Name = "godhuman_dash"
 mover.MaxForce = Vector3.one * 1000000
 mover.P = 30000
 mover.Velocity = direction * speed
 mover.Parent = root
 local started = os.clock()
 local previous = root.Position
 local target
 while os.clock() - started < duration and root.Parent do
  runservice.Heartbeat:Wait()
  target = firstline(character, previous, root.Position, 5) or firstnear(character, root.Position, 5)
  previous = root.Position
  if target then
   break
  end
 end
 if mover.Parent then
  mover:Destroy()
 end
 if root.Parent then
  root.AssemblyLinearVelocity = Vector3.zero
 end
 return target
end

local function soaringbeast(character, root, humanoid, aim)
	local origin = root.Position
	local destination = kit:clamprange(origin, aim.target, 70)
	local offset = destination - origin
	local direction = offset.Magnitude > 1 and offset.Unit or aim.forward
	local distance = math.clamp(offset.Magnitude, 8, 70)
	local duration = math.clamp(distance / 175, 0.08, 0.42)
	local facing = CFrame.lookAt(origin, origin + direction)
	root.CFrame = facing
	kit.busyuntil = os.clock() + duration + 0.9
	local forcefield = protect(character)
	task.delay(1.6, function()
		unprotect(forcefield)
	end)
	kit:play("SuperhumanV2.Z", {
		Stage = 2,
		Character = character,
		Root = root,
		Humanoid = humanoid,
		Duration = duration,
		Timestamp = now(),
		Velocity = direction * 175,
	})
	local started = os.clock()
	local previous = root.Position
	local target
	local mover = Instance.new("BodyVelocity")
	mover.Name = "godhuman_dash"
	mover.MaxForce = Vector3.one * 1000000
	mover.P = 30000
	mover.Velocity = direction * 175
	mover.Parent = root
	while os.clock() - started < duration and root.Parent and humanoid.Health > 0 do
		runservice.Heartbeat:Wait()
		target = firstline(character, previous, root.Position, 5) or firstnear(character, root.Position, 5)
		previous = root.Position
		if target then
			break
		end
	end
	if mover.Parent then
		mover:Destroy()
	end
	if not root.Parent then
		unprotect(forcefield)
		return
	end
	root.AssemblyLinearVelocity = Vector3.zero
	if not target then
		unprotect(forcefield)
		return
	end
	local targetroot = target.root
	local targethumanoid = target.humanoid
	if not targetroot or not alive(target.model) then
		unprotect(forcefield)
		return
	end
	local close = (targetroot.Position - origin).Magnitude <= 12
	local wasanchored = targetroot.Anchored
	targetroot.Anchored = true
	local punchamount = 6
	local totaldamage = data.Damage.Z * (close and 1.15 or 1)
	local durationofbarrage = 0.72
	kit.busyuntil = os.clock() + durationofbarrage + 0.25
	kit:play("SuperhumanV2.Z", {
		Stage = 3,
		TargetRoot = targetroot,
		TargetHumanoid = targethumanoid,
		UserRoot = root,
		UserHumanoid = humanoid,
		Duration = durationofbarrage,
		PunchAmount = punchamount,
		Timestamp = now(),
	})
	stun(target.model, durationofbarrage)
	for _ = 1, punchamount do
		if targetroot.Parent and root.Parent then
			targetroot.CFrame = root.CFrame * CFrame.new(0, 0, -3)
		end
		if alive(target.model) then
			dealdamage(character, targethumanoid, totaldamage / punchamount, targetroot)
		end
		task.wait(durationofbarrage / punchamount)
	end
	if targetroot.Parent then
		targetroot.Anchored = wasanchored
	end
	if targetroot.Parent and root.Parent then
		local finalcf = CFrame.lookAt(root.Position, targetroot.Position)
		kit:play("SuperhumanV2.Z", {
			Stage = 4,
			TargetRoot = targetroot,
			UserRoot = root,
			Timestamp = now(),
			UserCFrame = finalcf,
		})
		push(targetroot, targetroot.Position - root.Position, 55, 22)
	end
	unprotect(forcefield)
end

local function heavenandearthtap(character, root, aim)
	local origin = root.Position + Vector3.new(0, 2, 0)
	local direction = aim.forward
	local distance = 180
	local impact = rayimpact(character, origin, direction, distance)
	local target = firstline(character, origin, impact, 4)
	if target and target.root then
		local targetdistance = (target.root.Position - origin).Magnitude
		local wallDistance = (impact - origin).Magnitude
		if targetdistance < wallDistance then
			impact = target.root.Position
		else
			target = nil
		end
	end
	local travel = math.clamp((impact - origin).Magnitude / 220, 0.12, 0.75)
	local positionobject = Instance.new("Vector3Value")
	positionobject.Name = "godhumanprojectileposition"
	positionobject.Value = origin
	positionobject.Parent = tool
	local cframe = CFrame.lookAt(origin, impact)
	kit.busyuntil = os.clock() + travel + 0.35
	kit:play("SuperhumanV2.X", {
		Stage = 2,
		CFrame = cframe,
		Lifetime = travel,
		Distance = (impact - origin).Magnitude,
		PositionObject = positionobject,
		Timestamp = now(),
		Character = character,
	})
	task.delay(travel, function()
		if positionobject.Parent then
			positionobject.Value = impact
		end
		if not character.Parent then
			if positionobject.Parent then
				positionobject:Destroy()
			end
			return
		end
		kit:play("SuperhumanV2.X", {
			Stage = 4,
			Character = character,
		})
		damagearea(character, impact, 11, data.Damage.XTap)
		if target and target.root and target.root.Parent then
			push(target.root, target.root.Position - origin, 38, 50)
			stun(target.model, 0.35)
		end
		task.delay(2, function()
			if positionobject.Parent then
				positionobject:Destroy()
			end
		end)
	end)
end

local function heavenandearthheld(character, root, held)
	local scale = math.clamp(held / 4, 0.15, 1)
	local radius = 42 * scale
	local damage = data.Damage.XHeld * scale
	local center = root.Position
	local cframe = CFrame.lookAt(center, Vector3.new(kit.mousepos.Value.X, center.Y, kit.mousepos.Value.Z))
	kit.busyuntil = os.clock() + 0.8
	kit:play("SuperhumanV2.X", {
		Stage = 3,
		CFrame = cframe,
		Floor = kit:groundbelow(center, character),
		Timestamp = now(),
		ClapDelay = 0.65,
		HeldScale = scale,
	})
	task.delay(0.65, function()
		if not character.Parent then
			return
		end
		local ground = kit:groundbelow(root.Position, character)
		local targets = hitbox.sphere(character, ground, radius)
		for _, target in ipairs(targets) do
			if target.humanoid and alive(target.model) then
				if dealdamage(character, target.humanoid, damage, target.root) then
					stun(target.model, 0.5)
					if target.root then
						push(target.root, target.root.Position - root.Position, 34 * scale, 58 * scale)
					end
				end
			end
		end
	end)
end

local function sixthrealmguntap(character, root, humanoid, aim, held)
 local charged = held >= 0.2
 local range = charged and 150 or 85
 local speed = charged and 260 or 220
 local origin = root.Position
 local destination = kit:clamprange(origin, aim.target, range)
 local direction = destination - origin
 if direction.Magnitude < 1 then
  direction = aim.forward
 else
  direction = direction.Unit
 end
 local anticipated = firstline(character, origin, origin + direction * range, 5)
 local targetposition = anticipated and anticipated.root and anticipated.root.Position or origin + direction * range
 local travel = math.clamp((targetposition - origin).Magnitude / speed, 0.08, 0.65)
 local forcefield = charged and protect(character) or nil
 if forcefield then
  task.delay(travel + 1.2, function()
   unprotect(forcefield)
  end)
 end
 kit.busyuntil = os.clock() + travel
 kit:play("SuperhumanV2.C", {
  Stage = 2,
  Char = character,
  TargetChar = anticipated and anticipated.model or nil,
  Timestamp = now(),
  TravelTime = travel,
  TargetPosition = targetposition,
 })
 local target = dash(character, root, direction, speed, travel)
 if not target or not target.root or not alive(target.model) then
  unprotect(forcefield)
  return
 end
 local targetroot = target.root
 local targethumanoid = target.humanoid
 local grabtime = charged and 0.75 or 0.22
 kit.busyuntil = os.clock() + grabtime + 0.25
 kit:play("SuperhumanV2.C", {
  Stage = 3,
  Char = character,
  TargetChar = target.model,
  TargetPosition = targetroot.Position,
  Timestamp = now(),
  TravelTime = travel,
  EndLag = 0.25,
  GrabTime = grabtime,
  Charged = charged,
 })
 stun(target.model, grabtime)
 task.wait(grabtime)
 if not alive(target.model) then
  unprotect(forcefield)
  return
 end
 dealdamage(character, targethumanoid, charged and data.Damage.CHeld or data.Damage.CTap, targetroot)
 damagearea(character, targetroot.Position, charged and 18 or 12, (charged and data.Damage.CHeld or data.Damage.CTap) * 0.55, target.model)
 push(targetroot, targetroot.Position - root.Position, charged and 105 or 70, charged and 40 or 26)
 unprotect(forcefield)
end

kit = fruitkit.new(tool, {
	holdkeys = { X = true, C = true },
	maxhold = 6,
	canhold = function(_, character, _, key)
		return spend(character, data.Cost[key])
	end,
	onholdstart = function(_, character, root, key)
		holdstarted[key] = os.clock()
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if key == "X" then
			kit:play("SuperhumanV2.X", {
				Stage = 1,
				Character = character,
				Humanoid = humanoid,
				HoldValue = kit.effectholding,
				MinHold = 0.12,
			})
		elseif key == "C" then
			kit:play("SuperhumanV2.C", {
				Stage = 1,
				Character = character,
				Humanoid = humanoid,
				HoldValue = kit.effectholding,
			})
		end
	end,	onrelease = function(_, character, root, key, aim)
		local held = math.clamp(os.clock() - (holdstarted[key] or os.clock()), 0, 6)
		holdstarted[key] = nil
		if key == "X" then
			if held >= 0.12 then
				heavenandearthheld(character, root, held)
			else
				heavenandearthtap(character, root, aim)
			end
		elseif key == "C" then
			sixthrealmguntap(character, root, character:FindFirstChildOfClass("Humanoid"), aim, held)
		end
	end,
	onkey = function(_, character, root, humanoid, key)
		if key ~= "Z" or not kit:canuse(character, key) or not spend(character, data.Cost.Z) then
			return
		end
		kit.lastused.Z = os.clock()
		soaringbeast(character, root, humanoid, kit:aim(root))
	end,
})
