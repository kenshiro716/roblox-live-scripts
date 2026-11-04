-- Open the existing team menu before loading optional UI, analytics, or realm services.
local teamPlayer = game:GetService("Players").LocalPlayer
local teamGui = script.Parent
local teamMenu = teamGui:WaitForChild("ChooseTeam")
teamGui.Enabled = true
teamMenu.Visible = teamPlayer.Team == nil
teamGui:SetAttribute("TeamMenuReady", true)
local teamJoining = false
local function chooseTeamImmediately(teamName)
    if teamJoining or teamPlayer.Team then return end
    teamJoining = true
    teamGui:SetAttribute("TeamJoinError", nil)
    local remote = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CommF_")
    local success, message = pcall(function()
        return remote:InvokeServer("SetTeam2", teamName)
    end)
    if not success then
        teamGui:SetAttribute("TeamJoinError", tostring(message))
        warn("[TeamSelect] Could not join:", message)
    end
    teamJoining = false
    if teamPlayer.Team then teamMenu.Visible = false end
end
for _, side in ipairs({"Pirates", "Marines"}) do
    local button = teamMenu:WaitForChild("Container"):WaitForChild(side):WaitForChild("Frame"):WaitForChild("TextButton")
    button.Activated:Connect(function() chooseTeamImmediately(side) end)
end
teamPlayer:GetPropertyChangedSignal("Team"):Connect(function()
    teamMenu.Visible = teamPlayer.Team == nil
end)

local Util = game.ReplicatedStorage:WaitForChild("Util")
local Debris = require(Util:WaitForChild("Debris"))
local Remotes = game.ReplicatedStorage:WaitForChild("Remotes")
local Notification = require(game.ReplicatedStorage:WaitForChild("Notification"))
local LastInput = require(game.ReplicatedStorage.Modules.LastInput)
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Realm = require(game.ReplicatedStorage.Util.Realm)
local v9 = Realm.getIfCurrentRealmHasTagAsync("IsCelebrationEvent")
local AnalyticsUtil = require(game.ReplicatedStorage.Util.AnalyticsUtil)
local Easter2026 = require(game.ReplicatedStorage.EventConfig.Easter2026)
local Locations = require(script.Locations)

task.spawn(function()
	repeat
		local ok = pcall(function()
			game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
		end)

		task.wait()
	until ok
end)

for _, child in pairs(workspace:WaitForChild("_WorldOrigin"):WaitForChild("EnemyRegions"):GetChildren()) do
	child.Transparency = 1
end

local UserInputService = game:GetService("UserInputService")

game:GetService("ContextActionService")

local DoTeamSelection = require(ReplicatedStorage.React.Components.TeamSelection.DoTeamSelection)

LastInput:IsMobile()

if GuiService:IsTenFootInterface() then
	local _ = UserInputService.GamepadEnabled
end

local scriptParent = script.Parent
local u19 = false
local ChooseTeam = scriptParent:WaitForChild("ChooseTeam")

task.spawn(function()
	local ok, err = pcall(function()
		local ct = script.Parent:WaitForChild("ChooseTeam")
		for _, side in ipairs({"Pirates", "Marines"}) do
			local vf = ct:WaitForChild("Container"):WaitForChild(side):WaitForChild("Frame"):WaitForChild("ViewportFrame")
			local wm = vf:WaitForChild("WorldModel", 10)
			local model = wm and wm:FindFirstChildOfClass("Model")
			if model then
				local cam = vf:FindFirstChildOfClass("Camera") or Instance.new("Camera")
				cam.Name = "Camera"
				cam.Parent = vf
				local piv = model:GetPivot()
				local target = piv.Position + Vector3.new(0, 0.6, 0)
				cam.CFrame = CFrame.lookAt(target + piv.LookVector * 6.5 + Vector3.new(0, 0.4, 0), target)
				cam.FieldOfView = 50
				vf.CurrentCamera = cam
			end
		end
	end)
	if not ok then warn("Pick a Side camera:", err) end
end)
local LocalPlayer = game.Players.LocalPlayer

LocalPlayer:WaitForChild("PlayerGui")

local CurrentCamera = workspace.CurrentCamera
local t1 = {
	Sea2 = Locations.Sea2[1].CFrame,
	Sea1 = Locations.Sea1[1].CFrame
}

