local serverstorage = game:GetService("ServerStorage")
local runservice = game:GetService("RunService")
local debris = game:GetService("Debris")

local fruitkit = require(serverstorage:WaitForChild("fruitkit"))
local meleekit = require(serverstorage:WaitForChild("meleekit"))
local hitbox = require(serverstorage:WaitForChild("hitbox"))

local tool = script.Parent
local data = require(tool:WaitForChild("Data"))
local kit

local function hands(character)
	return character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm"), character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm")
end

local function steamfist(character, root, aim)
	local right = hands(character)
	local direction = aim.forward
	kit.busyuntil = os.clock() + 0.6
	kit:play("WaterKungfu.Z", { Stage = 2, Origin = root.Position, Direction = direction, RightHand = right })
	task.delay(0.15, function()
		if not root.Parent then
			return
		end
		local from = root.Position + direction * 2
		meleekit.along(kit, character, from, from + direction * data.Fist.Range, data.Fist.Radius, data.Damage.Z, { stun = 0.5, push = 55, lift = 15, ignore = {} })
	end)
end

local function deadlyshower(character, root, aim)
	local right, left = hands(character)
	kit.busyuntil = os.clock() + 0.7
	local origin = root.Position + Vector3.new(0, 1, 0)
	local base = aim.target - origin
	base = base.Magnitude > 1 and base.Unit or root.CFrame.LookVector
	for index = 1, data.Shower.Count do
		task.delay((index - 1) * data.Shower.Interval, function()
			if not root.Parent then
				return
			end
			local spread = CFrame.lookAt(Vector3.zero, base) * CFrame.Angles(math.rad(math.random(-6, 6)), math.rad(math.random(-8, 8)), 0)
			local direction = spread.LookVector
			local start = root.Position + Vector3.new(0, 1, 0) + direction * 3
			local velocity = direction * data.Shower.Speed
			local proxy = Instance.new("Part")
			proxy.Name = "waterbullet"
			proxy.Size = Vector3.one
			proxy.Transparency = 1
			proxy.Anchored = true
			proxy.CanCollide = false
			proxy.CanQuery = false
			proxy.CanTouch = false
			proxy.CFrame = CFrame.lookAt(start, start + direction)
			proxy.Parent = workspace:FindFirstChild("_WorldOrigin") or workspace
			debris:AddItem(proxy, 3)
			kit:play("WaterKungfu.X", {
				Stage = 2,
				Origin = start,
				Root = root,
				Proxy = proxy,
				randCFrame = CFrame.lookAt(start, start + direction),
				velocity = velocity,
				RightHand = right,
				LeftHand = left,
			})
			local started = os.clock()
			local position = start
			while os.clock() - started < data.Shower.Life and proxy.Parent do
				local step = runservice.Heartbeat:Wait()
				local nextposition = position + velocity * step
				local blocked = workspace:Raycast(position, nextposition - position, meleekit.rayparams(character))
				local victim = meleekit.firstline(character, position, nextposition, 2)
				if blocked or victim then
					position = blocked and blocked.Position or victim.root.Position
					break
				end
				position = nextposition
				proxy.CFrame = CFrame.new(position)
			end
			proxy.CFrame = CFrame.new(position)
			proxy:SetAttribute("Exploded", true)
			meleekit.area(kit, character, position, data.Shower.Radius, data.Damage.X, { stun = 0.25 })
		end)
	end
end

local function heavypunch(character, root, aim)
	local direction = aim.target - root.Position
	direction = Vector3.new(direction.X, 0, direction.Z)
	direction = direction.Magnitude > 1 and direction.Unit or root.CFrame.LookVector
	local _, left = hands(character)
	root.CFrame = CFrame.lookAt(root.Position, root.Position + direction)
	kit.busyuntil = os.clock() + 0.6
	local target = meleekit.dash(character, root, direction, data.Punch.Range / data.Punch.Duration, data.Punch.Duration, data.Punch.Radius)
	local position = target and target.root.Position or root.Position + direction * 4
	kit:play("WaterKungfu.C", { Stage = 2, Origin = root.Position, Root = root, LeftHand = left, TargetPosition = position })
	task.delay(0.175, function()
		meleekit.area(kit, character, position, data.Punch.Radius + 2, data.Damage.C, { stun = 0.4, push = 90, lift = 25 })
	end)
end

kit = fruitkit.new(tool, {
	holdkeys = { Z = true, X = true, C = true },
	maxhold = 2,
	canhold = function(_, character, _, key)
		return meleekit.spend(character, data.Cost[key])
	end,
	onholdstart = function(_, character, root, key)
		local right, left = hands(character)
		kit:play("WaterKungfu." .. key, {
			Stage = 1,
			Origin = root.Position,
			Holding = kit.effectholding,
			RightHand = right,
			LeftHand = left,
			Root = root,
		})
	end,
	onrelease = function(_, character, root, key, aim)
		if key == "Z" then
			steamfist(character, root, aim)
		elseif key == "X" then
			deadlyshower(character, root, aim)
		elseif key == "C" then
			heavypunch(character, root, aim)
		end
	end,
})
