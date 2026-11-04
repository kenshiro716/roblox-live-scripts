local serverstorage = game:GetService("ServerStorage")
local debris = game:GetService("Debris")

local fruitkit = require(serverstorage:WaitForChild("fruitkit"))
local meleekit = require(serverstorage:WaitForChild("meleekit"))
local hitbox = require(serverstorage:WaitForChild("hitbox"))

local tool = script.Parent
local data = require(tool:WaitForChild("Data"))
local kit
local holdstarted = {}
local tick = 0

local function nexttick()
	tick += 1
	return tostring(tick) .. "_" .. tostring(math.random(1000, 9999))
end

local function rampagestart(character, root)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local started = os.clock()
	task.spawn(function()
		while root.Parent and humanoid.Health > 0 and kit.effectholding.Value and os.clock() - started < data.Rampage.MaxHold do
			kit:play("Electrov2.Z", { Arg = "ClawSlash", SlashOrigin = root, SizeMult = 1 })
			local center = root.Position + root.CFrame.LookVector * data.Rampage.Reach * 0.5
			for _, target in ipairs(hitbox.box(character, CFrame.lookAt(center, center + root.CFrame.LookVector), Vector3.new(9, 8, data.Rampage.Reach))) do
				if meleekit.alive(target.model) and kit:hit(target.humanoid, data.Damage.ZSlash, target.root) then
					meleekit.stun(target.model, 0.4)
				end
			end
			task.wait(data.Rampage.Tick)
		end
	end)
end

local function rampagedash(character, root, aim, held)
	local direction = aim.forward
	local distance = data.Rampage.Dash * (1 + math.clamp(held / data.Rampage.MaxHold, 0, 1))
	local endpoint, _, blocked = meleekit.impact(character, root.Position, direction, distance)
	if blocked then
		endpoint -= direction * 3
	end
	local oldpos = root.CFrame
	local newcf = CFrame.lookAt(endpoint, endpoint + direction)
	kit.busyuntil = os.clock() + 0.4
	root.CFrame = newcf
	kit:play("Electrov2.Z", {
		Arg = "Dash",
		PierceOrigin = root,
		PierceChar = character,
		oldPos = oldpos,
		newCF = newcf,
		StrikeDist = (endpoint - oldpos.Position).Magnitude,
		VanishMult = 1,
	})
	meleekit.along(kit, character, oldpos.Position, endpoint, data.Rampage.Radius, data.Damage.ZDash, { stun = 0.5, ignore = {} })
end

local function thrustcharge(root)
	kit:play("Electrov2.X", { Arg = "Charge", dashRef = root, FullLifetime = data.Thrust.MaxHold, Rate = 6, Lifetime = 0.3, Remove = false })
end

local function thrust(character, root, aim, held)
	kit:play("Electrov2.X", { Arg = "Charge", dashRef = root, Remove = true })
	local power = math.clamp(held / data.Thrust.MaxHold, 0, 1)
	local direction = aim.forward
	local range = data.Thrust.Range * (1 + power * 0.6)
	local duration = range / data.Thrust.Speed
	kit.busyuntil = os.clock() + duration + 0.4
	kit:play("Electrov2.X", { Arg = "Dash", dashRef = root, FullLifetime = duration, Rate = 6, Lifetime = 0.3 })
	local carried = {}
	meleekit.dash(character, root, direction, data.Thrust.Speed, duration, nil, function()
		for _, target in ipairs(hitbox.sphere(character, root.Position + direction * 3, data.Thrust.Radius)) do
			if meleekit.alive(target.model) and not carried[target.model] then
				carried[target.model] = target
				meleekit.stun(target.model, duration + 0.5)
			end
		end
		for _, target in pairs(carried) do
			if target.root and target.root.Parent and meleekit.isnpc(target.model) then
				target.root.CFrame = root.CFrame * CFrame.new(0, 0, -4)
			end
		end
	end)
	if not root.Parent then
		return
	end
	kit:play("Electrov2.X", { Arg = "Explosion", Ref = root, SizeMult = 1 + power * 0.5, mousePos = aim.target })
	meleekit.area(kit, character, root.Position + direction * 4, data.Thrust.ExplosionRadius, data.Damage.X, { stun = 0.5, push = 70, lift = 25 })
