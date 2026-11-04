local serverstorage = game:GetService("ServerStorage")
local httpservice = game:GetService("HttpService")

local fruitkit = require(serverstorage:WaitForChild("fruitkit"))
local meleekit = require(serverstorage:WaitForChild("meleekit"))
local hitbox = require(serverstorage:WaitForChild("hitbox"))

local tool = script.Parent
local data = require(tool:WaitForChild("Data"))
local kit
local holdstarted = {}
local chargeid

local function drain(player, character, root, aim)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local direction = aim.forward
	local origin = root.Position
	local target = meleekit.firstline(character, origin, origin + direction * data.Drain.Range * data.Drain.FarMult, data.Drain.Radius)
	local endpoint
	if target then
		endpoint = target.root.Position - direction * 3.5
	else
		local hitpos, _, blocked = meleekit.impact(character, origin, direction, data.Drain.Range)
		endpoint = blocked and hitpos - direction * 3 or hitpos
	end
	local firedir = CFrame.lookAt(origin, origin + direction)
	kit.busyuntil = os.clock() + (target and 1.4 or 0.4)
	kit:play("Saddi2.Saddi_Z", {
		Stage = 1,
		player = player,
		hrp = root,
		origin = origin,
		fireDir = firedir,
		targetPos = endpoint,
	})
	task.wait(0.125)
	if not root.Parent then
		return
	end
	root.CFrame = CFrame.lookAt(endpoint, endpoint + direction)
	if not target or not meleekit.alive(target.model) then
		return
	end
	local release = meleekit.hold(target, root.CFrame * CFrame.new(0, 0, -3.5) * CFrame.Angles(0, math.pi, 0), 1)
	meleekit.stun(target.model, 1.1)
	kit:play("Saddi2.Saddi_Z", { Stage = 2, player = player, hrp = root, origin = root.Position, fireDir = root.CFrame })
	kit:play("Saddi2.Saddi_Z_Victim", { player = player, hrp = root, origin = root.Position, fireDir = root.CFrame, victimRoot = target.root })
	if humanoid and humanoid.Health > 0 then
		humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + humanoid.MaxHealth * data.Drain.Heal)
	end
	for _ = 1, data.Drain.Ticks do
		if not meleekit.alive(target.model) then
			break
		end
		kit:hit(target.humanoid, data.Damage.ZTick, target.root)
		task.wait(data.Drain.TickTime)
	end
	release()
	if meleekit.alive(target.model) then
		kit:hit(target.humanoid, data.Damage.Z, target.root)
		meleekit.push(target.root, direction, 80, 25)
	end
end

local function scarlet(player, character, root, aim)
	local origin = root.Position
	local targetpos = kit:clamprange(origin, aim.target, data.Tear.Range)
	local direction = (targetpos - origin).Unit
	if direction ~= direction then
		direction = aim.forward
		targetpos = origin + direction * data.Tear.Range
	end
	local blocked = workspace:Raycast(origin, targetpos - origin, meleekit.rayparams(character))
	if blocked then
		targetpos = blocked.Position
	end
	local flies = (targetpos - origin).Magnitude / data.Tear.Speed
	kit.busyuntil = os.clock() + 0.5
	kit:play("Saddi2.Saddi_X", {
		player = player,
		hrp = root,
		origin = origin,
		fireDir = CFrame.lookAt(origin, targetpos),
		targetPos = targetpos,
		projectileFliesFor = flies,
		projectileSpeed = data.Tear.Speed,
	})
	local dragged = {}
	local started = os.clock()
	local previous = origin
	while os.clock() - started < flies and root.Parent do
		task.wait(0.05)
		local position = origin + (targetpos - origin) * math.clamp((os.clock() - started) / flies, 0, 1)
		for _, target in ipairs(hitbox.line(character, previous, position, data.Tear.Radius)) do
			if target.root and meleekit.alive(target.model) and not dragged[target.model] then
				dragged[target.model] = target
				meleekit.stun(target.model, 0.8)
				kit:hit(target.humanoid, data.Damage.XDrag, target.root)
				kit:play("Saddi2.Saddi_X_Victim", { player = player, hrp = target.root })
			end
		end
		for _, target in pairs(dragged) do
			if meleekit.isnpc(target.model) and target.root.Parent and meleekit.alive(target.model) then
				target.root.CFrame = CFrame.new(position + direction * 2)
			end
		end
		previous = position
	end
	if blocked then
		meleekit.area(kit, character, targetpos, data.Tear.BurstRadius, data.Damage.X, { stun = 0.5, push = 70, lift = 20 })
	else
		for _, target in pairs(dragged) do
			if meleekit.alive(target.model) then
				kit:hit(target.humanoid, data.Damage.X * 0.6, target.root)
			end
		end
	end
end

kit = fruitkit.new(tool, {
	holdkeys = { Z = true, X = true },
	maxhold = 2,
	canhold = function(_, character, _, key)
		return meleekit.spend(character, data.Cost[key])
	end,
	onholdstart = function(player, _, root, key)
		holdstarted[key] = os.clock()
		if key == "Z" then
			chargeid = httpservice:GenerateGUID(false)
			kit:play("Saddi2.Saddi_Z_Held", { EffectID = chargeid, player = player, hrp = root, origin = root.Position, fireDir = root.CFrame, skillHeld = true })
		end
	end,
	onrelease = function(player, character, root, key, aim)
		holdstarted[key] = nil
		if key == "Z" then
			if chargeid then
				kit:play("Saddi2.Saddi_Z_Held", { EffectID = chargeid, player = player, hrp = root, origin = root.Position, fireDir = root.CFrame, skillHeld = false })
				chargeid = nil
			end
			drain(player, character, root, aim)
		elseif key == "X" then
			scarlet(player, character, root, aim)
		end
	end,
})
