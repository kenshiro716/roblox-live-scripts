local players = game:GetService("Players")
local replicatedstorage = game:GetService("ReplicatedStorage")
local serverstorage = game:GetService("ServerStorage")
local runservice = game:GetService("RunService")

local fruitkit = require(serverstorage:WaitForChild("fruitkit"))
local util = require(replicatedstorage:WaitForChild("Util"))
local masterclock = util.MasterClock

local tool = script.Parent
local data = require(tool:WaitForChild("Data"))

local basecooldown = table.clone(data.Cooldown)

local kit
local form = "base"
local formbefore = "base"
local combo, lastm1 = 0, 0
local hold = nil
local healthconnection, lasthealth = nil, nil
local soar = nil
local dragon = nil

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
	local hits = {}
	enemiesnear(character, position, radius, function(model, humanoid, root)
		if kit:hit(humanoid, amount, root) then
			table.insert(hits, model)
			if stunfor then
				stun(model, stunfor)
			end
		end
	end)
	return hits
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

local function worldparams(character)
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

local function worldhit(character, from, to)
	local result = workspace:Raycast(from, to - from, worldparams(character))
	if result then
		return result.Position, result.Normal, result.Instance
	end
	return to, Vector3.yAxis, nil
end

local function burn(model, ticks, amount)
	task.spawn(function()
		for _ = 1, ticks do
			task.wait(1)
			local humanoid = model.Parent and model:FindFirstChildOfClass("Humanoid")
			if not humanoid or humanoid.Health <= 0 then
				return
			end
			kit:hit(humanoid, amount, rootof(model))
		end
	end)
end

local function base(player, root, extra)
	local params = { player = player, Player = player, Root = root, hrp = root }
	for k, v in pairs(extra or {}) do
		params[k] = v
	end
	return params
end

local function dragontype(player)
	local fruit = player and player:FindFirstChild("Data") and player.Data:FindFirstChild("DevilFruit")
	local value = fruit and fruit:GetAttribute("DragonType")
	if value ~= "East" and value ~= "West" then
		value = tool:GetAttribute("DragonType")
	end
	if value ~= "East" and value ~= "West" then
		value = "West"
	end
	if fruit and fruit:GetAttribute("DragonType") ~= value then
		fruit:SetAttribute("DragonType", value)
	end
	return value
end

local function rage()
	return kit:ragevalue()
end

local function setrage(amount)
	local value = rage()
	if value then
		value.Value = math.clamp(amount, 0, 100)
	end
end

local function addrage(amount)
	local value = rage()
	if value then
		setrage(value.Value + amount)
	end
end

local function ishybrid()
	return form == "hybrid"
end

local function hybridscale(a, b)
	return ishybrid() and b or a
end

local function aimcframe(root)
	local aim = kit:aim(root)
	return CFrame.lookAt(root.Position, aim.target), aim
end

local function forcerelease(token, after)
	task.delay(after, function()
		if hold == token and kit.active and kit.active.key == token.key then
			kit:release(token.player, token.character, token.root, token.key)
		end
	end)
end

local hybridstowed = false

local function sethybrid(character, root, player, enabled)
	local existing = character:FindFirstChild("DragonHybrid")
	if enabled then
		if not existing then
			local folder = Instance.new("Folder")
			folder.Name = "DragonHybrid"
			folder:SetAttribute("Scaler", 1)
			folder.Parent = character
		end
		kit:play("Dragon2.Hybrid.Transform", { ID = 1, Root = root, player = player })
		kit:play("Dragon2.Hybrid.State", { ID = 1, Character = character, Scaler = 1, player = player })
		form = "hybrid"
	else
		if existing then
			existing:Destroy()
		end
		kit:play("Dragon2.Hybrid.Untransform", { ID = 1, Root = root, player = player })
		kit:play("Dragon2.Hybrid.State", { ID = 2, Character = character, player = player })
		form = "base"
	end
end

