local serverstorage = game:GetService("ServerStorage")
local replicatedstorage = game:GetService("ReplicatedStorage")
local runservice = game:GetService("RunService")
local debris = game:GetService("Debris")

local fruitkit = require(serverstorage:WaitForChild("fruitkit"))
local meleekit = require(serverstorage:WaitForChild("meleekit"))
local hitbox = require(serverstorage:WaitForChild("hitbox"))

local tool = script.Parent
local data = require(tool:WaitForChild("Data"))
local anims = replicatedstorage:WaitForChild("Storage"):WaitForChild("Anims")
local kit
local holdstarted = {}
local markers = {}

local function playanim(character, name)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	local animation = anims:FindFirstChild(name, true)
	if not animator or not animation then
		return
	end
	local ok, track = pcall(animator.LoadAnimation, animator, animation)
	if ok then
		track.Priority = Enum.AnimationPriority.Action2
		track:Play()
	end
end

local function marker(class, name, parent, lifetime)
	local value = Instance.new(class)
	value.Name = name
	value.Parent = parent
	debris:AddItem(value, lifetime or 8)
	return value
end

local function clearmarker(key)
	if markers[key] then
		markers[key]:Destroy()
		markers[key] = nil
	end
end

local function talonlighter(character, root, aim, held)
	local power = math.clamp(held / data.Lighter.MaxHold, 0, 1)
	local range = data.Lighter.Range * (1 + power * data.Lighter.HoldRange)
	local duration = range / data.Lighter.Speed
	local direction = aim.forward
	local start = CFrame.lookAt(root.Position, root.Position + direction)
	root.CFrame = start
	kit.busyuntil = os.clock() + duration + 0.3
	kit:play("DragonTalon.Z", {
		stage = 1,
		Character = character,
		Root = root,
		origin = root.Position,
		StartCFrame = start,
		DashSpeed = duration,
		DashRange = range,
	})
	local target = meleekit.dash(character, root, direction, data.Lighter.Speed, duration, data.Lighter.Radius)
	if not target or not root.Parent then
		return
	end
	local total = data.Damage.ZBurn * data.Lighter.Ticks + data.Damage.Z
	local finisher = target.humanoid.Health <= total
	kit.busyuntil = os.clock() + (finisher and 3 or 2.2)
	local grabcf = root.CFrame * CFrame.new(0, 0, -3.5)
	local release = meleekit.hold(target, CFrame.lookAt(grabcf.Position, root.Position), finisher and 3 or 2.2)
	meleekit.stun(target.model, finisher and 3 or 2.2)
	local anchored = root.Anchored
	root.Anchored = true
	kit:play("DragonTalon.Z", {
		stage = finisher and 3 or 2,
		Character = character,
		Root = root,
		origin = root.Position,
		StartCFrame = root.CFrame,
		GrabTarget = target.root,
		CFrameGoal = target.root.CFrame,
	})
	playanim(character, finisher and "DTalon_ZExecute" or "DTalon_ZRegularHit")
	task.wait(0.5)
	for _ = 1, data.Lighter.Ticks do
		if not meleekit.alive(target.model) then
			break
		end
		kit:hit(target.humanoid, data.Damage.ZBurn, target.root)
		task.wait(data.Lighter.TickTime)
	end
	task.wait(finisher and 0.6 or 0.15)
	if root.Parent then
		root.Anchored = anchored
	end
	release()
	if meleekit.alive(target.model) then
		kit:hit(target.humanoid, data.Damage.Z, target.root)
		meleekit.push(target.root, direction, 90, 30)
	end
end

local function ember(character, root, aim)
	clearmarker("X")
	local direction = (aim.target - root.Position).Unit
	if direction ~= direction then
		direction = aim.forward
	end
	local start = CFrame.lookAt(root.Position + direction * 4, root.Position + direction * 5)
	local proxy = marker("CFrameValue", "dragontalonproxy", root, data.Ember.Duration + 2)
	proxy.Value = start
	local holding = marker("BoolValue", "dragontalonholding", root, data.Ember.Duration + 2)
	holding.Value = false
	kit.busyuntil = os.clock() + 0.5
	kit:play("DragonTalon.X", {
		Stage = 1,
		Character = character,
		Root = root,
		origin = root.Position,
		Proxy = proxy,
		Holding = holding,
		StartCFrame = start,
		Range = data.Ember.Range,
		Speed = data.Ember.Speed,
		Duration = data.Ember.Duration,
	})
	local carried = {}
	local position = start.Position
	local heading = direction
	local started = os.clock()
	local lasttick = 0
	local blocked
	while os.clock() - started < data.Ember.Duration and root.Parent do
		local dt = runservice.Heartbeat:Wait()
		local desired = (kit.mousepos.Value - position)
		if desired.Magnitude > 2 then
			heading = heading:Lerp(desired.Unit, math.clamp(dt * data.Ember.Turn, 0, 1)).Unit
		end
		local nextposition = position + heading * data.Ember.Speed * dt
		blocked = workspace:Raycast(position, nextposition - position, meleekit.rayparams(character))
		position = blocked and blocked.Position or nextposition
		proxy.Value = CFrame.lookAt(position, position + heading)
		for _, target in ipairs(hitbox.sphere(character, position, data.Ember.Radius)) do
			if target.root and meleekit.alive(target.model) and not carried[target.model] then
				carried[target.model] = target
				meleekit.stun(target.model, data.Ember.Duration)
			end
		end
		local ticking = os.clock() - lasttick >= data.Ember.TickTime
		if ticking then
			lasttick = os.clock()
		end
		for _, target in pairs(carried) do
			if meleekit.alive(target.model) then
				if meleekit.isnpc(target.model) and target.root.Parent then
					target.root.CFrame = CFrame.new(position + heading * 3)
					target.root.AssemblyLinearVelocity = Vector3.zero
				end
				if ticking then
					kit:hit(target.humanoid, data.Damage.XDrag, target.root)
				end
			end
		end
		if blocked or (position - root.Position).Magnitude > data.Ember.Range then
			break
		end
	end
	proxy:Destroy()
	holding:Destroy()
	local floor = blocked and { blocked.Position, blocked.Normal }
	if not floor then
		local ground = workspace:Raycast(position + Vector3.new(0, 2, 0), Vector3.new(0, -30, 0), meleekit.rayparams(character))
		floor = ground and { ground.Position, ground.Normal }
	end
	kit:play("DragonTalon.X", {
		Stage = 2,
		Character = character,
		origin = position,
		ExplosionCFrame = CFrame.new(position),
		FloorBurn = floor,
		BurnDuration = data.Ember.BurnTime,
	})
	meleekit.area(kit, character, position, data.Ember.ExplosionRadius, data.Damage.X, { stun = 0.5, push = 60, lift = 30 })
	if floor then
		local burnat = floor[1]
		task.spawn(function()
			local burnstarted = os.clock()
			while os.clock() - burnstarted < data.Ember.BurnTime do
				task.wait(data.Ember.BurnTick)
				if not character.Parent then
					break
				end
				meleekit.area(kit, character, burnat, data.Ember.BurnRadius, data.Damage.XBurn, {})
			end
		end)
	end
