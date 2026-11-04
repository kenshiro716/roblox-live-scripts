local players = game:GetService("Players")
local serverstorage = game:GetService("ServerStorage")
local replicatedstorage = game:GetService("ReplicatedStorage")
local debris = game:GetService("Debris")
local runservice = game:GetService("RunService")

local fruitkit = require(serverstorage:WaitForChild("fruitkit"))
local hitbox = require(serverstorage:WaitForChild("hitbox"))
local tool = script.Parent
local held = {}
local charges = {}
local passive = {}
local kit
local damageestimate = {
	M1 = 55,
	Z = 320,
	X = 110,
	C = 300,
	V = 420,
	F = 190,
}

local function rootof(character)
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function orbs(character)
	local value = character and character:FindFirstChild("LightningOrbs")
	if not value and character then
		value = Instance.new("IntValue")
		value.Name = "LightningOrbs"
		value.Value = 4
		value.Parent = character
	end
	return value
end

local function canpay(character, key)
	local energy = character and character:FindFirstChild("Energy")
	local cost = kit and kit.data.Cost[key] or 0
	if cost > 0 and (not energy or energy.Value < cost) then
		return false
	end
	if key == "Z" or key == "F" or key == "V" then
		local value = orbs(character)
		if not value or value.Value < 1 then
			return false
		end
	end
	return true
end

local function spend(character, key)
	local energy = character and character:FindFirstChild("Energy")
	local cost = kit.data.Cost[key] or 0
	if cost > 0 then
		if not energy or energy.Value < cost then
			return false
		end
		energy.Value -= cost
	end
	if key == "Z" or key == "F" or key == "V" then
		local value = orbs(character)
		if not value or value.Value < 1 then
			return false
		end
		value.Value -= 1
	end
	return true
end

local function setstun(model, duration)
	local stun = model and model:FindFirstChild("Stun")
	if stun and stun:IsA("NumberValue") then
		stun.Value = math.max(stun.Value, duration)
	end
end

local function radius(character, position, size, amount, stunfor)
	for _, target in ipairs(hitbox.sphere(character, position, size)) do
		if kit:hit(target.humanoid, amount, target.root or target.part) and stunfor then
			setstun(target.model, stunfor)
		end
	end
end

local function playhold(player, character, root, key)
	held[key] = os.clock()
	charges[key] = 0
	local aim = kit:aim(root)
	if key == "Z" then
		kit:play("Lightning2.ZHeld", {
			Character = character,
			Holding = kit.effectholding,
			player = player,
		})
	else
		local holdtarget = kit:clamprange(root.Position, aim.target, 700)
		kit:play("Lightning2." .. key, {
			Stage = 1,
			Character = character,
			Holding = kit.effectholding,
			Root = root,
			Player = player,
			player = player,
			Origin = root.Position,
			StartCFrame = aim.facing,
			EndCFrame = CFrame.new(holdtarget),
			MousePos = aim.target,
		})
	end
	if key == "V" then
		task.spawn(function()
			local token = held[key]
			while held[key] == token and kit.active and kit.active.key == key and charges[key] < 3 do
				task.wait(0.65)
				if held[key] ~= token or not kit.active or kit.active.key ~= key then
					break
				end
				local value = orbs(character)
				if value and value.Value > 1 then
					value.Value -= 1
					charges[key] += 1
				else
					break
				end
			end
		end)
	end
end

