local serverstorage = game:GetService("ServerStorage")

local fruitkit = require(serverstorage:WaitForChild("fruitkit"))
local meleekit = require(serverstorage:WaitForChild("meleekit"))
local hitbox = require(serverstorage:WaitForChild("hitbox"))

local tool = script.Parent
local data = require(tool:WaitForChild("Data"))
local kit
local holdstarted = {}

local function meteortackle(player, character, root, aim)
	local direction = (aim.target - root.Position)
	direction = direction.Magnitude > 1 and direction.Unit or root.CFrame.LookVector
	kit.busyuntil = os.clock() + 0.5
	root.CFrame = CFrame.lookAt(root.Position, root.Position + Vector3.new(direction.X, 0, direction.Z))
	kit:play("Combat2V2.Z", { plr = player, hrp = root, CFrame = root.CFrame, mouse = aim.target })
	local hit = {}
	meleekit.dash(character, root, direction, data.Tackle.Speed, data.Tackle.Duration, nil, function()
		for _, target in ipairs(hitbox.sphere(character, root.Position + direction * 2, data.Tackle.Radius)) do
			if not hit[target.model] and meleekit.alive(target.model) then
				hit[target.model] = true
				if kit:hit(target.humanoid, data.Damage.Z, target.root) then
					meleekit.stun(target.model, 0.45)
					meleekit.push(target.root, direction, 60, 20)
				end
			end
		end
	end)
end

local function rockpoints(character, origin, count, radius)
	local points = {}
	for index = 1, count do
		local angle = (index / count) * math.pi * 2
		local flat = origin + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		local ground = meleekit.ground(character, flat)
		table.insert(points, { Ground = ground, Float = ground + Vector3.new(0, 10 + (index % 3) * 3, 0) })
	end
	return points
end

local function groundbreaker(player, character, root)
	local airborne = not meleekit.grounded(character, root)
	local origin = meleekit.ground(character, root.Position + root.CFrame.LookVector * 6)
	local cframe = CFrame.lookAt(origin, origin + root.CFrame.LookVector)
	local key = tostring(player.UserId) .. "_" .. tostring(os.clock())
	local points = rockpoints(character, origin, 8, data.Breaker.Radius * 0.6)
	local victims = {}
	for _, target in ipairs(hitbox.sphere(character, origin, data.Breaker.Radius)) do
		if meleekit.alive(target.model) then
			table.insert(victims, target)
		end
	end
	local miss = #victims == 0
	local start = meleekit.now()
	kit.busyuntil = os.clock() + 0.8
	kit:play("Combat2V2.X", {
		Stage = "Cast",
		Origin = origin,
		CFrame = cframe,
		Points = points,
		StartTime = start,
		Rise = 0.35,
		RockKey = key,
		Miss = miss,
		Airborne = airborne,
	})
	if miss then
		task.delay(0.9, function()
			kit:play("Combat2V2.X", { Stage = "Drop", Origin = origin, RockKey = key })
		end)
		return
	end
	local models = {}
	local releases = {}
	for _, target in ipairs(victims) do
		table.insert(models, target.model)
		kit:hit(target.humanoid, data.Damage.X * 0.4, target.root)
		meleekit.stun(target.model, 2)
		table.insert(releases, meleekit.hold(target, nil, 2))
	end
	local sequence = {}
	local elapsed = 0
	for index = 1, math.min(#points, 5) do
		elapsed += 0.16
		table.insert(sequence, { Index = index, Time = elapsed })
	end
	local landing = origin + root.CFrame.LookVector * 10
	task.delay(0.4, function()
		kit:play("Combat2V2.X", {
			Stage = "Bounce",
			Origin = origin,
			Points = points,
			Victims = models,
			RockKey = key,
			Sequence = sequence,
			StartTime = meleekit.now(),
			Landing = landing,
		})
		for index = 1, #sequence do
			task.wait(0.16)
			for _, target in ipairs(victims) do
				if meleekit.alive(target.model) then
					kit:hit(target.humanoid, data.Damage.X * 0.1, target.root)
				end
			end
		end
		local lastpoint = points[sequence[#sequence].Index]
		kit:play("Combat2V2.X", {
			Stage = "Slam",
			Origin = origin,
			CFrame = CFrame.new(landing),
			Victims = models,
			Landing = landing,
			From = lastpoint and lastpoint.Float or landing + Vector3.new(0, 15, 0),
			Fall = 0.13,
			StartTime = meleekit.now(),
			RockKey = key,
		})
		task.wait(0.13)
		for _, release in ipairs(releases) do
			release()
		end
		for _, target in ipairs(victims) do
			if target.root and target.root.Parent then
				target.root.CFrame = CFrame.new(landing + Vector3.new(0, 3, 0))
			end
			if meleekit.alive(target.model) then
				kit:hit(target.humanoid, data.Damage.X * 0.3, target.root)
				meleekit.stun(target.model, 0.6)
			end
		end
	end)
end

local function chargedpunch(player, character, root, held)
	local power = math.clamp(1 + math.floor(held / data.Punch.ChargeStep), 1, 3)
	local direction = root.CFrame.LookVector
	local origin = root.Position + direction * 3
	kit.busyuntil = os.clock() + 0.5
	kit:play("Combat2V2.C", { CFrame = root.CFrame, Origin = origin, Power = power })
	local length = data.Punch.Range * (0.7 + power * 0.3)
	local finish = origin + direction * length
	meleekit.along(kit, character, origin, finish, data.Punch.Radius + power, data.Damage.C * (0.75 + power * 0.25), { stun = 0.5, push = 50 + power * 20, lift = 15, ignore = {} })
end

kit = fruitkit.new(tool, {
	holdkeys = { C = true },
	maxhold = 2,
	canhold = function(_, character, _, key)
		return meleekit.spend(character, data.Cost[key])
	end,
	onholdstart = function(_, _, _, key)
		holdstarted[key] = os.clock()
	end,
	onrelease = function(player, character, root, key)
		local held = meleekit.heldfor(holdstarted[key])
		holdstarted[key] = nil
		if key == "C" then
			chargedpunch(player, character, root, held)
		end
	end,
	onkey = function(player, character, root, _, key)
		if not kit:canuse(character, key) or not meleekit.spend(character, data.Cost[key]) then
			return
		end
		kit.lastused[key] = os.clock()
		if key == "Z" then
			meteortackle(player, character, root, kit:aim(root))
		elseif key == "X" then
			groundbreaker(player, character, root)
		end
	end,
})