end

local function thunderclap(character, root, aim)
	local direction = aim.forward
	local target = meleekit.firstline(character, root.Position, root.Position + direction * data.Clap.Range, data.Clap.SearchRadius)
	kit.busyuntil = os.clock() + 1.6
	if not target then
		local endpoint, _, blocked = meleekit.impact(character, root.Position, direction, data.Clap.Range * 0.5)
		if blocked then
			endpoint -= direction * 3
		end
		local previous = root.CFrame
		root.CFrame = CFrame.lookAt(endpoint, endpoint + direction)
		kit:play("Electrov2.C", { Arg = "ZigZag", TrailRef = root, prevPos = previous, tTick = nexttick() })
		return
	end
	local grab = Instance.new("BoolValue")
	grab.Name = "electroclawgrab"
	grab.Parent = root
	debris:AddItem(grab, 2)
	local release = meleekit.hold(target, nil, 1.6)
	meleekit.stun(target.model, 1.6)
	task.spawn(function()
		for index = 1, data.Clap.Blinks do
			if not root.Parent or not meleekit.alive(target.model) then
				break
			end
			local previous = root.CFrame
			local angle = (index / data.Clap.Blinks) * math.pi * 2 + (index % 2) * math.pi
			local spot = target.root.Position + Vector3.new(math.cos(angle) * 8, 0, math.sin(angle) * 8)
			root.CFrame = CFrame.lookAt(spot, target.root.Position)
			kit:play("Electrov2.C", { Arg = "ZigZag", TrailRef = root, prevPos = previous, tTick = nexttick() })
			kit:hit(target.humanoid, data.Damage.CBlink, target.root)
			task.wait(data.Clap.BlinkTime)
		end
		if not root.Parent then
			release()
			return
		end
		kit:play("Electrov2.C", { Arg = "ElectroJump", jumpRef = root })
		task.wait(0.2)
		local hitcf = target.root and target.root.CFrame or root.CFrame
		kit:play("Electrov2.C", { Arg = "Strike", explosionRef = root, hitCf = hitcf, tTick = nexttick() })
		task.wait(0.15)
		kit:play("Electrov2.C", { Arg = "Explode", explosionRef = root, hitCf = hitcf })
		release()
		grab:Destroy()
		if meleekit.alive(target.model) then
			kit:hit(target.humanoid, data.Damage.C, target.root)
			meleekit.stun(target.model, 0.75)
			meleekit.push(target.root, Vector3.zero, 0, 60)
		end
		meleekit.area(kit, character, hitcf.Position, data.Clap.ExplosionRadius, data.Damage.C * 0.4, { exclude = target.model, stun = 0.5 })
	end)
end

kit = fruitkit.new(tool, {
	holdkeys = { Z = true, X = true },
	maxhold = 2,
	canhold = function(_, character, _, key)
		return meleekit.spend(character, data.Cost[key])
	end,
	onholdstart = function(_, character, root, key)
		holdstarted[key] = os.clock()
		if key == "Z" then
			rampagestart(character, root)
		elseif key == "X" then
			thrustcharge(root)
		end
	end,
	onrelease = function(_, character, root, key, aim)
		local held = meleekit.heldfor(holdstarted[key])
		holdstarted[key] = nil
		if key == "Z" then
			rampagedash(character, root, aim, held)
		elseif key == "X" then
			thrust(character, root, aim, held)
		end
	end,
	onkey = function(_, character, root, _, key)
		if key ~= "C" or not kit:canuse(character, key) or not meleekit.spend(character, data.Cost.C) then
			return
		end
		kit.lastused.C = os.clock()
		thunderclap(character, root, kit:aim(root))
	end,
})
