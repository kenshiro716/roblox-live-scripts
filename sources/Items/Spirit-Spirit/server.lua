local players = game:GetService("Players")
local replicatedstorage = game:GetService("ReplicatedStorage")
local serverstorage = game:GetService("ServerStorage")

local fruitkit = require(serverstorage:WaitForChild("fruitkit"))
local hitbox = require(serverstorage:WaitForChild("hitbox"))
local util = require(replicatedstorage:WaitForChild("Util"))

local tool = script.Parent
local data = require(tool:WaitForChild("Data"))
local masterclock = util.MasterClock

local kit
local passive = nil
local buddies = {}
local buddycount = 0
local lastbuddy = "Shu"
local holdstarted = {}
local beam = nil
local flight = nil
local burning = setmetatable({}, { __mode = "k" })

local heavenbuddies = { 3, 4 }
local hellbuddies = { 1, 2, 5 }

local function now()
	return masterclock:GetTime()
end

local function isnpc(model)
	return players:GetPlayerFromCharacter(model) == nil
end

local function rootof(model)
	return model and (model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart)
end

local function alive(model)
	local humanoid = model and model.Parent and model:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
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

local function freeze(model, duration)
	stun(model, duration)
	local root = rootof(model)
	if root and isnpc(model) and not root.Anchored then
		root.Anchored = true
		task.delay(duration, function()
			if root.Parent then
				root.Anchored = false
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

local function nearest(character, position, radius)
	local best, bestdistance = nil, math.huge
	for _, target in ipairs(hitbox.sphere(character, position, radius)) do
		local root = target.root
		if root and alive(target.model) then
			local distance = (root.Position - position).Magnitude
			if distance < bestdistance then
				best, bestdistance = target, distance
			end
		end
	end
	return best
end

local function hitfx(root, devil)
	kit:play("Spirit.Misc", { EffectID = devil and 4 or 5, HitRoot = root })
end

local function burn(model, humanoid, root)
	if burning[model] then
		return
	end
	burning[model] = true
	task.spawn(function()
		for _ = 1, data.x.burnticks do
			task.wait(0.5)
			if not alive(model) then
				break
			end
			kit:hit(humanoid, data.damage.xburn, root)
		end
		burning[model] = nil
	end)
end

local function blast(character, position, radius, amount, devil, after)
	local hits = hitbox.sphere(character, position, radius)
	for _, target in ipairs(hits) do
		if target.humanoid and alive(target.model) and kit:hit(target.humanoid, amount, target.root) then
			hitfx(target.root, devil)
			if after then
				after(target)
			end
		end
	end
	return hits
end

local function flyon(character, root, aim, range, lifetime)
	local target = kit:clamprange(root.Position, aim.target, range)
	if (target - root.Position).Magnitude < 1 then
		target = root.Position + aim.forward * 10
	end
	kit:play("Spirit.DevilAngel", {
		ActionID = 7,
		Root = root,
		Timestamp = now(),
		Lifetime = lifetime,
		StartCF = CFrame.lookAt(root.Position, target),
		Distance = (target - root.Position).Magnitude,
	})
end

local function despawnbuddy(entry)
	if buddies[entry.id] ~= entry then
		return
	end
	buddies[entry.id] = nil
	kit:play("Spirit.Buddies", { Index = entry.index, UniqueID = entry.id, ActionID = 2, CFrame = entry.cf })
end

local function buddyattack(entry, extra)
	local params = { Index = entry.index, UniqueID = entry.id, ActionID = 3, CFrame = entry.cf }
	for k, v in pairs(extra) do
		params[k] = v
	end
	kit:play("Spirit.Buddies", params)
end

local function runbuddy(entry, character, root)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local index = entry.index
	local position = entry.position

	local function active()
		return buddies[entry.id] == entry and os.clock() < entry.ends and character.Parent ~= nil and humanoid and humanoid.Health > 0
	end

	if index == 1 then
		kit:play("Spirit.Misc", { EffectID = 7, SpawnPosition = position, Lifetime = data.spirits.buddylife, Timestamp = entry.stamp })
		buddyattack(entry, {})
		while active() do
			blast(character, position, 22, data.damage.mushroom, true)
			task.wait(0.5)
		end
	elseif index == 2 then
		task.wait(0.6)
		while active() do
			local target = nearest(character, position, 45)
			if target then
				local troot = target.root
				buddyattack(entry, { TargetRootPart = troot })
				kit:play("Spirit.Misc", { EffectID = 6, SpawnPosition = position + Vector3.new(0, 3, 0), GoalPosition = troot.Position, Timestamp = now() })
				task.wait(0.25)
				if troot.Parent and alive(target.model) then
					local pull = position + (troot.Position - position).Unit * 6
					if isnpc(target.model) then
						troot.CFrame = CFrame.new(Vector3.new(pull.X, troot.Position.Y, pull.Z)) * troot.CFrame.Rotation
					end
					if kit:hit(target.humanoid, data.damage.frog, troot) then
						kit:play("Spirit.Misc", { EffectID = 1, HitRoot = troot, Frog = true })
						stun(target.model, 0.8)
					end
				end
				task.wait(1.75)
			else
				task.wait(0.4)
			end
		end
	elseif index == 3 then
		task.wait(1)
		while active() do
			buddyattack(entry, { HealedRoot = root, ActionDelay = 1, Timestamp = now() })
			task.wait(1)
			if active() then
				humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + humanoid.MaxHealth * data.spirits.heal)
			end
			task.wait(math.random(2, 5) - 1)
		end
	elseif index == 4 then
		task.wait(0.5)
		if active() then
			buddyattack(entry, { BoostedRoot = root, ActionDelay = 0.5, Timestamp = now() })
			task.wait(0.5)
			local base = humanoid.WalkSpeed
			local boosted = base * data.spirits.speed
			humanoid.WalkSpeed = boosted
			task.delay(data.spirits.speedtime, function()
				if humanoid.Parent and humanoid.WalkSpeed == boosted then
					humanoid.WalkSpeed = base
				end
			end)
		end
		while active() do
			task.wait(0.25)
		end
	elseif index == 5 then
		task.wait(0.8)
		while active() do
			local target = nearest(character, position, 60)
			if target then
				local troot = target.root
				buddyattack(entry, { TargetRootPart = troot })
				task.wait(0.5)
				if troot.Parent then
					local spot = kit:groundbelow(troot.Position, character)
					kit:play("Spirit.Misc", { EffectID = 2, SpawnPosition = spot })
					blast(character, spot, 10, data.damage.tree, true, function(hit)
						stun(hit.model, 1.5)
					end)
				end
				task.wait(2)
			else
				task.wait(0.4)
			end
		end
	end
	despawnbuddy(entry)
