local serverstorage = game:GetService("ServerStorage")
local debris = game:GetService("Debris")

local fruitkit = require(serverstorage:WaitForChild("fruitkit"))
local meleekit = require(serverstorage:WaitForChild("meleekit"))
local hitbox = require(serverstorage:WaitForChild("hitbox"))

local tool = script.Parent
local data = require(tool:WaitForChild("Data"))
local kit
local holdstarted = {}
local overheatuntil = 0
local drillactive = nil

local function overheated()
	return os.clock() < overheatuntil
end

local function effect(name)
	return overheated() and ("DeathStep2.Mode." .. name) or ("DeathStep2." .. name)
end

local function amount(base)
	return base * (overheated() and data.OverheatBoost or 1)
end

local function marker(name, parent, life)
	local value = Instance.new("BoolValue")
	value.Name = name
	value.Value = true
	value.Parent = parent
	debris:AddItem(value, life)
	return value
end

local function burn(character, position)
	if not overheated() then
		return
	end
	task.spawn(function()
		local started = os.clock()
		while os.clock() - started < data.Overheat.FireTime and character.Parent do
			meleekit.area(kit, character, position, data.Overheat.FireRadius, data.Damage.Fire)
			task.wait(0.5)
		end
	end)
end

local function rocketkickstart(root)
	local using = marker("deathstepusing", root, 3)
	holdstarted.using = using
	kit:play(effect("RocketKick"), { HRP = root, Holding = kit.effectholding, Using = using })
end

local function rocketkick(character, root, aim, held)
	local using = holdstarted.using
	holdstarted.using = nil
	local power = math.clamp(held / data.Kick.MaxHold, 0, 1)
	local direction = aim.target - root.Position
	direction = direction.Magnitude > 1 and direction.Unit or root.CFrame.LookVector
	local range = data.Kick.Range * (0.7 + power * 0.6)
	local speed = data.Kick.Speed * (1 + power * 0.35)
	local duration = range / speed
	root.CFrame = CFrame.lookAt(root.Position, root.Position + Vector3.new(direction.X, 0, direction.Z))
	kit.busyuntil = os.clock() + duration + 0.3
	local hit = {}
	local impact = nil
	local normal = Vector3.yAxis
	meleekit.dash(character, root, direction, speed, duration, nil, function()
		if impact then
			return
		end
		local wall = workspace:Raycast(root.Position, direction * 4, meleekit.rayparams(character))
		if wall then
			impact, normal = wall.Position, wall.Normal
		end
		for _, target in ipairs(hitbox.sphere(character, root.Position + direction * 2, data.Kick.Radius)) do
			if not hit[target.model] and meleekit.alive(target.model) then
				hit[target.model] = true
				if kit:hit(target.humanoid, amount(data.Damage.Z), target.root) then
					meleekit.stun(target.model, 0.5)
					meleekit.push(target.root, direction, 75, 20)
				end
			end
		end
	end)
	if using then
		using:Destroy()
	end
	if impact then
		kit:play(effect("RocketKick"), { HRP = root, Position = impact, Normal = normal, Scale = 1 + power * 0.5 })
		meleekit.area(kit, character, impact, data.Kick.DentRadius, amount(data.Damage.Z) * 0.5, { stun = 0.4 })
		burn(character, impact)
	end
end

local function windbullet(character, root, aim)
	local origin = root.Position + Vector3.new(0, 1, 0)
	local direction = aim.target - origin
	direction = direction.Magnitude > 1 and direction.Unit or root.CFrame.LookVector
	local impact = meleekit.impact(character, origin, direction, data.Bullet.Range)
	local target = meleekit.firstline(character, origin, impact, data.Bullet.Radius)
	if target and (target.root.Position - origin).Magnitude < (impact - origin).Magnitude then
		impact = target.root.Position
	end
	local length = (impact - origin).Magnitude
	kit.busyuntil = os.clock() + 0.4
	kit:play(effect("AirShot"), { CFrame = CFrame.lookAt(origin, origin + direction), Character = character, Length = length, SCALE = 1 })
	task.delay(length / data.Bullet.Speed, function()
		if not character.Parent then
			return
		end
		if target and meleekit.alive(target.model) then
			kit:hit(target.humanoid, amount(data.Damage.X), target.root)
		end
		meleekit.area(kit, character, impact, data.Bullet.ExplosionRadius, amount(data.Damage.X) * 1.25, { stun = 0.4, push = 45, lift = 25 })
		burn(character, meleekit.ground(character, impact))
	end)
