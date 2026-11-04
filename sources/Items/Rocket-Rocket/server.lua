local players = game:GetService("Players")
local serverstorage = game:GetService("ServerStorage")
local debris = game:GetService("Debris")

local fruitkit = require(serverstorage:WaitForChild("fruitkit"))
local hitbox = require(serverstorage:WaitForChild("hitbox"))
local tool = script.Parent
local kit
local flight = {}
local damageestimate = {
	Z = 2547,
	X = 3054,
	C = 3477,
}

local function spend(character, key)
	local energy = character and character:FindFirstChild("Energy")
	local cost = kit.data.Cost[key] or 0
	if cost > 0 then
		if not energy or energy.Value < cost then
			return false
		end
		energy.Value -= cost
	end
	return true
end

local function canpay(character, key)
	local energy = character and character:FindFirstChild("Energy")
	local cost = kit.data.Cost[key] or 0
	return cost <= 0 or energy and energy.Value >= cost
end

local function damagearea(character, position, radius, amount)
	for _, target in ipairs(hitbox.sphere(character, position, radius)) do
		kit:hit(target.humanoid, amount, target.root or target.part)
	end
end

local function rayend(character, root, target)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = false
	params.FilterDescendantsInstances = {
		character,
		workspace:FindFirstChild("Characters"),
		workspace:FindFirstChild("Enemies"),
		workspace:FindFirstChild("_WorldOrigin"),
	}
	local delta = target - root.Position
	if delta.Magnitude < 1 then
		delta = root.CFrame.LookVector * 500
	end
	local result = workspace:Raycast(root.Position, delta, params)
	return result and result.Position or root.Position + delta
end

local function onholdstart(player, character, root, key)
	if key == "Z" then
		local aim = kit:aim(root)
		local target = kit:clamprange(root.Position, aim.target, 500)
		kit:play("Rocket.Z", {
			Root = root,
			Position = target,
			Holding = kit.effectholding,
		})
	elseif key == "F" then
		kit:play("Rocket.F", {
			Root = root,
			Holding = kit.effectholding,
		})
		local mover = Instance.new("BodyVelocity")
		mover.Name = "RocketFlightVelocity"
		mover.MaxForce = Vector3.new(90000, 90000, 90000)
		mover.P = 1500
		mover.Velocity = Vector3.new(0, 55, 0)
		mover.Parent = root
		flight[player] = mover
		task.spawn(function()
			local launched = os.clock()
			while kit.active and kit.active.key == "F" and kit.active.player == player and root.Parent and mover.Parent do
				local aim = kit:aim(root)
				local direction = Vector3.new(aim.target.X - root.Position.X, 0, aim.target.Z - root.Position.Z)
				if direction.Magnitude < 1 then
					direction = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
				end
				direction = direction.Magnitude > 0 and direction.Unit or Vector3.zAxis
				mover.Velocity = direction * 38 + Vector3.new(0, os.clock() - launched < 0.35 and 50 or 5, 0)
				task.wait(0.05)
			end
			if mover.Parent then
				mover:Destroy()
			end
			if flight[player] == mover then
				flight[player] = nil
			end
		end)
	end
end

local function onrelease(player, character, root, key, aim)
	if key == "F" then
		local mover = flight[player]
		flight[player] = nil
		if mover and mover.Parent then
			mover:Destroy()
		end
		return
	end
	if not spend(character, key) then
		return
	end
	local target = kit:clamprange(root.Position, aim.target, 500)
	local endpoint = rayend(character, root, target)
	kit:play("Rocket.Z", {
		Root = root,
		Position = endpoint,
	})
	local hit = hitbox.first(character, root.Position, endpoint, 2.5)
	local impact = hit and hit.root and hit.root.Position or endpoint
	local delaytime = math.min((impact - root.Position).Magnitude / 250, 2)
	task.delay(delaytime, function()
		if character.Parent then
			damagearea(character, impact, 7, damageestimate.Z)
		end
	end)
end

local function onkey(player, character, root, humanoid, key)
	if key ~= "X" and key ~= "C" then
		return
	end
	if not kit:canuse(character, key) or not spend(character, key) then
		return
	end
	kit.lastused[key] = os.clock()
	local aim = kit:aim(root)
	local target = kit:clamprange(root.Position, aim.target, key == "C" and 500 or 250)
	if key == "X" then
		local offsets = {
			Vector3.new(-12, 0, -12),
			Vector3.new(12, 0, -12),
			Vector3.new(0, 0, 0),
			Vector3.new(-12, 0, 12),
			Vector3.new(12, 0, 12),
		}
		task.spawn(function()
			for _, offset in ipairs(offsets) do
				if not character.Parent then
					break
				end
				local ground = kit:groundbelow(target + offset, character)
				local start = ground + Vector3.new(0, 55, 0)
				kit:play("Rocket.X", {
					Position0 = CFrame.lookAt(start, ground),
					Position1 = CFrame.new(ground),
				})
				task.delay(0.25, function()
					if character.Parent then
						damagearea(character, ground, 9, damageestimate.X / 5)
					end
				end)
				task.wait(0.18)
			end
		end)
		return
	end
	local ground = kit:groundbelow(target, character)
	local mid = root.Position + Vector3.new(0, 50, 0)
	local forward = Vector3.new(target.X - root.Position.X, 0, target.Z - root.Position.Z)
	if forward.Magnitude < 1 then
		forward = Vector3.new(aim.forward.X, 0, aim.forward.Z)
	end
	forward = forward.Magnitude > 0 and forward.Unit or Vector3.zAxis
	kit:play("Rocket.C", {
		Root = root,
		Humanoid = humanoid,
		Origin = root.Position,
		FireDir = forward,
		Mid = mid,
		Goal = ground,
	})
	task.spawn(function()
		root.CFrame = CFrame.lookAt(root.Position, mid)
		task.wait(0.35)
		if not root.Parent or humanoid.Health <= 0 then
			return
		end
		root.CFrame = CFrame.new(mid, ground)
		task.wait(0.1)
		if not root.Parent or humanoid.Health <= 0 then
			return
		end
		local height = math.min(3.5, root.Size.Y * 0.5 + humanoid.HipHeight)
		root.CFrame = CFrame.new(ground + Vector3.new(0, height, 0), ground + forward)
		damagearea(character, ground, 18, damageestimate.C)
	end)
end

kit = fruitkit.new(tool, {
	holdkeys = { Z = true, F = true },
	maxhold = 8,
	canhold = function(_, character, _, key)
		return canpay(character, key)
	end,
	onholdstart = onholdstart,
	onrelease = onrelease,
	onkey = onkey,
	onunequip = function(player)
		local mover = player and flight[player]
		flight[player] = nil
		if mover and mover.Parent then
			mover:Destroy()
		end
	end,
})
tool.Destroying:Connect(function()
	for player, mover in pairs(flight) do
		flight[player] = nil
		if mover and mover.Parent then
			mover:Destroy()
		end
	end
end)