end

local function buddygroundoffset(index)
	local name = index == 1 and "Shroomy" or "Froggy"
	local folder = serverstorage:FindFirstChild("FX")
	local spirits = folder and folder:FindFirstChild("Spirit")
	local buddiesfolder = spirits and spirits:FindFirstChild("Buddies")
	local model = buddiesfolder and buddiesfolder:FindFirstChild(name)
	if not model or not model:IsA("Model") then
		return 1.5
	end
	local bounds, size = model:GetBoundingBox()
	local bottom = bounds.Position.Y - size.Y / 2
	return model:GetPivot().Position.Y - bottom + 0.1
end

local function summon(player, character, root)
	local state = passive
	if not state or state.character ~= character or state.souls.Value <= 0 then
		return
	end
	state.souls.Value -= 1
	local heaven = state.rage.Value <= 50
	local list = heaven and heavenbuddies or hellbuddies
	local index = list[math.random(#list)]
	local aim = kit:aim(root)
	local spot = kit:groundbelow(kit:clamprange(root.Position, aim.target, 60), character)
	local height = (index == 3 or index == 4) and 5 or 1.5
	if index == 1 or index == 2 then
		height = buddygroundoffset(index)
	end
	local position = spot + Vector3.new(0, height, 0)
	local face = Vector3.new(root.Position.X, position.Y, root.Position.Z)
	local cf = (face - position).Magnitude > 0.5 and CFrame.lookAt(position, face) or CFrame.new(position)
	buddycount += 1
	local entry = {
		id = tostring(player.UserId) .. "_" .. buddycount,
		index = index,
		cf = cf,
		position = position,
		stamp = now(),
		ends = os.clock() + data.spirits.buddylife,
	}
	buddies[entry.id] = entry
	kit:play("Spirit.Buddies", {
		Index = index,
		UniqueID = entry.id,
		ActionID = 1,
		CFrame = cf,
		Lifetime = data.spirits.buddylife,
		Timestamp = entry.stamp,
		InitialTarget = heaven and root or nil,
	})
	task.spawn(runbuddy, entry, character, root)
end

local function frostfire(character, root, aim)
	lastbuddy = "Shu"
	kit.busyuntil = os.clock() + data.z.flight + data.z.stuck
	kit:play("Spirit.Z", { Stage = 4, Root = root })
	flyon(character, root, aim, data.z.range, data.z.flight)
	task.delay(data.z.flight, function()
		if not character.Parent then
			return
		end
		local center = root.Position
		kit:play("Spirit.Z", { Stage = 1, Position = center })
		kit:play("Spirit.Z", { Stage = 2, Position = center, Timestamp = now(), StuckTime = data.z.stuck })
		local caught = {}
		for _, target in ipairs(hitbox.sphere(character, center, data.z.radius)) do
			if target.humanoid and alive(target.model) then
				table.insert(caught, target)
				freeze(target.model, data.z.stuck + 0.6)
			end
		end
		task.wait(data.z.stuck)
		local multiplier = 1 + data.damage.zmultitarget * math.max(0, #caught - 1)
		for _, target in ipairs(caught) do
			if alive(target.model) and kit:hit(target.humanoid, data.damage.zburst * multiplier, target.root) then
				hitfx(target.root, true)
				stun(target.model, 0.8)
			end
		end
	end)
end

local function wrathofra(character, root, aim, held)
	lastbuddy = "Ra"
	local distance = math.clamp(data.x.tap + held * 70, data.x.tap, data.x.held)
	local ground = kit:groundbelow(root.Position + aim.forward * distance, character)
	local origin = root.Position + Vector3.new(0, 3, 0)
	local length = (ground - origin).Magnitude
	local life = math.max(0.35, length * data.x.speed)
	kit.busyuntil = os.clock() + 0.4
	kit:play("Spirit.X", { Stage = 1, RootPart = root })
	kit:play("Spirit.DevilAngel", {
		ActionID = 6,
		Root = root,
		HoldValue = kit.effectholding,
		StartupTime = life,
		Timestamp = now(),
		Lifetime = life,
		Distance = length,
		StartCF = CFrame.lookAt(origin, ground),
	})
	task.delay(life, function()
		if not character.Parent then
			return
		end
		kit:play("Spirit.X", { Stage = 3, Position = ground, Life = 2, SizeMul = 1 })
		blast(character, ground, data.x.radius, data.damage.xpillar, true, function(target)
			stun(target.model, 1)
			burn(target.model, target.humanoid, target.root)
		end)
		for i = 1, 4 do
			local angle = math.rad(i * 90 + math.random(-25, 25))
			local spot = kit:groundbelow(ground + Vector3.new(math.cos(angle), 0, math.sin(angle)) * math.random(15, 30), character)
			kit:play("Spirit.X", { Stage = 4, StartPos = ground + Vector3.new(0, 10, 0), EndPos = spot, Life = 1, Timestamp = now() })
			task.delay(1, function()
				if character.Parent then
					blast(character, spot, data.x.meteorradius, data.damage.xmeteor, true, function(target)
						burn(target.model, target.humanoid, target.root)
					end)
				end
			end)
		end
	end)
end

local function wrathofshu(character, root, aim)
	lastbuddy = "Shu"
	kit.busyuntil = os.clock() + data.c.flight + 0.4
	flyon(character, root, aim, data.c.range, data.c.flight)
	task.delay(data.c.flight, function()
		if not character.Parent then
			return
		end
		local center = kit:groundbelow(root.Position, character) + Vector3.new(0, 2, 0)
		kit:play("Spirit.C", { Stage = 3, Position = center, Root = root, Dir = aim.forward })
		blast(character, center, data.c.radius, data.damage.cfreeze, false, function(target)
			freeze(target.model, data.c.freeze)
			kit:play("Spirit.C", { Stage = 4, Root = target.root, Duration = data.c.freeze, Timestamp = now() })
		end)
	end)
end

local function endoftimes(character, root)
	local aim = kit:aim(root)
	local origin = workspace:FindFirstChild("_WorldOrigin") or workspace
	local point = Instance.new("Part")
	point.Name = "spiritbeamend"
	point.Anchored = true
	point.CanCollide = false
	point.CanTouch = false
	point.CanQuery = false
	point.Transparency = 1
	point.Size = Vector3.one
	point.Position = kit:clamprange(root.Position, aim.target, 20)
	point.Parent = origin
	local current = { point = point, started = os.clock() }
	beam = current
	kit.busyuntil = os.clock() + kit.maxhold + 1
	kit:play("Spirit.V", { Stage = 1, Root = root })
	kit:play("Spirit.DevilAngel", {
		ActionID = 8,
		Root = root,
		HoldValue = kit.effectholding,
		EndPoint = point,
		WinddownTime = 0.5,
		Minimum = data.v.minimum,
		Duration = kit.maxhold,
		Timestamp = now(),
	})
	task.spawn(function()
		local lasttick = 0
		while beam == current and character.Parent and alive(character) do
			local elapsed = os.clock() - current.started
			if elapsed >= kit.maxhold or (elapsed >= data.v.minimum and not kit.effectholding.Value) then
				break
			end
			local goal = kit:clamprange(root.Position, kit.mousepos.Value, data.v.range)
			point.Position = point.Position:Lerp(goal, data.v.turn)
			if os.clock() - lasttick >= 0.25 then
				lasttick = os.clock()
				for _, target in ipairs(hitbox.line(character, root.Position, point.Position, data.v.beamradius)) do
					if target.humanoid and alive(target.model) and kit:hit(target.humanoid, data.damage.vbeam, target.root) then
						stun(target.model, 0.6)
					end
				end
			end
			task.wait(0.05)
		end
		if beam == current then
			beam = nil
		end
		kit.busyuntil = os.clock() + 0.6
		local center = point.Position
		task.delay(0.15, function()
			kit:play("Spirit.V", { Stage = 2, Position = center })
			task.wait(0.3)
			blast(character, center, data.v.explosionradius, data.damage.vexplosion, false, function(target)
				freeze(target.model, 2)
			end)
		end)
		task.delay(3, function()
			point:Destroy()
		end)
	end)
end

local function startflight(character, root)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local marker = Instance.new("Folder")
	marker.Name = "SpiritFlight"
	marker:SetAttribute("Speed", data.f.speed)
	marker.Parent = root
	flight = marker
	kit:play("Spirit.DevilAngel", {
		ActionID = lastbuddy == "Ra" and 5 or 4,
		Root = root,
		HoldValue = kit.effectholding,
		StartupTime = 0.3,
	})
end

local function endflight()
	if flight then
		flight:Destroy()
		flight = nil
	end
end

local function startpassive(player, character)
	local root = character:WaitForChild("HumanoidRootPart", 5)
	if not root or (passive and passive.character == character) then
		return
	end
	local rage = kit:ragevalue(character)
	rage.Value = 0
	local souls = character:FindFirstChild("Souls")
	if not souls then
		souls = Instance.new("IntValue")
		souls.Name = "Souls"
		souls.Parent = character
	end
	local state = { player = player, character = character, root = root, rage = rage, souls = souls }
	passive = state
	kit:play("Spirit.DevilAngel", { ActionID = 1, Root = root })
	task.spawn(function()
		local direction = 1
		local step = 0.05
		while passive == state and character.Parent do
			task.wait(step)
			rage.Value = math.clamp(rage.Value + direction * 100 * step / data.spirits.sweep, 0, 100)
			if (direction > 0 and rage.Value >= 100) or (direction < 0 and rage.Value <= 0) then
				direction = -direction
				souls.Value = math.min(data.spirits.max, souls.Value + 1)
			end
		end
	end)
end

local function endpassive(character)
	local state = passive
	if not state or state.character ~= character then
		return
	end
	passive = nil
	endflight()
	beam = nil
	for _, entry in pairs(buddies) do
		despawnbuddy(entry)
	end
	kit:play("Spirit.DevilAngel", { ActionID = 2, Root = state.root })
	if state.rage.Parent then
		state.rage.Value = 0
	end
	if state.souls.Parent then
		state.souls:Destroy()
	end
end

players.PlayerAdded:Connect(function()
	task.wait(6)
	if passive and passive.root.Parent then
		kit:play("Spirit.DevilAngel", { ActionID = 1, Root = passive.root })
	end
end)

kit = fruitkit.new(tool, {
	holdkeys = { X = true, C = true, V = true, F = true },
	maxhold = 6,
	canhold = function(_, character, _, key)
		return spend(character, data.Cost[key])
	end,
	onholdstart = function(_, character, root, key)
		holdstarted[key] = os.clock()
		if key == "C" then
			lastbuddy = "Shu"
			kit:play("Spirit.C", { Stage = 1, Root = root, Humanoid = character:FindFirstChildOfClass("Humanoid"), HoldValue = kit.effectholding, ChargeTime = 0 })
			kit:play("Spirit.DevilAngel", { ActionID = 4, Root = root, HoldValue = kit.effectholding, StartupTime = 0.3 })
		elseif key == "V" then
			endoftimes(character, root)
		elseif key == "F" then
			startflight(character, root)
		end
	end,
	onrelease = function(_, character, root, key, aim)
		local held = os.clock() - (holdstarted[key] or os.clock())
		if key == "X" then
			wrathofra(character, root, aim, held)
		elseif key == "C" then
			wrathofshu(character, root, aim)
		elseif key == "F" then
			endflight()
		end
	end,
	onm1 = function(player, character, root)
		summon(player, character, root)
	end,
	onkey = function(_, character, root, _, key)
		if key ~= "Z" or not kit:canuse(character, key) or not spend(character, data.Cost.Z) then
			return
		end
		kit.lastused.Z = os.clock()
		frostfire(character, root, kit:aim(root))
	end,
	onunequip = function()
		endflight()
	end,
	onpassivestart = function(player, character)
		task.spawn(startpassive, player, character)
	end,
	onpassiveend = function(character)
		endpassive(character)
	end,
})
