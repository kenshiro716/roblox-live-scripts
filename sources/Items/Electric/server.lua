local serverstorage = game:GetService("ServerStorage")

local fruitkit = require(serverstorage:WaitForChild("fruitkit"))
local meleekit = require(serverstorage:WaitForChild("meleekit"))
local hitbox = require(serverstorage:WaitForChild("hitbox"))

local tool = script.Parent
local data = require(tool:WaitForChild("Data"))
local kit

local function stomp(player, character, root, humanoid)
	local move = humanoid.MoveDirection
	local direction = move.Magnitude > 0.1 and move.Unit or Vector3.zero
	kit.busyuntil = os.clock() + 0.9
	local lift = Instance.new("BodyVelocity")
	lift.Name = "electrostomp"
	lift.MaxForce = Vector3.one * 1e6
	lift.Velocity = Vector3.new(0, 55, 0) + direction * 12
	lift.Parent = root
	task.delay(0.25, function()
		lift.Velocity = direction * 6
	end)
	task.delay(0.45, function()
		lift.Velocity = Vector3.new(0, -140, 0) + direction * 20
	end)
	task.delay(0.6, function()
		lift:Destroy()
		if not root.Parent then
			return
		end
		root.AssemblyLinearVelocity = Vector3.zero
		local landing = meleekit.ground(character, root.Position)
		kit:play("Electro.ElectroZ", { Player = player, Pos = landing })
		task.wait(0.5)
		meleekit.area(kit, character, landing, data.Stomp.Radius, data.Damage.Z, { stun = 0.6, push = 10, lift = 45 })
	end)
end

local function tackle(player, character, root, aim)
	local direction = aim.target - root.Position
	direction = direction.Magnitude > 1 and direction.Unit or root.CFrame.LookVector
	local target = root.Position + direction * data.Tackle.Range
	target = meleekit.impact(character, root.Position, direction, data.Tackle.Range)
	kit.busyuntil = os.clock() + 0.6
	kit:play("Electro.ElectroX", { Player = player, MousePos = target })
	local hit = {}
	meleekit.dash(character, root, direction, data.Tackle.Range / data.Tackle.Duration, data.Tackle.Duration, nil, function()
		for _, victim in ipairs(hitbox.sphere(character, root.Position, data.Tackle.Radius)) do
			if not hit[victim.model] and meleekit.alive(victim.model) then
				hit[victim.model] = true
				if kit:hit(victim.humanoid, data.Damage.X, victim.root) then
					meleekit.stun(victim.model, 0.5)
				end
			end
		end
	end)
end

local function floor(player, character, root)
	kit.busyuntil = os.clock() + 1.9
	kit:play("Electro.ElectroC", { Player = player })
	local anchor = root.Anchored
	root.Anchored = true
	task.spawn(function()
		task.wait(0.25)
		local started = os.clock()
		while os.clock() - started < data.Floor.Duration and root.Parent do
			local center = root.Position + root.CFrame.LookVector * data.Floor.Reach * 0.5
			local cframe = CFrame.lookAt(center, center + root.CFrame.LookVector)
			for _, target in ipairs(hitbox.box(character, cframe, Vector3.new(data.Floor.Width, 8, data.Floor.Reach))) do
				if meleekit.alive(target.model) and kit:hit(target.humanoid, data.Damage.C, target.root) then
					meleekit.stun(target.model, data.Floor.Tick + 0.3)
				end
			end
			task.wait(data.Floor.Tick)
		end
		if root.Parent then
			root.Anchored = anchor
		end
	end)
end

kit = fruitkit.new(tool, {
	holdkeys = {},
	onkey = function(player, character, root, humanoid, key)
		if not kit:canuse(character, key) or not meleekit.spend(character, data.Cost[key]) then
			return
		end
		kit.lastused[key] = os.clock()
		if key == "Z" then
			stomp(player, character, root, humanoid)
		elseif key == "X" then
			tackle(player, character, root, kit:aim(root))
		elseif key == "C" then
			floor(player, character, root)
		end
	end,
})
