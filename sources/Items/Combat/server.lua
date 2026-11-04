local serverstorage = game:GetService("ServerStorage")

local fruitkit = require(serverstorage:WaitForChild("fruitkit"))
local meleekit = require(serverstorage:WaitForChild("meleekit"))
local hitbox = require(serverstorage:WaitForChild("hitbox"))

local tool = script.Parent
local data = require(tool:WaitForChild("Data"))
local kit

local function quicktackle(player, character, root)
	local direction = root.CFrame.LookVector
	kit.busyuntil = os.clock() + 0.45
	kit:play("Combat2.Z", { plr = player, hrp = root, CFrame = root.CFrame, mouse = kit.mousepos.Value })
	local hit = {}
	meleekit.dash(character, root, Vector3.new(direction.X, 0, direction.Z).Unit, data.Tackle.Speed, data.Tackle.Duration, nil, function()
		for _, target in ipairs(hitbox.sphere(character, root.Position + direction * 2, data.Tackle.Radius)) do
			if not hit[target.model] and meleekit.alive(target.model) then
				hit[target.model] = true
				if kit:hit(target.humanoid, data.Damage.Z, target.root) then
					meleekit.stun(target.model, 0.4)
					meleekit.push(target.root, direction, 70, 25)
				end
			end
		end
	end)
end

local function groundsmash(player, character, root)
	kit.busyuntil = os.clock() + 0.6
	kit:play("Combat2.X", { plr = player, hrp = root, CFrame = root.CFrame, mouse = kit.mousepos.Value })
	task.delay(0.15, function()
		if not root.Parent then
			return
		end
		local center = root.Position
		if not meleekit.grounded(character, root) then
			center -= Vector3.new(0, 4, 0)
		end
		meleekit.area(kit, character, center, data.Smash.Radius, data.Damage.X, { stun = 0.5, push = 45, lift = 20 })
	end)
end

kit = fruitkit.new(tool, {
	holdkeys = {},
	onkey = function(player, character, root, _, key)
		if not kit:canuse(character, key) or not meleekit.spend(character, data.Cost[key]) then
			return
		end
		kit.lastused[key] = os.clock()
		if key == "Z" then
			quicktackle(player, character, root)
		elseif key == "X" then
			groundsmash(player, character, root)
		end
	end,
})
