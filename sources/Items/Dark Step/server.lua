local serverstorage = game:GetService("ServerStorage")

local fruitkit = require(serverstorage:WaitForChild("fruitkit"))
local meleekit = require(serverstorage:WaitForChild("meleekit"))
local hitbox = require(serverstorage:WaitForChild("hitbox"))

local tool = script.Parent
local data = require(tool:WaitForChild("Data"))
local kit
local holdstarted = {}
local overheatuntil = 0

local function overheated()
	return os.clock() < overheatuntil
end

local function amount(base)
	return base * (overheated() and data.OverheatBoost or 1)
end

local function flyingkick(character, root, humanoid, aim)
	local devil = overheated()
	local target = kit:clamprange(root.Position, aim.target, data.Kick.MaxRange)
	target = meleekit.ground(character, target)
	kit.busyuntil = os.clock() + 0.9
	kit:play("BlackLeg.X", {
		SubEffect = 2,
		Character = character,
		MousePos = target,
		EndLag = 0.25,
		Timestamp = meleekit.now(),
		Devil = devil,
	})
	task.delay(0.666, function()
		if not root.Parent or humanoid.Health <= 0 then
			return
		end
		local radius = devil and data.Kick.OverheatRadius or data.Kick.Radius
		meleekit.area(kit, character, root.Position, radius, amount(data.Damage.Z), { stun = 0.5, push = 35, lift = 15 })
		if devil then
			kit:play("BlackLeg.X", { SubEffect = 3, Character = character, Devil = true })
		end
	end)
end

local function breakdance(character, root)
	local devil = overheated()
	local lifetime = data.Breakdance.Lifetime
	kit.busyuntil = os.clock() + lifetime + 0.2
	kit:play("BlackLeg.Z", { SubEffect = 1, RootPart = root, Lifetime = lifetime, Timestamp = meleekit.now(), Devil = devil })
	local anchor = root.Anchored
	root.Anchored = true
	task.spawn(function()
		local started = os.clock()
		while os.clock() - started < lifetime and root.Parent do
			for _, target in ipairs(hitbox.sphere(character, root.Position, data.Breakdance.Radius)) do
				if meleekit.alive(target.model) and kit:hit(target.humanoid, amount(data.Damage.X), target.root) then
					meleekit.stun(target.model, data.Breakdance.Tick + 0.2)
				end
			end
			task.wait(data.Breakdance.Tick)
		end
		if root.Parent then
			root.Anchored = anchor
		end
	end)
end

local function barragestart(character, root, humanoid)
	local devil = overheated()
	local started = os.clock()
	kit:play("BlackLeg.C", {
		SubEffect = 1,
		Character = character,
		Devil = devil,
		HoldValue = kit.effectholding,
		Humanoid = humanoid,
		MinHold = data.Barrage.MinHold,
	})
	task.spawn(function()
		while root.Parent and humanoid.Health > 0 and (os.clock() - started < data.Barrage.MinHold or kit.effectholding.Value) and os.clock() - started < data.Barrage.MaxHold do
			local aim = kit:aim(root)
			local direction = (aim.target - root.Position)
			direction = direction.Magnitude > 1 and direction.Unit or root.CFrame.LookVector
			local center = root.Position + direction * data.Barrage.Reach * 0.5
			for _, target in ipairs(hitbox.box(character, CFrame.lookAt(center, center + direction), Vector3.new(7, 7, data.Barrage.Reach))) do
				if meleekit.alive(target.model) and kit:hit(target.humanoid, amount(data.Damage.C), target.root) then
					meleekit.stun(target.model, 0.35)
				end
			end
			task.wait(data.Barrage.Tick)
		end
		if root.Parent then
			kit:play("BlackLeg.C", { SubEffect = 2, CFrame = root.CFrame, Devil = devil })
		end
	end)
end

local function overheat(character, root)
	overheatuntil = os.clock() + data.Overheat.Duration
	tool:SetAttribute("overheat", true)
	kit.busyuntil = os.clock() + 0.8
	kit:play("BlackLeg.V", { SubEffect = 1, RootPart = root, Fast = false })
	task.delay(0.5, function()
		if root.Parent then
			meleekit.area(kit, character, root.Position, data.Overheat.Radius, data.Damage.V, { stun = 0.3 })
		end
	end)
	task.delay(data.Overheat.Duration, function()
		if os.clock() >= overheatuntil then
			tool:SetAttribute("overheat", nil)
		end
	end)
end

kit = fruitkit.new(tool, {
	holdkeys = { Z = true, C = true },
	maxhold = 3,
	canhold = function(_, character, _, key)
		return meleekit.spend(character, data.Cost[key])
	end,
	onholdstart = function(_, character, root, key)
		holdstarted[key] = os.clock()
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if key == "Z" then
			kit:play("BlackLeg.X", { SubEffect = 1, Character = character, HoldValue = kit.effectholding, Humanoid = humanoid, MaxRange = data.Kick.MaxRange })
		elseif key == "C" then
			barragestart(character, root, humanoid)
		end
	end,
	onrelease = function(_, character, root, key, aim)
		holdstarted[key] = nil
		if key == "Z" then
			flyingkick(character, root, character:FindFirstChildOfClass("Humanoid"), aim)
		end
	end,
	onkey = function(_, character, root, _, key)
		if not kit:canuse(character, key) or not meleekit.spend(character, data.Cost[key]) then
			return
		end
		kit.lastused[key] = os.clock()
		if key == "X" then
			breakdance(character, root)
		elseif key == "V" then
			overheat(character, root)
		end
	end,
})
