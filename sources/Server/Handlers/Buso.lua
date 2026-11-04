local players = game:GetService("Players")
local serverstorage = game:GetService("ServerStorage")
local tweenservice = game:GetService("TweenService")
local runservice = game:GetService("RunService")
local replicatedstorage = game:GetService("ReplicatedStorage")

local appearance = require(replicatedstorage:WaitForChild("Definitions"):WaitForChild("Skin"):WaitForChild("Appearance"))
local aurastats = require(serverstorage:WaitForChild("aurastats"))

local prices = { Geppo = 10000, Buso = 25000, Soru = 100000 }
local limbs = { "LeftHand", "LeftLowerArm", "RightHand", "RightLowerArm" }
local layerpadding = { BusoLayer1 = 0.04, BusoLayer2 = 0.08 }
local layertransparency = { BusoLayer1 = 0, BusoLayer2 = 0.7 }
local togglecooldown = 0.5
local fadetime = 0.25
local defaultcolor = Color3.new(0.1, 0.1, 0.1)
local pulsetime = 1.6

return function(Router, ServerData)
	local meshes = serverstorage:WaitForChild("BushMeshes")
	local lasttoggle = {}

	local function abilities(player)
		local extra = ServerData.GetExtra(player)
		if not extra then
			return nil
		end
		if type(extra.Abilities) ~= "table" then
			extra.Abilities = {}
		end
		return extra.Abilities
	end

	local function tagcharacter(player, character)
		local owned = abilities(player)
		if not owned or not character then
			return
		end
		for name in pairs(prices) do
			if owned[name] then
				character:AddTag(name)
			end
		end
	end

	local function busoof(character)
		return character and character:FindFirstChild("HasBuso")
	end

	local function auracolors(player)
		local id = player:GetAttribute("auraskin")
		if type(id) == "number" and id > 0 then
			local ok, set = pcall(function()
				return appearance.match(id):asNullable()
			end)
			if ok and set and set.Type == "ColorSet" and set.Color3 then
				return set.Color3, set.FadeColor3
			end
		end
		return defaultcolor, nil
	end

	local function busocolorvalue(player, color, fade)
		local value = player:FindFirstChild("BusoColor")
		if not value then
			value = Instance.new("Color3Value")
			value.Name = "BusoColor"
			value.Parent = player
		end
		value.Value = color
		value:SetAttribute("FadeTo", fade)
	end

	local function paint(player, folder)
		local color, fade = auracolors(player)
		busocolorvalue(player, color, fade)
		for _, mesh in ipairs(folder:GetChildren()) do
			if mesh:IsA("BasePart") then
				local pulse = mesh:FindFirstChild("aurapulse")
				if pulse then
					pulse:Destroy()
				end
				mesh.Color = color
				mesh:SetAttribute("Colored", color)
				mesh:SetAttribute("FadeTo", fade)
				if fade then
					local marker = Instance.new("Configuration")
					marker.Name = "aurapulse"
					marker.Parent = mesh
					local tween = tweenservice:Create(mesh, TweenInfo.new(pulsetime, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Color = fade })
					marker.Destroying:Once(function()
						tween:Cancel()
					end)
					tween:Play()
				end
			end
		end
	end

	local function removebuso(character)
		local folder = busoof(character)
		if folder then
			folder:Destroy()
		end
		character:SetAttribute("BusoEnabled", false)
	character:SetAttribute("BusoStage", nil)
	end

	local function addbuso(player, character)
		local folder = Instance.new("Folder")
		folder.Name = "HasBuso"
		for _, limbname in ipairs(limbs) do
			local limb = character:FindFirstChild(limbname)
			if limb and limb:IsA("BasePart") then
				for layer, padding in pairs(layerpadding) do
					local template = meshes:FindFirstChild(limbname .. "_" .. layer)
					if template then
						local mesh = template:Clone()
						local target = layertransparency[layer]
						mesh.Name = limbname .. "_" .. layer
						mesh.Anchored = false
						mesh.CanCollide = false
						mesh.CanQuery = false
						mesh.CanTouch = false
						mesh.Massless = true
						mesh.CastShadow = false
						mesh.Size = limb.Size + Vector3.one * padding
						mesh.CFrame = limb.CFrame
						mesh.Transparency = 1
						local weld = Instance.new("Weld")
						weld.Part0 = limb
						weld.Part1 = mesh
						weld.C0 = CFrame.identity
						weld.Parent = mesh
						mesh.Parent = folder
						tweenservice:Create(mesh, TweenInfo.new(fadetime), { Transparency = target }):Play()
					end
				end
			end
		end
		paint(player, folder)
		folder.Parent = character
		character:SetAttribute("BusoEnabled", true)
	local stage = aurastats.stage(player)
	player:SetAttribute("BusoStage", stage)
	character:SetAttribute("BusoStage", stage)
	end

	local function togglebuso(player)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 or not character:HasTag("Buso") then
			return false
		end
		local now = os.clock()
		if now - (lasttoggle[player] or 0) < togglecooldown then
			return busoof(character) ~= nil
		end
		lasttoggle[player] = now
		if busoof(character) then
			removebuso(character)
			return false
		end
		addbuso(player, character)
		return true
	end

	local function buyhaki(player, name)
		local price = type(name) == "string" and prices[name]
		local owned = abilities(player)
		if not price or not owned then
			return 0
		end
		if owned[name] then
			return 2
		end
		local beli = ServerData.Get(player, "Beli") or 0
		if beli < price then
			return 0
		end
		ServerData.Set(player, "Beli", beli - price)
		owned[name] = true
		if player.Character then
			player.Character:AddTag(name)
		end
		return 1
	end

	local function onplayer(player)
		if not ServerData.WaitReady(player, 60) then
			return
		end
		local owned = abilities(player)
		local stage = aurastats.stage(player)
		player:SetAttribute("BusoStage", stage)
		if owned and runservice:IsStudio() then
			owned.Buso = true
		end
		local color, fade = auracolors(player)
		busocolorvalue(player, color, fade)
		player:GetAttributeChangedSignal("auraskin"):Connect(function()
			local folder = busoof(player.Character)
			if folder then
				paint(player, folder)
			else
				local newcolor, newfade = auracolors(player)
				busocolorvalue(player, newcolor, newfade)
			end
		end)
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("CharacterReady", 30)
			tagcharacter(player, character)
			local currentstage = aurastats.stage(player)
			player:SetAttribute("BusoStage", currentstage)
			character:SetAttribute("BusoStage", currentstage)
		end)
		if player.Character then
			tagcharacter(player, player.Character)
			player.Character:SetAttribute("BusoStage", stage)
		end
	end

	players.PlayerAdded:Connect(onplayer)
	for _, player in ipairs(players:GetPlayers()) do
		task.spawn(onplayer, player)
	end
	players.PlayerRemoving:Connect(function(player)
		lasttoggle[player] = nil
	end)

	Router.commF("Buso", togglebuso, { rate = 4, burst = 6 })
	Router.commF("BuyHaki", buyhaki, { rate = 2, burst = 4 })
end