end

local function vortexrise(character, root)
	clearmarker("C")
	local top = root.CFrame + Vector3.new(0, data.Vortex.Height, 0)
	local ceiling = workspace:Raycast(root.Position, Vector3.new(0, data.Vortex.Height, 0), meleekit.rayparams(character))
	if ceiling then
		top = root.CFrame.Rotation + (ceiling.Position - Vector3.new(0, 4, 0))
	end
	local hover = Instance.new("BodyPosition")
	hover.Name = "dragontalonhover"
	hover.MaxForce = Vector3.one * 1e6
	hover.P = 20000
	hover.D = 800
	hover.Position = top.Position
	hover.Parent = root
	debris:AddItem(hover, data.Vortex.TimeOut + 1)
	markers.C = hover
	for _, target in ipairs(hitbox.sphere(character, root.Position, data.Vortex.StunRadius)) do
		if meleekit.alive(target.model) then
			meleekit.stun(target.model, 0.8)
		end
	end
	kit:play("DragonTalon.C", {
		Stage = 1,
		Character = character,
		Root = root,
		origin = root.Position,
		StartCFrame = root.CFrame,
		UpDistance = top.Position.Y - root.Position.Y,
		goalCF = top,
		Holding = kit.effectholding,
		TimeOut = data.Vortex.TimeOut,
	})
end

local function vortexdive(player, character, root, aim)
	local hover = markers.C
	markers.C = nil
	local top = root.CFrame
	local aimpoint = kit:clamprange(root.Position, aim.target, data.Vortex.Range)
	local ground = workspace:Raycast(aimpoint + Vector3.new(0, 4, 0), Vector3.new(0, -400, 0), meleekit.rayparams(character))
	if not ground then
		ground = workspace:Raycast(root.Position, Vector3.new(0, -400, 0), meleekit.rayparams(character))
	end
	local landing = ground and ground.Position + Vector3.new(0, 3, 0) or root.Position - Vector3.new(0, data.Vortex.Height, 0)
	local flat = (landing - root.Position) * Vector3.new(1, 0, 1)
	local land = flat.Magnitude > 0.1 and CFrame.lookAt(landing, landing + flat) or CFrame.new(landing) * root.CFrame.Rotation
	local timetoland = data.Vortex.TimeToLand
	kit.busyuntil = os.clock() + timetoland + 0.6
	if hover then
		hover.Position = landing
		hover.P = 8000
	end
	kit:play("DragonTalon.C", {
		Stage = 2,
		Character = character,
		Root = root,
		Player = player,
		origin = root.Position,
		StartCFrame = land,
		TopCFrame = top,
		TimeToLand = timetoland,
	})
	playanim(character, "DTalon_CDiveDown")
	task.wait(timetoland)
	if hover then
		hover:Destroy()
	end
	if not root.Parent then
		return
	end
	playanim(character, "DTalon_CLand")
	meleekit.area(kit, character, landing, data.Vortex.Radius, data.Damage.C, { stun = 0.6, push = 110, lift = 45 })
end

kit = fruitkit.new(tool, {
	holdkeys = { Z = true, X = true, C = true },
	maxhold = 2,
	canhold = function(_, character, _, key)
		return meleekit.spend(character, data.Cost[key])
	end,
	onholdstart = function(_, character, root, key)
		holdstarted[key] = os.clock()
		if key == "Z" then
			kit:play("DragonTalon.ZHold", { Root = root, origin = root.Position, Holding = kit.effectholding, Dur = data.Lighter.MaxHold })
		elseif key == "X" then
			clearmarker("X")
			local maid = marker("BoolValue", "dragontalonmaid", root, 4)
			markers.X = maid
			kit:play("DragonTalon.X", { Stage = 0, Character = character, Root = root, origin = root.Position, Maid = maid })
		elseif key == "C" then
			vortexrise(character, root)
		end
	end,
	onrelease = function(player, character, root, key, aim)
		local held = meleekit.heldfor(holdstarted[key])
		holdstarted[key] = nil
		if key == "Z" then
			talonlighter(character, root, aim, held)
		elseif key == "X" then
			ember(character, root, aim)
		elseif key == "C" then
			vortexdive(player, character, root, aim)
		end
	end,
	onunequip = function()
		clearmarker("X")
		clearmarker("C")
	end,
})