local function m1(player, character, root)
	if os.clock() - lastm1 > data.m1.reset then
		combo = 0
	end
	lastm1 = os.clock()
	local maxcombo = hybridscale(data.m1.combo, data.m1.hybridcombo)
	combo = combo % maxcombo + 1
	local facing = CFrame.lookAt(root.Position, root.Position + root.CFrame.LookVector)
	kit:play("Dragon2.M1", base(player, root, {
		Combo = combo,
		MaxCombo = maxcombo,
		Hybrid = ishybrid(),
		CFrame = facing,
	}))
	local range = hybridscale(data.m1.range, data.m1.hybridrange)
	local radius = hybridscale(data.m1.radius, data.m1.hybridradius)
	local amount = hybridscale(data.damage.m1, data.damage.m1hybrid) * (combo == maxcombo and 1.4 or 1)
	task.delay(0.12, function()
		if not root.Parent then
			return
		end
		local center = root.Position + root.CFrame.LookVector * range
		for _, model in ipairs(blast(character, center, radius, amount, 0.35)) do
			if ishybrid() then
				burn(model, 1, amount * 0.25)
			end
		end
	end)
	if combo == maxcombo then
		kit.busyuntil = os.clock() + 0.45
	end
end

local function zstart(token)
	local player, character, root = token.player, token.character, token.root
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	token.zstart = masterclock:GetTime()
	token.zclock = os.clock()
	kit:play("Dragon2.Z", {
		player = player,
		ID = 1,
		Head = character:FindFirstChild("Head"),
		HoldValue = kit.effectholding,
		Humanoid = humanoid,
		Start = token.zstart,
		Charge = data.z.charge,
		WindUp = data.z.windup,
		Offset = CFrame.new(0, 0, -1.5),
		Hybrid = ishybrid(),
		SuperCharge = false,
	})
	forcerelease(token, data.z.maxhold)
end

local function zfire(token, aim)
	local player, character, root = token.player, token.character, token.root
	local head = character:FindFirstChild("Head") or root
	local held = math.clamp((os.clock() - (token.zclock or os.clock())) / data.z.charge, 0, 1)
	local range = hybridscale(data.z.range, data.z.hybridrange) * (1 + (data.z.heldrange - 1) * held)
	local origin = head.Position
	local target = kit:clamprange(origin, aim.target, range)
	if (target - origin).Magnitude < 1 then
		target = origin + root.CFrame.LookVector * range
	end
	local direction = (target - origin).Unit
	local hitpos, normal, instance = worldhit(character, origin, origin + direction * range)
	local victim = kit:firstalong(character, origin, hitpos, data.z.beamradius)
	local explosion = victim and victim.Position or hitpos
	local life = data.z.life
	kit:play("Dragon2.Z", {
		player = player,
		ID = 2,
		Head = head,
		Character = character,
		CFrame = head.CFrame,
		ExplosionPosition = explosion,
		Offset = CFrame.new(0, 0, -1.5),
		Scale = hybridscale(1, 1.6) + held,
		chargeTime = held,
		SpawnTime = masterclock:GetTime(),
		Life = life,
		Distance = range,
		RayData = { Hit = victim or instance, Norm = normal },
		SuperCharge = held >= 1 and 1 or nil,
		Hybrid = ishybrid(),
	})
	kit.busyuntil = os.clock() + 0.5
	local amount = data.damage.z + (data.damage.zheld - data.damage.z) * held
	local travel = (explosion - origin).Magnitude / math.max(range, 1) * life
	task.delay(travel, function()
		kit:damagealong(character, origin, explosion, data.z.beamradius, amount * 0.25)
		local radius = hybridscale(data.z.radius, data.z.hybridradius) * (1 + held * 0.4)
		for _, model in ipairs(blast(character, explosion, radius, amount * 0.75, 0.8)) do
			local victimroot = rootof(model)
			if victimroot and isnpc(model) and not victimroot.Anchored then
				victimroot.AssemblyLinearVelocity = (victimroot.Position - explosion).Unit * 60 + Vector3.new(0, 30, 0)
			end
		end
	end)
	addrage(-data.fury.z)
