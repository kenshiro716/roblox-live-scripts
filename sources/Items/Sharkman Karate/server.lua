local serverstorage = game:GetService("ServerStorage")
local runservice = game:GetService("RunService")
local debris = game:GetService("Debris")

local fruitkit = require(serverstorage:WaitForChild("fruitkit"))
local meleekit = require(serverstorage:WaitForChild("meleekit"))
local hitbox = require(serverstorage:WaitForChild("hitbox"))

local tool = script.Parent
local data = require(tool:WaitForChild("Data"))
local kit
local holdstarted = {}
local guard = 0
local guardconnection
local lasthealth

local function marker(class, name, parent, lifetime)
	local value = Instance.new(class)
	value.Name = name
	value.Parent = parent
	debris:AddItem(value, lifetime or 6)
	return value
end

local function watchguard(character)
	if guardconnection then
		guardconnection:Disconnect()
		guardconnection = nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	lasthealth = humanoid.Health
	guardconnection = humanoid.HealthChanged:Connect(function(health)
		local loss = (lasthealth or health) - health
		lasthealth = health
		if loss <= 0 or health <= 0 or guard <= 0 then
			return
		end
		humanoid.Health = math.min(humanoid.MaxHealth, health + loss * guard)
		lasthealth = humanoid.Health
	end)
end

local function setguard(character, amount, duration)
	guard = amount
	watchguard(character)
	if duration then
		task.delay(duration, function()
			if guard == amount then
				guard = 0
			end
		end)
	end
end

local function palms(character, root, aim)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local direction = aim.forward
	local state = marker("Configuration", "sharkmanzstate", root, 4)
	local duration = data.Palms.Range / data.Palms.Speed
	kit.busyuntil = os.clock() + duration + 1.4
	root.CFrame = CFrame.lookAt(root.Position, root.Position + direction)
	kit:play("Sharkman2.Z", {
		Character = character,
		Humanoid = humanoid,
		CFrame = root.CFrame,
		Duration = duration,
		Distance = data.Palms.Range,
		State = state,
	})
	local target = meleekit.dash(character, root, direction, data.Palms.Speed, duration, data.Palms.Radius)
	if not target or not root.Parent then
		state:SetAttribute("State", 0)
		return
	end
	local release = meleekit.hold(target, nil, 1.2)
	meleekit.stun(target.model, 1.3)
	state:SetAttribute("State", 1)
	local started = os.clock()
	while os.clock() - started < data.Palms.Barrage and root.Parent and meleekit.alive(target.model) do
		local look = (target.root.Position - root.Position) * Vector3.new(1, 0, 1)
		if look.Magnitude < 0.1 then
			look = direction
		end
		local nextpos = target.root.Position - look.Unit * 4 + Vector3.new(math.random(-15, 15) / 10, 0, math.random(-15, 15) / 10)
		state:SetAttribute("NextPos", nextpos)
		state:SetAttribute("MousePos", aim.target)
		kit:hit(target.humanoid, data.Damage.ZPalm, target.root)
		task.wait(data.Palms.Tick)
	end
	state:SetAttribute("State", 2)
	release()
	if meleekit.alive(target.model) then
		kit:hit(target.humanoid, data.Damage.Z, target.root)
		meleekit.push(target.root, direction, 60, 20)
	end
end

local function vortex(character, root, aim, held)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local direction = (aim.target - root.Position).Unit
	if direction ~= direction then
		direction = aim.forward
	end
	local proxy = marker("BoolValue", "sharkmanxproxy", root, 5)
	proxy.Value = true
	local position = root.Position + direction * 5
	proxy:SetAttribute("ServerPosition", position)
	kit.busyuntil = os.clock() + 0.5
	kit:play("Sharkman2.X", {
		Character = character,
		Humanoid = humanoid,
		Stage = 1,
		Holding = kit.effectholding,
		HeldProxy = proxy,
		Duration = data.Vortex.Duration,
	})
	local started = os.clock()
	local target
	while os.clock() - started < data.Vortex.Duration and root.Parent do
		local dt = runservice.Heartbeat:Wait()
		local nextposition = position + direction * data.Vortex.Speed * dt
		local blocked = workspace:Raycast(position, nextposition - position, meleekit.rayparams(character))
		target = meleekit.firstline(character, position, nextposition, data.Vortex.Radius)
		position = blocked and blocked.Position or nextposition
		proxy:SetAttribute("ServerPosition", position)
		if target or blocked then
			break
		end
	end
	proxy.Value = false
	proxy:Destroy()
	if not target then
		kit:play("Sharkman2.X", { Character = character, Humanoid = humanoid, Stage = 2, CFrame = CFrame.new(position) })
		meleekit.area(kit, character, position, data.Vortex.ExplosionRadius, data.Damage.X * 0.5, { stun = 0.4 })
		return
	end
	meleekit.stun(target.model, 1.2)
	if held >= data.Vortex.HoldThreshold and target.root then
		local grab = marker("CFrameValue", "sharkmanxgrab", root, data.Vortex.MaxHold + 1)
		grab.Value = target.root.CFrame
		grab:SetAttribute("ServerCFrame", target.root.CFrame)
		kit:play("Sharkman2.X", {
			Character = character,
			Humanoid = humanoid,
			Stage = 3,
			CFrame = target.root.CFrame,
			VictimRoot = target.root,
			GrabProxy = grab,
			MaxHold = data.Vortex.MaxHold,
			MousePos = kit.mousepos.Value,
		})
		local release = meleekit.hold(target, nil, data.Vortex.MaxHold)
		meleekit.stun(target.model, data.Vortex.MaxHold + 0.5)
		local grabbed = os.clock()
		local current = target.root.Position
		while os.clock() - grabbed < data.Vortex.MaxHold and root.Parent and meleekit.alive(target.model) do
			local dt = runservice.Heartbeat:Wait()
			local goal = kit:clamprange(root.Position, kit.mousepos.Value, data.Vortex.ControlRange) + Vector3.new(0, 3, 0)
			current = current:Lerp(goal, math.clamp(dt * 6, 0, 1))
			local cframe = CFrame.new(current)
			grab:SetAttribute("ServerCFrame", cframe)
			if meleekit.isnpc(target.model) and target.root.Parent then
				target.root.CFrame = cframe
			end
		end
		grab:Destroy()
		release()
	else
		kit:play("Sharkman2.X", {
			Character = character,
			Humanoid = humanoid,
			Stage = 2,
			CFrame = target.root.CFrame,
			VictimRoot = target.root,
		})
		local release = meleekit.hold(target, nil, 1)
		task.wait(1)
		release()
	end
	if target.root and target.root.Parent then
		position = target.root.Position
	end
	meleekit.area(kit, character, position, data.Vortex.ExplosionRadius, data.Damage.X, { stun = 0.5, lift = 30 })
