local serverstorage = game:GetService("ServerStorage")

local fruitkit = require(serverstorage:WaitForChild("fruitkit"))
local meleekit = require(serverstorage:WaitForChild("meleekit"))
local hitbox = require(serverstorage:WaitForChild("hitbox"))

local tool = script.Parent
local data = require(tool:WaitForChild("Data"))
local kit

local function hand(character, side)
	return character:FindFirstChild(side .. "Hand") or character:FindFirstChild(side .. " Arm")
end

local function rushonce(character, root, direction, damage, hit)
	root.CFrame = CFrame.lookAt(root.Position, root.Position + direction)
	kit:play("DragonClaw.Z", { SubEffect = 2, CFrame = root.CFrame, RootPart = root })
	local target = meleekit.dash(character, root, direction, data.Rush.Range / data.Rush.Duration, data.Rush.Duration, data.Rush.Radius)
	if target and not hit[target.model] then
		hit[target.model] = true
		local offset = (target.root.Position - root.Position).Magnitude
		kit:play("DragonClaw.Z", { SubEffect = 3, CFrame = root.CFrame, RootPart = root, Offset = offset })
		if kit:hit(target.humanoid, damage, target.root) then
			meleekit.stun(target.model, 0.6)
		end
		root.CFrame = root.CFrame * CFrame.new(0, 0, -(offset + 6))
		return true
	end
	return false
end

local function dragonrush(character, root)
	kit.busyuntil = os.clock() + data.Rush.Duration * 2 + 0.6
	kit:play("DragonClaw.Z", { SubEffect = 1, Boolean = true, RightHand = hand(character, "Right") })
	local hit = {}
	task.spawn(function()
		local firsthit = rushonce(character, root, kit:aim(root).forward, data.Damage.Z, hit)
		task.wait(data.Rush.Pause)
		if not root.Parent then
			return
		end
		rushonce(character, root, kit:aim(root).forward, firsthit and data.Damage.Z / 10 or data.Damage.Z, hit)
		kit:play("DragonClaw.Z", { SubEffect = 1, Boolean = false, RightHand = hand(character, "Right") })
	end)
end

local function dragonflames(character, root, aim)
	local direction = aim.forward
	local origin = root.Position
	local targetcframe = CFrame.lookAt(origin + direction * data.Flames.Range, origin + direction * (data.Flames.Range + 1))
	kit.busyuntil = os.clock() + 1.1
	kit:play("DragonClaw.X", { SubEffect = 1, Boolean = true, RightHand = hand(character, "Right"), LeftHand = hand(character, "Left") })
	task.delay(0.35, function()
		if not root.Parent then
			return
		end
		kit:play("DragonClaw.X", { SubEffect = 2, CFrame = root.CFrame, TargetCFrame = targetcframe, Timestamp = meleekit.now() })
		local hit = {}
		for step = 1, 6 do
			local from = origin + direction * 3
			local to = from + direction * data.Flames.Range * (step / 6)
			for _, target in ipairs(hitbox.line(character, from, to, data.Flames.Radius)) do
				if meleekit.alive(target.model) and not hit[target.model] then
					hit[target.model] = 0
				end
				if hit[target.model] and hit[target.model] < 3 and meleekit.alive(target.model) then
					hit[target.model] += 1
					if kit:hit(target.humanoid, data.Damage.X / 3, target.root) then
						meleekit.stun(target.model, 0.4)
						if hit[target.model] == 3 then
							meleekit.push(target.root, direction, 55, 20)
						end
					end
				end
			end
			task.wait(0.1)
		end
	end)
end

local function dragonexplosion(character, root)
	kit.busyuntil = os.clock() + 1.4
	kit:play("DragonClaw.C", { SubEffect = 1, Root = root })
	local anchor = root.Anchored
	root.Anchored = true
	task.delay(data.Explosion.Windup, function()
		if not root.Parent then
			return
		end
		root.Anchored = anchor
		local ground = meleekit.ground(character, root.Position)
		kit:play("DragonClaw.C", { SubEffect = 2, CFrame = CFrame.new(ground) * root.CFrame.Rotation })
		meleekit.area(kit, character, ground, data.Explosion.Radius, data.Damage.C, { stun = 0.6, push = 70, lift = 40 })
	end)
end

kit = fruitkit.new(tool, {
	holdkeys = {},
	onkey = function(_, character, root, _, key)
		if not kit:canuse(character, key) or not meleekit.spend(character, data.Cost[key]) then
			return
		end
		kit.lastused[key] = os.clock()
		if key == "Z" then
			dragonrush(character, root)
		elseif key == "X" then
			dragonflames(character, root, kit:aim(root))
		elseif key == "C" then
			dragonexplosion(character, root)
		end
	end,
})
