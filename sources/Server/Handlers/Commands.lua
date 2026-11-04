local players = game:GetService("Players")
local textchatservice = game:GetService("TextChatService")
local runservice = game:GetService("RunService")

local function allowed(player)
	if runservice:IsStudio() then
		return true
	end
	if game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId then
		return true
	end
	return game.PrivateServerOwnerId ~= 0 and player.UserId == game.PrivateServerOwnerId
end

local function maxrage(player)
	local character = player.Character
	if not character then
		return false
	end
	local rage = character:FindFirstChild("Rage")
	if not rage then
		rage = Instance.new("NumberValue")
		rage.Name = "Rage"
		rage.Parent = character
	end
	rage.Value = 100
	local armfunctions = character:FindFirstChild("MagnetArmFunctions")
	if armfunctions then
		armfunctions:SetAttribute("CurrentTier", 3)
	end
	return true
end

return function(_, ServerData)
	local folder = textchatservice:FindFirstChild("TextChatCommands")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "TextChatCommands"
		folder.Parent = textchatservice
	end
	local command = folder:FindFirstChild("ragecommand")
	if not command then
		command = Instance.new("TextChatCommand")
		command.Name = "ragecommand"
		command.PrimaryAlias = "/rage"
		command.Parent = folder
	end
	command.Triggered:Connect(function(source)
		local player = source and players:GetPlayerByUserId(source.UserId)
		if not player or not allowed(player) then
			return
		end
		if maxrage(player) then
			ServerData.Notify(player, "Rage set to max.")
		end
	end)
end