end

local function spear(player, character, root, aim, held)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local direction = aim.forward
	local cframe = CFrame.lookAt(root.Position, root.Position + direction)
	root.CFrame = cframe
	guard = 0
	kit.busyuntil = os.clock() + 2
	kit:play("Sharkman2.C", { Character = character, Humanoid = humanoid, Player = player, Stage = 1, CFrame = cframe })
	if held >= data.Spear.HoldThreshold then
		kit:play("Sharkman2.C", { Character = character, Humanoid = humanoid, Player = player, Stage = 3, CFrame = cframe })
		setguard(character, data.Spear.AfterGuard, data.Spear.AfterGuardTime)
	end
	task.wait(0.3)
	local victims = {}
	local roots = {}
	for _, target in ipairs(hitbox.line(character, root.Position, root.Position + direction * data.Spear.Range, data.Spear.Radius)) do
		if target.root and meleekit.alive(target.model) and not victims[target.model] then
			victims[target.model] = target
			table.insert(roots, target.root)
			meleekit.stun(target.model, 1.8)
		end
	end
	if #roots == 0 then
		kit.busyuntil = os.clock() + 0.5
		return
	end
	local releases = {}
	local index = 0
	for _, target in pairs(victims) do
		index += 1
		local spot = root.CFrame * CFrame.new((index - 1) * 2 - (#roots - 1), 0, -4)
		table.insert(releases, meleekit.hold(target, CFrame.lookAt(spot.Position, root.Position), 1.6))
	end
	task.wait(0.25)
	kit:play("Sharkman2.C", {
		Character = character,
		Humanoid = humanoid,
		Player = player,
		Stage = 2,
		CFrame = root.CFrame,
		VictimRoots = roots,
		Timestamp = workspace:GetServerTimeNow(),
	})
	local started = os.clock()
	while os.clock() - started < data.Spear.Barrage and root.Parent do
		for _, target in pairs(victims) do
			if meleekit.alive(target.model) then
				kit:hit(target.humanoid, data.Damage.CBarrage, target.root)
			end
		end
		task.wait(data.Spear.Tick)
	end
	for _, release in ipairs(releases) do
		release()
	end
	for _, target in pairs(victims) do
		if meleekit.alive(target.model) then
			kit:hit(target.humanoid, data.Damage.C, target.root)
			meleekit.push(target.root, direction, 90, 25)
		end
	end
end

kit = fruitkit.new(tool, {
	holdkeys = { X = true, C = true },
	maxhold = 3,
	canhold = function(_, character, _, key)
		return meleekit.spend(character, data.Cost[key])
	end,
	onholdstart = function(player, character, root, key)
		holdstarted[key] = os.clock()
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if key == "C" then
			setguard(character, data.Spear.HoldGuard)
			kit:play("Sharkman2.C", { Character = character, Humanoid = humanoid, Player = player, Holding = kit.effectholding })
		end
	end,
	onrelease = function(player, character, root, key, aim)
		local held = meleekit.heldfor(holdstarted[key])
		holdstarted[key] = nil
		if key == "X" then
			vortex(character, root, aim, held)
		elseif key == "C" then
			spear(player, character, root, aim, held)
		end
	end,
	onkey = function(_, character, root, _, key)
		if key ~= "Z" or not kit:canuse(character, key) or not meleekit.spend(character, data.Cost.Z) then
			return
		end
		kit.lastused.Z = os.clock()
		local aim = kit:aim(root)
		task.wait(data.Palms.Windup)
		if root.Parent then
			palms(character, root, aim)
		end
	end,
	onunequip = function()
		guard = 0
	end,
})

