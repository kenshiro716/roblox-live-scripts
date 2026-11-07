
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Util = require(ReplicatedStorage:WaitForChild("Util"))
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CurrentCamera = workspace.CurrentCamera

local function RecolorControlColor(p1, color3: Color3) -- line: 9
	-- upvalues: Util (copy)
	if typeof(p1) ~= "Instance" or not p1:IsA("Player") or not p1.Parent then
		return color3
	end

	return Util.WrapColor3Constructor(color3, p1, "ControlFruitVFXColor")
end

local VUltimateCutscene = require(ReplicatedStorage:WaitForChild("FX")):WaitForChild("ControlRework").VUltimateCutscene
local VisualHelper = require(script.Parent.Shared.Utility.VisualHelper)
local _ = workspace._WorldOrigin
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local t1 = {
	"Ambient",
	"Brightness",
	"ColorShift_Bottom",
	"ColorShift_Top",
	"EnvironmentDiffuseScale",
	"EnvironmentSpecularScale",
	"ExposureCompensation",
	"GeographicLatitude",
	"OutdoorAmbient"
}

local function decodeValue(p2) -- line: 46
	if typeof(p2) == "table" and p2.__t then
		if p2.__t == "Color3" then
			return Color3.new(p2.r, p2.g, p2.b)
		end

		if p2.__t == "Vector3" then
			return (Vector3.new(p2.x, p2.y, p2.z))
		end
	end

	return p2
end
local function ApplyLightingFromJSON(p3) -- line: 57
	-- upvalues: t1 (copy), Lighting (copy), HttpService (copy)
	local t2 = {}

	for _, v in ipairs(t1) do
		t2[v] = Lighting[v]
	end

	local data = HttpService:JSONDecode(p3)

	for k, v in pairs(data) do
		pcall(function() -- line: 65
			-- upvalues: Lighting (copy), k (copy), v (copy)
			local v79 = Lighting
			local v80 = k
			local v81 = v

			v79[v80] = if typeof(v81) ~= "table" or not v81.__t then v81 else if v81.__t ~= "Color3" then if v81.__t ~= "Vector3" then v81 else Vector3.new(v81.x, v81.y, v81.z) else Color3.new(v81.r, v81.g, v81.b)
		end)
	end

	local function revert() -- line: 70
		-- upvalues: t2 (copy), Lighting (copy)
		for k, v in pairs(t2) do
			pcall(function() -- line: 72
				-- upvalues: Lighting (copy), k (copy), v (copy)
				Lighting[k] = v
			end)
		end
	end

	return revert
end

local t3 = {
	{
		"CamReAdd",
		"Cam",
		"Glitchsave"
	},
	{
		"CamReAdd",
		"AnimationController",
		"Glitchsave"
	},
	{
		"CamReAdd",
		"Cam",
		"Cam 🡪 Part1"
	},
	{
		"CamReAdd",
		"Cam",
		"BAMP",
		"GlitchBreakDomain"
	}
}

local function findByPath(p4, t4: {[any]: any}) -- line: 88
	for _, v33 in t4 do
		if not p4 then
			return nil
		end

		p4 = p4:FindFirstChild(v33)
	end

	return p4
end
local function foldDuplicateEmitters(p5, s1: string) -- line: 99
	if not p5 then
		return nil
	end

	local v36 = nil

	for _, child in p5:GetChildren() do
		if s1 == child.Name and child:IsA("ParticleEmitter") then
			if v36 then
				child:Destroy()
			else
				v36 = child
			end
		end
	end

	return v36
end
local function thinCutsceneFill(p6) -- line: 116
	-- upvalues: foldDuplicateEmitters (copy), t3 (copy)
	local v40 = p6

	for _, v42 in {
		"ControlRig",
		"SETCFRAMES",
		"DOMAINAURA"
	} do
		if not v40 then
			v40 = nil

			break
		end

		v40 = v40:FindFirstChild(v42)
	end

	if v40 then
		local v43 = v40

		for _, v45 in {
			"BG",
			"SmokeStay"
		} do
			if not v43 then
				v43 = nil

				break
			end

			v43 = v43:FindFirstChild(v45)
		end

		if v43 and v43:IsA("ParticleEmitter") then
			v43.Rate = 100
			v43.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.13, 0.03),
				NumberSequenceKeypoint.new(0.71, 0.03),
				NumberSequenceKeypoint.new(0.88, 0.4),
				NumberSequenceKeypoint.new(1, 1)
			})
		end

		local v46 = v40

		for _, v48 in {
			"BG",
			"SmokeStayB"
		} do
			if not v46 then
				v46 = nil

				break
			end

			v46 = v46:FindFirstChild(v48)
		end

		if v46 then
			v46:SetAttribute("EmitCount", 20)
		end

		local Star = v40:FindFirstChild("Star")

		if Star and Star:IsA("ParticleEmitter") then
			Star.Rate = 50
			Star.Brightness = Star.Brightness * 3
		end

		local v50 = foldDuplicateEmitters(v40:FindFirstChild("Glitch"), "PushSmokeFast")

		if v50 then
			v50:SetAttribute("EmitCount", 60)
		end
	end

	local v51 = p6

	for _, v53 in {
		"ControlRig",
		"SETCFRAMES",
		"CubeBreak",
		"bre"
	} do
		if not v51 then
			v51 = nil

			break
		end

		v51 = v51:FindFirstChild(v53)
	end

	if v51 then
		local ARGGHGHG = v51:FindFirstChild("ARGGHGHG")

		if ARGGHGHG then
			local v55 = nil

			for _, descendant in ARGGHGHG:GetDescendants() do
				if descendant.Name == "Flash" and descendant:IsA("ParticleEmitter") then
					if v55 then
						descendant:Destroy()
					else
						v55 = descendant
					end
				end
			end
		end

		for _, v59 in {
			"second",
			"Flash2"
		} do
			if not v51 then
				v51 = nil

				break
			end

			v51 = v51:FindFirstChild(v59)
		end

		if v51 then
			v51:SetAttribute("EmitCount", 10)
		end
	end

	local v60 = p6

	for _, v62 in {
		"CamReAdd",
		"Cam",
		"BAMP",
		"Glitch"
	} do
		if not v60 then
			v60 = nil

			break
		end

		v60 = v60:FindFirstChild(v62)
	end

	if v60 then
		for _, descendant in v60:GetDescendants() do
			if descendant.Name == "Cube" and descendant:IsA("ParticleEmitter") then
				descendant.Rate = descendant.Rate / 2
			end
		end
	end

	for _, v66 in t3 do
		local v67 = p6

		for _, v69 in v66 do
			if not v67 then
				v67 = nil

				break
			end

			v67 = v67:FindFirstChild(v69)
		end

		if v67 then
			for _, descendant in v67:GetDescendants() do
				if descendant:IsA("ParticleEmitter") then
					descendant:Destroy()
				end
			end
		end
	end
end