end

local function xstart(token)
	local player, character = token.player, token.character
	kit:play("Dragon2.X", {
		player = player,
		ID = 1,
		Character = character,
		HoldValue = kit.effectholding,
		ChargeTime = data.x.charge,
	})
	forcerelease(token, data.x.maxhold)
end

local function xthrow(player, character, root, victimmodel, aim)
	local victimroot = rootof(victimmodel)
	local victimhumanoid = victimmodel:FindFirstChildOfClass("Humanoid")
	if not victimroot or not victimhumanoid then
		return
	end
	local origin = victimroot.Position
	local target = kit:clamprange(origin, aim.target, data.x.throwrange)
	local hitpos, normal = worldhit(character, origin, origin + (target - origin).Unit * data.x.throwrange)
	if (target - origin).Magnitude < 1 then
		hitpos, normal = worldhit(character, origin, origin + root.CFrame.LookVector * data.x.throwrange)
	end
	local landing = hitpos + normal * 3
	kit:play("Dragon2.X", {
		player = player,
		Player = player,
		ID = 4,
		Hit = true,
		Pos = landing,
		Norm = normal,
		Origin = origin,
		Root = victimroot,
		FlightDuration = data.x.flight,
		Hybrid = ishybrid(),
	})
	local rotation = victimroot.CFrame.Rotation
	drivenpc(victimroot, data.x.flight, function(alpha)
		return rotation + origin:Lerp(landing, alpha)
	end, function()
		local amount = data.damage.ximpact * (ishybrid() and 1.2 or 1)
		kit:hit(victimhumanoid, amount, victimroot)
		blast(character, landing, data.x.impactradius, amount * 0.35, 0.6)
		stun(victimmodel, 1.2)
		burn(victimmodel, 2, data.damage.xburn)
	end)
end

local function xdash(token, aim)
	local player, character, root = token.player, token.character, token.root
	local look = CFrame.lookAt(root.Position, aim.target)
	local duration = hybridscale(data.x.duration, data.x.hybridduration)
	local speed = hybridscale(data.x.speed, data.x.hybridspeed)
	local started = workspace:GetServerTimeNow()
	kit:play("Dragon2.X", {
		player = player,
		ID = 2,
		Character = character,
		Time = started,
		Look = look,
		Duration = duration,
		DashSpeed = speed,
		Height = data.x.height,
		Hybrid = ishybrid(),
	})
	kit.busyuntil = os.clock() + duration + 0.3
	addrage(-data.fury.x)
	local radius = hybridscale(data.x.radius, data.x.hybridradius)
	task.spawn(function()
		local stop = os.clock() + duration + 0.15
		local last = root.Position
		while os.clock() < stop and root.Parent do
			local now = root.Position
			local victim = kit:firstalong(character, last, now + look.LookVector * 3, radius)
			last = now
			if victim then
				local model = victim.Parent
				local humanoid = model:FindFirstChildOfClass("Humanoid")
				if humanoid and kit:hit(humanoid, data.damage.xgrab, victim) then
					stun(model, data.x.drag + data.x.throwdelay + data.x.flight + 0.4)
					kit:play("Dragon2.X", {
						player = player,
						ID = 3,
						Character = character,
						VictimCharacter = model,
						Time = workspace:GetServerTimeNow(),
						Duration = data.x.drag,
						ThrowDelay = data.x.throwdelay,
						CaughtPos = victim.Position,
						UserLook = root.CFrame.LookVector,
						UserMouse = kit.mousepos,
						DashSpeed = speed,
						Hybrid = ishybrid(),
					})
					kit.busyuntil = os.clock() + data.x.drag + data.x.throwdelay + 0.3
					drivenpc(victim, data.x.drag + data.x.throwdelay, function()
						return root.CFrame * CFrame.new(0, 0, -4)
					end, function()
						xthrow(player, character, root, model, kit:aim(root))
					end)
					return
				end
			end
			task.wait()
		end
	end)
end

