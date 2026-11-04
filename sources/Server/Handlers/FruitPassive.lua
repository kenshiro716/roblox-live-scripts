local players = game:GetService("Players")

return function()
	local function watch(character)
		character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") and child.ToolTip == "Blox Fruit" then
				character:SetAttribute("passivefruit", child.Name)
			end
		end)
	end

	local function onplayer(player)
		player.CharacterAdded:Connect(watch)
		if player.Character then
			watch(player.Character)
		end
	end

	players.PlayerAdded:Connect(onplayer)
	for _, player in ipairs(players:GetPlayers()) do
		onplayer(player)
	end
end