end

local function drillstart(character, root)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if meleekit.grounded(character, root) then
		local hop = Instance.new("BodyVelocity")
		hop.MaxForce = Vector3.new(0, 1e6, 0)
		hop.Velocity = Vector3.new(0, 35, 0)
		hop.Parent = root
		debris:AddItem(hop, 0.2)
	end
	local active = marker("deathstepdrill", root, data.Drill.MaxHold + 1)
	drillactive = active
	kit:play(effect("Drill"), { Character = character, Active = active })
	local hover = Instance.new("BodyVelocity")
	hover.Name = "deathstephover"
	hover.MaxForce = Vector3.one * 1e6
	hover.Velocity = Vector3.zero
	hover.Parent = root
	local caught = {}
	task.spawn(function()
		local started = os.clock()
		while active.Parent and humanoid.Health > 0 and os.clock() - started < data.Drill.MaxHold and (kit.effectholding.Value or os.clock() - started < data.Drill.MinHold) do
			task.wait(0.15)
			if os.clock() - started >= 0.2 then
				hover.Parent = nil
			end
			local aim = kit:aim(root)
			local direction = aim.target - root.Position
			direction = direction.Magnitude > 1 and direction.Unit or root.CFrame.LookVector
			local center = root.Position + direction * data.Drill.Reach * 0.5
			for _, target in ipairs(hitbox.box(character, CFrame.lookAt(center, center + direction), Vector3.new(7, 7, data.Drill.Reach))) do
				if meleekit.alive(target.model) and kit:hit(target.humanoid, amount(data.Damage.C), target.root) then
					caught[target.model] = target
					meleekit.stun(target.model, 0.5)
				end
			end
		end
		hover:Destroy()
		if active.Parent then
			active:Destroy()
		end
		drillactive = nil
		for model, target in pairs(caught) do
			if meleekit.alive(model) then
				kit:hit(target.humanoid, amount(data.Damage.CFinish), target.root)
				meleekit.push(target.root, Vector3.new(0, -1, 0), 0, -60)
				burn(character, meleekit.ground(character, target.root.Position))
			end
		end
	end)
end

local function maximumoverheat(character, root)
	overheatuntil = os.clock() + data.Overheat.Duration
	tool:SetAttribute("overheat", true)
	kit.busyuntil = os.clock() + 0.8
	kit:play("DeathStep.V", { HRP = root })
	task.delay(0.6, function()
		if root.Parent then
			meleekit.area(kit, character, root.Position, data.Overheat.Radius, data.Damage.V, { stun = 0.4, push = 30, lift = 15 })
		end
	end)
	task.delay(data.Overheat.Duration, function()
		if os.clock() >= overheatuntil then
			tool:SetAttribute("overheat", nil)
		end
	end)
end

kit = fruitkit.new(tool, {
	holdkeys = { Z = true, X = true, C = true },
	maxhold = 3,
	canhold = function(_, character, _, key)
		return meleekit.spend(character, data.Cost[key])
	end,
	onholdstart = function(_, character, root, key)
		holdstarted[key] = os.clock()
		if key == "Z" then
			rocketkickstart(root)
		elseif key == "C" then
			drillstart(character, root)
		end
	end,
	onrelease = function(_, character, root, key, aim)
		local held = meleekit.heldfor(holdstarted[key])
		holdstarted[key] = nil
		if key == "Z" then
			rocketkick(character, root, aim, math.min(held, data.Kick.MaxHold))
		elseif key == "X" then
			windbullet(character, root, aim)
		end
	end,
	onkey = function(_, character, root, _, key)
		if key ~= "V" or not kit:canuse(character, key) or not meleekit.spend(character, data.Cost.V) then
			return
		end
		kit.lastused.V = os.clock()
		maximumoverheat(character, root)
	end,
	onunequip = function()
		if drillactive and drillactive.Parent then
			drillactive:Destroy()
		end
	end,
})