local function cstart(token)
	local player, character, root = token.player, token.character, token.root
	kit:play("Dragon2.C", { ID = 1, player = player, Position = root.Position, Root = root, Hybrid = ishybrid() })
	addrage(-data.fury.c)
	local hybrid = ishybrid()
	task.delay(data.c.jump, function()
		if hold ~= token or not root.Parent then
			return
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local holdmax = hybrid and data.c.hybridholdmax or data.c.holdmax
		local life = data.c.life
		local deviation = hybrid and data.c.hybriddeviation or data.c.deviation
		local distance = math.clamp((kit.mousepos.Value - root.Position).Magnitude, 30, 160)
		kit:play("Dragon2.C", {
			ID = 2,
			player = player,
			Root = root,
			Holding = kit.effectholding,
			Mouse = kit.mousepos,
			Humanoid = humanoid,
			Timestamp = masterclock:GetTime(),
			Life = life,
			Dist = distance,
			Devi = deviation,
			Dely = 0,
			HoldMin = data.c.holdmin,
			HoldMax = holdmax,
			Hybrid = hybrid,
		})
		forcerelease(token, holdmax)
		local started = os.clock()
		local taken = {}
		local cap = data.damage.cfireball * (holdmax / (hybrid and data.c.hybridinterval or data.c.interval)) * data.c.capfraction * 0.35
		local spent = data.fury.c
		local maxspend = hybrid and data.fury.cmaxhybrid or data.fury.cmax
		local interval = hybrid and data.c.hybridinterval or data.c.interval
		local radius = hybrid and data.c.hybridradius or data.c.radius
		while root.Parent and os.clock() - started <= holdmax and (os.clock() - started < data.c.holdmin or kit.effectholding.Value) do
			local aimpos = kit.mousepos.Value
			local flat = (aimpos - root.Position)
			local direction = flat.Magnitude > 1 and flat.Unit or root.CFrame.LookVector
			local point = root.Position + direction * distance + Vector3.new((math.random() - 0.5) * 2 * deviation, 0, (math.random() - 0.5) * 2 * deviation)
			local impact = worldhit(character, point + Vector3.new(0, 40, 0), point - Vector3.new(0, 80, 0))
			task.delay(life, function()
				enemiesnear(character, impact, radius, function(model, victimhumanoid, victimroot)
					local dealt = taken[model] or 0
					local amount = data.damage.cfireball * (hybrid and 1.25 or 1)
					if dealt >= cap then
						amount *= data.c.reduced
					end
					if kit:hit(victimhumanoid, amount, victimroot) then
						taken[model] = dealt + amount
						stun(model, 0.4)
						if spent < maxspend then
							spent += data.fury.cperfireball
							addrage(-data.fury.cperfireball)
						end
					end
				end)
			end)
			task.wait(interval)
		end
		kit.busyuntil = os.clock() + 0.4
	end)
end

local function endsoar()
	local current = soar
	if not current then
		return
	end
	soar = nil
	if current.marker and current.marker.Parent then
		current.marker:Destroy()
	end
	if current.root and current.root.Parent then
		kit:play("Dragon2.Wings", { HRP = current.root, Enabled = false, player = current.player })
	end
end

local function soargrab(current, model, victimroot)
	local player, character, root = current.player, current.character, current.root
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	current.caught = true
	stun(model, data.f.carry + 0.8)
	local victimplayer = players:GetPlayerFromCharacter(model)
	kit:play("Dragon2.F", {
		Root = root,
		Player = player,
		Stage = 2,
		Caught = model,
		VictimPlayers = victimplayer and { victimplayer } or {},
		Iterations = data.f.iterations,
		Look = root.CFrame,
		Hybrid = ishybrid(),
	})
	local ticks = 5
	task.spawn(function()
		for _ = 1, ticks do
			if not model.Parent or humanoid.Health <= 0 then
				break
			end
			kit:hit(humanoid, data.damage.f, victimroot)
			task.wait(data.f.carry / ticks)
		end
		if model.Parent and humanoid.Health > 0 then
			kit:hit(humanoid, data.damage.fslash, victimroot)
			if isnpc(model) and not victimroot.Anchored then
				victimroot.AssemblyLinearVelocity = root.CFrame.LookVector * 80 + Vector3.new(0, -40, 0)
			end
		end
	end)
	drivenpc(victimroot, data.f.carry, function()
		return root.CFrame * CFrame.new(0, -1, -5)
	end)