return function(p7) -- line: 191
	-- upvalues: CurrentCamera (copy), Util (copy), VisualHelper (copy), ApplyLightingFromJSON (copy), Lighting (copy), TweenService (copy), VUltimateCutscene (copy), thinCutsceneFill (copy), RunService (copy)
	if typeof(p7.Player) == "Instance" and (p7.Player:IsA("Player") and not p7.Player:FindFirstChild("PlayerGui") and p7.Player ~= game.Players.LocalPlayer) then
		Instance.new("Folder", p7.Player).Name = "PlayerGui"
	end

	local v73 = p7.Origin or (p7.Root and p7.Root.Position or (p7.hrp and p7.hrp.Position or (p7.Player and p7.Player.Character.PrimaryPart.Position or p7.player and p7.player.Character.PrimaryPart.Position)))

	assert(v73, "Origin Vector3 missing in: ", script:GetFullName())

	if (CurrentCamera.CFrame.Position - v73).Magnitude > 1400 then
		return
	end

	local Stage = p7.Stage

	if Stage == 1 then
		return
	end

	if Stage == 2 then
		local Model = nil
		local u76 = nil
		local ok, result = pcall(function() -- line: 211
			-- upvalues: p7 (copy), Model (ref), Util (copy), VisualHelper (copy), ApplyLightingFromJSON (copy), Lighting (copy), TweenService (copy), VUltimateCutscene (copy), thinCutsceneFill (copy), CurrentCamera (copy), u76 (ref), RunService (copy)
			local LocalPlayer = game:GetService("Players").LocalPlayer
			local v85 = LocalPlayer == p7.Player
			local CaughtPlayers = p7.CaughtPlayers
			local v87 = false

			if v85 then
				v87 = true
			end

			for _, v in pairs(CaughtPlayers) do
				if v == LocalPlayer then
					v87 = true

					break
				end
			end

			Model = Instance.new("Model", workspace._WorldOrigin)
			Util.Debris:AddItem(Model, 30)

			local v90 = workspace._WorldOrigin:FindFirstChild("ControlVIndicators" .. VisualHelper:OwnerName(p7.Player))

			if v90 then
				v90.Name = "Destroying"
			end

			local Root = p7.Root
			local Character = p7.Character
			local u93 = false

			if v87 then
				local HipHeight = Character.Humanoid.HipHeight

				Character.Humanoid.HipHeight = 2
				_G.InCutscene = true
				Character:SetAttribute("InControlCutscene", true)
				Root.Anchored = true

				local v95 = ApplyLightingFromJSON("{\"ExposureCompensation\":0,\"ColorShift_Bottom\":{\"__t\":\"Color3\",\"b\":0,\"g\":0,\"r\":0},\"EnvironmentDiffuseScale\":0.30000001192092898,\"EnvironmentSpecularScale\":0.30000001192092898,\"GeographicLatitude\":0,\"Ambient\":{\"__t\":\"Color3\",\"b\":0.6666666865348816,\"g\":0.6666666865348816,\"r\":0.6666666865348816},\"OutdoorAmbient\":{\"__t\":\"Color3\",\"b\":0.49803921580314639,\"g\":0.49803921580314639,\"r\":0.49803921580314639},\"Brightness\":2,\"ColorShift_Top\":{\"__t\":\"Color3\",\"b\":0,\"g\":0,\"r\":0}}")
				local ClockTime = Lighting.ClockTime

				task.spawn(function() -- line: 258
					-- upvalues: TweenService (copy), Lighting (copy), u93 (ref), ClockTime (copy)
					local elapsed = task.wait(1)

					TweenService:Create(Lighting, TweenInfo.new(1), {
						ClockTime = 0
					}):Play()

					local v141 = elapsed + task.wait(1)
					local v142 = tick() + 15.133333333333333 - (v141 + 1.5)

					while v142 > tick() and not u93 do
						Lighting.ClockTime = 0
						task.wait()
					end

					TweenService:Create(Lighting, TweenInfo.new(1.5), {
						ClockTime = ClockTime
					}):Play()
				end)
				Root.CFrame = CFrame.lookAt(Vector3.new(0, 0, 0), Root.CFrame.LookVector * Vector3.new(1, 0, 1)) + Root.Position

				local RootCFrame = Root.CFrame
				local clone = VUltimateCutscene.UltimateModel:Clone()

				clone:PivotTo(Root.CFrame)
				pcall(thinCutsceneFill, clone)

				local UpperTorso = Character.UpperTorso
				local t5 = {}
				local clone2 = VUltimateCutscene.DaggerAttach.DaggerL:Clone()
				local clone3 = VUltimateCutscene.DaggerAttach.DaggerR:Clone()
				local LeftDaggerWeld = clone2.LeftDaggerWeld
				local RightDaggerWeld = clone3.RightDaggerWeld

				LeftDaggerWeld.Part0 = Character.LeftHand
				RightDaggerWeld.Part0 = Character.RightHand
				Util.SetParentOverrideWithColor(clone2, Character, p7.Player, "ControlFruitVFXColor")
				Util.SetParentOverrideWithColor(clone3, Character, p7.Player, "ControlFruitVFXColor")
				table.insert(t5, clone2)
				table.insert(t5, clone3)
				table.insert(t5, LeftDaggerWeld)
				table.insert(t5, RightDaggerWeld)

				local Cubes = clone.Cubes
				local CamReAdd = clone.CamReAdd
				local ControlRig = clone.ControlRig
				local _ = ControlRig.CUTSCENEVFX
				local SETCFRAMES = ControlRig.SETCFRAMES

				SETCFRAMES.CubeBreak.CFrame = Root.CFrame * CFrame.new(0, 10169.997, 0)
				SETCFRAMES.DOMAINAURA.CFrame = Root.CFrame * CFrame.new(0, 10000, 0)
				SETCFRAMES.Main.CFrame = Root.CFrame * CFrame.new(0, -3.645, 0)

				local H = clone.CamReAdd.H

				H.CFrame = H.CFrame * CFrame.new(0, 3.182, 0)

				for _, child in pairs(ControlRig.CUTSCENEVFX:GetChildren()) do
					child.CFrame = UpperTorso.CFrame
				end

				for _, child in pairs(VUltimateCutscene.CharStuff.UpperTorso:GetChildren()) do
					local clone4 = child:Clone()

					Util.SetParentOverrideWithColor(clone4, Root.Parent.UpperTorso, p7.Player, "ControlFruitVFXColor")
					table.insert(t5, clone4)

					if clone4:IsA("Weld") then
						clone4.Part0 = Root.Parent.UpperTorso
						clone4.Part1 = ControlRig.CUTSCENEVFX:FindFirstChild(clone4.Name)
					end
				end

				local clone5 = VUltimateCutscene.CharStuff.LowerTorso.SPIN:Clone()

				Util.SetParentOverrideWithColor(clone5, Character.LowerTorso, p7.Player, "ControlFruitVFXColor")
				table.insert(t5, clone5)

				for _, child in pairs(VUltimateCutscene.CharStuff.HumanoidRootPart:GetChildren()) do
					local clone6 = child:Clone()

					Util.SetParentOverrideWithColor(clone6, Root, p7.Player, "ControlFruitVFXColor")
					table.insert(t5, clone6)
				end

				for _, child in pairs(VUltimateCutscene.CharStuff.DaggerVFX:GetChildren()) do
					local clone7 = child:Clone()
					local clone8 = child:Clone()

					Util.SetParentOverrideWithColor(clone7, clone2.Texture, p7.Player, "ControlFruitVFXColor")
					Util.SetParentOverrideWithColor(clone8, clone3.Texture, p7.Player, "ControlFruitVFXColor")
					table.insert(t5, clone7)
					table.insert(t5, clone8)
				end

				local clone9 = VUltimateCutscene.BAMPBLOOM:Clone()
				local clone10 = VUltimateCutscene.BAMPDOF:Clone()
				local clone11 = VUltimateCutscene.CONTROLCCE:Clone()
				local clone12 = VUltimateCutscene.BAMPAtmosphere:Clone()
				local clone13 = VUltimateCutscene.Bloom:Clone()

				clone9.Parent = Lighting
				clone10.Parent = Lighting
				clone11.Parent = Lighting
				clone12.Parent = Lighting.LightingLayers
				clone13.Parent = Lighting
				table.insert(t5, clone9)
				table.insert(t5, clone10)
				table.insert(t5, clone11)
				table.insert(t5, clone12)
				table.insert(t5, clone13)

				local Highlight = Instance.new("Highlight")
				local Player = p7.Player
				local color3 = Color3.fromRGB(255, 0, 0)

				Highlight.FillColor = if typeof(Player) == "Instance" and (not not Player:IsA("Player") and Player.Parent) then Util.WrapColor3Constructor(color3, Player, "ControlFruitVFXColor") else color3
				Highlight.FillTransparency = 1

				local Player2 = p7.Player
				local color3_2 = Color3.fromRGB(255, 255, 255)

				Highlight.OutlineColor = if typeof(Player2) == "Instance" and (not not Player2:IsA("Player") and Player2.Parent) then Util.WrapColor3Constructor(color3_2, Player2, "ControlFruitVFXColor") else color3_2
				Highlight.OutlineTransparency = 0
				Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				Highlight.Enabled = true
				Highlight.Parent = Root.Parent
				table.insert(t5, Highlight)
				Util.SetParentOverrideWithColor(clone, Model, p7.Player, "ControlFruitVFXColor")

				local connection = nil
				local connection2 = nil
				local v136 = Util.Sound:Play("Ctrl_Ult_Cutscene_01_V2", LocalPlayer.PlayerGui)

				local function clear() -- line: 422
					if u93 then return end
					u93 = true
					-- upvalues: connection (ref), connection2 (ref), CurrentCamera (copy), v136 (copy), Util (copy), TweenService (copy), u93 (ref), Character (copy), HipHeight (copy), Root (copy), t5 (ref), v95 (copy), Model (ref)
					if connection then
						connection:Disconnect()
					end

					if connection2 then
						connection2:Disconnect()
					end

					CurrentCamera.CameraType = Enum.CameraType.Custom
					CurrentCamera.CameraSubject = game.Players.LocalPlayer.Character.Humanoid
					pcall(function() -- line: 433
						-- upvalues: v136 (copy), Util (copy)
						if v136 then
							Util.Sound:FadeOut(v136, 0.2)
						end
					end)
					task.spawn(function() -- line: 439
						-- upvalues: TweenService (copy)
						TweenService:Create(workspace.Camera, TweenInfo.new(0.2), {
							FieldOfView = 70
						}):Play()
						task.wait()
						TweenService:Create(workspace.Camera, TweenInfo.new(0.2), {
							FieldOfView = 70
						}):Play()
						task.wait()
						TweenService:Create(workspace.Camera, TweenInfo.new(1), {
							FieldOfView = 70
						}):Play()
					end)
					u93 = true
					_G.InCutscene = nil
					Character:SetAttribute("InControlCutscene", nil)
					Character.Humanoid.HipHeight = HipHeight
					Root.Anchored = false

					for _, v in pairs(t5) do
						v:Destroy()
					end

					v95()
					Model:Destroy()
					Model = nil
					t5 = nil
					_G.updateMusic2(false)
				end

				u76 = clear
				task.delay(17, function() if not u93 then pcall(clear) end end)
				task.spawn(function() -- line: 468
					-- upvalues: v136 (copy), Util (copy), p7 (copy), clone (copy), CurrentCamera (copy), clone10 (copy), clone9 (copy), clone11 (copy), Highlight (copy), clone3 (copy), clone2 (copy), UpperTorso (copy), Root (copy), Cubes (copy), CamReAdd (copy), ControlRig (copy), Character (copy), v85 (copy), LocalPlayer (copy), RootCFrame (copy), u93 (ref), RunService (copy), HipHeight (copy), t5 (ref), v95 (copy), Model (ref)
					task.wait()
					v136.TimePosition = 0
					v136.Volume = 1

					local function Emit(p8) -- line: 476
						if p8:IsA("Beam") then
							local EmitDelay = p8:GetAttribute("EmitDelay")
							local EmitDuration = p8:GetAttribute("EmitDuration")

							task.delay(tonumber(EmitDelay) or 0, function() -- line: 479
								-- upvalues: EmitDuration (copy), p8 (copy)
								if tonumber(EmitDuration) and EmitDuration ~= 0 then
									p8.Enabled = true

									if not p8:GetAttribute("pr3") then
										p8:SetAttribute("pr3", 0)
									end

									local v185 = (p8:GetAttribute("pr3") + 1) % 1000

									p8:SetAttribute("pr3", v185)
									task.wait(EmitDuration)

									if v185 == p8:GetAttribute("pr3") then
										p8.Enabled = false
									end
								end
							end)

							return
						end

						local EmitCount = p8:GetAttribute("EmitCount")
						local EmitDelay = p8:GetAttribute("EmitDelay")
						local EmitDuration = p8:GetAttribute("EmitDuration")

						task.delay(tonumber(EmitDelay) or 0, function() -- line: 495
							-- upvalues: p8 (copy), EmitCount (copy), EmitDuration (copy)
							p8:Emit(EmitCount or 0)

							if tonumber(EmitDuration) and EmitDuration ~= 0 then
								p8.Enabled = true

								if not p8:GetAttribute("pr3") then
									p8:SetAttribute("pr3", 0)
								end

								local v186 = (p8:GetAttribute("pr3") + 1) % 1000

								p8:SetAttribute("pr3", v186)
								task.wait(EmitDuration)

								if v186 == p8:GetAttribute("pr3") then
									p8.Enabled = false
								end
							end
						end)
					end

					local TweenProperty = Util.xmc_Helper_Control.TweenProperty

					local function v147(p9, p10, p11, ...) -- line: 514
						-- upvalues: p7 (copy), Util (copy), TweenProperty (copy)
						if typeof(p11) == "Color3" then
							local Player3 = p7.Player

							p11 = if typeof(Player3) == "Instance" and (not not Player3:IsA("Player") and Player3.Parent) then Util.WrapColor3Constructor(p11, Player3, "ControlFruitVFXColor") else p11
						end

						return TweenProperty(p9, p10, p11, ...)
					end

					local t6 = {
						[1] = clone.CamReAdd,
						[2] = clone.Cubes,
						[3] = clone.ControlRig,
						[4] = CurrentCamera,
						[5] = game.Lighting,
						[6] = clone10,
						[7] = clone9,
						[8] = clone11,
						[9] = Highlight,
						[10] = clone3.Texture.Star,
						[11] = clone2.Texture.Trail,
						[12] = clone3.Texture.Trail,
						[13] = UpperTorso.torsotrail.TORSOTRAIL,
						[14] = UpperTorso:FindFirstChild("BODYTRAIL", true),
						[19] = Root.Slice.BEAM1.SliceBeam2,
						[20] = Root.Slice.BEAM2.SliceBeam1,
						[21] = Cubes.LargeCubeHalf1.Shader.fade.fade1,
						[22] = Cubes.LargeCubeHalf2.Shader.fade.fade2,
						[23] = Cubes.SplitCubeB8.Shader.FADE22.ImageLabel,
						[24] = Cubes.SplitCubeB8.Shader.FADE21.ImageLabel,
						[25] = Cubes.SplitCubeB8.Shader.FADE2.ImageLabel,
						[26] = Cubes.SplitCubeB7.Shader.FADE22.ImageLabel,
						[27] = Cubes.SplitCubeB7.Shader.FADE21.ImageLabel,
						[28] = Cubes.SplitCubeB7.Shader.FADE2.ImageLabel,
						[29] = Cubes.SplitCubeB6.Shader.FADE22.ImageLabel,
						[30] = Cubes.SplitCubeB6.Shader.FADE21.ImageLabel,
						[31] = Cubes.SplitCubeB6.Shader.FADE2.ImageLabel,
						[32] = Cubes.SplitCubeB5.Shader.FADE21.ImageLabel,
						[33] = Cubes.SplitCubeB5.Shader.FADE2.ImageLabel,
						[34] = Cubes.SplitCubeB4.Shader.FADE21.ImageLabel,
						[35] = Cubes.SplitCubeB4.Shader.FADE2.ImageLabel,
						[36] = Cubes.SplitCubeB3.Shader.FADE21.ImageLabel,
						[37] = Cubes.SplitCubeB3.Shader.FADE2.ImageLabel,
						[38] = Cubes.SplitCubeB2.Shader.FADE21.ImageLabel,
						[39] = Cubes.SplitCubeB2.Shader.FADE2.ImageLabel,
						[40] = Cubes.SplitCubeB1.Shader.FADE21.ImageLabel,
						[41] = Cubes.SplitCubeB1.Shader.FADE2.ImageLabel,
						[42] = clone2.Texture.StarEnable.star,
						[43] = clone3.Texture.StarEnable.star,
						[44] = Root.BIGSLICE.b2x.BIGSLASH2,
						[45] = Root.BIGSLICE.b2x.BIGSLASH,
						[46] = Root.BIGSLICE.b2.BIGSLASH2,
						[47] = Root.BIGSLICE.b2.BIGSLASH,
						[48] = Root.BIGSLICE.Attachment.Wind,
						[49] = clone.CamReAdd.Cam.BAMP.Glitch,
						[50] = Cubes.RootPart,
						[51] = Root,
						[52] = clone.CamReAdd.H
					}
					local CFrame2 = t6[50].CFrame
					local CFrame3 = t6[51].CFrame
					local CFrame4 = t6[52].CFrame
					local ExposureCompensation = t6[5].ExposureCompensation
					local t7 = {}

					t6[4].FieldOfView = 70

					local v154 = t6[4]

					v154.CFrame = v154.CFrame * CFrame.new(2.371880292892456, 32.62141799926758, -59.45380783081055, -0.998380184173584, -0.03514741361141205, 0.0447407141327858, 1.862645149230957E-09, 0.7863696217536926, 0.6177563071250916, -0.05689527094364166, 0.6167556643486023, -0.7850958108901978)
					t6[5].ExposureCompensation = 0
					t6[6].InFocusRadius = 0
					t6[6].FarIntensity = 0
					t6[6].FocusDistance = 0
					t6[6].NearIntensity = 0
					t6[7].Threshold = 4
					t6[7].Intensity = 0
					t6[7].Size = 0

					local v155 = t6[8]
					local Player4 = p7.Player
					local color3_3 = Color3.fromRGB(255, 255, 255)

					v155.TintColor = if typeof(Player4) == "Instance" and (not not Player4:IsA("Player") and Player4.Parent) then Util.WrapColor3Constructor(color3_3, Player4, "ControlFruitVFXColor") else color3_3
					t6[8].Brightness = 0
					t6[8].Saturation = 0
					t6[8].Contrast = 0

					local v158 = t6[9]
					local Player5 = p7.Player
					local color3_4 = Color3.fromRGB(255, 0, 0)

					v158.FillColor = if typeof(Player5) == "Instance" and (not not Player5:IsA("Player") and Player5.Parent) then Util.WrapColor3Constructor(color3_4, Player5, "ControlFruitVFXColor") else color3_4
					t6[9].OutlineTransparency = 0
					t6[9].FillTransparency = 1

					local v161 = t6[10]

					v161.CFrame = v161.CFrame * CFrame.new(0.025390625, -0.41717529296875, -0.129669189453125, 1, 2.8610236313397763E-06, -1.4901171425663051E-06, -2.8610238587134518E-06, 1, -1.639088367255681E-07, 1.4901166878189542E-06, 1.6391309998198267E-07, 1)
					t6[11].Enabled = true
					t6[11].Lifetime = 0.30000001192092896
					t6[12].Enabled = true
					t6[12].Lifetime = 0.30000001192092896
					t6[13].Enabled = false
					t6[14].Enabled = true
					t6[14].WidthScale = NumberSequence.new(0)
					t6[14].Lifetime = 2
					t6[19].Enabled = false
					t6[19].Width0 = 0
					t6[19].Width1 = 2
					t6[20].Enabled = false
					t6[20].Width0 = 0
					t6[20].Width1 = 2
					t6[21].ImageTransparency = 0
					t6[22].ImageTransparency = 0
					t6[23].ImageTransparency = 0
					t6[24].ImageTransparency = 0
					t6[25].ImageTransparency = 0
					t6[26].ImageTransparency = 0
					t6[27].ImageTransparency = 0
					t6[28].ImageTransparency = 0
					t6[29].ImageTransparency = 0
					t6[30].ImageTransparency = 0
					t6[31].ImageTransparency = 0
					t6[32].ImageTransparency = 0
					t6[33].ImageTransparency = 0
					t6[34].ImageTransparency = 0
					t6[35].ImageTransparency = 0
					t6[36].ImageTransparency = 0
					t6[37].ImageTransparency = 0
					t6[38].ImageTransparency = 0
					t6[39].ImageTransparency = 0
					t6[40].ImageTransparency = 0
					t6[41].ImageTransparency = 0
					t6[42].Enabled = false
					t6[43].Enabled = false
					t6[44].Enabled = false
					t6[44].Width0 = 15
					t6[44].Width1 = 15
					t6[45].Enabled = false
					t6[45].Width0 = 15
					t6[45].Width1 = 15
					t6[46].Enabled = false
					t6[46].Width0 = 15
					t6[46].Width1 = 15
					t6[47].Enabled = false
					t6[47].Width0 = 15
					t6[47].Width1 = 15
					t6[48]:Emit(10)
					t6[48].Enabled = false

					local v162 = t6[49]

					v162.CFrame = v162.CFrame * CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)

					local v163 = t6[50]

					v163.CFrame = v163.CFrame * CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)

					local v164 = t6[51]

					v164.CFrame = v164.CFrame * CFrame.new(0, 0, 0, 1, -2.9016967560466852E-40, 0, -8.705090268140056E-40, 1, 1.284651299361831E-19, 0, 4.282171213284388E-20, 1)

					local v165 = t6[52]

					v165.CFrame = v165.CFrame * CFrame.new(0, -3.181999921798706, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)
					t7[0] = function() -- line: 668
						-- upvalues: v147 (copy), t6 (ref), CamReAdd (copy), Emit (copy), clone3 (copy), CFrame2 (copy), CFrame3 (copy), CFrame4 (ref)
						v147(t6[4], "FieldOfView", 40, 0.1, "Linear", nil)
						task.spawn(function() -- line: 670
							-- upvalues: CamReAdd (copy), Emit (copy), clone3 (copy)
							for _, descendant in CamReAdd.Cam.ScreenFX.Wind:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end

							for _, descendant in clone3.Texture.Star:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
						v147(t6[5], "ExposureCompensation", 0, 2.35, "Linear", nil)
						v147(t6[6], "FarIntensity", 0, 0.63333, "Linear", nil)
						v147(t6[6], "InFocusRadius", 0, 0.63333, "Linear", nil)
						v147(t6[6], "FocusDistance", 0, 0.63333, "Linear", nil)
						v147(t6[6], "NearIntensity", 0, 0.63333, "Linear", nil)
						v147(t6[9], "OutlineTransparency", 1, 0.31667, "Linear", nil)
						v147(t6[11], "Enabled", true, 0.51667, "Constant", nil)
						v147(t6[12], "Enabled", true, 0.51667, "Constant", nil)
						v147(t6[13], "Enabled", true, 10.25, "Constant", nil)
						v147(t6[14], "Enabled", false, 5.23333, "Constant", nil)
						v147(t6[19], "Width0", 0, 6.8, "Linear", nil)
						v147(t6[19], "Width1", 0, 6.8, "Linear", nil)
						v147(t6[20], "Width0", 0, 6.8, "Linear", nil)
						v147(t6[20], "Width1", 0, 6.8, "Linear", nil)
						v147(t6[21], "ImageTransparency", 1, 6.78333, "Linear", nil)
						v147(t6[22], "ImageTransparency", 1, 6.78333, "Linear", nil)
						v147(t6[23], "ImageTransparency", 1, 10.48333, "Linear", nil)
						v147(t6[24], "ImageTransparency", 1, 10.48333, "Linear", nil)
						v147(t6[25], "ImageTransparency", 1, 10.48333, "Linear", nil)
						v147(t6[26], "ImageTransparency", 1, 10.48333, "Linear", nil)
						v147(t6[27], "ImageTransparency", 1, 10.48333, "Linear", nil)
						v147(t6[28], "ImageTransparency", 1, 10.48333, "Linear", nil)
						v147(t6[29], "ImageTransparency", 1, 10.48333, "Linear", nil)
						v147(t6[30], "ImageTransparency", 1, 10.48333, "Linear", nil)
						v147(t6[31], "ImageTransparency", 1, 10.48333, "Linear", nil)
						v147(t6[32], "ImageTransparency", 1, 10.48333, "Linear", nil)
						v147(t6[33], "ImageTransparency", 1, 10.48333, "Linear", nil)
						v147(t6[34], "ImageTransparency", 1, 10.48333, "Linear", nil)
						v147(t6[35], "ImageTransparency", 1, 10.48333, "Linear", nil)
						v147(t6[36], "ImageTransparency", 1, 10.48333, "Linear", nil)
						v147(t6[37], "ImageTransparency", 1, 10.48333, "Linear", nil)
						v147(t6[38], "ImageTransparency", 1, 10.48333, "Linear", nil)
						v147(t6[39], "ImageTransparency", 1, 10.48333, "Linear", nil)
						v147(t6[40], "ImageTransparency", 1, 10.48333, "Linear", nil)
						v147(t6[41], "ImageTransparency", 1, 10.48333, "Linear", nil)
						v147(t6[42], "Enabled", true, 7.13333, "Constant", nil)
						v147(t6[43], "Enabled", true, 6.46667, "Constant", nil)
						v147(t6[50], "CFrame", CFrame2 * CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), 3.31667, "Linear", nil)
						v147(t6[51], "CFrame", CFrame3 * CFrame.new(0, 0, 0, 1, -2.9016967560466852E-40, 0, -8.705090268140056E-40, 1, 1.284651299361831E-19, 0, 4.282171213284388E-20, 1), 3.31667, "Linear", nil)
						v147(t6[52], "CFrame", CFrame4 * CFrame.new(0, -3.181999921798706, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), 3.31667, "Linear", nil)
					end
					t7[4] = function() -- line: 736
						-- upvalues: ControlRig (copy), Emit (copy)
						task.spawn(function() -- line: 737
							-- upvalues: ControlRig (copy), Emit (copy)
							for _, descendant in ControlRig.SETCFRAMES.Main:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
					end
					t7[6] = function() -- line: 748
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 40, 0.18333, "Linear", nil)
					end
					t7[9] = function() -- line: 751
						-- upvalues: clone2 (copy), Emit (copy), clone3 (copy)
						task.spawn(function() -- line: 752
							-- upvalues: clone2 (copy), Emit (copy), clone3 (copy)
							for _, descendant in clone2.Texture.SPIN2:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end

							for _, descendant in clone3.Texture.SPIN2:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
					end
					t7[17] = function() -- line: 772
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 100, 0.31667, "Linear", nil)
					end
					t7[31] = function() -- line: 775
						-- upvalues: clone2 (copy), Emit (copy), clone3 (copy), v147 (copy), t6 (ref)
						task.spawn(function() -- line: 776
							-- upvalues: clone2 (copy), Emit (copy), clone3 (copy)
							for _, descendant in clone2.Texture.Star:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end

							for _, descendant in clone3.Texture.Star:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
						v147(t6[11], "Enabled", false, 4.6, "Constant", nil)
						v147(t6[12], "Enabled", false, 4.6, "Constant", nil)
					end
					t7[35] = function() -- line: 799
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "TintColor", Color3.fromRGB(133, 85, 255), 0.01667, "Linear", nil)
						v147(t6[8], "Brightness", 2, 0.01667, "Linear", nil)
						v147(t6[8], "Saturation", -1, 0.01667, "Linear", nil)
						v147(t6[8], "Contrast", -5, 0.01667, "Linear", nil)
					end
					t7[36] = function() -- line: 805
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 30, 0.13333, "Linear", nil)
						v147(t6[8], "TintColor", Color3.fromRGB(75, 0, 255), 0.03333, "Linear", nil)
						v147(t6[8], "Brightness", -2, 0.05, "Linear", nil)
						v147(t6[8], "Saturation", -1, 0.05, "Linear", nil)
						v147(t6[8], "Contrast", -5, 0.05, "Linear", nil)
					end
					t7[38] = function() -- line: 812
						-- upvalues: Root (copy), Emit (copy), v147 (copy), t6 (ref)
						task.spawn(function() -- line: 813
							-- upvalues: Root (copy), Emit (copy)
							for _, descendant in Root.GlowShape:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
						v147(t6[6], "FarIntensity", 0.39800000190734863, 0.11667, "Linear", nil)
						v147(t6[6], "InFocusRadius", 1.6150000095367432, 0.11667, "Linear", nil)
						v147(t6[6], "FocusDistance", 0, 0.11667, "Linear", nil)
						v147(t6[6], "NearIntensity", 0.39800000190734863, 0.11667, "Linear", nil)
						v147(t6[8], "TintColor", Color3.fromRGB(133, 85, 255), 0.01667, "Linear", nil)
					end
					t7[39] = function() -- line: 829
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "TintColor", Color3.fromRGB(255, 255, 255), 0.01667, "Linear", nil)
						v147(t6[8], "Brightness", 0, 0.01667, "Linear", nil)
						v147(t6[8], "Saturation", 0, 0.01667, "Linear", nil)
						v147(t6[8], "Contrast", 0, 0.01667, "Linear", nil)
					end
					t7[40] = function() -- line: 835
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "TintColor", Color3.fromRGB(255, 255, 255), 0.36667, "Linear", nil)
						v147(t6[8], "Brightness", 0, 0.36667, "Linear", nil)
						v147(t6[8], "Saturation", 0, 0.36667, "Linear", nil)
						v147(t6[8], "Contrast", 0, 0.36667, "Linear", nil)
					end
					t7[44] = function() -- line: 841
						-- upvalues: v147 (copy), t6 (ref), clone2 (copy), Emit (copy), clone3 (copy)
						v147(t6[4], "FieldOfView", 15, 0.33333, "Back", "In", 1.70158)
						task.spawn(function() -- line: 843
							-- upvalues: clone2 (copy), Emit (copy), clone3 (copy)
							for _, descendant in clone2.Texture.Star:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end

							for _, descendant in clone3.Texture.Star:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
					end
					t7[45] = function() -- line: 864
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[6], "FarIntensity", 0, 0.26667, "Linear", nil)
						v147(t6[6], "InFocusRadius", 0, 0.26667, "Linear", nil)
						v147(t6[6], "FocusDistance", 0, 0.26667, "Linear", nil)
						v147(t6[6], "NearIntensity", 0, 0.26667, "Linear", nil)
					end
					t7[52] = function() -- line: 870
						-- upvalues: clone2 (copy), Emit (copy), clone3 (copy)
						task.spawn(function() -- line: 871
							-- upvalues: clone2 (copy), Emit (copy), clone3 (copy)
							for _, descendant in clone2.Texture.Wind:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end

							for _, descendant in clone3.Texture.Wind:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
					end
					t7[57] = function() -- line: 893
						-- upvalues: clone2 (copy), Emit (copy), clone3 (copy)
						task.spawn(function() -- line: 894
							-- upvalues: clone2 (copy), Emit (copy), clone3 (copy)
							for _, descendant in clone2.Texture.Star:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end

							for _, descendant in clone3.Texture.Star:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
					end
					t7[61] = function() -- line: 915
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[6], "FarIntensity", 0, 2.4, "Linear", nil)
						v147(t6[6], "InFocusRadius", 0, 2.4, "Linear", nil)
						v147(t6[6], "FocusDistance", 0, 2.4, "Linear", nil)
						v147(t6[6], "NearIntensity", 0, 2.4, "Linear", nil)
					end
					t7[62] = function() -- line: 921
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "TintColor", Color3.fromRGB(133, 85, 255), 0.01667, "Linear", nil)
						v147(t6[8], "Brightness", -5, 0.01667, "Linear", nil)
						v147(t6[8], "Saturation", -1, 0.01667, "Linear", nil)
						v147(t6[8], "Contrast", -5, 0.01667, "Linear", nil)
					end
					t7[63] = function() -- line: 927
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "TintColor", Color3.fromRGB(133, 85, 255), 0.03333, "Linear", nil)
						v147(t6[8], "Brightness", -5, 0.03333, "Linear", nil)
						v147(t6[8], "Saturation", -1, 0.03333, "Linear", nil)
						v147(t6[8], "Contrast", -5, 0.03333, "Linear", nil)
					end
					t7[64] = function() -- line: 933
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 75, 0.16667, "Linear", nil)
					end
					t7[65] = function() -- line: 936
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "TintColor", Color3.fromRGB(133, 85, 255), 0.01667, "Linear", nil)
						v147(t6[8], "Brightness", 2, 0.01667, "Linear", nil)
						v147(t6[8], "Saturation", -1, 0.01667, "Linear", nil)
						v147(t6[8], "Contrast", -5, 0.01667, "Linear", nil)
					end
					t7[66] = function() -- line: 942
						-- upvalues: Root (copy), Emit (copy), v147 (copy), t6 (ref)
						task.spawn(function() -- line: 943
							-- upvalues: Root (copy), Emit (copy)
							for _, descendant in Root.SliceFirst:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
						v147(t6[8], "TintColor", Color3.fromRGB(62, 70, 255), 0.01667, "Linear", nil)
						v147(t6[8], "Brightness", 2, 0.01667, "Linear", nil)
						v147(t6[8], "Saturation", 1, 0.01667, "Linear", nil)
						v147(t6[8], "Contrast", 1, 0.01667, "Linear", nil)
					end
					t7[67] = function() -- line: 958
						-- upvalues: CamReAdd (copy), Emit (copy), v147 (copy), t6 (ref)
						task.spawn(function() -- line: 959
							-- upvalues: CamReAdd (copy), Emit (copy)
							for _, descendant in CamReAdd.Cam.BAMP.Glint:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
						v147(t6[8], "TintColor", Color3.fromRGB(133, 85, 255), 0.01667, "Linear", nil)
						v147(t6[8], "Brightness", -5, 0.01667, "Linear", nil)
						v147(t6[8], "Saturation", -1, 0.01667, "Linear", nil)
						v147(t6[8], "Contrast", -5, 0.01667, "Linear", nil)
					end
					t7[68] = function() -- line: 974
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "TintColor", Color3.fromRGB(186, 177, 255), 0.03333, "Linear", nil)
						v147(t6[8], "Brightness", 0.5, 0.03333, "Linear", nil)
						v147(t6[8], "Saturation", 0, 0.03333, "Linear", nil)
						v147(t6[8], "Contrast", 0.7, 0.03333, "Linear", nil)
					end
					t7[70] = function() -- line: 980
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "TintColor", Color3.fromRGB(255, 255, 255), 1.71667, "Linear", nil)
						v147(t6[8], "Brightness", 0, 1.71667, "Linear", nil)
						v147(t6[8], "Saturation", 0, 1.71667, "Linear", nil)
						v147(t6[8], "Contrast", 0, 1.71667, "Linear", nil)
					end
					t7[74] = function() -- line: 986
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 50, 0.25, "Sine", "Out")
					end
					t7[79] = function() -- line: 989
						-- upvalues: CamReAdd (copy), Emit (copy)
						task.spawn(function() -- line: 990
							-- upvalues: CamReAdd (copy), Emit (copy)
							for _, descendant in CamReAdd.Cam.BAMP.Glitch:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
					end
					t7[89] = function() -- line: 1001
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 48, 1.83333, "Linear", nil)
					end
					t7[104] = function() -- line: 1004
						-- upvalues: CamReAdd (copy), Emit (copy)
						task.spawn(function() -- line: 1005
							-- upvalues: CamReAdd (copy), Emit (copy)
							for _, descendant in CamReAdd.Camweld:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
					end
					t7[141] = function() -- line: 1016
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[5], "ExposureCompensation", 7, 0.1, "Linear", nil)
					end
					t7[147] = function() -- line: 1019
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[5], "ExposureCompensation", 0, 0.26667, "Linear", nil)
					end
					t7[163] = function() -- line: 1022
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[5], "ExposureCompensation", 0, 0.51667, "Linear", nil)
					end
					t7[173] = function() -- line: 1025
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "TintColor", Color3.fromRGB(255, 255, 255), 0.2, "Linear", nil)
						v147(t6[8], "Brightness", 0, 0.2, "Linear", nil)
						v147(t6[8], "Saturation", 0, 0.2, "Linear", nil)
						v147(t6[8], "Contrast", 0, 0.2, "Linear", nil)
					end
					t7[181] = function() -- line: 1031
						-- upvalues: CamReAdd (copy), Emit (copy)
						task.spawn(function() -- line: 1032
							-- upvalues: CamReAdd (copy), Emit (copy)
							for _, descendant in CamReAdd.Cam.BAMP.error:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
					end
					t7[185] = function() -- line: 1043
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "TintColor", Color3.fromRGB(255, 255, 255), 2.23333, "Linear", nil)
						v147(t6[8], "Brightness", 0, 0.23333, "Linear", nil)
						v147(t6[8], "Saturation", 0, 2.23333, "Linear", nil)
						v147(t6[8], "Contrast", 0, 2.23333, "Linear", nil)
					end
					t7[194] = function() -- line: 1049
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[5], "ExposureCompensation", 9, 0.06667, "Linear", nil)
					end
					t7[198] = function() -- line: 1052
						-- upvalues: v147 (copy), t6 (ref), clone2 (copy), clone3 (copy)
						v147(t6[5], "ExposureCompensation", 0, 0.2, "Linear", nil)
						task.spawn(function() -- line: 1055
							-- upvalues: clone2 (copy), clone3 (copy)
							for _, descendant in clone2:GetDescendants() do
								if descendant:IsA("ParticleEmitter") then
									descendant.Enabled = false
									descendant:Clear()
								end
							end

							for _, descendant in clone3:GetDescendants() do
								if descendant:IsA("ParticleEmitter") then
									descendant.Enabled = false
									descendant:Clear()
								end
							end
						end)
					end
					t7[199] = function() -- line: 1073
						-- upvalues: v147 (copy), t6 (ref), CFrame2 (copy), CFrame3 (copy), CFrame4 (ref)
						v147(t6[4], "FieldOfView", 38, 0.01667, "Linear", nil)
						v147(t6[8], "Brightness", 1, 0.01667, "Linear", nil)
						v147(t6[9], "OutlineTransparency", 0, 0.01667, "Linear", nil)
						v147(t6[50], "CFrame", CFrame2 * CFrame.new(0, 10000, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), 0.01667, "Linear", nil)
						v147(t6[51], "CFrame", CFrame3 * CFrame.new(0, 10000, 0, 1, -2.9016967560466852E-40, 0, 2.9016967560466852E-40, 1, 1.284651299361831E-19, 0, -1.284651299361831E-19, 1), 0.01667, "Linear", nil)
						v147(t6[52], "CFrame", CFrame4 * CFrame.new(0, 9996.7998046875, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), 0.01667, "Linear", nil)
					end
					t7[200] = function() -- line: 1081
						-- upvalues: v147 (copy), t6 (ref), CFrame2 (copy), CFrame3 (copy), CFrame4 (ref)
						v147(t6[4], "FieldOfView", 60, 1.78333, "Linear", nil)
						v147(t6[8], "Brightness", 0, 0.36667, "Sine", "Out")
						v147(t6[9], "OutlineTransparency", 0, 1.98333, "Linear", nil)
						v147(t6[50], "CFrame", CFrame2 * CFrame.new(0, 10000, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), 9.55, "Linear", nil)
						v147(t6[51], "CFrame", CFrame3 * CFrame.new(0, 10000, 0, 1, -2.9016967560466852E-40, 0, 2.9016967560466852E-40, 1, 1.284651299361831E-19, 0, -1.284651299361831E-19, 1), 10.78333, "Linear", nil)
						v147(t6[52], "CFrame", CFrame4 * CFrame.new(0, 9996.7998046875, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), 10.78333, "Linear", nil)
					end
					t7[202] = function() -- line: 1089
						-- upvalues: ControlRig (copy), Emit (copy)
						task.spawn(function() -- line: 1090
							-- upvalues: ControlRig (copy), Emit (copy)
							for _, descendant in ControlRig.SETCFRAMES.DOMAINAURA.Glitch:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
					end
					t7[205] = function() -- line: 1101
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[6], "FarIntensity", 0, 0.98333, "Linear", nil)
						v147(t6[6], "InFocusRadius", 0, 0.98333, "Linear", nil)
						v147(t6[6], "FocusDistance", 0, 0.98333, "Linear", nil)
						v147(t6[6], "NearIntensity", 0, 0.98333, "Linear", nil)
					end
					t7[210] = function() -- line: 1107
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[5], "ExposureCompensation", 0, 0.65, "Linear", nil)
					end
					t7[220] = function() -- line: 1110
						-- upvalues: clone2 (copy), Emit (copy), clone3 (copy)
						task.spawn(function() -- line: 1111
							-- upvalues: clone2 (copy), Emit (copy), clone3 (copy)
							for _, descendant in clone2.Texture.SPIN:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end

							for _, descendant in clone3.Texture.SPIN:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
					end
					t7[222] = function() -- line: 1131
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "Brightness", 0, 1.61667, "Linear", nil)
					end
					t7[223] = function() -- line: 1134
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[7], "Threshold", 0.19999999999999998, 0.13333, "Linear", nil)
						v147(t6[7], "Intensity", 1, 0.13333, "Linear", nil)
						v147(t6[7], "Size", 56, 0.13333, "Linear", nil)
					end
					t7[231] = function() -- line: 1139
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[7], "Threshold", 1.090999960899353, 0.28333, "Linear", nil)
						v147(t6[7], "Intensity", 0.6499999761581421, 0.28333, "Linear", nil)
						v147(t6[7], "Size", 56, 0.28333, "Linear", nil)
					end
					t7[248] = function() -- line: 1144
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[7], "Threshold", 1.4780000448226929, 0.6, "Linear", nil)
						v147(t6[7], "Intensity", 0.20000000298023224, 0.6, "Linear", nil)
						v147(t6[7], "Size", 56, 0.6, "Linear", nil)
					end
					t7[249] = function() -- line: 1149
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[5], "ExposureCompensation", 0, 0.96667, "Linear", nil)
					end
					t7[264] = function() -- line: 1152
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[6], "FarIntensity", 0.024444444105029106, 0.91667, "Linear", nil)
						v147(t6[6], "InFocusRadius", 0, 0.91667, "Linear", nil)
						v147(t6[6], "FocusDistance", 4.891194820404053, 0.91667, "Linear", nil)
						v147(t6[6], "NearIntensity", 0, 0.91667, "Linear", nil)
					end
					t7[284] = function() -- line: 1158
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[7], "Threshold", 1.4780000448226929, 0.66667, "Linear", nil)
						v147(t6[7], "Intensity", 0.20000000298023224, 0.66667, "Linear", nil)
						v147(t6[7], "Size", 56, 0.66667, "Linear", nil)
					end
					t7[304] = function() -- line: 1163
					end
					t7[307] = function() -- line: 1169
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 25, 0.21667, "Linear", nil)
						v147(t6[5], "ExposureCompensation", 0, 0.2, "Linear", nil)
						v147(t6[11], "Enabled", false, 1.36667, "Constant", nil)
						v147(t6[12], "Enabled", false, 1.36667, "Constant", nil)
					end
					t7[314] = function() -- line: 1175
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[14], "Enabled", false, 2.93333, "Constant", nil)
					end
					t7[319] = function() -- line: 1178
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[5], "ExposureCompensation", 2, 0.01667, "Linear", nil)
						v147(t6[6], "FarIntensity", 0.24699999392032623, 0.05, "Linear", nil)
						v147(t6[6], "InFocusRadius", 0, 0.05, "Linear", nil)
						v147(t6[6], "FocusDistance", 5.1579999923706055, 0.05, "Linear", nil)
						v147(t6[6], "NearIntensity", 0.31200000643730164, 0.05, "Linear", nil)
						v147(t6[8], "TintColor", Color3.fromRGB(133, 85, 255), 0.01667, "Linear", nil)
						v147(t6[8], "Brightness", 2, 0.01667, "Linear", nil)
						v147(t6[8], "Saturation", -1, 0.01667, "Linear", nil)
						v147(t6[8], "Contrast", -5, 0.01667, "Linear", nil)
						v147(t6[9], "FillColor", Color3.fromRGB(0, 0, 0), 0.01667, "Linear", nil)
						v147(t6[9], "OutlineTransparency", 1, 0.01667, "Linear", nil)
						v147(t6[9], "FillTransparency", 0, 0.01667, "Linear", nil)
					end
					t7[320] = function() -- line: 1192
						-- upvalues: v147 (copy), t6 (ref), clone2 (copy), Emit (copy)
						v147(t6[4], "FieldOfView", 70, 0.06667, "Linear", nil)
						task.spawn(function() -- line: 1194
							-- upvalues: clone2 (copy), Emit (copy)
							for _, descendant in clone2.Texture.POP:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
						v147(t6[5], "ExposureCompensation", -2, 0.05, "Linear", nil)
						v147(t6[8], "TintColor", Color3.fromRGB(75, 0, 255), 0.03333, "Linear", nil)
						v147(t6[8], "Brightness", -2, 0.05, "Linear", nil)
						v147(t6[8], "Saturation", -1, 0.05, "Linear", nil)
						v147(t6[8], "Contrast", -5, 0.05, "Linear", nil)
						v147(t6[9], "FillColor", Color3.fromRGB(0, 0, 0), 0.05, "Linear", nil)
						v147(t6[9], "OutlineTransparency", 1, 0.05, "Linear", nil)
						v147(t6[9], "FillTransparency", 1, 0.05, "Linear", nil)
					end
					t7[322] = function() -- line: 1213
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[6], "FarIntensity", 0.26899999380111694, 0.06667, "Linear", nil)
						v147(t6[6], "InFocusRadius", 0, 0.06667, "Linear", nil)
						v147(t6[6], "FocusDistance", 40.86000061035156, 0.06667, "Linear", nil)
						v147(t6[6], "NearIntensity", 0.3440000116825104, 0.06667, "Linear", nil)
						v147(t6[8], "TintColor", Color3.fromRGB(133, 85, 255), 0.01667, "Linear", nil)
					end
					t7[323] = function() -- line: 1220
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[5], "ExposureCompensation", 0, 0.01667, "Linear", nil)
						v147(t6[8], "TintColor", Color3.fromRGB(255, 255, 255), 0.01667, "Linear", nil)
						v147(t6[8], "Brightness", 0, 0.01667, "Linear", nil)
						v147(t6[8], "Saturation", 0, 0.01667, "Linear", nil)
						v147(t6[8], "Contrast", 0, 0.01667, "Linear", nil)
						v147(t6[9], "FillColor", Color3.fromRGB(255, 0, 0), 0.01667, "Linear", nil)
						v147(t6[9], "OutlineTransparency", 0, 0.01667, "Linear", nil)
						v147(t6[9], "FillTransparency", 1, 0.01667, "Linear", nil)
					end
					t7[324] = function() -- line: 1230
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 50, 0.01667, "Linear", nil)
						v147(t6[5], "ExposureCompensation", 0, 9.45, "Linear", nil)
						v147(t6[7], "Threshold", 1.4780000448226929, 1.01667, "Linear", nil)
						v147(t6[7], "Intensity", 0.20000000298023224, 1.01667, "Linear", nil)
						v147(t6[7], "Size", 56, 1.01667, "Linear", nil)
						v147(t6[8], "TintColor", Color3.fromRGB(255, 255, 255), 1.35, "Linear", nil)
						v147(t6[8], "Brightness", 0, 1.35, "Linear", nil)
						v147(t6[8], "Saturation", 0, 1.35, "Linear", nil)
						v147(t6[8], "Contrast", 0, 1.35, "Linear", nil)
						v147(t6[9], "FillColor", Color3.fromRGB(255, 0, 0), 2.76667, "Linear", nil)
						v147(t6[9], "OutlineTransparency", 0, 2.76667, "Linear", nil)
						v147(t6[9], "FillTransparency", 1, 2.76667, "Linear", nil)
					end
					t7[325] = function() -- line: 1244
						-- upvalues: v147 (copy), t6 (ref), clone2 (copy), Emit (copy), clone3 (copy)
						v147(t6[4], "FieldOfView", 95, 0.43333, "Back", "In", 1.70158)
						task.spawn(function() -- line: 1246
							-- upvalues: clone2 (copy), Emit (copy), clone3 (copy)
							for _, descendant in clone2.Texture.Star:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end

							for _, descendant in clone3.Texture.Star:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
					end
					t7[326] = function() -- line: 1268
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[6], "FarIntensity", 0, 0.13333, "Linear", nil)
						v147(t6[6], "InFocusRadius", 0, 0.13333, "Linear", nil)
						v147(t6[6], "FocusDistance", 0, 0.13333, "Linear", nil)
						v147(t6[6], "NearIntensity", 0, 0.13333, "Linear", nil)
					end
					t7[334] = function() -- line: 1274
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[6], "FarIntensity", 0.21199999749660492, 1.36667, "Linear", nil)
						v147(t6[6], "InFocusRadius", 0, 1.36667, "Linear", nil)
						v147(t6[6], "FocusDistance", 42.41999816894531, 1.36667, "Linear", nil)
						v147(t6[6], "NearIntensity", 0, 1.36667, "Linear", nil)
					end
					t7[337] = function() -- line: 1280
						-- upvalues: Root (copy), Emit (copy), clone3 (copy)
						task.spawn(function() -- line: 1281
							-- upvalues: Root (copy), Emit (copy), clone3 (copy)
							for _, descendant in Root.Footsteps.STEP1:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end

							for _, descendant in clone3.Texture.Star:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
					end
					t7[342] = function() -- line: 1303
						-- upvalues: Root (copy), Emit (copy), clone3 (copy)
						task.spawn(function() -- line: 1304
							-- upvalues: Root (copy), Emit (copy), clone3 (copy)
							for _, descendant in Root.Footsteps.STEP2:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end

							for _, descendant in clone3.Texture.Star:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
					end
					t7[348] = function() -- line: 1326
						-- upvalues: Root (copy), Emit (copy), clone3 (copy)
						task.spawn(function() -- line: 1327
							-- upvalues: Root (copy), Emit (copy), clone3 (copy)
							for _, descendant in Root.Footsteps.STEP3:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end

							for _, descendant in clone3.Texture.Star:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
					end
					t7[351] = function() -- line: 1349
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 70, 0.61667, "Linear", nil)
					end
					t7[354] = function() -- line: 1352
						-- upvalues: Root (copy), Emit (copy), clone3 (copy)
						task.spawn(function() -- line: 1353
							-- upvalues: Root (copy), Emit (copy), clone3 (copy)
							for _, descendant in Root.Footsteps.STEP4:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end

							for _, descendant in clone3.Texture.Star:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
					end
					t7[358] = function() -- line: 1375
						-- upvalues: Root (copy), Emit (copy), clone3 (copy)
						task.spawn(function() -- line: 1376
							-- upvalues: Root (copy), Emit (copy), clone3 (copy)
							for _, descendant in Root.Footsteps.STEP5:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end

							for _, descendant in clone3.Texture.Star:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
					end
					t7[361] = function() -- line: 1398
						-- upvalues: Root (copy), Emit (copy), clone3 (copy)
						task.spawn(function() -- line: 1399
							-- upvalues: Root (copy), Emit (copy), clone3 (copy)
							for _, descendant in Root.Footsteps.STEP6:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end

							for _, descendant in clone3.Texture.Star:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
					end
					t7[367] = function() -- line: 1421
						-- upvalues: Root (copy), Emit (copy), clone3 (copy)
						task.spawn(function() -- line: 1422
							-- upvalues: Root (copy), Emit (copy), clone3 (copy)
							for _, descendant in Root.Footsteps.STEP7:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end

							for _, descendant in clone3.Texture.Star:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
					end
					t7[372] = function() -- line: 1444
						-- upvalues: Root (copy), Emit (copy), clone3 (copy)
						task.spawn(function() -- line: 1445
							-- upvalues: Root (copy), Emit (copy), clone3 (copy)
							for _, descendant in Root.Footsteps.STEP8:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end

							for _, descendant in clone3.Texture.Star:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
					end
					t7[376] = function() -- line: 1467
						-- upvalues: Root (copy), Emit (copy), clone3 (copy)
						task.spawn(function() -- line: 1468
							-- upvalues: Root (copy), Emit (copy), clone3 (copy)
							for _, descendant in Root.Dash:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end

							for _, descendant in clone3.Texture.Star:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
					end
					t7[385] = function() -- line: 1490
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[7], "Threshold", 1.4780000448226929, 5.88333, "Linear", nil)
						v147(t6[7], "Intensity", 0.20000000298023224, 5.88333, "Linear", nil)
						v147(t6[7], "Size", 56, 5.88333, "Linear", nil)
					end
					t7[388] = function() -- line: 1495
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 50, 0.01667, "Linear", nil)
						v147(t6[43], "Enabled", false, 1.03333, "Constant", nil)
					end
					t7[389] = function() -- line: 1499
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 30, 0.18333, "Linear", nil)
						v147(t6[11], "Enabled", true, 0.45, "Constant", nil)
						v147(t6[12], "Enabled", true, 0.45, "Constant", nil)
					end
					t7[400] = function() -- line: 1504
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 35, 0.06667, "Linear", nil)
					end
					t7[404] = function() -- line: 1507
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 56, 0.1, "Linear", nil)
					end
					t7[405] = function() -- line: 1510
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "TintColor", Color3.fromRGB(133, 85, 255), 0.01667, "Linear", nil)
						v147(t6[8], "Brightness", 2, 0.01667, "Linear", nil)
						v147(t6[8], "Saturation", -1, 0.01667, "Linear", nil)
						v147(t6[8], "Contrast", -5, 0.01667, "Linear", nil)
					end
					t7[406] = function() -- line: 1516
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "TintColor", Color3.fromRGB(62, 70, 255), 0.03333, "Linear", nil)
						v147(t6[8], "Brightness", 2, 0.03333, "Linear", nil)
						v147(t6[8], "Saturation", 1, 0.03333, "Linear", nil)
						v147(t6[8], "Contrast", 1, 0.03333, "Linear", nil)
					end
					t7[407] = function() -- line: 1522
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[21], "ImageTransparency", 0, 0.01667, "Linear", nil)
						v147(t6[22], "ImageTransparency", 0, 0.01667, "Linear", nil)
					end
					t7[408] = function() -- line: 1526
						-- upvalues: Root (copy), Emit (copy), clone3 (copy), v147 (copy), t6 (ref)
						task.spawn(function() -- line: 1527
							-- upvalues: Root (copy), Emit (copy), clone3 (copy)
							for _, descendant in Root.Slice:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end

							for _, descendant in clone3.Texture.Star:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
						v147(t6[8], "TintColor", Color3.fromRGB(133, 85, 255), 0.01667, "Linear", nil)
						v147(t6[8], "Brightness", -5, 0.01667, "Linear", nil)
						v147(t6[8], "Saturation", -1, 0.01667, "Linear", nil)
						v147(t6[8], "Contrast", -5, 0.01667, "Linear", nil)
						v147(t6[19], "Width0", 0, 0.13333, "Linear", nil)
						v147(t6[19], "Width1", 11, 0.13333, "Linear", nil)
						v147(t6[20], "Width0", 0, 0.13333, "Linear", nil)
						v147(t6[20], "Width1", 11, 0.13333, "Linear", nil)
						v147(t6[21], "ImageTransparency", 1, 0.75, "Sine", "InOut")
						v147(t6[22], "ImageTransparency", 1, 0.75, "Sine", "InOut")
					end
					t7[409] = function() -- line: 1559
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "TintColor", Color3.fromRGB(255, 255, 255), 0.01667, "Linear", nil)
						v147(t6[8], "Brightness", 0, 0.01667, "Linear", nil)
						v147(t6[8], "Saturation", 0, 0.01667, "Linear", nil)
						v147(t6[8], "Contrast", 0, 0.01667, "Linear", nil)
					end
					t7[410] = function() -- line: 1565
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 90, 0.18333, "Linear", nil)
						v147(t6[8], "TintColor", Color3.fromRGB(255, 255, 255), 1.36667, "Linear", nil)
						v147(t6[8], "Brightness", 0, 1.36667, "Linear", nil)
						v147(t6[8], "Saturation", 0, 1.36667, "Linear", nil)
						v147(t6[8], "Contrast", 0, 1.36667, "Linear", nil)
					end
					t7[411] = function() -- line: 1572
						-- upvalues: CamReAdd (copy), Emit (copy), clone3 (copy)
						task.spawn(function() -- line: 1573
							-- upvalues: CamReAdd (copy), Emit (copy), clone3 (copy)
							for _, descendant in CamReAdd.Cam.ScreenFX.Wind:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end

							for _, descendant in clone3.Texture.Star:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
					end
					t7[416] = function() -- line: 1595
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[6], "FarIntensity", 0.4300000071525574, 0.08333, "Linear", nil)
						v147(t6[6], "InFocusRadius", 0, 0.08333, "Linear", nil)
						v147(t6[6], "FocusDistance", 0, 0.08333, "Linear", nil)
						v147(t6[6], "NearIntensity", 0.15000000596046448, 0.08333, "Linear", nil)
						v147(t6[11], "Enabled", false, 0.48333, "Constant", nil)
						v147(t6[12], "Enabled", false, 0.48333, "Constant", nil)
						v147(t6[19], "Width0", 0, 0.2, "Sine", "Out")
						v147(t6[19], "Width1", 0, 0.2, "Sine", "InOut")
						v147(t6[20], "Width0", 0, 0.2, "Sine", "Out")
						v147(t6[20], "Width1", 0, 0.2, "Sine", "InOut")
					end
					t7[420] = function() -- line: 1607
						-- upvalues: Character (copy), Emit (copy), clone3 (copy)
						task.spawn(function() -- line: 1608
							-- upvalues: Character (copy), Emit (copy), clone3 (copy)
							for _, descendant in Character.LowerTorso.SPIN:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end

							for _, descendant in clone3.Texture.Star:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
					end
					t7[421] = function() -- line: 1630
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 76, 0.16667, "Linear", nil)
						v147(t6[6], "FarIntensity", 0.7850000262260437, 0.45, "Linear", nil)
						v147(t6[6], "InFocusRadius", 0, 0.45, "Linear", nil)
						v147(t6[6], "FocusDistance", 55.91999816894531, 0.45, "Linear", nil)
						v147(t6[6], "NearIntensity", 0, 0.45, "Linear", nil)
					end
					t7[428] = function() -- line: 1637
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[42], "Enabled", false, 0.36667, "Constant", nil)
					end
					t7[431] = function() -- line: 1640
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 70, 0.35, "Linear", nil)
					end
					t7[441] = function() -- line: 1643
						-- upvalues: Cubes (copy), Emit (copy), clone3 (copy)
						task.spawn(function() -- line: 1644
							-- upvalues: Cubes (copy), Emit (copy), clone3 (copy)
							for _, descendant in Cubes.LargeCube5.GroundPart:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end

							for _, descendant in clone3.Texture.Star:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
					end
					t7[444] = function() -- line: 1666
						-- upvalues: Root (copy), Emit (copy), clone3 (copy)
						task.spawn(function() -- line: 1667
							-- upvalues: Root (copy), Emit (copy), clone3 (copy)
							for _, descendant in Root.Expand:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end

							for _, descendant in clone3.Texture.Star:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
					end
					t7[445] = function() -- line: 1689
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[11], "Enabled", false, 0.68333, "Constant", nil)
						v147(t6[12], "Enabled", false, 0.68333, "Constant", nil)
					end
					t7[448] = function() -- line: 1693
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[6], "FarIntensity", 0.21199999749660492, 0.16667, "Linear", nil)
						v147(t6[6], "InFocusRadius", 0, 0.16667, "Linear", nil)
						v147(t6[6], "FocusDistance", 42.41999816894531, 0.16667, "Linear", nil)
						v147(t6[6], "NearIntensity", 0, 0.16667, "Linear", nil)
					end
					t7[450] = function() -- line: 1699
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[42], "Enabled", true, 2.63333, "Constant", nil)
						v147(t6[43], "Enabled", true, 2.63333, "Constant", nil)
					end
					t7[452] = function() -- line: 1703
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 51, 0.01667, "Linear", nil)
					end
					t7[453] = function() -- line: 1706
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 51.000003814697266, 0.68333, "Linear", nil)
					end
					t7[458] = function() -- line: 1709
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[6], "FarIntensity", 0, 0.45, "Linear", nil)
						v147(t6[6], "InFocusRadius", 0, 0.45, "Linear", nil)
						v147(t6[6], "FocusDistance", 0, 0.45, "Linear", nil)
						v147(t6[6], "NearIntensity", 0, 0.45, "Linear", nil)
					end
					t7[479] = function() -- line: 1715
						-- upvalues: ControlRig (copy), Emit (copy), clone3 (copy)
						task.spawn(function() -- line: 1716
							-- upvalues: ControlRig (copy), Emit (copy), clone3 (copy)
							for _, descendant in ControlRig.CUTSCENEVFX.TP1st:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end

							for _, descendant in clone3.Texture.Star:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
					end
					t7[485] = function() -- line: 1738
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[6], "FarIntensity", 0.21199999749660492, 0.81667, "Linear", nil)
						v147(t6[6], "InFocusRadius", 0, 0.81667, "Linear", nil)
						v147(t6[6], "FocusDistance", 42.41999816894531, 0.81667, "Linear", nil)
						v147(t6[6], "NearIntensity", 0, 0.81667, "Linear", nil)
					end
					t7[486] = function() -- line: 1744
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[11], "Enabled", false, 2.38333, "Constant", nil)
						v147(t6[12], "Enabled", false, 2.38333, "Constant", nil)
					end
					t7[490] = function() -- line: 1748
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[9], "FillColor", Color3.fromRGB(0, 0, 0), 0.01667, "Linear", nil)
						v147(t6[9], "OutlineTransparency", 1, 0.01667, "Linear", nil)
						v147(t6[9], "FillTransparency", 0, 0.01667, "Linear", nil)
						v147(t6[14], "Enabled", true, 3.71667, "Constant", nil)
					end
					t7[491] = function() -- line: 1754
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[9], "FillColor", Color3.fromRGB(0, 0, 0), 0.11667, "Linear", nil)
						v147(t6[9], "OutlineTransparency", 1, 0.11667, "Linear", nil)
						v147(t6[9], "FillTransparency", 0, 0.11667, "Linear", nil)
					end
					t7[492] = function() -- line: 1759
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "TintColor", Color3.fromRGB(255, 255, 255), 0.01667, "Linear", nil)
						v147(t6[8], "Brightness", -0.7, 0.01667, "Linear", nil)
						v147(t6[8], "Saturation", 0, 0.01667, "Linear", nil)
						v147(t6[8], "Contrast", 1, 0.01667, "Linear", nil)
					end
					t7[493] = function() -- line: 1765
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "TintColor", Color3.fromRGB(255, 255, 255), 0.1, "Linear", nil)
						v147(t6[8], "Brightness", -0.7, 0.03333, "Linear", nil)
						v147(t6[8], "Saturation", 0, 0.05, "Linear", nil)
						v147(t6[8], "Contrast", 0.5, 0.05, "Linear", nil)
					end
					t7[494] = function() -- line: 1771
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 61, 0.01667, "Linear", nil)
					end
					t7[495] = function() -- line: 1774
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 51.000003814697266, 0.03333, "Linear", nil)
						v147(t6[8], "Brightness", 0.5, 0.03333, "Linear", nil)
					end
					t7[496] = function() -- line: 1778
						-- upvalues: Root (copy), Emit (copy), clone3 (copy), v147 (copy), t6 (ref)
						task.spawn(function() -- line: 1779
							-- upvalues: Root (copy), Emit (copy), clone3 (copy)
							for _, descendant in Root.Footsteps.POUNCE1:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end

							for _, descendant in clone3.Texture.Star:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
						v147(t6[8], "Saturation", 0, 0.05, "Linear", nil)
						v147(t6[8], "Contrast", 2, 0.01667, "Linear", nil)
					end
					t7[497] = function() -- line: 1803
						-- upvalues: v147 (copy), t6 (ref), ControlRig (copy), Emit (copy), clone3 (copy)
						v147(t6[4], "FieldOfView", 51.000003814697266, 0.38333, "Linear", nil)
						task.spawn(function() -- line: 1805
							-- upvalues: ControlRig (copy), Emit (copy), clone3 (copy)
							for _, descendant in ControlRig.CUTSCENEVFX.TP2nd:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end

							for _, descendant in clone3.Texture.Star:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
						v147(t6[8], "Brightness", 0, 0.03333, "Linear", nil)
						v147(t6[8], "Contrast", 0, 0.03333, "Linear", nil)
					end
					t7[498] = function() -- line: 1829
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[9], "FillColor", Color3.fromRGB(255, 0, 0), 0.01667, "Linear", nil)
						v147(t6[9], "OutlineTransparency", 0, 0.01667, "Linear", nil)
						v147(t6[9], "FillTransparency", 1, 0.01667, "Linear", nil)
					end
					t7[499] = function() -- line: 1834
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "TintColor", Color3.fromRGB(255, 255, 255), 0.35, "Linear", nil)
						v147(t6[8], "Brightness", 0, 0.35, "Linear", nil)
						v147(t6[8], "Saturation", 0, 0.35, "Linear", nil)
						v147(t6[8], "Contrast", 0, 0.35, "Linear", nil)
						v147(t6[9], "FillColor", Color3.fromRGB(255, 0, 0), 0.26667, "Linear", nil)
						v147(t6[9], "OutlineTransparency", 0, 0.26667, "Linear", nil)
						v147(t6[9], "FillTransparency", 1, 0.26667, "Linear", nil)
					end
					t7[515] = function() -- line: 1843
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[9], "FillColor", Color3.fromRGB(0, 0, 0), 0.01667, "Linear", nil)
						v147(t6[9], "OutlineTransparency", 1, 0.01667, "Linear", nil)
						v147(t6[9], "FillTransparency", 0, 0.01667, "Linear", nil)
					end
					t7[516] = function() -- line: 1848
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[9], "FillColor", Color3.fromRGB(0, 0, 0), 0.11667, "Linear", nil)
						v147(t6[9], "OutlineTransparency", 1, 0.11667, "Linear", nil)
						v147(t6[9], "FillTransparency", 0, 0.11667, "Linear", nil)
					end
					t7[520] = function() -- line: 1853
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 96, 0.03333, "Linear", nil)
						v147(t6[8], "TintColor", Color3.fromRGB(255, 255, 255), 0.01667, "Linear", nil)
						v147(t6[8], "Brightness", -0.7, 0.01667, "Linear", nil)
						v147(t6[8], "Saturation", 0, 0.01667, "Linear", nil)
						v147(t6[8], "Contrast", 1, 0.01667, "Linear", nil)
					end
					t7[521] = function() -- line: 1860
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "TintColor", Color3.fromRGB(255, 255, 255), 0.1, "Linear", nil)
						v147(t6[8], "Brightness", -0.7, 0.03333, "Linear", nil)
						v147(t6[8], "Saturation", 0, 0.05, "Linear", nil)
						v147(t6[8], "Contrast", 0.5, 0.05, "Linear", nil)
					end
					t7[522] = function() -- line: 1866
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 51.000003814697266, 0.06667, "Linear", nil)
					end
					t7[523] = function() -- line: 1869
						-- upvalues: Root (copy), Emit (copy), clone3 (copy), v147 (copy), t6 (ref)
						task.spawn(function() -- line: 1870
							-- upvalues: Root (copy), Emit (copy), clone3 (copy)
							for _, descendant in Root.Footsteps.POUNCE2:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end

							for _, descendant in clone3.Texture.Star:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
						v147(t6[8], "Brightness", 0.5, 0.03333, "Linear", nil)
						v147(t6[9], "FillColor", Color3.fromRGB(255, 0, 0), 0.01667, "Linear", nil)
						v147(t6[9], "OutlineTransparency", 0, 0.01667, "Linear", nil)
						v147(t6[9], "FillTransparency", 1, 0.01667, "Linear", nil)
					end
					t7[524] = function() -- line: 1896
						-- upvalues: ControlRig (copy), Emit (copy), clone3 (copy), v147 (copy), t6 (ref)
						task.spawn(function() -- line: 1897
							-- upvalues: ControlRig (copy), Emit (copy), clone3 (copy)
							for _, descendant in ControlRig.CUTSCENEVFX.TP3rd:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end

							for _, descendant in clone3.Texture.Star:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
						v147(t6[8], "Saturation", 0, 0.05, "Linear", nil)
						v147(t6[8], "Contrast", 2, 0.01667, "Linear", nil)
						v147(t6[9], "FillColor", Color3.fromRGB(255, 0, 0), 0.56667, "Linear", nil)
						v147(t6[9], "OutlineTransparency", 0, 0.56667, "Linear", nil)
						v147(t6[9], "FillTransparency", 1, 0.56667, "Linear", nil)
					end
					t7[525] = function() -- line: 1924
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "Brightness", 0, 0.03333, "Linear", nil)
						v147(t6[8], "Contrast", 0, 0.03333, "Linear", nil)
					end
					t7[526] = function() -- line: 1928
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 51.000003814697266, 0.21667, "Linear", nil)
					end
					t7[527] = function() -- line: 1931
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "TintColor", Color3.fromRGB(255, 255, 255), 0.6, "Linear", nil)
						v147(t6[8], "Brightness", 0, 0.6, "Linear", nil)
						v147(t6[8], "Saturation", 0, 0.6, "Linear", nil)
						v147(t6[8], "Contrast", 0, 0.6, "Linear", nil)
					end
					t7[534] = function() -- line: 1937
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[6], "FarIntensity", 0.4300000071525574, 0.08333, "Linear", nil)
						v147(t6[6], "InFocusRadius", 0, 0.08333, "Linear", nil)
						v147(t6[6], "FocusDistance", 0, 0.08333, "Linear", nil)
						v147(t6[6], "NearIntensity", 0.15000000596046448, 0.08333, "Linear", nil)
					end
					t7[539] = function() -- line: 1943
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 45, 0.13333, "Linear", nil)
						v147(t6[6], "FarIntensity", 0.7850000262260437, 0.45, "Linear", nil)
						v147(t6[6], "InFocusRadius", 0, 0.45, "Linear", nil)
						v147(t6[6], "FocusDistance", 55.91999816894531, 0.45, "Linear", nil)
						v147(t6[6], "NearIntensity", 0, 0.45, "Linear", nil)
					end
					t7[547] = function() -- line: 1950
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 64, 0.06667, "Linear", nil)
					end
					t7[551] = function() -- line: 1953
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 51.000003814697266, 0.1, "Linear", nil)
					end
					t7[557] = function() -- line: 1956
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 42, 0.08333, "Linear", nil)
					end
					t7[558] = function() -- line: 1959
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[9], "FillColor", Color3.fromRGB(0, 0, 0), 0.01667, "Linear", nil)
						v147(t6[9], "OutlineTransparency", 1, 0.01667, "Linear", nil)
						v147(t6[9], "FillTransparency", 0, 0.01667, "Linear", nil)
					end
					t7[559] = function() -- line: 1964
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[9], "FillColor", Color3.fromRGB(0, 0, 0), 0.11667, "Linear", nil)
						v147(t6[9], "OutlineTransparency", 1, 0.11667, "Linear", nil)
						v147(t6[9], "FillTransparency", 0, 0.11667, "Linear", nil)
					end
					t7[562] = function() -- line: 1969
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 40, 0.4, "Linear", nil)
					end
					t7[563] = function() -- line: 1972
						-- upvalues: Root (copy), Emit (copy), clone3 (copy), v147 (copy), t6 (ref)
						task.spawn(function() -- line: 1973
							-- upvalues: Root (copy), Emit (copy), clone3 (copy)
							for _, descendant in Root.Footsteps.POUNCE:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end

							for _, descendant in clone3.Texture.Star:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
						v147(t6[8], "TintColor", Color3.fromRGB(255, 255, 255), 0.01667, "Linear", nil)
						v147(t6[8], "Brightness", -0.7, 0.01667, "Linear", nil)
						v147(t6[8], "Saturation", 0, 0.01667, "Linear", nil)
						v147(t6[8], "Contrast", 1, 0.01667, "Linear", nil)
					end
					t7[564] = function() -- line: 1999
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "TintColor", Color3.fromRGB(255, 255, 255), 0.1, "Linear", nil)
						v147(t6[8], "Brightness", -0.7, 0.03333, "Linear", nil)
						v147(t6[8], "Saturation", 0, 0.05, "Linear", nil)
						v147(t6[8], "Contrast", 0.5, 0.05, "Linear", nil)
					end
					t7[566] = function() -- line: 2005
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[6], "FarIntensity", 0.21199999749660492, 0.16667, "Linear", nil)
						v147(t6[6], "InFocusRadius", 0, 0.16667, "Linear", nil)
						v147(t6[6], "FocusDistance", 42.41999816894531, 0.16667, "Linear", nil)
						v147(t6[6], "NearIntensity", 0, 0.16667, "Linear", nil)
						v147(t6[8], "Brightness", 0.5, 0.03333, "Linear", nil)
						v147(t6[9], "FillColor", Color3.fromRGB(255, 0, 0), 0.01667, "Linear", nil)
						v147(t6[9], "OutlineTransparency", 0, 0.01667, "Linear", nil)
						v147(t6[9], "FillTransparency", 1, 0.01667, "Linear", nil)
					end
					t7[567] = function() -- line: 2015
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "Saturation", 0, 0.05, "Linear", nil)
						v147(t6[8], "Contrast", 2, 0.01667, "Linear", nil)
						v147(t6[9], "OutlineTransparency", 0, 4.5, "Linear", nil)
						v147(t6[9], "FillTransparency", 1, 4.5, "Linear", nil)
					end
					t7[568] = function() -- line: 2021
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "Brightness", 0, 0.03333, "Linear", nil)
						v147(t6[8], "Contrast", 0, 0.03333, "Linear", nil)
					end
					t7[570] = function() -- line: 2025
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "TintColor", Color3.fromRGB(255, 255, 255), 1.01667, "Linear", nil)
						v147(t6[8], "Brightness", 0, 1.01667, "Linear", nil)
						v147(t6[8], "Saturation", 0, 1.01667, "Linear", nil)
						v147(t6[8], "Contrast", 0, 1.01667, "Linear", nil)
					end
					t7[576] = function() -- line: 2031
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[6], "FarIntensity", 0, 0.45, "Linear", nil)
						v147(t6[6], "InFocusRadius", 0, 0.45, "Linear", nil)
						v147(t6[6], "FocusDistance", 0, 0.45, "Linear", nil)
						v147(t6[6], "NearIntensity", 0, 0.45, "Linear", nil)
					end
					t7[586] = function() -- line: 2037
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 41, 0.01667, "Linear", nil)
					end
					t7[587] = function() -- line: 2040
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 35, 0.68333, "Back", "In", 1.70158)
					end
					t7[603] = function() -- line: 2043
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[6], "FarIntensity", 0.21199999749660492, 2.3, "Linear", nil)
						v147(t6[6], "InFocusRadius", 0, 2.3, "Linear", nil)
						v147(t6[6], "FocusDistance", 42.41999816894531, 2.3, "Linear", nil)
						v147(t6[6], "NearIntensity", 0, 2.3, "Linear", nil)
					end
					t7[608] = function() -- line: 2049
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[42], "Enabled", false, 0.43333, "Constant", nil)
						v147(t6[43], "Enabled", false, 0.43333, "Constant", nil)
					end
					t7[615] = function() -- line: 2053
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[13], "Enabled", false, 0.68333, "Constant", nil)
					end
					t7[622] = function() -- line: 2056
						-- upvalues: clone3 (copy), Emit (copy)
						task.spawn(function() -- line: 2057
							-- upvalues: clone3 (copy), Emit (copy)
							for _, descendant in clone3.Texture.Pressure:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end

							for _, descendant in clone3.Texture.Star:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
					end
					t7[623] = function() -- line: 2079
						-- upvalues: CamReAdd (copy), Emit (copy), clone3 (copy)
						task.spawn(function() -- line: 2080
							-- upvalues: CamReAdd (copy), Emit (copy), clone3 (copy)
							for _, descendant in CamReAdd.Cam.ScreenFX.Wind:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end

							for _, descendant in clone3.Texture.Star:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
					end
					t7[624] = function() -- line: 2102
						-- upvalues: clone2 (copy), Emit (copy), clone3 (copy)
						task.spawn(function() -- line: 2103
							-- upvalues: clone2 (copy), Emit (copy), clone3 (copy)
							for _, descendant in clone2.Texture.Pressure:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end

							for _, descendant in clone3.Texture.Star:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
					end
					t7[628] = function() -- line: 2125
						-- upvalues: v147 (copy), t6 (ref), ControlRig (copy), Emit (copy), clone3 (copy)
						v147(t6[4], "FieldOfView", 15, 0.03333, "Bounce", "Out")
						task.spawn(function() -- line: 2127
							-- upvalues: ControlRig (copy), Emit (copy), clone3 (copy)
							for _, descendant in ControlRig.SETCFRAMES.CubeBreak:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end

							for _, descendant in clone3.Texture.Star:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
					end
					t7[629] = function() -- line: 2149
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[11], "Enabled", false, 0.46667, "Constant", nil)
						v147(t6[12], "Enabled", false, 0.46667, "Constant", nil)
						v147(t6[23], "ImageTransparency", 0, 0.01667, "Linear", nil)
						v147(t6[24], "ImageTransparency", 0, 0.01667, "Linear", nil)
						v147(t6[25], "ImageTransparency", 0, 0.01667, "Linear", nil)
						v147(t6[26], "ImageTransparency", 0, 0.01667, "Linear", nil)
						v147(t6[27], "ImageTransparency", 0, 0.01667, "Linear", nil)
						v147(t6[28], "ImageTransparency", 0, 0.01667, "Linear", nil)
						v147(t6[29], "ImageTransparency", 0, 0.01667, "Linear", nil)
						v147(t6[30], "ImageTransparency", 0, 0.01667, "Linear", nil)
						v147(t6[31], "ImageTransparency", 0, 0.01667, "Linear", nil)
						v147(t6[32], "ImageTransparency", 0, 0.01667, "Linear", nil)
						v147(t6[33], "ImageTransparency", 0, 0.01667, "Linear", nil)
						v147(t6[34], "ImageTransparency", 0, 0.01667, "Linear", nil)
						v147(t6[35], "ImageTransparency", 0, 0.01667, "Linear", nil)
						v147(t6[36], "ImageTransparency", 0, 0.01667, "Linear", nil)
						v147(t6[37], "ImageTransparency", 0, 0.01667, "Linear", nil)
						v147(t6[38], "ImageTransparency", 0, 0.01667, "Linear", nil)
						v147(t6[39], "ImageTransparency", 0, 0.01667, "Linear", nil)
						v147(t6[40], "ImageTransparency", 0, 0.01667, "Linear", nil)
						v147(t6[41], "ImageTransparency", 0, 0.01667, "Linear", nil)
					end
					t7[630] = function() -- line: 2172
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 66, 0.1, "Linear", nil)
						v147(t6[23], "ImageTransparency", 1, 0.46667, "Bounce", "In")
						v147(t6[24], "ImageTransparency", 1, 0.46667, "Bounce", "In")
						v147(t6[25], "ImageTransparency", 1, 0.46667, "Bounce", "In")
						v147(t6[26], "ImageTransparency", 1, 0.46667, "Bounce", "In")
						v147(t6[27], "ImageTransparency", 1, 0.46667, "Bounce", "In")
						v147(t6[28], "ImageTransparency", 1, 0.46667, "Bounce", "In")
						v147(t6[29], "ImageTransparency", 1, 0.46667, "Bounce", "In")
						v147(t6[30], "ImageTransparency", 1, 0.46667, "Bounce", "In")
						v147(t6[31], "ImageTransparency", 1, 0.46667, "Bounce", "In")
						v147(t6[32], "ImageTransparency", 1, 0.46667, "Bounce", "In")
						v147(t6[33], "ImageTransparency", 1, 0.46667, "Bounce", "In")
						v147(t6[34], "ImageTransparency", 1, 0.46667, "Bounce", "In")
						v147(t6[35], "ImageTransparency", 1, 0.46667, "Bounce", "In")
						v147(t6[36], "ImageTransparency", 1, 0.46667, "Bounce", "In")
						v147(t6[37], "ImageTransparency", 1, 0.46667, "Bounce", "In")
						v147(t6[38], "ImageTransparency", 1, 0.46667, "Bounce", "In")
						v147(t6[39], "ImageTransparency", 1, 0.46667, "Bounce", "In")
						v147(t6[40], "ImageTransparency", 1, 0.46667, "Bounce", "In")
						v147(t6[41], "ImageTransparency", 1, 0.46667, "Bounce", "In")
					end
					t7[631] = function() -- line: 2194
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "TintColor", Color3.fromRGB(133, 85, 255), 0.01667, "Linear", nil)
						v147(t6[8], "Brightness", -5, 0.01667, "Linear", nil)
						v147(t6[8], "Saturation", -1, 0.01667, "Linear", nil)
						v147(t6[8], "Contrast", -5, 0.01667, "Linear", nil)
					end
					t7[632] = function() -- line: 2200
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "TintColor", Color3.fromRGB(133, 85, 255), 0.03333, "Linear", nil)
						v147(t6[8], "Brightness", -5, 0.03333, "Linear", nil)
						v147(t6[8], "Saturation", -1, 0.03333, "Linear", nil)
						v147(t6[8], "Contrast", -5, 0.03333, "Linear", nil)
					end
					t7[633] = function() -- line: 2206
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[11], "Lifetime", 0.30000001192092896, 1.33333, "Linear", nil)
						v147(t6[12], "Lifetime", 0.30000001192092896, 1.33333, "Linear", nil)
					end
					t7[634] = function() -- line: 2210
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "TintColor", Color3.fromRGB(133, 85, 255), 0.01667, "Linear", nil)
						v147(t6[8], "Brightness", 2, 0.01667, "Linear", nil)
						v147(t6[8], "Saturation", -1, 0.01667, "Linear", nil)
						v147(t6[8], "Contrast", -5, 0.01667, "Linear", nil)
						v147(t6[42], "Enabled", true, 1.26667, "Constant", nil)
						v147(t6[43], "Enabled", true, 1.26667, "Constant", nil)
					end
					t7[635] = function() -- line: 2218
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "TintColor", Color3.fromRGB(62, 70, 255), 0.01667, "Linear", nil)
						v147(t6[8], "Brightness", 2, 0.01667, "Linear", nil)
						v147(t6[8], "Saturation", 1, 0.01667, "Linear", nil)
						v147(t6[8], "Contrast", 1, 0.01667, "Linear", nil)
					end
					t7[636] = function() -- line: 2224
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 66, 0.33333, "Linear", nil)
						v147(t6[8], "TintColor", Color3.fromRGB(133, 85, 255), 0.01667, "Linear", nil)
						v147(t6[8], "Brightness", -5, 0.01667, "Linear", nil)
						v147(t6[8], "Saturation", -1, 0.01667, "Linear", nil)
						v147(t6[8], "Contrast", -5, 0.01667, "Linear", nil)
					end
					t7[637] = function() -- line: 2231
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "TintColor", Color3.fromRGB(186, 177, 255), 0.03333, "Linear", nil)
						v147(t6[8], "Brightness", 0.5, 0.03333, "Linear", nil)
						v147(t6[8], "Saturation", 0, 0.03333, "Linear", nil)
						v147(t6[8], "Contrast", 0.7, 0.03333, "Linear", nil)
					end
					t7[639] = function() -- line: 2237
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "TintColor", Color3.fromRGB(255, 255, 255), 0.51667, "Linear", nil)
						v147(t6[8], "Brightness", 0, 0.51667, "Linear", nil)
						v147(t6[8], "Saturation", -0.695652186870575, 0.23333, "Linear", nil)
						v147(t6[8], "Contrast", 0.695652186870575, 0.23333, "Linear", nil)
					end
					t7[653] = function() -- line: 2243
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "Saturation", 0, 0.28333, "Linear", nil)
						v147(t6[8], "Contrast", 0, 0.28333, "Linear", nil)
					end
					t7[656] = function() -- line: 2247
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 104, 0.01667, "Linear", nil)
						v147(t6[13], "Enabled", true, 0.03333, "Constant", nil)
					end
					t7[657] = function() -- line: 2251
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 55, 0.65, "Back", "InOut", 1.70158)
						v147(t6[11], "Enabled", true, 0.28333, "Constant", nil)
						v147(t6[12], "Enabled", true, 0.28333, "Constant", nil)
					end
					t7[658] = function() -- line: 2256
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[13], "Enabled", false, 1.15, "Constant", nil)
					end
					t7[670] = function() -- line: 2259
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "TintColor", Color3.fromRGB(255, 255, 255), 0.01667, "Linear", nil)
						v147(t6[8], "Brightness", -0.7, 0.01667, "Linear", nil)
						v147(t6[8], "Saturation", 0, 0.01667, "Linear", nil)
						v147(t6[8], "Contrast", 1, 0.01667, "Linear", nil)
					end
					t7[671] = function() -- line: 2265
						-- upvalues: CamReAdd (copy), Emit (copy), clone3 (copy), v147 (copy), t6 (ref)
						task.spawn(function() -- line: 2266
							-- upvalues: CamReAdd (copy), Emit (copy), clone3 (copy)
							for _, descendant in CamReAdd.Cam.ScreenFX.Wind:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end

							for _, descendant in clone3.Texture.Star:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
						v147(t6[8], "TintColor", Color3.fromRGB(255, 255, 255), 0.1, "Linear", nil)
						v147(t6[8], "Brightness", -0.7, 0.03333, "Linear", nil)
						v147(t6[8], "Saturation", 0, 0.05, "Linear", nil)
						v147(t6[8], "Contrast", 0.5, 0.05, "Linear", nil)
					end
					t7[673] = function() -- line: 2292
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "Brightness", 0.5, 0.03333, "Linear", nil)
					end
					t7[674] = function() -- line: 2295
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "Saturation", 0, 0.05, "Linear", nil)
						v147(t6[8], "Contrast", 2, 0.01667, "Linear", nil)
						v147(t6[11], "Enabled", true, 0.65, "Constant", nil)
						v147(t6[12], "Enabled", true, 0.65, "Constant", nil)
					end
					t7[675] = function() -- line: 2301
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "Brightness", 0, 0.03333, "Linear", nil)
						v147(t6[8], "Contrast", 0, 0.03333, "Linear", nil)
					end
					t7[677] = function() -- line: 2305
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "TintColor", Color3.fromRGB(255, 255, 255), 1.1, "Linear", nil)
						v147(t6[8], "Brightness", 0, 1.1, "Linear", nil)
						v147(t6[8], "Saturation", 0, 1.1, "Linear", nil)
						v147(t6[8], "Contrast", 0, 1.1, "Linear", nil)
					end
					t7[680] = function() -- line: 2311
						-- upvalues: CamReAdd (copy), Emit (copy), clone3 (copy)
						task.spawn(function() -- line: 2312
							-- upvalues: CamReAdd (copy), Emit (copy), clone3 (copy)
							for _, descendant in CamReAdd.Cam.ScreenFX.Wind:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end

							for _, descendant in clone3.Texture.Star:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
					end
					t7[696] = function() -- line: 2334
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 55, 0.01667, "Linear", nil)
					end
					t7[697] = function() -- line: 2337
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 98, 0.48333, "Bounce", "In")
					end
					t7[708] = function() -- line: 2340
					end
					t7[710] = function() -- line: 2343
						-- upvalues: Character (copy), Emit (copy), clone3 (copy), v147 (copy), t6 (ref)
						task.spawn(function() -- line: 2344
							-- upvalues: Character (copy), Emit (copy), clone3 (copy)
							for _, descendant in Character.LowerTorso.SPIN:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end

							for _, descendant in clone3.Texture.Star:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
						v147(t6[42], "Enabled", false, 1.3, "Constant", nil)
						v147(t6[43], "Enabled", false, 1.3, "Constant", nil)
					end
					t7[713] = function() -- line: 2368
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[11], "Enabled", false, 0.36667, "Constant", nil)
						v147(t6[11], "Lifetime", 2, 0.46667, "Linear", nil)
						v147(t6[12], "Enabled", false, 0.36667, "Constant", nil)
						v147(t6[12], "Lifetime", 2, 0.46667, "Linear", nil)
						v147(t6[14], "Enabled", false, 0.28333, "Constant", nil)
					end
					t7[718] = function() -- line: 2375
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[14], "Lifetime", 0, 0.8, "Linear", nil)
					end
					t7[726] = function() -- line: 2378
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 40, 0.01667, "Linear", nil)
					end
					t7[727] = function() -- line: 2381
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 65, 0.4, "Linear", nil)
					end
					t7[730] = function() -- line: 2384
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[14], "Enabled", true, 0.1, "Constant", nil)
					end
					t7[735] = function() -- line: 2387
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[11], "Enabled", true, 0.01667, "Constant", nil)
						v147(t6[12], "Enabled", true, 0.01667, "Constant", nil)
					end
					t7[736] = function() -- line: 2391
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[11], "Enabled", false, 0.18333, "Constant", nil)
						v147(t6[12], "Enabled", false, 0.18333, "Constant", nil)
						v147(t6[14], "Enabled", false, 0.46667, "Constant", nil)
					end
					t7[738] = function() -- line: 2396
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[7], "Threshold", 5, 0.26667, "Linear", nil)
						v147(t6[7], "Intensity", 0, 0.26667, "Linear", nil)
						v147(t6[7], "Size", 56, 0.26667, "Linear", nil)
					end
					t7[739] = function() -- line: 2401
						-- upvalues: Character (copy), Emit (copy), clone3 (copy)
						task.spawn(function() -- line: 2402
							-- upvalues: Character (copy), Emit (copy), clone3 (copy)
							for _, descendant in Character.LowerTorso.SPIN:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end

							for _, descendant in clone3.Texture.Star:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
					end
					t7[741] = function() -- line: 2424
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[6], "FarIntensity", 0.4300000071525574, 0.2, "Linear", nil)
						v147(t6[6], "InFocusRadius", 0, 0.2, "Linear", nil)
						v147(t6[6], "FocusDistance", 0, 0.2, "Linear", nil)
						v147(t6[6], "NearIntensity", 0.15000000596046448, 0.2, "Linear", nil)
						v147(t6[11], "Lifetime", 0.30000001192092896, 0.28333, "Linear", nil)
						v147(t6[12], "Lifetime", 0.30000001192092896, 0.2, "Linear", nil)
					end
					t7[743] = function() -- line: 2432
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "TintColor", Color3.fromRGB(255, 255, 255), 1.48333, "Linear", nil)
						v147(t6[8], "Brightness", 0, 0.56667, "Linear", nil)
						v147(t6[8], "Saturation", -0.695652186870575, 0.56667, "Bounce", "In")
						v147(t6[8], "Contrast", 0.695652186870575, 0.56667, "Bounce", "In")
					end
					t7[744] = function() -- line: 2438
						-- upvalues: Root (copy), Emit (copy), clone3 (copy)
						task.spawn(function() -- line: 2439
							-- upvalues: Root (copy), Emit (copy), clone3 (copy)
							for _, descendant in Root.DOWNSHOCK:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end

							for _, descendant in clone3.Texture.Star:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
					end
					t7[747] = function() -- line: 2461
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[11], "Enabled", false, 0.56667, "Constant", nil)
						v147(t6[12], "Enabled", false, 0.56667, "Constant", nil)
					end
					t7[751] = function() -- line: 2465
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 61, 0.23333, "Linear", nil)
					end
					t7[753] = function() -- line: 2468
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[6], "FarIntensity", 0.7850000262260437, 0.33333, "Linear", nil)
						v147(t6[6], "InFocusRadius", 0, 0.33333, "Linear", nil)
						v147(t6[6], "FocusDistance", 8.600000381469727, 0.33333, "Linear", nil)
						v147(t6[6], "NearIntensity", 0, 0.33333, "Linear", nil)
						v147(t6[12], "Lifetime", 0, 0.43333, "Linear", nil)
					end
					t7[754] = function() -- line: 2475
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[7], "Threshold", 1.4780000448226929, 0.25, "Linear", nil)
						v147(t6[7], "Intensity", 0.20000000298023224, 0.25, "Linear", nil)
						v147(t6[7], "Size", 56, 0.25, "Linear", nil)
					end
					t7[758] = function() -- line: 2480
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[11], "Lifetime", 0.30000001192092896, 0.35, "Linear", nil)
					end
					t7[764] = function() -- line: 2483
					end
					t7[765] = function() -- line: 2486
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 52, 0.06667, "Linear", nil)
					end
					t7[766] = function() -- line: 2489
					end
					t7[769] = function() -- line: 2492
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 58, 0.13333, "Linear", nil)
						v147(t6[7], "Threshold", 1.4780000448226929, 0.6, "Linear", nil)
						v147(t6[7], "Intensity", 0.20000000298023224, 0.6, "Linear", nil)
						v147(t6[7], "Size", 56, 0.6, "Linear", nil)
					end
					t7[772] = function() -- line: 2498
						-- upvalues: Character (copy), Emit (copy), clone3 (copy)
						task.spawn(function() -- line: 2499
							-- upvalues: Character (copy), Emit (copy), clone3 (copy)
							for _, descendant in Character.LowerTorso.SPIN:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end

							for _, descendant in clone3.Texture.Star:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
					end
					t7[773] = function() -- line: 2521
						-- upvalues: v147 (copy), t6 (ref), CFrame2 (copy)
						v147(t6[6], "FarIntensity", 0.21199999749660492, 0.16667, "Linear", nil)
						v147(t6[6], "InFocusRadius", 0, 0.16667, "Linear", nil)
						v147(t6[6], "FocusDistance", 42.41999816894531, 0.16667, "Linear", nil)
						v147(t6[6], "NearIntensity", 0, 0.16667, "Linear", nil)
						v147(t6[50], "CFrame", CFrame2 * CFrame.new(0, 10000, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), 1.23333, "Linear", nil)
					end
					t7[777] = function() -- line: 2528
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 48, 0.33333, "Linear", nil)
						v147(t6[8], "Brightness", -1.5, 0.05, "Linear", nil)
						v147(t6[8], "Saturation", -1, 0.05, "Linear", nil)
						v147(t6[8], "Contrast", 1, 0.05, "Linear", nil)
					end
					t7[779] = function() -- line: 2534
					end
					t7[780] = function() -- line: 2537
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "Brightness", 0, 0.01667, "Linear", nil)
						v147(t6[8], "Saturation", 0, 0.01667, "Linear", nil)
						v147(t6[8], "Contrast", 0, 0.01667, "Linear", nil)
					end
					t7[781] = function() -- line: 2542
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "Brightness", 0, 0.6, "Linear", nil)
						v147(t6[8], "Saturation", 0, 0.6, "Linear", nil)
						v147(t6[8], "Contrast", 0, 0.6, "Linear", nil)
					end
					t7[783] = function() -- line: 2547
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[6], "FarIntensity", 0.21199999749660492, 0.7, "Linear", nil)
						v147(t6[6], "InFocusRadius", 0, 0.7, "Linear", nil)
						v147(t6[6], "FocusDistance", 42.41999816894531, 0.7, "Linear", nil)
						v147(t6[6], "NearIntensity", 0, 0.7, "Linear", nil)
					end
					t7[788] = function() -- line: 2553
					end
					t7[792] = function() -- line: 2556
						-- upvalues: Root (copy), Emit (copy), clone3 (copy)
						task.spawn(function() -- line: 2557
							-- upvalues: Root (copy), Emit (copy), clone3 (copy)
							for _, descendant in Root.SLICEBAMP:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end

							for _, descendant in clone3.Texture.Star:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
					end
					t7[796] = function() -- line: 2579
					end
					t7[797] = function() -- line: 2582
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 42, 0.53333, "Linear", nil)
					end
					t7[805] = function() -- line: 2585
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[7], "Threshold", 5, 0.26667, "Linear", nil)
						v147(t6[7], "Intensity", 0, 0.26667, "Linear", nil)
						v147(t6[7], "Size", 56, 0.26667, "Linear", nil)
					end
					t7[817] = function() -- line: 2590
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "Brightness", 0, 0.23333, "Linear", nil)
						v147(t6[8], "Saturation", -1, 0.23333, "Linear", nil)
						v147(t6[8], "Contrast", 1, 0.23333, "Linear", nil)
					end
					t7[821] = function() -- line: 2595
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[7], "Threshold", 1, 0.25, "Linear", nil)
						v147(t6[7], "Intensity", 0.19999999999999998, 0.25, "Linear", nil)
						v147(t6[7], "Size", 12, 0.25, "Linear", nil)
					end
					t7[825] = function() -- line: 2600
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[6], "FarIntensity", 0.7850000262260437, 0.15, "Linear", nil)
						v147(t6[6], "InFocusRadius", 0, 0.15, "Linear", nil)
						v147(t6[6], "FocusDistance", 8.600000381469727, 0.15, "Linear", nil)
						v147(t6[6], "NearIntensity", 0, 0.15, "Linear", nil)
					end
					t7[829] = function() -- line: 2606
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 12, 0.01667, "Linear", nil)
					end
					t7[830] = function() -- line: 2609
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 12, 0.03333, "Linear", nil)
					end
					t7[831] = function() -- line: 2612
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "Brightness", 0, 0.01667, "Linear", nil)
						v147(t6[8], "Saturation", 0, 0.01667, "Linear", nil)
						v147(t6[8], "Contrast", 0, 0.01667, "Linear", nil)
					end
					t7[832] = function() -- line: 2617
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 55, 0.2, "Expo", "Out")
						v147(t6[8], "TintColor", Color3.fromRGB(133, 85, 255), 0.01667, "Linear", nil)
						v147(t6[8], "Brightness", -5, 0.01667, "Linear", nil)
						v147(t6[8], "Saturation", -1, 0.01667, "Linear", nil)
						v147(t6[8], "Contrast", -5, 0.01667, "Linear", nil)
					end
					t7[833] = function() -- line: 2624
						-- upvalues: v85 (copy), LocalPlayer (copy), CamReAdd (copy), CFrame4 (ref), Util (copy), Root (copy), Emit (copy), clone3 (copy), v147 (copy), t6 (ref)
						task.spawn(function() -- line: 2625
							-- upvalues: v85 (copy), LocalPlayer (copy), CamReAdd (copy), CFrame4 (ref), Util (copy), Root (copy), Emit (copy), clone3 (copy)
							if not v85 then
								local Character2 = LocalPlayer.Character
								local HumanoidRootPartCFrame = Character2.HumanoidRootPart.CFrame

								CamReAdd:PivotTo(HumanoidRootPartCFrame)
								CFrame4 = HumanoidRootPartCFrame

								local v367 = Util.Anims:Get(Character2, "CRUltimate_VictimPlayer")

								v367.Priority = Enum.AnimationPriority.Action4
								v367:Play()

								local v368 = Util.Anims:Get(CamReAdd, "CRUltimate_VictimCamera")

								v368.Priority = Enum.AnimationPriority.Action4
								v368:Play()
							end

							for _, descendant in Root.BIGSLICE:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end

							for _, descendant in clone3.Texture.Star:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
						v147(t6[8], "TintColor", Color3.fromRGB(133, 85, 255), 0.01667, "Linear", nil)
						v147(t6[8], "Brightness", -5, 0.01667, "Linear", nil)
						v147(t6[8], "Saturation", -1, 0.01667, "Linear", nil)
						v147(t6[8], "Contrast", -5, 0.01667, "Linear", nil)
					end
					t7[834] = function() -- line: 2666
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[6], "FarIntensity", 0, 0.25, "Linear", nil)
						v147(t6[6], "InFocusRadius", 0, 0.25, "Linear", nil)
						v147(t6[6], "FocusDistance", 0, 0.25, "Linear", nil)
						v147(t6[6], "NearIntensity", 0, 0.25, "Linear", nil)
						v147(t6[8], "TintColor", Color3.fromRGB(133, 85, 255), 0.03333, "Linear", nil)
						v147(t6[8], "Brightness", 0, 0.03333, "Linear", nil)
						v147(t6[8], "Saturation", -1, 0.03333, "Linear", nil)
						v147(t6[8], "Contrast", -5, 0.03333, "Linear", nil)
					end
					t7[836] = function() -- line: 2676
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "TintColor", Color3.fromRGB(62, 70, 255), 0.01667, "Linear", nil)
						v147(t6[8], "Brightness", 2, 0.01667, "Linear", nil)
						v147(t6[8], "Saturation", 1, 0.01667, "Linear", nil)
						v147(t6[8], "Contrast", 1, 0.01667, "Linear", nil)
					end
					t7[837] = function() -- line: 2682
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "TintColor", Color3.fromRGB(133, 85, 255), 0.05, "Linear", nil)
						v147(t6[8], "Brightness", -5, 0.05, "Linear", nil)
						v147(t6[8], "Saturation", -1, 0.05, "Linear", nil)
						v147(t6[8], "Contrast", -5, 0.05, "Linear", nil)
						v147(t6[9], "OutlineTransparency", 1, 0.01667, "Linear", nil)
						v147(t6[9], "FillTransparency", 1, 0.01667, "Linear", nil)
						v147(t6[44], "Enabled", true, 0.05, "Constant", nil)
						v147(t6[44], "Width0", 0, 0.15, "Linear", nil)
						v147(t6[44], "Width1", 0, 0.15, "Linear", nil)
						v147(t6[45], "Enabled", true, 0.05, "Constant", nil)
						v147(t6[45], "Width0", 0, 0.15, "Linear", nil)
						v147(t6[45], "Width1", 0, 0.15, "Linear", nil)
						v147(t6[46], "Enabled", true, 0.05, "Constant", nil)
						v147(t6[46], "Width0", 0, 0.15, "Linear", nil)
						v147(t6[46], "Width1", 0, 0.15, "Linear", nil)
						v147(t6[47], "Enabled", true, 0.05, "Constant", nil)
						v147(t6[47], "Width0", 0, 0.15, "Linear", nil)
						v147(t6[47], "Width1", 0, 0.15, "Linear", nil)
					end
					t7[838] = function() -- line: 2702
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[9], "OutlineTransparency", 1, 0.15, "Linear", nil)
						v147(t6[9], "FillTransparency", 1, 0.15, "Linear", nil)
					end
					t7[840] = function() -- line: 2706
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "TintColor", Color3.fromRGB(186, 177, 255), 0.03333, "Linear", nil)
						v147(t6[8], "Brightness", 0.5, 0.03333, "Linear", nil)
						v147(t6[8], "Saturation", 0, 0.03333, "Linear", nil)
						v147(t6[8], "Contrast", 0.7, 0.03333, "Linear", nil)
					end
					t7[842] = function() -- line: 2712
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "TintColor", Color3.fromRGB(255, 255, 255), 0.03333, "Linear", nil)
						v147(t6[8], "Brightness", 0, 0.03333, "Linear", nil)
						v147(t6[8], "Saturation", 0, 0.03333, "Linear", nil)
						v147(t6[8], "Contrast", 0, 0.03333, "Linear", nil)
					end
					t7[844] = function() -- line: 2718
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[4], "FieldOfView", 120, 1.06667, "Back", "In", 1.70158)
						v147(t6[8], "TintColor", Color3.fromRGB(133, 85, 255), 0.01667, "Linear", nil)
						v147(t6[8], "Brightness", -5, 0.01667, "Linear", nil)
						v147(t6[8], "Saturation", -1, 0.01667, "Linear", nil)
						v147(t6[8], "Contrast", -5, 0.01667, "Linear", nil)
					end
					t7[845] = function() -- line: 2725
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "TintColor", Color3.fromRGB(133, 85, 255), 0.01667, "Linear", nil)
						v147(t6[8], "Brightness", -5, 0.01667, "Linear", nil)
						v147(t6[8], "Saturation", -1, 0.01667, "Linear", nil)
						v147(t6[8], "Contrast", -5, 0.01667, "Linear", nil)
					end
					t7[846] = function() -- line: 2731
						-- upvalues: Root (copy), Emit (copy), clone3 (copy), v147 (copy), t6 (ref)
						task.spawn(function() -- line: 2732
							-- upvalues: Root (copy), Emit (copy), clone3 (copy)
							for _, descendant in Root.DOMAINBREAK:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end

							for _, descendant in clone3.Texture.Star:GetDescendants() do
								if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
									Emit(descendant)
								end
							end
						end)
						v147(t6[8], "TintColor", Color3.fromRGB(255, 255, 255), 0.03333, "Linear", nil)
						v147(t6[8], "Brightness", 0, 0.03333, "Linear", nil)
						v147(t6[8], "Saturation", 0, 0.03333, "Linear", nil)
						v147(t6[8], "Contrast", 0, 0.03333, "Linear", nil)
						v147(t6[44], "Width0", 15, 0.06667, "Linear", nil)
						v147(t6[44], "Width1", 15, 0.06667, "Linear", nil)
						v147(t6[45], "Width0", 15, 0.06667, "Linear", nil)
						v147(t6[45], "Width1", 15, 0.06667, "Linear", nil)
						v147(t6[46], "Width0", 15, 0.06667, "Linear", nil)
						v147(t6[46], "Width1", 15, 0.06667, "Linear", nil)
						v147(t6[47], "Width0", 15, 0.06667, "Linear", nil)
						v147(t6[47], "Width1", 15, 0.06667, "Linear", nil)
					end
					t7[847] = function() -- line: 2766
						-- upvalues: v147 (copy), t6 (ref), v85 (copy), CFrame3 (copy), CFrame4 (ref)
						v147(t6[9], "OutlineTransparency", 0, 0.01667, "Linear", nil)
						v147(t6[9], "FillTransparency", 1, 0.01667, "Linear", nil)

						if not v85 then
							v147(t6[51], "CFrame", CFrame3 * CFrame.new(0, 0, 0, 1, -2.9016967560466852E-40, 0, -8.705090268140056E-40, 1, 1.284651299361831E-19, 0, 4.282171213284388E-20, 1), 0.01667, "Linear", nil)
							v147(t6[52], "CFrame", CFrame4 * CFrame.new(0, -3.181999921798706, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), 0.01667, "Linear", nil)

							return
						end

						v147(t6[51], "CFrame", CFrame3 * CFrame.new(0, 10000, 0, 1, -2.9016967560466852E-40, 0, -8.705090268140056E-40, 1, 1.284651299361831E-19, 0, 4.282171213284388E-20, 1), 0.01667, "Linear", nil)
						v147(t6[52], "CFrame", CFrame4 * CFrame.new(0, 9996.818000078201, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), 0.01667, "Linear", nil)
					end
					t7[848] = function() -- line: 2777
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "TintColor", Color3.fromRGB(255, 255, 255), 0.1, "Linear", nil)
						v147(t6[8], "Brightness", 0, 0.1, "Linear", nil)
						v147(t6[8], "Saturation", -1, 0.01667, "Linear", nil)
						v147(t6[8], "Contrast", 1, 0.01667, "Linear", nil)
					end
					t7[849] = function() -- line: 2783
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[6], "FarIntensity", 0.22599999606609344, 0.7, "Bounce", "In")
						v147(t6[6], "InFocusRadius", 20.969999313354492, 0.7, "Bounce", "In")
						v147(t6[6], "FocusDistance", 12.899999618530273, 0.7, "Bounce", "In")
						v147(t6[6], "NearIntensity", 0, 0.7, "Bounce", "In")
						v147(t6[8], "Saturation", 0, 0.08333, "Linear", nil)
						v147(t6[8], "Contrast", 0, 0.08333, "Linear", nil)
					end
					t7[850] = function() -- line: 2791
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[44], "Width0", 0, 0.75, "Back", "In", 1.70158)
						v147(t6[44], "Width1", 0, 0.75, "Back", "In", 1.70158)
						v147(t6[45], "Width0", 0, 0.75, "Back", "In", 1.70158)
						v147(t6[45], "Width1", 0, 0.75, "Back", "In", 1.70158)
						v147(t6[46], "Width0", 0, 0.75, "Back", "In", 1.70158)
						v147(t6[46], "Width1", 0, 0.75, "Back", "In", 1.70158)
						v147(t6[47], "Width0", 0, 0.75, "Back", "In", 1.70158)
						v147(t6[47], "Width1", 0, 0.75, "Back", "In", 1.70158)
					end
					t7[854] = function() -- line: 2801
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "Brightness", 0, 0.55, "Linear", nil)
						v147(t6[8], "Saturation", 0, 0.55, "Linear", nil)
						v147(t6[8], "Contrast", 0, 0.55, "Linear", nil)
					end
					t7[887] = function() -- line: 2806
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[8], "Brightness", 1.5, 0.35, "Linear", nil)
						v147(t6[8], "Saturation", -1, 0.35, "Linear", nil)
					end
					t7[891] = function() -- line: 2810
						-- upvalues: v147 (copy), t6 (ref)
						v147(t6[5], "ExposureCompensation", 3, 0.18333, "Linear", nil)
						v147(t6[6], "FarIntensity", 0, 0.25, "Linear", nil)
						v147(t6[6], "InFocusRadius", 0, 0.25, "Linear", nil)
						v147(t6[6], "FocusDistance", 0, 0.25, "Linear", nil)
						v147(t6[6], "NearIntensity", 0, 0.25, "Linear", nil)
					end
					t7[895] = function() -- line: 2817
					end
					t7[902] = function() -- line: 2820
					end
					t7[906] = function() -- line: 2823
					end
					t7[908] = function() -- line: 2826
						-- upvalues: Root (copy), RootCFrame (copy), v147 (copy), t6 (ref), ExposureCompensation (copy)
						Root.CFrame = RootCFrame
						v147(t6[51], "CFrame", RootCFrame, 0.05, "Linear", nil)
						v147(t6[4], "FieldOfView", 70, 0.05, "Back", "In", 1.70158)
						v147(t6[5], "ExposureCompensation", ExposureCompensation, 0.05, "Linear", nil)
					end
					_G.updateMusic2(true)

					local n1 = -1
					local n2 = 0

					while not u93 do
						local v168 = n2 * 60 // 1
						local v169 = v168 - n1

						if v169 > 0 then
							for i = n1 + 1, n1 + v169 do
								local v171 = t7[i]

								if v171 then
									pcall(v171)
								end
							end

							n1 = v168
						end

						n2 += RunService.RenderStepped:Wait() * 1

						if v168 > 908 then
							break
						end
					end

					pcall(clear)
					t6 = nil
				end)
				Util.Anims:Get(Character, "CRUltimate_Player"):Play()
				Util.Anims:Get(clone2, "CRUltimate_LeftDagger"):Play()
				Util.Anims:Get(clone3, "CRUltimate_RightDagger"):Play()
				Util.Anims:Get(CamReAdd, "CRUltimate_Camera"):Play()
				Util.Anims:Get(Cubes, "CRUltimate_Cubes"):Play()

				local timestamp = tick()
				local CurrentCamera2 = workspace.CurrentCamera

				if v87 then
					CurrentCamera2.CameraType = Enum.CameraType.Scriptable
				end

				connection2 = LocalPlayer.CharacterRemoving:Once(function() -- line: 2908
					-- upvalues: u76 (ref)
					u76()
				end)
				connection = RunService.RenderStepped:Connect(function(_) -- line: 2912
					-- upvalues: CamReAdd (copy), timestamp (copy), connection (ref), CurrentCamera2 (copy)
					if CamReAdd.Parent == nil or tick() - timestamp > 15.133333333333333 then
						connection:Disconnect()
						CurrentCamera2.CameraType = Enum.CameraType.Custom
						CurrentCamera2.CameraSubject = game.Players.LocalPlayer.Character.Humanoid

						return
					end

					CurrentCamera2.CFrame = CamReAdd.Cam.CFrame
				end)
			end
		end)

		if not ok then
			warn("wow nice it broke", result)

			if Model then
				Model:Destroy()
			end

			if u76 then
				task.spawn(u76)
			end
		end
	end
end
