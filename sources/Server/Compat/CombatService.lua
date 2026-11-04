local players = game:GetService("Players")
local replicatedstorage = game:GetService("ReplicatedStorage")
local debris = game:GetService("Debris")
local aurastats = require(game:GetService("ServerStorage"):WaitForChild("aurastats"))

local combatservice = {}

local statnames = {
	Melee = "Melee",
	Sword = "Sword",
	Gun = "Gun",
	["Demon Fruit"] = "Demon Fruit",
}
local damageperlevel = 0.04
local creatorlifetime = 10

local net = nil
local combatutil = nil
local animations = {}

local function getnet()
	if not net then
		net = require(replicatedstorage.Modules.Net)
	end
	return net
end

local function getcombatutil()
	if not combatutil then
		combatutil = require(replicatedstorage.Modules.CombatUtil)
	end
	return combatutil
end

local function statlevel(player, weapontype)
	local stat = statnames[weapontype]
	local data = player and player:FindFirstChild("Data")
	local stats = data and data:FindFirstChild("Stats")
	local folder = stat and stats and stats:FindFirstChild(stat)
	local level = folder and folder:FindFirstChild("Level")
	return level and level.Value or 0
end

local function canhurt(attackercharacter, rig)
	if not rig or rig == attackercharacter then
		return false
	end
	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 or rig:FindFirstChildOfClass("ForceField") then
		return false
	end
	local attacker = players:GetPlayerFromCharacter(attackercharacter)
	local victim = players:GetPlayerFromCharacter(rig)
	if victim and victim:GetAttribute("InSafeZone") then
		return false
	end
	if attacker and victim then
		if attackercharacter:GetAttribute("PvpDisabled") ~= false or rig:GetAttribute("PvpDisabled") ~= false then
			return false
		end
		if attacker:GetAttribute("InSafeZone") or victim:GetAttribute("InSafeZone") then
			return false
		end
		if attacker.Team and attacker.Team == victim.Team and attacker.Team.Name == "Marines" then
			return false
		end
	end
	return true
end

function combatservice:scaledamage(player, weapontype, base)
	if type(base) ~= "number" then
		return 0
	end
	local statscaling = require(game:GetService("ServerStorage"):WaitForChild("statscaling"))
	local character = player and player.Character
	local tool = character and character:FindFirstChildOfClass("Tool")
	local stat = statnames[weapontype] or statscaling.stattype(tool)
	if not stat then
		return base
	end
	return base * statscaling.multiplier(statscaling.effective(player, stat, tool))
end

function combatservice:damagerig(attackercharacter, rig, amount, weaponname, weapontype, hitpart)
	if not canhurt(attackercharacter, rig) or type(amount) ~= "number" or amount <= 0 then
		return false
	end
	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	amount = aurastats.outgoing(attackercharacter, amount, weapontype)
	amount = aurastats.incoming(rig, amount)
	local before = humanoid.Health
	humanoid:TakeDamage(amount)
	if humanoid.Health < before then
		aurastats.record(attackercharacter, rig, weapontype)
	end

	local attacker = players:GetPlayerFromCharacter(attackercharacter)
	local tag = humanoid:FindFirstChild("creator")
	if tag then
		tag:Destroy()
	end
	tag = Instance.new("ObjectValue")
	tag.Name = "creator"
	tag.Value = attacker
	tag.Parent = humanoid
	debris:AddItem(tag, creatorlifetime)
	rig:SetAttribute("LastAttacker", attacker and attacker.UserId or 0)

	local remote = getnet():RemoteEvent("ReceivedHit")
	for _, player in ipairs(players:GetPlayers()) do
		if player ~= attacker then
			remote:FireClient(player, rig, attackercharacter, weaponname, weapontype, hitpart)
		end
	end
	return true
end

function combatservice:RegisterHit(attackercharacter, hitpart)
	if typeof(attackercharacter) ~= "Instance" or typeof(hitpart) ~= "Instance" then
		return nil
	end
	local util = getcombatutil()
	local rig = util:GetRigOfHitPart(hitpart)
	local tool = util:GetEquippedWeaponTool(attackercharacter) or attackercharacter:FindFirstChild("EquippedWeapon")
	if not rig or not tool then
		return nil
	end
	local name = util:GetWeaponName(tool)
	local data = util:GetWeaponData(name)
	if not data then
		return nil
	end
	local basic = data.Moveset and data.Moveset.Basic
	local damage = basic and basic[1] and basic[1].Damage or data.Damage or 0
	local attacker = players:GetPlayerFromCharacter(attackercharacter)
	damage = attacker and self:scaledamage(attacker, data.WeaponType, damage) or damage * (attackercharacter:GetAttribute("DamageMultiplier") or 1)
	return self:damagerig(attackercharacter, rig, damage, name, data.WeaponType, hitpart)
end

function combatservice.Attack(attacker, targetcharacter, weaponname, damage)
	local character = typeof(attacker) == "Instance" and (attacker:IsA("Player") and attacker.Character or attacker) or nil
	local data = getcombatutil():GetWeaponData(tostring(weaponname or ""))
	local root = targetcharacter and (targetcharacter:FindFirstChild("HumanoidRootPart") or targetcharacter.PrimaryPart)
	return combatservice:damagerig(character, targetcharacter, damage, weaponname, data and data.WeaponType or "Melee", root)
end

function combatservice:RegisterEquipAnimation(player, _, animation)
	local character = player and player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return nil
	end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	local source = animation
	if type(animation) == "string" then
		source = animations[animation]
		if not source then
			source = Instance.new("Animation")
			source.AnimationId = animation
			animations[animation] = source
		end
	end
	if typeof(source) ~= "Instance" or not source:IsA("Animation") then
		return nil
	end
	local ok, track = pcall(animator.LoadAnimation, animator, source)
	return ok and track or nil
end

return combatservice