end

local function fstart(token)
	local player, character, root = token.player, token.character, token.root
	endsoar()
	addrage(-data.fury.f)
	kit:play("Dragon2.F", { Root = root, Player = player, Stage = 0, Hybrid = ishybrid() })
	kit:play("Dragon2.Wings", { HRP = root, Enabled = true, player = player })
	local marker = Instance.new("BoolValue")
	marker.Name = "DragonSoar"
	marker:SetAttribute("Speed", data.f.speed * (ishybrid() and 1.1 or 1))
	marker:SetAttribute("DiveSpeed", data.f.divespeed * (ishybrid() and 1.1 or 1))
	marker.Parent = root
	local current = { player = player, character = character, root = root, marker = marker, started = os.clock(), token = token }
	soar = current
	task.delay(0.2, function()
		if soar ~= current or not root.Parent then
			return
		end
		kit:play("Dragon2.F", { Root = root, Player = player, Stage = 1, Look = root.CFrame, Hybrid = ishybrid() })
	end)
	forcerelease(token, data.f.maxhold)
	task.spawn(function()
		while soar == current and root.Parent do
			if not current.caught then
				local found = nil
				enemiesnear(character, root.Position + root.CFrame.LookVector * 3, data.f.grabradius, function(model, _, victimroot)
					if not found then
						found = { model, victimroot }
					end
				end)
				if found then
					soargrab(current, found[1], found[2])
				end
			end
			task.wait(0.05)
		end
	end)
end

local function basehold(player, character, root, key)
	local token = { key = key, player = player, character = character, root = root }
	hold = token
	if key == "Z" then
		zstart(token)
	elseif key == "X" then
		xstart(token)
	elseif key == "C" then
		cstart(token)
	elseif key == "F" then
		fstart(token)
	end
end

local function baserelease(player, character, root, key, aim)
	local token = hold
	hold = nil
	if not token or token.key ~= key then
		return
	end
	if key == "Z" then
		zfire(token, aim)
	elseif key == "X" then
		xdash(token, aim)
	elseif key == "C" then
		kit.busyuntil = os.clock() + 0.3
	elseif key == "F" then
		local current = soar
		task.delay(current and current.caught and 0.3 or 0.05, function()
			if soar == current then
				endsoar()
			end
		end)
	end
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
		local reduction = form == "dragon" and data.defense.dragon or (form == "hybrid" and data.defense.hybrid or 0)
		if reduction > 0 then
			humanoid.Health = math.min(humanoid.MaxHealth, health + loss * reduction)
			lasthealth = humanoid.Health
		end
	end)
end

local function setcooldowns(kind)
	local source = kind and data.TransformedCooldown[kind] or basecooldown
	for key, value in pairs(source) do
		data.Cooldown[key] = value
	end
end

local dragonmodule = script:FindFirstChild("dragonform") and require(script.dragonform) or nil

local function imperial(player, character, root, humanoid)
	local value = rage()
	local fury = value and value.Value or 0
	if form == "dragon" then
		if dragonmodule then
			dragonmodule.untransform(false)
		end
		return
	end
	if fury >= data.fury.dragonneed and dragonmodule then
		formbefore = form
		if dragonmodule.transform(player, character, root, humanoid, dragontype(player)) then
			addrage(-data.fury.dragoncost)
		end
		return
	end
	if form == "hybrid" then
		sethybrid(character, root, player, false)
		return
	end
	if fury >= data.fury.hybridneed then
		sethybrid(character, root, player, true)
		addrage(-data.fury.hybridcost)
	end
end

