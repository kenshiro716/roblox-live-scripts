local replicatedstorage = game:GetService("ReplicatedStorage")
local serverstorage = game:GetService("ServerStorage")
local runservice = game:GetService("RunService")

local tool = script.Parent
local hitbox = require(serverstorage:WaitForChild("hitbox"))
local util = require(replicatedstorage:WaitForChild("Util"))
local fruitkit = require(serverstorage:WaitForChild("fruitkit"))
local masterclock = util.MasterClock

local holdstarted = {}
local kit

local function alive(model)
	local humanoid = model and model:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

local function setstun(model, duration)
	local stun = model and model:FindFirstChild("Stun")
	if stun and stun:IsA("ValueBase") and type(stun.Value) == "number" then
		stun.Value = math.max(stun.Value, duration)
	end
end

local function tier()
	local upgrades = tool:FindFirstChild("Upgrades")
	local value = upgrades and upgrades.Value or 0
	if value >= 2 then
		return 3, "V3"
	elseif value == 1 then
		return 2, "V2"
	end
	return 1, "V1"
end

local function blocked(character, origin, target)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {
		character,
		workspace:FindFirstChild("_WorldOrigin"),
		workspace:FindFirstChild("Characters"),
		workspace:FindFirstChild("Enemies"),
	}
	local result = workspace:Raycast(origin, target - origin, params)
	if result then
		return result.Position - (target - origin).Unit * 3
	end
	return target
end

local function initial(player, root, origin, direction)
	local stage = tier()
	kit:play("Yoru2.InitialSlash", {
		Stage = stage,
		player = player,
		hrp = root,
		origin = origin,
		fireDir = direction,
	})
end

local function onethousandslices(player, character, root, aim, held)
	local _, version = tier()
	local data = kit.data.Damage
	local direction = aim.forward
	local origin = root.Position
	local dashing = held >= data.HoldThreshold
	local length = dashing and data.ZDashRange or data.ZRange
	local endpoint = blocked(character, origin, origin + direction * length)
	local duration = dashing and 0.45 or 0.3
	initial(player, root, origin, direction)
	kit.busyuntil = os.clock() + duration + 0.3
	kit:play("Yoru2.SphereSlices" .. version, {
		player = player,
		hrp = root,
		origin = origin,
		fireDir = direction,
		startSlicesPosition = origin + direction * 4,
		endSlicesPosition = endpoint,
		duration = duration,
	})
	if dashing then
		local mover = Instance.new("BodyVelocity")
		mover.Name = "tdbdash"
		mover.MaxForce = Vector3.new(1, 0, 1) * 1e6
		mover.Velocity = direction * ((endpoint - origin).Magnitude / duration)
		mover.Parent = root
		task.delay(duration, function()
			mover:Destroy()
			if root.Parent then
				root.AssemblyLinearVelocity = Vector3.zero
			end
		end)
	end
	task.spawn(function()
		local ticks = data.ZTicks
		for index = 1, ticks do
			if not character.Parent then
				return
			end
			local center = dashing and root.Position + direction * 4 or origin:Lerp(endpoint, index / ticks)
			for _, target in ipairs(hitbox.sphere(character, center, data.ZRadius)) do
				if alive(target.model) and kit:hit(target.humanoid, data.Z, target.root) then
					setstun(target.model, 0.3)
				end
			end
			task.wait(duration / ticks)
		end
	end)
end

local function darkairslash(player, character, root, aim, held)
	local _, version = tier()
	local data = kit.data.Damage
	local special = held >= data.HoldThreshold
	local direction = aim.forward
	local origin = root.Position + Vector3.new(0, 1.5, 0)
	local right = root.CFrame.RightVector
	local distance = data.XRange
	local flighttime = special and 0.22 or 0.38
	initial(player, root, origin, direction)
	kit.busyuntil = os.clock() + 0.6
	for index = -1, 1 do
		local start = origin + right * (index * 4)
		local finish = blocked(character, start, start + direction * distance)
		task.delay((index + 1) * (special and 0.05 or 0.1), function()
			if not character.Parent or not root.Parent then
				return
			end
			local params = {
				player = player,
				hrp = root,
				origin = start,
				fireDir = direction,
				targetPos = finish,
				ClockTime = masterclock:GetTime(),
				fliesFor = flighttime,
			}
			if version ~= "V1" then
				params.specialActivated = special
			end
			kit:play("Yoru2.Slash" .. version, params)
			local hit = {}
			local started = os.clock()
			while os.clock() - started < flighttime and character.Parent do
				local alpha = math.clamp((os.clock() - started) / flighttime, 0, 1)
				local point = start:Lerp(finish, alpha)
				for _, target in ipairs(hitbox.box(character, CFrame.lookAt(point, point + direction), Vector3.new(3, 16, 6))) do
					if not hit[target.model] and alive(target.model) then
						hit[target.model] = true
						if kit:hit(target.humanoid, data.X, target.root) then
							setstun(target.model, 0.4)
							if target.root and target.root:IsA("BasePart") and not target.root.Anchored then
								target.root.AssemblyLinearVelocity += direction * 18
							end
						end
					end
				end
				runservice.Heartbeat:Wait()
			end
		end)
	end
end

kit = fruitkit.new(tool, {
	holdkeys = { Z = true, X = true },
	maxhold = 2,
	onholdstart = function(_, _, _, key)
		holdstarted[key] = os.clock()
	end,
	onrelease = function(player, character, root, key, aim)
		local held = math.clamp(os.clock() - (holdstarted[key] or os.clock()), 0, 2)
		holdstarted[key] = nil
		if key == "Z" then
			onethousandslices(player, character, root, aim, held)
		elseif key == "X" then
			darkairslash(player, character, root, aim, held)
		end
	end,
	onunequip = function()
		table.clear(holdstarted)
	end,
})