CurrentCamera.CameraType = "Scriptable"

local v24 = Realm.getCurrentSeaAsync()

CurrentCamera.CFrame = ((if not v24 then nil else t1[v24])) or CurrentCamera.CFrame

local CurrentCameraCFrame = CurrentCamera.CFrame

local function fixcam()

	if not LocalPlayer.Team then
		CurrentCamera.CameraType = "Scriptable"
		CurrentCamera.CFrame = CurrentCameraCFrame
		CurrentCamera.Focus = CurrentCamera.CFrame + CurrentCamera.CFrame.LookVector
	end
end

CurrentCamera:GetPropertyChangedSignal("CameraType"):Connect(function()

	if not LocalPlayer.Team then
		CurrentCamera.CameraType = "Scriptable"
		CurrentCamera.CFrame = CurrentCameraCFrame
		CurrentCamera.Focus = CurrentCamera.CFrame + CurrentCamera.CFrame.LookVector
	end
end)
CurrentCamera:GetPropertyChangedSignal("CameraSubject"):Connect(function()

	if not LocalPlayer.Team then
		CurrentCamera.CameraType = "Scriptable"
		CurrentCamera.CFrame = CurrentCameraCFrame
		CurrentCamera.Focus = CurrentCamera.CFrame + CurrentCamera.CFrame.LookVector
	end
end)
workspace:WaitForChild("Map")