kit = fruitkit.new(tool, {
	holdkeys = { Z = true, X = true, C = true, F = true },
	maxhold = 8,
	canhold = function(player, character, root, key)
		if form == "dragon" then
			return dragonmodule ~= nil and dragonmodule.canhold(key)
		end
		return spend(character, data.Cost[key])
	end,
	onholdstart = function(player, character, root, key)
		if form == "dragon" then
			dragonmodule.holdstart(player, character, root, key)
			return
		end
		basehold(player, character, root, key)
	end,
	onrelease = function(player, character, root, key, aim)
		if form == "dragon" then
			dragonmodule.release(player, character, root, key, aim)
			return
		end
		baserelease(player, character, root, key, aim)
	end,
	onm1 = function(player, character, root, humanoid)
		if form == "dragon" then
			dragonmodule.m1(player, character, root)
			return
		end
		m1(player, character, root)
	end,
	onkey = function(player, character, root, humanoid, key, argument)
		if key == "V" then
			if not kit:canuse(character, "V") or not spend(character, data.Cost.V) then
				return
			end
			kit.lastused.V = os.clock()
			imperial(player, character, root, humanoid)
		elseif key == "TAPEND" and form == "dragon" then
			dragonmodule.m1end()
		end
	end,
	onhit = function(amount)
		local gain = form == "dragon" and data.fury.dragongainperdamage or data.fury.gainperdamage
		addrage(amount * gain)
	end,
	onequip = function(player, character)
		dragontype(player)
		local root = rootof(character)
		if hybridstowed and root and form == "base" then
			hybridstowed = false
			sethybrid(character, root, player, true)
		end
		hybridstowed = false
	end,
	onunequip = function(owner)
		endsoar()
		hold = nil
		local character = owner and owner.Character
		local root = character and rootof(character)
		if form == "hybrid" and root then
			sethybrid(character, root, owner, false)
			hybridstowed = true
		end
	end,
	onpassivestart = function(player, character)
		dragontype(player)
		watchhealth(character)
		local value = kit:ragevalue(character)
		if value then
			value.Value = math.clamp(value.Value, 0, 100)
		end
	end,
	onpassiveend = function(character)
		endsoar()
		if dragonmodule and form == "dragon" then
			dragonmodule.untransform(true)
		end
		local root = rootof(character)
		if character:FindFirstChild("DragonHybrid") and root then
			sethybrid(character, root, players:GetPlayerFromCharacter(character), false)
		end
		hybridstowed = false
		form = "base"
		setcooldowns(nil)
		if healthconnection then
			healthconnection:Disconnect()
			healthconnection = nil
		end
	end,
})

if dragonmodule then
	dragonmodule.init({
		kit = kit,
		data = data,
		tool = tool,
		helpers = {
			isnpc = isnpc,
			rootof = rootof,
			enemyof = enemyof,
			stun = stun,
			spend = spend,
			enemiesnear = enemiesnear,
			blast = blast,
			drivenpc = drivenpc,
			worldhit = worldhit,
			burn = burn,
			addrage = addrage,
			setrage = setrage,
			rage = rage,
			sethybrid = sethybrid,
			setcooldowns = setcooldowns,
		},
		getform = function()
			return form
		end,
		setform = function(value)
			form = value
		end,
		getformbefore = function()
			return formbefore
		end,
	})
end

task.spawn(function()
	local step = 0.25
	while true do
		task.wait(step)
		local character = kit:getcharacter() or (kit.passivecharacter and kit.passivecharacter.Parent and kit.passivecharacter)
		local value = character and character:FindFirstChild("Rage")
		if value then
			if form == "base" and value.Value < data.fury.hybridneed then
				value.Value = math.min(data.fury.hybridneed, value.Value + data.fury.orangeregen * step)
			elseif form == "dragon" then
				value.Value = math.max(0, value.Value - data.fury.dragondrain * step)
				if value.Value <= 0 and dragonmodule then
					dragonmodule.untransform(false)
				end
			end
		end
		if soar and not soar.root.Parent then
			endsoar()
		end
	end
end)