local function release(player, character, root, key, aim)
	local start = held[key] or os.clock()
	local duration = math.min(os.clock() - start, kit.maxhold)
	local charge = charges[key] or 0
	held[key] = nil
	charges[key] = nil
	if not spend(character, key) then
		return
	end
	local target = kit:clamprange(root.Position, aim.target, 700)
	local forward = (target - root.Position)
	if forward.Magnitude < 1 then
		forward = aim.forward * 100
	end
	forward = forward.Unit
	local facing = CFrame.lookAt(root.Position, root.Position + forward)

	if key == "Z" then
		local projectile = Instance.new("Part")
		projectile.Name = "LightningHitbox"
		projectile.Size = Vector3.new(4, 4, 4)
		projectile.Transparency = 1
		projectile.Anchored = true
		projectile.CanCollide = false
		projectile.CanTouch = false
		projectile.CanQuery = false
		projectile.CFrame = facing * CFrame.new(0, 0, -4)
		projectile:SetAttribute("Targeting", target)
		projectile.Parent = workspace
		kit:play("Lightning2.Z", {
			Stage = 2,
			Hitbox = projectile,
			StartCFrame = facing,
			Origin = root.Position,
			Speed = 150 + duration * 20,
			player = player,
		})
		kit:track({
			duration = 1.4,
			radius = 5,
			position = function()
				return projectile.Parent and projectile.Position or root.Position
			end,
			damage = damageestimate.Z,
			source = tool.Name,
		})
		task.spawn(function()
			for _ = 1, 36 do
				if not projectile.Parent then
					break
				end
				projectile.CFrame += forward * 5
				task.wait(0.03)
			end
			if projectile.Parent then
				projectile:SetAttribute("Exploding", true)
				radius(character, projectile.Position, 12, damageestimate.Z, 0.25)
				debris:AddItem(projectile, 0.3)
			end
		end)
	elseif key == "X" then
		local cloudid = "LightningX_" .. tostring(player.UserId) .. "_" .. tostring(math.floor(os.clock() * 1000))
		local proxy = Instance.new("Part")
		proxy.Name = "LightningCloudProxy"
		proxy.Size = Vector3.one
		proxy.Transparency = 1
		proxy.Anchored = true
		proxy.CanCollide = false
		proxy.CanQuery = false
		proxy.CanTouch = false
		proxy.Position = target + Vector3.new(0, 36, 0)
		proxy:SetAttribute("Position", target)
		proxy.Parent = workspace:WaitForChild("_WorldOrigin")
		kit:play("Lightning2.X", {
			Stage = 2,
			Player = player,
			player = player,
			Root = root,
			StartCFrame = facing,
			CloudId = cloudid,
			CloudProxy = proxy,
			Height = 36,
			Amount = damageestimate.X,
		})
		task.spawn(function()
			for _ = 1, 4 do
				if not character.Parent then break end
				radius(character, target, 22, damageestimate.X, 0.2)
				task.wait(0.65)
			end
		end)
		debris:AddItem(proxy, 8)
	elseif key == "C" then
		kit:play("Lightning2.C", {
			Stage = 2,
			Player = player,
			player = player,
			Root = root,
			StartCFrame = facing,
			Origin = target,
			Position = target,
			Amount = damageestimate.C,
			Holding = kit.effectholding,
		})
		task.delay(0.75, function()
			if character.Parent then
				radius(character, target, 18, damageestimate.C, 1)
			end
		end)
	elseif key == "V" then
		local ground = kit:groundbelow(target, character)
		local endcframe = CFrame.lookAt(ground, ground + forward)
		kit:play("Lightning2.V", {
			Stage = 2,
			Player = player,
			player = player,
			Root = root,
			Origin = root.Position,
			StartCFrame = facing,
			EndCFrame = endcframe,
			Duration = 0.8 + charge * 0.45,
			Speed = 0.8 + charge * 0.45,
			Absorbed = 1 + charge,
			Amount = damageestimate.V * (1 + charge * 0.2),
			Size = 14 + charge * 3,
		})
		task.delay(0.8 + charge * 0.2, function()
			if character.Parent then
				radius(character, target, 18 + charge * 4, damageestimate.V * (1 + charge * 0.2), 0.4)
			end
		end)
	elseif key == "F" then
		local endposition = kit:clamprange(root.Position, target, 85)
		local rayparams = RaycastParams.new()
		rayparams.FilterType = Enum.RaycastFilterType.Exclude
		rayparams.FilterDescendantsInstances = { character, workspace:FindFirstChild("Characters"), workspace:FindFirstChild("Enemies"), workspace:FindFirstChild("_WorldOrigin") }
		local result = workspace:Raycast(root.Position, endposition - root.Position, rayparams)
		if result then
			endposition = result.Position - forward * 3
		end
		kit:play("Lightning2.F", {
			Stage = 2,
			Player = player,
			player = player,
			Root = root,
			StartCFrame = CFrame.lookAt(endposition, endposition + forward),
			StartCFrame2 = facing,
			newCF = CFrame.lookAt(endposition, endposition + forward),
		})
		local from = root.Position
		root.CFrame = CFrame.lookAt(endposition, endposition + forward)
		kit:damagealong(character, from, endposition, 7, damageestimate.F)
	end
end

kit = fruitkit.new(tool, {
	holdkeys = { Z = true, X = true, C = true, V = true, F = true },
	maxhold = 3,
	canhold = function(_, character, _, key)
		return canpay(character, key)
	end,
	onholdstart = playhold,
	onrelease = release,
	onm1 = function(player, character, root)
		if tool.Holding:IsA("BoolValue") then
			tool.Holding.Value = true
		end
		local aim = kit:aim(root)
		kit:play("Lightning2.M1", {
			Character = character,
			Holding = tool.Holding,
			Root = root,
			Player = player,
			player = player,
			Origin = root.Position,
			MousePos = aim.target,
			Range = 10,
		})
		kit:damagealong(character, root.Position, root.Position + root.CFrame.LookVector * 9, 5, damageestimate.M1)
		task.delay(0.2, function()
			if tool.Parent then
				tool.Holding.Value = false
			end
		end)
	end,
	onpassivestart = function(player, character)
		local value = orbs(character)
		local token = {}
		passive[player] = token
		task.spawn(function()
			while passive[player] == token and character.Parent and character:GetAttribute("passivefruit") == tool.Name do
				task.wait(5)
				if passive[player] == token and value.Value < 4 then
					value.Value += 1
				end
			end
		end)
	end,
	onpassiveend = function(character)
		local player = players:GetPlayerFromCharacter(character)
		if player then
			passive[player] = nil
		end
		local value = character:FindFirstChild("LightningOrbs")
		if value then
			value:Destroy()
		end
	end,
})