if not game.PlaceId == 98656254829613 then
	task.spawn(function()

		local t2 = {}

		if Realm.getIfCurrentRealmHasTagAsync("IsCelebrationEvent") then
			for _, v36 in Locations.CelebrationEvent do
				table.insert(t2, v36.CFrame)
			end
		else
			for _, v38 in Locations.Sea3 do
				if not (Easter2026.NO_MORE_GAMEPLAY_AT:ToDateTimeUTC().UnixTimestamp > DateTime.now().UnixTimestamp) then
					table.insert(t2, v38.CFrame)
				end
			end
		end

		local function getNearestPoints(p1)

			local n1 = 1e999
			local t3 = {}

			for _, v in pairs(t2) do
				local Magnitude = (v.Position - p1).Magnitude

				if Magnitude < n1 then
					n1 = Magnitude

					local v78 = v;

					(p1 - v78.Position):Dot(v78.LookVector)
				end

				if not (#t3 > 3) and not (Magnitude > 5000) then
					table.insert(t3, {
						showTime = 15,
						distance = Magnitude,
						cf = v
					})
				end
			end

			table.sort(t3, function(p2, p3)
				return p2.distance < p3.distance
			end)

			local t4 = {}

			for _ = 1, #t3 do
				local v81 = table.remove(t3, math.random(1, #t3))

				if v81 then
					table.insert(t4, v81)
				end
			end

			return t4
		end

		if workspace.StreamingEnabled then
			local n2 = 0

			repeat
				n2 += task.wait()
			until LocalPlayer:GetAttribute("FocalSpawnPoint") or n2 > 10

			if LocalPlayer:GetAttribute("FocalSpawnPoint") then
				local v41 = getNearestPoints(LocalPlayer:GetAttribute("FocalSpawnPoint"))

				if #v41 > 0 then
					t2 = v41
					v41[1].showTime = 15
					game.ReplicatedStorage.Remotes:WaitForChild("RequestStreamAroundAsync"):FireServer({
						v41[1],
						v41[2]
					})
				end
			else
				print("not found spawn point")
			end
		end

		if typeof(t2[1]) == "CFrame" then
			for k, v in pairs(t2) do
				t2[k] = {
					showTime = 15,
					cf = v,
					dist = v.Position.Magnitude
				}
			end
		end

		local n3 = 1

		CurrentCamera.CFrame = t2[n3].cf
		CurrentCameraCFrame = CurrentCamera.CFrame
		task.spawn(function()
		end)

		local timestamp = tick()

		tick()

		local n4 = 0
		local u47 = false

		while CurrentCamera.CameraType == Enum.CameraType.Scriptable do
			if tick() - timestamp > t2[n3].showTime and not u47 then
				u47 = true
				task.spawn(function()

					local v82 = n3 + 1

					if v82 > #t2 then
						v82 = 1
					end

					if workspace.StreamingEnabled then
						if v82 ~= n3 then
							local Folder = Instance.new("Folder", game.ReplicatedStorage)

							Debris:AddItem(Folder, 2)

							if game.ReplicatedStorage.EffectContainer:FindFirstChild("BlindCam") then
								require(game.ReplicatedStorage.Effect).new("BlindCam"):play({
									Duration = 0.1,
									Fade = 0.25,
									ZIndex = -10,
									Reference = Folder,
									Color = Color3.new(0.06, 0.06, 0.06)
								})
							end

							task.delay(0.4, function()

								Folder:Destroy()
							end)
							task.wait(0.04)
						end
					elseif v82 ~= n3 then
						require(game.ReplicatedStorage.Effect).new("BlindCam"):play({
							Duration = 0.1,
							Fade = 0.25,
							ZIndex = -10,
							Color = Color3.new(0.06, 0.06, 0.06)
						})
					end

					task.wait(0.26)
					n4 = 0
					n3 += 1

					if n3 > #t2 then
						n3 = 1
					end

					if CurrentCamera.CameraType == Enum.CameraType.Scriptable then
						CurrentCamera.CFrame = t2[n3].cf
						CurrentCameraCFrame = CurrentCamera.CFrame
					end

					timestamp = tick()
					u47 = false
					n3 = v82
					game.ReplicatedStorage.Remotes:WaitForChild("RequestStreamAroundAsync"):FireServer({ t2[n3 + 1] })
				end)
			end

			CurrentCamera.CFrame = t2[n3].cf * CFrame.new(0, 0, -math.min(20, n4 / 1.5))
			CurrentCameraCFrame = CurrentCamera.CFrame
			n4 += task.wait()
		end
	end)
end

local function change(s1: string)

	if u19 then
		return
	end

	u19 = true
	Notification.new("Joining..."):Display()

	local ok, _ = pcall(function()

		Remotes.CommF_:InvokeServer("SetTeam2", s1)
	end)

	if not ok then
		u19 = false
		Notification.new("<Color=Red>Player data still not ready, please wait and try again.<Color=/>"):Display()

		return
	end

	repeat
		task.wait()
	until LocalPlayer.Character and LocalPlayer.Character:IsDescendantOf(workspace.Characters)
end

ChooseTeam.Container:FindFirstChildWhichIsA("UIListLayout").HorizontalAlignment = Enum.HorizontalAlignment.Center
script.Parent:WaitForChild("HomescreenPlayButton").Activated:Connect(function()

	change("Pirates")
end)

if workspace.StreamingEnabled then
	local u28 = false

	task.spawn(function()

		game.ReplicatedStorage.Remotes:WaitForChild("RequestStreamAroundAsync"):FireServer("SpawnPoint")
		game.ReplicatedStorage.Remotes:WaitForChild("RequestStreamAroundAsync").OnClientEvent:Wait()
		u28 = true
	end)

	local n5 = 0

	repeat
		n5 += task.wait(0.03333333333333333)
	until u28 or n5 > 30
end
print("heywww")
-- The existing ChooseTeam UI is shown immediately by the startup block above.
print("DrCococnut")
task.spawn(function()

	if v9 then
		ChooseTeam.Container.Pirates.Frame.ViewportFrame:WaitForChild("WorldModel"):WaitForChild("Pirate").Pants.PantsTemplate = "http://www.roblox.com/asset/?id=12006404759"
		ChooseTeam.Container.Pirates.Frame.ViewportFrame:WaitForChild("WorldModel"):WaitForChild("Pirate").Shirt.ShirtTemplate = "http://www.roblox.com/asset/?id=12006400330"
		ChooseTeam.Container.Marines.Frame.ViewportFrame:WaitForChild("WorldModel"):WaitForChild("DummyB").Pants.PantsTemplate = "http://www.roblox.com/asset/?id=4678568647"
		ChooseTeam.Container.Marines.Frame.ViewportFrame:WaitForChild("WorldModel"):WaitForChild("DummyB").Shirt.ShirtTemplate = "http://www.roblox.com/asset/?id=4735441672"
		require(game.ReplicatedStorage.Util.Anims):Get(ChooseTeam.Container.Pirates.Frame.ViewportFrame:WaitForChild("WorldModel"):WaitForChild("Pirate"), "RedKingAnim"):Play()
		require(game.ReplicatedStorage.Util.Anims):Get(ChooseTeam.Container.Marines.Frame.ViewportFrame:WaitForChild("WorldModel"):WaitForChild("DummyB"), "RipIndraAnim"):Play()

		return
	end

	require(game.ReplicatedStorage.Util.Anims):Get(ChooseTeam.Container.Pirates.Frame.ViewportFrame:WaitForChild("WorldModel"):WaitForChild("Pirate"), "Menu_Idle"):Play()
	require(game.ReplicatedStorage.Util.Anims):Get(ChooseTeam.Container.Marines.Frame.ViewportFrame:WaitForChild("WorldModel"):WaitForChild("DummyB"), "Menu_Idle"):Play()
end)
require(game.ReplicatedStorage.Global).reducing = false

local function fastModeButton()

	AnalyticsUtil.reportActivity("TeamSelect/FastMode")

	local v51 = ChooseTeam:FindFirstChild("FastModeButton") and ChooseTeam.FastModeButton:FindFirstChild("TextLabel")

	if require(game.ReplicatedStorage.Global).reducing then
		return
	end

	require(game.ReplicatedStorage.Global).reducing = true

	if v51 then
		v51.Text = "Working.."
		ChooseTeam.FastModeButton.Notify.Text = "(You can play while it's working, usually takes 20 to 80 seconds to finish)"
	end

	require(game.ReplicatedStorage.Global).FastMode = true
	game:GetService("TextChatService").TextChannels.RBXGeneral:DisplaySystemMessage("<font color=\"#00FF00\">Tip: Try disabling allied FX in the settings menu for even less lag!</font>")

	local Map = workspace:WaitForChild("Map")
	local Unloaded = game.ReplicatedStorage:WaitForChild("Unloaded")

	require(Util.FPSTracker)

	local SmoothPlastic = Enum.Material.SmoothPlastic
	local descendants = Map:GetDescendants()

	task.wait(0.5)

	local descendants2 = Unloaded:GetDescendants()

	task.wait(0.5)

	local clock = os.clock
	local wait = task.wait
	local _ = rawget
	local IsA = Unloaded.IsA
	local v61 = clock()
	local timestamp = tick()
	local n6 = 0
	local v64 = v61

	for _, v in next, descendants do
		if IsA(v, "BasePart") then
			v.Material = SmoothPlastic
			n6 += 1

			if clock() - v64 > 0.008333333333333333 then
				local v67 = "Working.. " .. n6

				if v51 then
					v51.Text = v67
				end

				wait()
				wait()
				v64 = clock()
			end
		elseif v:IsA("Texture") and not v:GetAttribute("Offset") then
			v:Destroy()
		end
	end

	for _, v in next, descendants2 do
		if IsA(v, "BasePart") then
			v.Material = SmoothPlastic
			n6 += 1

			if clock() - v64 > 0.008333333333333333 then
				local v70 = "Working.. " .. n6

				if v51 then
					v51.Text = v70
				end

				wait()
				wait()
				v64 = clock()
			end
		elseif v:IsA("Texture") and not v:GetAttribute("Offset") then
			v:Destroy()
		end
	end

	LocalPlayer.PlayerScripts.OptimizerClientActor:SendMessage("Optimize", true)
	print("Time taken to Fast Mode: ", tick() - timestamp, clock() - v61)

	local v71 = "Finished in " .. math.floor(tick() - timestamp) .. "s"

	pcall(function()

		ChooseTeam.FastModeButton.Notify.Text = "Materials have been disabled."
		v51.Text = v71
	end)
end

ChooseTeam:WaitForChild("FastModeButton").Activated:Connect(fastModeButton)

local LocalPlayerTeleportData = game:GetService("TeleportService"):GetLocalPlayerTeleportData()

if LocalPlayerTeleportData ~= nil and type(LocalPlayerTeleportData) == "table" then
	local AutoJoinTeam = LocalPlayerTeleportData.AutoJoinTeam

	if AutoJoinTeam == "Pirates" or AutoJoinTeam == "Marines" then
		change(AutoJoinTeam)
	end
end
