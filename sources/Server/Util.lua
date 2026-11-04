local Players = game:GetService("Players")

local Util = {}

function Util.isString(value, maxLength)
	return type(value) == "string" and #value <= (maxLength or 200)
end

function Util.isNumber(value)
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

function Util.isInteger(value)
	return Util.isNumber(value) and value == math.floor(value)
end

function Util.clamp(value, minimum, maximum)
	return math.max(minimum, math.min(maximum, value))
end

function Util.getCharacter(player)
	local character = player.Character
	if character and character.Parent then
		return character
	end
	return nil
end

function Util.getHumanoid(player)
	local character = Util.getCharacter(player)
	return character and character:FindFirstChildOfClass("Humanoid") or nil
end

function Util.getRoot(player)
	local character = Util.getCharacter(player)
	return character and character:FindFirstChild("HumanoidRootPart") or nil
end

function Util.isAlive(player)
	local humanoid = Util.getHumanoid(player)
	return humanoid ~= nil and humanoid.Health > 0
end

function Util.playerFromModel(model)
	if typeof(model) ~= "Instance" then
		return nil
	end
	local current = model
	while current and current ~= workspace do
		local player = Players:GetPlayerFromCharacter(current)
		if player then
			return player
		end
		current = current.Parent
	end
	return nil
end

function Util.deepCopy(source)
	if type(source) ~= "table" then
		return source
	end
	local copy = {}
	for key, value in pairs(source) do
		copy[key] = Util.deepCopy(value)
	end
	return copy
end

function Util.reconcile(target, template)
	for key, value in pairs(template) do
		if target[key] == nil then
			target[key] = Util.deepCopy(value)
		elseif type(target[key]) == "table" and type(value) == "table" then
			Util.reconcile(target[key], value)
		end
	end
	return target
end

return Util
