
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Util = require(ReplicatedStorage:WaitForChild("Util"))
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CurrentCamera = workspace.CurrentCamera
local FX = require(ReplicatedStorage:WaitForChild("FX"))
local ControlFX = FX:WaitForChild("ControlRework")
local XOutside = ControlFX.XOutside
local GroundSliceTemplate = XOutside.Phase0:FindFirstChild("SliceGround") or ControlFX.CDagger.Phase1.SliceGround
local SparkTemplate = XOutside.Phase0:FindFirstChild("IronSingleSpark") or ControlFX.CDagger.Phase1.IronSingleSpark
local DarkSlashTemplate = XOutside.Phase0:FindFirstChild("DarkSlash") or ControlFX.XDagger.Phase0.DarkSlash
local Shared = script.Parent.Shared
local Utility = Shared.Utility
local VisualHelper = require(Utility.VisualHelper)
local MathHelper = require(Utility.MathHelper)

require(Shared.Textures)

local Rocks = require(Shared.Rocks)

require(Shared:WaitForChild("ObjectClass"))

local HexsStormClass = require(Shared:WaitForChild("HexsStormClass"))
local LightningBoltShafi = Util.LightningBoltShafi

local function RecolorControlColor(p1, color3: Color3) -- line: 22
	-- upvalues: Util (copy)
	if typeof(p1) ~= "Instance" or not p1:IsA("Player") or not p1.Parent then
		return color3
	end

	return Util.WrapColor3Constructor(color3, p1, "ControlFruitVFXColor")
end
local function RecolorControlColorSequence(p2, p3) -- line: 29
	-- upvalues: Util (copy)
	if typeof(p2) ~= "Instance" or not p2:IsA("Player") or not p2.Parent then
		return p3
	end

	return Util.WrapColorSequenceConstructor(p3, p2, "ControlFruitVFXColor")
end

local _WorldOrigin = workspace._WorldOrigin
local Domain_Katsuo = FX:WaitForChild("ControlRework").Domain_Katsuo
local C_Katsuo = FX:WaitForChild("ControlRework").C_Katsuo
local X_Katsuo = FX:WaitForChild("ControlRework").X_Katsuo

local function DeleteImpactAfterDuration(p4) -- line: 46
	task.spawn(function() -- line: 47
		-- upvalues: p4 (copy)
		local n1 = 0

		for _, descendant in pairs(p4:GetDescendants()) do
			if descendant:IsA("ParticleEmitter") then
				n1 = math.max(n1, descendant.Lifetime.Max)
			end
		end

		task.wait(n1)
		p4:Destroy()
	end)
end

function Debris(p5, n2: number) -- line: 59
	if not p5 then
		return
	end

	if n2 > 0 then
		return task.delay(n2, p5.Destroy, p5)
	end

	if p5 then
		p5:Destroy()
	end
end

local function Slash(cFrame: CFrame, n3: number?, b1: boolean?, n4: number?, p6) -- line: 68
	-- upvalues: _WorldOrigin (copy), Util (copy), XOutside (copy), VisualHelper (copy)
	local Model = Instance.new("Model")

	Model.Parent = _WorldOrigin
	Util.Debris:AddItem(Model, 10)

	local Model2 = Instance.new("Model", Model)
	local clone = XOutside.Phase0.Slash:Clone()

	clone:ScaleTo(n4 or 1.65)

	local Slash2 = clone.Slash

	Slash2.CFrame = cFrame
	Util.SetParentOverrideWithColor(Slash2, Model2, p6, "ControlFruitVFXColor")
	VisualHelper:Tween(Slash2.Winds, TweenInfo.new(0.17, Enum.EasingStyle.Sine), {
		Orientation = Vector3.new(0, 360, 0)
	})

	for _, child in Slash2.Winds:GetChildren() do
		child.Beam.Enabled = true
		VisualHelper:Tween(child.Beam, TweenInfo.new(0.17, Enum.EasingStyle.Sine), {
			Width0 = 0,
			Width1 = 0
		})
	end

	for _, descendant in Slash2.Slash:GetDescendants() do
		if descendant:IsA("ParticleEmitter") then
			descendant.LockedToPart = true
			descendant.Rotation = NumberRange.new(n3 or 0)
			VisualHelper:Emit(descendant)
		end
	end

	VisualHelper:EmitAll(Slash2, true)

	local SlashBeam = Slash2.SlashBeam

	SlashBeam.Orientation = Vector3.new(0, 180, 0)

	if b1 then
		local v50 = VisualHelper.BeamsFlipBook.new(8, 60)

		v50:Insert(SlashBeam.BeamThunder)
		v50:Play()
		task.delay(1, v50.Destroy, v50)
	end

	VisualHelper:Tween(SlashBeam, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {
		Orientation = SlashBeam.Orientation + Vector3.new(0, 180, 0)
	})

	for _, child in SlashBeam.Beams:GetChildren() do
		child.Enabled = true
		child.Width0 = child.Width0 * 2
		child.Width1 = child.Width1 * 2
		VisualHelper:Tween(child, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {
			Width0 = 0,
			Width1 = 0
		})
	end

	VisualHelper:Tween(Slash2.PointLight, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {
		Brightness = 0
	})
	Debris(Slash2, 2)

	return Slash2
end
local function DarkSlash(cFrame: CFrame, n5: number?, b2: boolean?, n6: number?, p7) -- line: 127
	-- upvalues: _WorldOrigin (copy), Util (copy), XOutside (copy), VisualHelper (copy)
	local Model = Instance.new("Model")

	Model.Parent = _WorldOrigin
	Util.Debris:AddItem(Model, 10)

	local clone = DarkSlashTemplate:Clone()

	clone:ScaleTo(n6 or 1.65)

	local Slash3 = clone.Slash

	Slash3.CFrame = cFrame
	Util.SetParentOverrideWithColor(Slash3, Model, p7, "ControlFruitVFXColor")
	VisualHelper:Tween(Slash3.Winds, TweenInfo.new(0.17, Enum.EasingStyle.Sine), {
		Orientation = Vector3.new(0, 360, 0)
	})

	for _, child in Slash3.Winds:GetChildren() do
		child.Beam.Enabled = true
		VisualHelper:Tween(child.Beam, TweenInfo.new(0.17, Enum.EasingStyle.Sine), {
			Width0 = 0,
			Width1 = 0
		})
	end

	for _, descendant in Slash3.Slash:GetDescendants() do
		if descendant:IsA("ParticleEmitter") then
			descendant.Rotation = NumberRange.new(n5 or 0)
			VisualHelper:Emit(descendant)
		end
	end

	VisualHelper:EmitAll(Slash3, true)

	local SlashBeam = Slash3.SlashBeam

	SlashBeam.Orientation = Vector3.new(0, 180, 0)

	if b2 then
		local v66 = VisualHelper.BeamsFlipBook.new(8, 60)

		v66:Insert(SlashBeam.BeamThunder)
		v66:Play()
		task.delay(1, v66.Destroy, v66)
	end

	VisualHelper:Tween(SlashBeam, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {
		Orientation = SlashBeam.Orientation + Vector3.new(0, 180, 0)
	})

	for _, child in SlashBeam.Beams:GetChildren() do
		child.Enabled = true
		child.Width0 = child.Width0 * 2
		child.Width1 = child.Width1 * 2
		VisualHelper:Tween(child, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {
			Width0 = 0,
			Width1 = 0
		})
	end

	VisualHelper:Tween(Slash3.PointLight, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {
		Brightness = 0
	})
	Debris(Slash3, 2)

	local StaticSlash = Slash3.StaticSlash

	StaticSlash.Beam.Enabled = true
	task.delay(0.025, function() -- line: 183
		-- upvalues: StaticSlash (copy)
		StaticSlash:Destroy()
	end)

	return Slash3
end
local function Flash(p8, b3: boolean, p9) -- line: 190
	-- upvalues: XOutside (copy), Util (copy)
	local clone = XOutside.Phase0.VaultF.Flash:Clone()

	Util.SetParentOverrideWithColor(clone, p8, p9, "ControlFruitVFXColor")

	for _, descendant in clone:GetDescendants() do
		descendant:Emit(descendant:GetAttribute("Emit"))
		descendant.LockedToPart = b3 or false
	end

	Debris(clone, 0.6)
end

local Map = workspace.Map

local function EmitExplosion(p10, b4: boolean?, p11) -- line: 204
	-- upvalues: _WorldOrigin (copy), Util (copy), XOutside (copy), VisualHelper (copy), MathHelper (copy), Map (copy)
	if not p10 then
		return
	end

	local v79 = typeof(p10) == "RaycastResult"
	local Model = Instance.new("Model")

	Model.Parent = _WorldOrigin
	Util.Debris:AddItem(Model, 10)
	Util.CameraShaker:Shake("Fast")

	local v81 = v79 and CFrame.lookAt(p10.Position, p10.Position + p10.Normal) * CFrame.Angles(-1.5707963267948966, 0, 0) * CFrame.new(0, 0.5, 0) or p10
	local clone = XOutside.Phase0.Explosion:Clone()

	clone:PivotTo(v81)
	Util.SetParentOverrideWithColor(clone, Model, p11, "ControlFruitVFXColor")

	if not v79 then
		clone.Main.GlowShape.Crater:Destroy()
	end

	VisualHelper:EmitAll(clone)
	Debris(clone, 6)

	local v83 = clone.Main.Size.X / 2
	local Beams = clone.Main.Beams

	VisualHelper:Tween(Beams, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {
		Orientation = Beams.Orientation + Vector3.new(0, 550, 0)
	})

	for _, descendant in Beams:GetDescendants() do
		if descendant:IsA("Beam") then
			descendant.Enabled = true
			VisualHelper:Tween(descendant, TweenInfo.new(0.2 + math.random() * 0.1, Enum.EasingStyle.Sine), {
				Width0 = 0,
				Width1 = 0
			})
		end
	end

	Debris(Beams, 0.5)

	local clone2 = XOutside.Phase0.BallNeon:Clone()

	clone2.CFrame = v81
	clone2.Transparency = 0.94

	local color3 = Color3.fromRGB(89, 133, 255)

	clone2.Color = if typeof(p11) == "Instance" and (not not p11:IsA("Player") and p11.Parent) then Util.WrapColor3Constructor(color3, p11, "ControlFruitVFXColor") else color3
	clone2.Size = Vector3.new(1, 1, 1) * (clone.Main.Size.Y * 0.65)
	clone2.Parent = Model
	VisualHelper:Tween(clone2, TweenInfo.new(0.14, Enum.EasingStyle.Sine), {
		Transparency = 1,
		Size = clone2.Size * 1.35
	})
	Debris(clone2, 0.14)

	local clone3 = XOutside.Phase0.BallNeon:Clone()

	clone3.CFrame = v81
	clone3.Transparency = 0.85

	local color3_2 = Color3.fromRGB(89, 133, 255)

	clone3.Color = if typeof(p11) == "Instance" and (not not p11:IsA("Player") and p11.Parent) then Util.WrapColor3Constructor(color3_2, p11, "ControlFruitVFXColor") else color3_2
	clone3.Size = Vector3.new(1, 1, 1) * clone.Main.Size.Y
	clone3.Parent = Model
	VisualHelper:Tween(clone3, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {
		Transparency = 1,
		Size = clone3.Size * 1.6
	})
	Debris(clone3, 0.15)

	if b4 then
		return
	end

	for _, child in clone.Main.Boom:GetChildren() do
		if child.Name == "Smoke" then
			child:Destroy()
		end
	end

	task.spawn(function() -- line: 273
		-- upvalues: v81 (copy), v83 (copy), MathHelper (copy), Map (copy), XOutside (copy), Util (copy), Model (copy), p11 (copy), VisualHelper (copy)
		for _ = 1, 3 do
			local v135 = v81 * CFrame.Angles(0, math.random() * 3.141592653589793 * 2, 0) * CFrame.new(0, 1, -math.random(v83 + 5, v83 + 25))
			local v136 = MathHelper:RayCast(v135.Position, v135.UpVector * -10, { Map }, Enum.RaycastFilterType.Include)

			if v136 then
				local clone4 = XOutside.Phase0.BoltExplosion:Clone()

				clone4.CFrame = CFrame.lookAt(v136.Position, v136.Position + v136.Normal) * CFrame.Angles(-1.5707963267948966, 0, 0) * CFrame.new(0, 0.5, 0)
				Util.SetParentOverrideWithColor(clone4, Model, p11, "ControlFruitVFXColor")
				VisualHelper:EmitAll(clone4)
				Debris(clone4, 1)
			end

			task.wait(0.125)
		end
	end)
end
local function EmitFloor(cFrame: CFrame, p12) -- line: 292
	-- upvalues: _WorldOrigin (copy), Util (copy), XOutside (copy), VisualHelper (copy)
	local Model = Instance.new("Model")

	Model.Parent = _WorldOrigin
	Util.Debris:AddItem(Model, 10)

	local clone = XOutside.Phase0.FloorSpawnEnd:Clone()

	clone.CFrame = cFrame
	Util.SetParentOverrideWithColor(clone, Model, p12, "ControlFruitVFXColor")
	VisualHelper:EmitAll(clone)
	clone.PointLight.Enabled = true
	VisualHelper:Tween(clone.PointLight, TweenInfo.new(0.25, Enum.EasingStyle.Sine), {
		Brightness = 0
	})
	Debris(clone, 2.15)
end

local random = Random.new()

return function(p13) -- line: 316
	-- upvalues: CurrentCamera (copy), Util (copy), TweenService (copy), Domain_Katsuo (copy), VisualHelper (copy), C_Katsuo (copy), MathHelper (copy), random (copy), X_Katsuo (copy), RunService (copy), _WorldOrigin (copy), XOutside (copy), Map (copy), EmitExplosion (copy), LightningBoltShafi (copy), Rocks (copy), EmitFloor (copy), Slash (copy), HexsStormClass (copy), Flash (copy)
	if typeof(p13.Player) == "Instance" and (p13.Player:IsA("Player") and not p13.Player:FindFirstChild("PlayerGui") and p13.Player ~= game.Players.LocalPlayer) then
		Instance.new("Folder", p13.Player).Name = "PlayerGui"
	end

	local v98 = p13.Origin or (p13.Root and p13.Root.Position or (p13.hrp and p13.hrp.Position or (p13.Player and p13.Player.Character.PrimaryPart.Position or p13.player and p13.player.Character.PrimaryPart.Position)))

	assert(v98, "Origin Vector3 missing in: ", script:GetFullName())

	if (CurrentCamera.CFrame.Position - v98).Magnitude > 1200 then
		return
	end

	local Stage = p13.Stage

	if Stage == 1 then
		local Player = p13.Player
		local Character = p13.Character
		local Root = p13.Root
		local Holding = p13.Holding

		if not Holding or not Holding.Value then
			return
		end

		local Model = Instance.new("Model", workspace._WorldOrigin)

		Util.Sound:Play("X_Activate_01", Root.Position)

		local v105 = Util.Sound:Play("X_Held_01", Root)

		TweenService:Create(v105, TweenInfo.new(0.4), {
			Volume = 1
		}):Play()

		local clone = Domain_Katsuo.ShaderScreen:Clone()

		clone.Name = "ControlXShaderScreen"
		clone.Image.ImageTransparency = 1
		clone.Parent = p13.Player == game.Players.LocalPlayer and p13.Player.PlayerGui or Model
		VisualHelper:Tween(clone.Image, TweenInfo.new(0.6, Enum.EasingStyle.Sine), {
			ImageTransparency = 0.86
		})

		local clone5 = Domain_Katsuo.DoubleNeonEye:Clone()

		clone5.Weld.Part0 = Character.Head
		Util.SetParentOverrideWithColor(clone5, Model, Player, "ControlFruitVFXColor")
		VisualHelper:SetEnableAll(clone5, true)

		local clone6 = C_Katsuo.FloorSpawn:Clone()

		clone6.CFrame = Root.CFrame * CFrame.new(0, -2.8, 0)
		Util.SetParentOverrideWithColor(clone6, Model, Player, "ControlFruitVFXColor")

		if not MathHelper:GroundRayCast(Character) then
			clone6.SmokeRotation:Destroy()
		end

		VisualHelper:Tween(clone6.CircleWinds, TweenInfo.new(0.25, Enum.EasingStyle.Sine), {
			Orientation = clone6.CircleWinds.Orientation + Vector3.new(0, 180, 0)
		})
		VisualHelper:EmitAll(clone6)
		clone6.PointLight.Enabled = true
		VisualHelper:Tween(clone6.PointLight, TweenInfo.new(0.25, Enum.EasingStyle.Sine), {
			Brightness = 0
		})

		for _, child in clone6.CircleWinds:GetChildren() do
			local Beam = child.Beam
			local v112 = Beam.Width0 / 2
			local v113 = Beam.Width1 / 2

			Beam.Width0 = v112
			Beam.Width1 = v113
			Beam.Enabled = true
			VisualHelper:Tween(Beam, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {
				Width0 = 0,
				Width1 = 0
			})
		end

		Util.Debris:AddItem(clone6, 2.15)

		local clone7 = C_Katsuo.NeonRotation:Clone()

		clone7:ScaleTo(1.2)
		clone7.Main.Weld.Part0 = Root
		Util.SetParentOverrideWithColor(clone7, Model, Player, "ControlFruitVFXColor")
		clone7.Main.Layers.Orientation = Vector3.new(0, 1, 0) * random:NextNumber(-360, 360)

		for i, child in clone7.Main.Layers:GetChildren() do
			child.Orientation = child.Orientation * 1.5
			child.Position = child.Position * 1.5

			local Beam = child.Beam
			local v118 = Beam.Width0 / 2
			local v119 = Beam.Width1 / 2

			Beam.Width0 = v118
			Beam.Width1 = v119
			Beam.Enabled = true

			local v120 = random:NextNumber(0.17, 0.25)

			VisualHelper:Tween(child, TweenInfo.new(v120, Enum.EasingStyle.Linear), {
				Orientation = child.Orientation + Vector3.new(0, 450 * (i % 2 ~= 0 and -1 or 1))
			})
			VisualHelper:Tween(Beam, TweenInfo.new(v120, Enum.EasingStyle.Sine), {
				Width0 = 0,
				Width1 = 0
			})
		end

		Util.Debris:AddItem(clone7, 2)

		local clone8 = X_Katsuo.Handle:Clone()

		clone8.Weld.Part1 = Root
		Util.SetParentOverrideWithColor(clone8, Model, Player, "ControlFruitVFXColor")
		VisualHelper:Tween(clone8.Beams, TweenInfo.new(0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {
			Orientation = clone8.Beams.Orientation - Vector3.new(0, 360, 0)
		})
		VisualHelper:SetEnableAll(clone8, true)

		if Holding and Holding.Value then
			local clone9 = Domain_Katsuo.CameraEffectsHex:Clone()

			Util.SetParentOverrideWithColor(clone9, CurrentCamera, Player, "ControlFruitVFXColor")

			if p13.Player == game.Players.LocalPlayer then
				VisualHelper:SetEnableAll(clone9, true)
				VisualHelper:EmitAll(clone9)
			end

			local n7 = 0

			while Holding and Holding.Value do
				n7 += RunService.RenderStepped:Wait()
				clone9.CFrame = CurrentCamera.CFrame * CFrame.new(0, 0, -2.25) * CFrame.Angles(0, 1.5707963267948966, 0)
			end

			clone9:Destroy()
		end

		if v105 then
			Util.Sound:FadeOut(v105, 0.2)
		end

		clone8:Destroy()
		clone5:Destroy()
		Util.Debris:AddItem(Model, 3)
		Util.Debris:AddItem(clone, 9)

		return
	end

	if Stage == 2 then
		local Player = p13.Player
		local ControlXShaderScreen = nil

		if Player == game:GetService("Players").LocalPlayer then
			ControlXShaderScreen = Player.PlayerGui:FindFirstChild("ControlXShaderScreen")
		end

		local Model = Instance.new("Model")

		Model.Parent = _WorldOrigin
		Util.Debris:AddItem(Model, 14)

		local _ = p13.Character
		local Root = p13.Root
		local StartCFrame = p13.StartCFrame

		Util.Sound:Play("X_Release_01", Root)

		local raycastParams = RaycastParams.new()

		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		raycastParams.IgnoreWater = false
		raycastParams.FilterDescendantsInstances = {
			workspace._WorldOrigin,
			workspace.Characters,
			workspace.Enemies
		}
		task.spawn(function() -- line: 474
			-- upvalues: XOutside (copy), Util (copy), Model (copy), Player (copy), StartCFrame (copy), p13 (copy), MathHelper (copy), Map (copy), EmitExplosion (copy), VisualHelper (copy), CurrentCamera (copy), Root (copy), LightningBoltShafi (copy), ControlXShaderScreen (ref), RunService (copy), random (copy), Rocks (copy), EmitFloor (copy), Slash (copy), TweenService (copy), HexsStormClass (copy), Flash (copy)
			local clone = XOutside.Phase0.Knife:Clone()

			clone:PivotTo(CFrame.new(0, 100000, 0))
			Util.SetParentOverrideWithColor(clone, Model, Player, "ControlFruitVFXColor")

			local v139 = StartCFrame
			local Distance = p13.Distance

			MathHelper:RayCast(v139.Position, v139.LookVector * (Distance + 3), { Map }, Enum.RaycastFilterType.Include)

			local function GetCFrameFromRayCast(raycastResult: RaycastResult) -- line: 488
				-- upvalues: StartCFrame (copy)
				return raycastResult and CFrame.new(CFrame.lookAt(raycastResult.Position, raycastResult.Position + raycastResult.Normal) * CFrame.new(0, 0, -3).Position) * CFrame.Angles(StartCFrame:ToEulerAnglesXYZ())
			end

			local EndCFrame = p13.EndCFrame

			EmitExplosion(StartCFrame * CFrame.new(0, -2.8, 0), nil, Player)

			if p13.Player == game.Players.LocalPlayer then
				VisualHelper:Tween(CurrentCamera, TweenInfo.new(0.25, Enum.EasingStyle.Back), {
					FieldOfView = 80
				})
			end

			task.wait(0.085)

			local tweenInfo = TweenInfo.new(p13.Duration, Enum.EasingStyle.Linear)
			local v144 = VisualHelper:Tween(Root, tweenInfo, {
				CFrame = EndCFrame
			})

			for _ = 1, 6 do
				local v146 = 0.45 + math.random() * 0.3
				local v147 = v139.Position + Vector3.new(math.random(-6.5, 6.5), math.random(4.333333333333333), math.random(-6.5, 6.5))
				local clone10 = XOutside.Phase0.Vault.HexTrailSpecs:Clone()

				clone10.Position = v147
				Util.SetParentOverrideWithColor(clone10, workspace.Terrain, Player, "ControlFruitVFXColor")
				Debris(clone10, v146 + 0.5)

				local cFrame = CFrame.new(math.random(-35, 35), math.random(-35, 35), 0)
				local cFrame2 = CFrame.new(math.random(-35, 35), math.random(-35, 35), 0)

				VisualHelper:TweenNumberValue(1, TweenInfo.new(v146, Enum.EasingStyle.Sine), function(n8: number) -- line: 523
					-- upvalues: Root (copy), v147 (copy), cFrame (copy), cFrame2 (copy), clone10 (copy), MathHelper (copy)
					local RootPosition = Root.Position
					local Magnitude = (v147 - RootPosition).Magnitude
					local cFrame3 = CFrame.lookAt(v147, RootPosition)
					local v192 = cFrame3 * CFrame.new(0, 0, -Magnitude * 0.25) * cFrame.Position
					local v193 = cFrame3 * CFrame.new(0, 0, -Magnitude * 0.75) * cFrame2.Position

					clone10.Position = MathHelper:CubicBezier(n8, v147, v192, v193, RootPosition)
				end)
			end

			local function RushMeshs(b5: boolean?, n9: number?, cFrame: CFrame?) -- line: 537
				-- upvalues: XOutside (copy), StartCFrame (copy), Util (copy), Model (copy), Player (copy), VisualHelper (copy)
				local v197 = n9 or 1
				local clone11 = XOutside.Phase0.RushMeshs:Clone()

				clone11:PivotTo((cFrame or StartCFrame) * CFrame.new(0, 0, -8) * CFrame.Angles(1.5707963267948966, 0, 0))
				Util.SetParentOverrideWithColor(clone11, Model, Player, "ControlFruitVFXColor")
				Debris(clone11, 1)

				local AirMeshHuge = clone11.AirMeshHuge

				VisualHelper:Tween(AirMeshHuge.Mesh, TweenInfo.new(0.3 * v197, Enum.EasingStyle.Sine), {
					Scale = AirMeshHuge.Mesh.Scale * Vector3.new(3, 2, 3)
				})
				VisualHelper:Tween(AirMeshHuge.Decal, TweenInfo.new(0.3 * v197, Enum.EasingStyle.Sine), {
					Transparency = 1
				})

				local AirMeshStorm = clone11.AirMeshStorm

				if b5 then
					AirMeshStorm.Mesh.Scale = Vector3.new(4.5, 15, 4.5)
					AirMeshStorm.Decal.Transparency = 0.9
				end

				VisualHelper:Tween(AirMeshStorm.Mesh, TweenInfo.new(0.2 * v197, Enum.EasingStyle.Sine), {
					Scale = AirMeshStorm.Mesh.Scale * if not b5 then Vector3.new(0.20000000298023224, 1.2999999523162842, 0.20000000298023224) else Vector3.new(0.699999988079071, 1.5, 0.699999988079071)
				})
				VisualHelper:Tween(AirMeshStorm.Decal, TweenInfo.new(0.2 * v197, Enum.EasingStyle.Sine), {
					Transparency = 1
				})
				VisualHelper:Tween(AirMeshStorm, TweenInfo.new(0.2 * v197, Enum.EasingStyle.Sine), {
					CFrame = AirMeshStorm.CFrame * CFrame.Angles(0, 3.141592653589793, 0)
				})

				local AirMeshHuge2 = clone11.AirMeshHuge2

				VisualHelper:Tween(AirMeshHuge2.Mesh, TweenInfo.new(0.15 * v197, Enum.EasingStyle.Sine), {
					Scale = AirMeshHuge2.Mesh.Scale * 1.3
				})
				VisualHelper:Tween(AirMeshHuge2.Decal, TweenInfo.new(0.15 * v197, Enum.EasingStyle.Sine), {
					Transparency = 1
				})

				local AirMeshHuge3 = clone11.AirMeshHuge3

				VisualHelper:Tween(AirMeshHuge3.Mesh, TweenInfo.new(0.3 * v197, Enum.EasingStyle.Sine), {
					Scale = AirMeshHuge3.Mesh.Scale * 1.5
				})
				VisualHelper:Tween(AirMeshHuge3.Decal, TweenInfo.new(0.3 * v197, Enum.EasingStyle.Sine), {
					Transparency = 1
				})

				local AirMeshHuge4 = clone11.AirMeshHuge4

				VisualHelper:Tween(AirMeshHuge4.Mesh, TweenInfo.new(0.1 * v197, Enum.EasingStyle.Sine), {
					Scale = AirMeshHuge4.Mesh.Scale * Vector3.new(3, 1.399999976158142, 3)
				})
				VisualHelper:Tween(AirMeshHuge4.Decal, TweenInfo.new(0.1 * v197, Enum.EasingStyle.Sine), {
					Transparency = 1
				})

				local BodyFlash = clone11.BodyFlash

				VisualHelper:Tween(BodyFlash.Decal, TweenInfo.new(0.1 * v197, Enum.EasingStyle.Sine), {
					Transparency = 1
				})
				VisualHelper:Tween(BodyFlash.Mesh, TweenInfo.new(0.1 * v197, Enum.EasingStyle.Sine), {
					Scale = BodyFlash.Mesh.Scale * Vector3.new(3, 1.7999999523162842, 3)
				})
			end
			local function Rush(n10: number, cFrame: CFrame?) -- line: 583
				-- upvalues: RushMeshs (copy), XOutside (copy), StartCFrame (copy), Util (copy), Model (copy), Player (copy), VisualHelper (copy), Distance (copy), LightningBoltShafi (copy)
				RushMeshs(false, 1, cFrame)

				local clone12 = XOutside.Phase0.Rush:Clone()

				clone12.CFrame = (cFrame or StartCFrame) * CFrame.new(0, 0, -clone12.Size.Z / 2)
				Util.SetParentOverrideWithColor(clone12, Model, Player, "ControlFruitVFXColor")
				VisualHelper:Tween(clone12.PointLight, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
					Brightness = 0
				})
				VisualHelper:EmitAll(clone12)
				Debris(clone12, 1.5)

				local Beams = clone12.Beams

				for i, child in Beams.Beams:GetChildren() do
					child.Enabled = true

					if child.Name == "Air" then
						VisualHelper:Tween(child, TweenInfo.new(0.55, Enum.EasingStyle.Sine), {
							Brightness = 0
						})
					else
						local v211 = child.Name == "Fade"

						VisualHelper:Tween(child, TweenInfo.new(if not v211 then 0.17 + i * 0.01 else 0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, if not v211 then n10 * 0.5 else 0), {
							Width0 = 0,
							Width1 = 0
						})
					end
				end

				Beams.Drag.Position = Vector3.new(0, 0, 0)
				VisualHelper:Tween(Beams.Drag, TweenInfo.new(n10 * 0.2, Enum.EasingStyle.Sine), {
					Position = Vector3.new(0, 1, -Distance)
				})

				local function NewBolt(p14, p15, _: number?) -- line: 612
					-- upvalues: LightningBoltShafi (copy), Model (copy), Player (copy), Util (copy)
					local v274 = LightningBoltShafi.new(p14, p15, 15, 0.7 + math.random() * 0.5, Model)
					local v275 = math.random(5, 10)
					local v276 = math.random(-10, -5)

					v274.CurveSize0 = v275
					v274.CurveSize1 = v276
					v274.MinRadius = 1
					v274.MaxRadius = 6
					v274.Frequency = 0.7
					v274.AnimationSpeed = math.random(4.5, 8.5)

					local v277 = 0.3 + math.random() * 0.75

					v274.MinThicknessMultiplier = 0.1
					v274.MaxThicknessMultiplier = v277
					v274.MinTransparency = 0
					v274.MaxTransparency = 1
					v274.PulseSpeed = 40
					v274.PulseLength = 1000000
					v274.FadeLength = 0.2

					local v278 = Player
					local colorSequence = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(125, 164, 255)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(85, 93, 255))
					})

					v274.Color = if typeof(v278) == "Instance" and (not not v278:IsA("Player") and v278.Parent) then Util.WrapColorSequenceConstructor(colorSequence, v278, "ControlFruitVFXColor") else colorSequence
					v274.ContractFrom = 0.5
					v274.ColorOffsetSpeed = 3

					return v274
				end

				Debris(NewBolt(Beams, Beams.Drag, 20), n10 * 0.3 + 0.1)
				Debris(NewBolt(Beams, Beams.Drag, 20), n10 * 0.3 + 0.2)
			end

			if ControlXShaderScreen then
				VisualHelper:Tween(ControlXShaderScreen.Image, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {
					ImageTransparency = 0.75
				})
			end

			local Duration = p13.Duration

			Rush(Duration)
			task.wait(Duration)

			if ControlXShaderScreen then
				VisualHelper:Tween(ControlXShaderScreen.Image, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {
					ImageTransparency = 0.925
				})
			end

			v144:Cancel()
			EmitExplosion(Root.CFrame * CFrame.new(0, -2.8, 0), nil, Player)

			if p13.Player == game.Players.LocalPlayer then
				VisualHelper:Tween(CurrentCamera, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {
					FieldOfView = 70
				})
			end

			local EnemyChar = p13.EnemyChar

			if not EnemyChar then
				if ControlXShaderScreen then
					VisualHelper:Tween(ControlXShaderScreen.Image, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {
						ImageTransparency = 1
					})
					Debris(ControlXShaderScreen, 0.5)
				end

				clone:Destroy()

				return
			end

			local HumanoidRootPart = EnemyChar.HumanoidRootPart
			local ThrowDirection = p13.ThrowDirection

			Root.CFrame = ThrowDirection
			Util.Sound:Play("X_Impact_Slash_01", HumanoidRootPart.Position)

			if game.Players.LocalPlayer.Character and Root.Parent == game.Players.LocalPlayer.Character then
				local RootCFrame = Root.CFrame
				local CurrentCamera2 = workspace.CurrentCamera
				local CurrentCamera2CFrame = CurrentCamera2.CFrame
				local _ = CurrentCamera2CFrame.p - Root.Position
				local v161, _, _ = (CurrentCamera2CFrame - CurrentCamera2CFrame.p):ToOrientation()
				local _, v165, v166 = RootCFrame:ToOrientation()

				RunService:BindToRenderStep("controlXTeleportCam", Enum.RenderPriority.Camera.Value + 1, function(p16) -- line: 689
					-- upvalues: CurrentCamera2 (copy), RootCFrame (copy), v161 (copy), v165 (copy), v166 (copy), RunService (copy)
					if CurrentCamera2 then
						CurrentCamera2.CFrame = CurrentCamera2.CFrame:Lerp(CFrame.new(RootCFrame.p) * CFrame.fromOrientation(v161, v165, v166), 0.2 * p16 * 60)
					else
						RunService:UnbindFromRenderStep("controlXTeleportCam")
					end

					RunService.RenderStepped:Wait()
				end)
				task.spawn(function() -- line: 697
					-- upvalues: RunService (copy)
					task.wait(0.4)
					RunService:UnbindFromRenderStep("controlXTeleportCam")
				end)
			end

			EmitExplosion(HumanoidRootPart.CFrame * CFrame.new(0, -2.8, 0), nil, Player)

			local clone13 = XOutside.Phase0.CameraEffectsHex:Clone()

			Util.SetParentOverrideWithColor(clone13, CurrentCamera, Player, "ControlFruitVFXColor")

			local CurrentCamera3 = workspace.CurrentCamera

			if p13.Player == game.Players.LocalPlayer then
				VisualHelper:SetEnableAll(clone13, true)
				VisualHelper:EmitAll(clone13)
			end

			local u169 = nil
			local GroundPart = nil
			local clone14 = nil
			local u172 = false
			local n12 = 0
			local connection = RunService.RenderStepped:Connect(function(dt) -- line: 722
				-- upvalues: n12 (ref), clone13 (copy), CurrentCamera3 (copy), u169 (ref), clone14 (ref), HumanoidRootPart (copy), XOutside (copy), Util (copy), Player (copy), VisualHelper (copy), MathHelper (copy), GroundPart (ref), Map (copy), ThrowDirection (copy), u172 (ref), random (copy), Model (copy), Rocks (copy)
				n12 += dt
				clone13.CFrame = CurrentCamera3.CFrame * CFrame.new(0, 0, -2.25) * CFrame.Angles(0, 1.5707963267948966, 0)

				if u169 then
					u169:Update(dt)
				end

				local v215 = n12 > 0.08

				if v215 then
					n12 = 0
				end

				if clone14 and v215 then
					local v216 = clone14.Main.Size.X * 2

					clone14:PivotTo(CFrame.new(HumanoidRootPart.Position))

					for i = 1, 2 do
						local v218 = 0.2 + math.random(5) * 0.03 - i * 0.05
						local v219 = clone14.Main.Position + Vector3.new(math.random(-v216, v216), math.random(-v216, v216), math.random(-v216, v216))
						local MainPosition = clone14.Main.Position
						local clone15 = XOutside.Phase0.VaultC.HexTrailSpecsMove2:Clone()

						Util.SetParentOverrideWithColor(clone15, workspace.Terrain, Player, "ControlFruitVFXColor")
						clone15.Position = v219
						Debris(clone15, v218 + 0.5)

						local Magnitude = (v219 - MainPosition).Magnitude
						local cFrame = CFrame.lookAt(v219, MainPosition)
						local v224 = cFrame * CFrame.new(math.random(-65, 65), math.random(-65, 65), -Magnitude * 0.25).Position
						local v225 = cFrame * CFrame.new(math.random(-65, 65), math.random(-65, 65), -Magnitude * 0.75).Position

						VisualHelper:TweenNumberValue(1, TweenInfo.new(v218, Enum.EasingStyle.Sine), function(n13: number) -- line: 755
							-- upvalues: clone15 (copy), MathHelper (copy), v219 (copy), v224 (copy), v225 (copy), MainPosition (copy)
							clone15.Position = MathHelper:CubicBezier(n13, v219, v224, v225, MainPosition)
						end)
					end
				end

				if GroundPart then
					local GroundPartParent = GroundPart.Parent
					local v227 = GroundPartParent.Size.X / 2 + 2
					local v228 = MathHelper:RayCast(GroundPartParent.Position, GroundPartParent.CFrame.RightVector * -v227, { Map }, Enum.RaycastFilterType.Include)

					if v228 then
						local _, v230 = CFrame.lookAt(ThrowDirection.Position, (Vector3.new(v228.Position.X, ThrowDirection.Y, v228.Position.Z))):ToEulerAnglesYXZ()

						GroundPart.CFrame = CFrame.new(v228.Position + Vector3.new(0, 0.15000000596046448, 0)) * CFrame.Angles(0, v230, 0)

						if not u172 then
							u172 = true
							VisualHelper:SetEnableAll(GroundPart, u172)
						end

						if not v215 then
							return
						end

						local clone16 = GroundSliceTemplate:Clone()

						clone16:ScaleTo(random:NextNumber(1.55, 3))
						clone16:PivotTo(CFrame.lookAt(v228.Position, v228.Position + v228.Normal) * CFrame.Angles(-1.5707963267948966, math.rad((math.random(360))), 0) * CFrame.new(math.random(-5, 5), 0, 0))
						Util.SetParentOverrideWithColor(clone16, Model, Player, "ControlFruitVFXColor")
						VisualHelper:EmitAll(clone16)

						local SliceGroundSize = clone16.SliceGround.Size

						clone16.SliceGround.Size = Vector3.new(0, 0, 0)
						VisualHelper:Tween(clone16.SliceGround, TweenInfo.new(0.22, Enum.EasingStyle.Sine), {
							Size = SliceGroundSize
						})
						task.delay(0.3, function() -- line: 789
							-- upvalues: VisualHelper (copy), clone16 (copy)
							VisualHelper:Tween(clone16.SliceGround.Decal, TweenInfo.new(0.25), {
								Color3 = Color3.fromRGB()
							})
							VisualHelper:Tween(clone16.SliceGround, TweenInfo.new(0.3), {
								Size = Vector3.new(0, 0, clone16.SliceGround.Size.Z)
							})
							task.wait(0.3)
							clone16:Destroy()
						end)

						local v233 = Rocks:AirRocks(GroundPart.CFrame, SparkTemplate.Size, true, math.random(50, 115), 2, 0, 20, false, false, SparkTemplate:Clone(), function(p17) -- line: 797
							p17.Anchored = true
							local trail = p17:FindFirstChildWhichIsA("Trail", true)
							if trail then trail.Enabled = false end
							task.wait(2)
							p17:Destroy()
						end)

						VisualHelper:EmitAll(v233.Main)
						VisualHelper:Tween(v233.Main.PointLight, TweenInfo.new(2.3, Enum.EasingStyle.Sine), {
							Brightness = 0
						})

						return
					end

					if u172 then
						u172 = false
						VisualHelper:SetEnableAll(GroundPart, u172)
					end
				end
			end)

			task.wait(0.22)
			EmitFloor(Root.CFrame * CFrame.new(0, -2.8, 0), Player)
			task.wait(0.05)
			Slash(ThrowDirection * CFrame.new(0, 0, -1) * CFrame.Angles(0, 3.141592653589793, -0.7853981633974483), 100, true, 3)
			task.wait(0.05)
			EmitExplosion(Root.CFrame * CFrame.new(0, -2.8, 0), nil, Player)
			RushMeshs(true, 0.5)

			local cFrame = CFrame.Angles(0, 0, 1.0471975511965976)
			local clone17 = XOutside.Phase0.StormSlash:Clone()

			clone17.CFrame = p13.KnockCFrame * CFrame.new(0, 3.3, -4) * cFrame
			Util.SetParentOverrideWithColor(clone17, Model, Player, "ControlFruitVFXColor")
			GroundPart = clone17.GroundPart

			local WindStorm = clone17.Charge.WindStorm

			VisualHelper:Tween(WindStorm, TweenInfo.new(0.4, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {
				Orientation = WindStorm.Orientation - Vector3.new(0, 360, 0)
			})

			local Storm = clone17.Charge.Storm

			VisualHelper:Tween(Storm, TweenInfo.new(0.05, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {
				Orientation = Storm.Orientation - Vector3.new(0, 360, 0)
			})
			VisualHelper:SetEnableAll(clone17, true, true)
			VisualHelper:SetEnableAll(clone17.Charge, true)
			VisualHelper:EmitAll(clone17.Init)
			VisualHelper:Tween(clone17, TweenInfo.new(0.05, Enum.EasingStyle.Linear), {
				CFrame = p13.KnockCFrame * cFrame
			})

			local KnockCFrame = p13.KnockCFrame
			local tweenInfo2 = TweenInfo.new(0.2, Enum.EasingStyle.Sine)

			VisualHelper:Tween(HumanoidRootPart, tweenInfo2, {
				CFrame = KnockCFrame
			})
			VisualHelper:Tween(clone17, tweenInfo2, {
				CFrame = KnockCFrame * cFrame
			})
			task.spawn(function() -- line: 855
				-- upvalues: EmitFloor (copy), Root (copy), Player (copy), HumanoidRootPart (copy), p13 (copy), tweenInfo2 (copy), Slash (copy), EmitExplosion (copy), clone (copy), XOutside (copy), Util (copy), VisualHelper (copy), MathHelper (copy)
				EmitFloor(Root.CFrame * CFrame.new(0, -2.8, 0), Player)

				local cFrame4 = CFrame.Angles(0, 0, -1.5707963267948966)
				local cFrame5 = CFrame.lookAt(Root.Position, HumanoidRootPart.Position)
				local _ = p13.KnifeDistance
				local Time = tweenInfo2.Time
				local v238 = Slash(cFrame5 * CFrame.new(0, 0, -1) * CFrame.Angles(0, 3.141592653589793, -0.7853981633974483), 100, true, 3, Player)

				EmitExplosion(Root.CFrame * CFrame.new(0, -2.8, 0), nil, Player)
				clone:PivotTo(cFrame5 * cFrame4)

				for _ = 1, 4 do
					local v240 = Time * (0.5 + math.random() * 0.5)
					local v241 = cFrame5.Position + Vector3.new(math.random(-32, 32), math.random(21.333333333333332), math.random(-32, 32))
					local clone18 = XOutside.Phase0.VaultC.HexTrailSpecs3:Clone()

					clone18.Position = v241
					Util.SetParentOverrideWithColor(clone18, workspace.Terrain, Player, "ControlFruitVFXColor")
					Debris(clone18, v240 + 0.5)

					local cFrame6 = CFrame.new(math.random(-65, 65), math.random(-65, 65), 0)
					local cFrame7 = CFrame.new(math.random(-65, 65), math.random(-65, 65), 0)

					VisualHelper:TweenNumberValue(1, TweenInfo.new(v240, Enum.EasingStyle.Sine), function(n14: number) -- line: 884
						-- upvalues: clone (copy), v241 (copy), cFrame6 (copy), cFrame7 (copy), clone18 (copy), MathHelper (copy)
						local Position = clone:GetPivot().Position
						local Magnitude = (v241 - Position).Magnitude
						local cFrame8 = CFrame.lookAt(v241, Position)
						local v286 = cFrame8 * CFrame.new(0, 0, -Magnitude * 0.25) * cFrame6.Position
						local v287 = cFrame8 * CFrame.new(0, 0, -Magnitude * 0.75) * cFrame7.Position

						clone18.Position = MathHelper:CubicBezier(n14, v241, v286, v287, Position)
					end)
				end

				local descendants = clone:GetDescendants()

				for _, v in pairs(descendants) do
					if v:IsA("ParticleEmitter") then
						v:Emit(v.Rate / 10)
					end
				end

				local elapsed = os.clock()

				while Time > os.clock() - elapsed do
					local v249 = CFrame.lookAt(HumanoidRootPart.Position, Root.Position) * CFrame.Angles(0, 3.141592653589793, 0)

					clone:PivotTo(cFrame5:Lerp(v249, (os.clock() - elapsed) / Time) * cFrame4)
					v238.CFrame = clone:GetPivot()
					task.wait()
				end

				for _, v in pairs(descendants) do
					if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") or v:IsA("SurfaceGui") then
						v.Enabled = false
					elseif v:IsA("BasePart") then
						v.Transparency = 1
					end
				end

				task.wait(2)
				clone:Destroy()
			end)
			task.wait(tweenInfo2.Time)
			task.wait(0.05)
			GroundPart = nil
			VisualHelper:EmitAll(clone17.Init)
			VisualHelper:SetEnableAll(clone17, false)
			Debris(clone17, 1)
			VisualHelper:Tween(clone17.PointLight, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {
				Brightness = 0
			})

			local HumanoidRootPartCFrame = HumanoidRootPart.CFrame

			EmitExplosion(HumanoidRootPart.CFrame * CFrame.new(0, -2.8, 0), nil, Player)
			task.wait(0.03)
			EmitFloor(Root.CFrame * CFrame.new(0, -2.8, 0), Player)
			task.wait(0.1)
			task.spawn(function() -- line: 953
				-- upvalues: p13 (copy), TweenService (copy), CurrentCamera3 (copy), XOutside (copy), Model (copy), RunService (copy)
				if p13.EnemyChar ~= game.Players.LocalPlayer.Character then
					return
				end

				local function getHorizontalFov() -- line: 956
					local FieldOfView = game.Workspace.CurrentCamera.FieldOfView
					local ViewportSize = game.Workspace.CurrentCamera.ViewportSize
					local v290 = ViewportSize.X / ViewportSize.Y

					return (math.deg(math.atan(math.tan(math.rad(FieldOfView) * 0.5) * v290) * 2))
				end

				TweenService:Create(CurrentCamera3, TweenInfo.new(1.2), {
					FieldOfView = 100
				}):Play()

				local FieldOfView = game.Workspace.CurrentCamera.FieldOfView
				local ViewportSize = game.Workspace.CurrentCamera.ViewportSize
				local v255 = ViewportSize.X / ViewportSize.Y
				local v256 = 100 + (math.deg(math.atan(math.tan(math.rad(FieldOfView) * 0.5) * v255) * 2) - 100) / 1.65
				local t1 = {
					topLeft = CFrame.new() * CFrame.Angles(0.8726646259971648, math.rad(v256 / 2), 0) * CFrame.new(0, 0, -5),
					topRight = CFrame.new() * CFrame.Angles(0.8726646259971648, -math.rad(v256 / 2), 0) * CFrame.new(0, 0, -5),
					bottomLeft = CFrame.new() * CFrame.Angles(-0.8726646259971648, math.rad(v256 / 2), 0) * CFrame.new(0, 0, -5),
					bottomRight = CFrame.new() * CFrame.Angles(-0.8726646259971648, -math.rad(v256 / 2), 0) * CFrame.new(0, 0, -5)
				}
				local magnitude = (t1.topLeft.Position - t1.topRight.Position).magnitude
				local magnitude2 = (t1.topLeft.Position - t1.bottomLeft.Position).magnitude
				local CurrentCamera4 = workspace.CurrentCamera
				local clone19 = XOutside.Phase1.CameraFocus1:Clone()

				clone19.Size = Vector3.new(magnitude, magnitude2, magnitude)
				clone19.Parent = Model

				local connection2 = RunService.RenderStepped:Connect(function() -- line: 1032
					-- upvalues: clone19 (copy), CurrentCamera4 (copy)
					clone19.CFrame = CurrentCamera4.CFrame * CFrame.new(0, 0, -5) * CFrame.Angles(0, 0, 0)
				end)

				for _, descendant in pairs(clone19:GetDescendants()) do
					if descendant:IsA("Beam") then
						task.spawn(function() -- line: 1038
							-- upvalues: descendant (copy)
							if descendant.Name == "Beam" then
								descendant.Enabled = false

								return
							end

							if descendant.Name == "Beam2" then
								descendant.Transparency = NumberSequence.new(1, 1)
								descendant.Enabled = true
							end
						end)
					elseif descendant:IsA("Attachment") then
						if descendant.Name ~= "Attachment" then
							descendant:SetAttribute("1", descendant.Position)
							descendant.Position = descendant.Parent.Attach0.Position
						end
					elseif descendant:IsA("ParticleEmitter") and descendant.Parent.Name ~= "Attachment" then
						descendant.Enabled = false
					end
				end

				for _, child in pairs(clone19:GetChildren()) do
					task.spawn(function() -- line: 1071
						-- upvalues: child (copy), TweenService (copy)
						for _, descendant in pairs(child:GetDescendants()) do
							if descendant:IsA("Beam") then
								task.spawn(function() -- line: 1074
									-- upvalues: descendant (copy), TweenService (copy)
									if descendant.Name == "Beam" then
										descendant.Enabled = true

										local tween = TweenService:Create(descendant, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
											TextureSpeed = 10
										})

										tween:Play()
										tween.Completed:Wait()
										TweenService:Create(descendant, TweenInfo.new(0.1, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
											TextureSpeed = 7
										}):Play()
										task.wait(0.075)

										for i = 0, 10 do
											descendant.Transparency = NumberSequence.new(i / 10, i / 10)
											task.wait(0.01)
										end

										return
									end

									if descendant.Name == "Beam2" then
										descendant.Transparency = NumberSequence.new(1, 1)
										task.wait(0.15)
										descendant.Enabled = true
										task.spawn(function() -- line: 1101
											-- upvalues: descendant (copy)
											for i = 10, 0, -1 do
												descendant.Transparency = NumberSequence.new(i / 10, i / 10)
												task.wait(0.025)
											end
										end)
										descendant.TextureLength = math.random(20, 100)

										local tween = TweenService:Create(descendant, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
											TextureSpeed = 3
										})

										tween:Play()
										tween.Completed:Wait()
										TweenService:Create(descendant, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
											TextureSpeed = math.random(1, 10) / 10
										}):Play()
									end
								end)
							elseif descendant:IsA("Attachment") then
								if descendant.Name ~= "Attachment" then
									task.spawn(function() -- line: 1126
										-- upvalues: descendant (copy), TweenService (copy)
										if descendant.Name == "Attach1" then
											local tween = TweenService:Create(descendant, TweenInfo.new(0.075, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
												Position = descendant:GetAttribute("1")
											})

											task.wait(math.random(20, 40) / 500)
											tween:Play()
										end
									end)
								end
							elseif descendant:IsA("ParticleEmitter") and descendant.Parent.Name ~= "Attachment" then
								task.spawn(function() -- line: 1139
									-- upvalues: descendant (copy)
									descendant.Enabled = false
									task.wait(0.05)
									descendant.Enabled = true
									task.wait(0.1)
									descendant.Enabled = false
								end)
							end
						end
					end)
					task.wait(0.05 + math.random() * 0.025)
				end

				task.wait(0.5)
				TweenService:Create(CurrentCamera4, TweenInfo.new(0.25, Enum.EasingStyle.Back), {
					FieldOfView = 70
				}):Play()

				local BloomEffect = Instance.new("BloomEffect")

				BloomEffect.Intensity = 2
				BloomEffect.Size = 12
				BloomEffect.Threshold = 0
				BloomEffect.Parent = game.Lighting

				local tween = TweenService:Create(BloomEffect, TweenInfo.new(0.25), {
					Intensity = 0
				})

				tween.Completed:Connect(function() -- line: 1167
					-- upvalues: BloomEffect (copy)
					BloomEffect:Destroy()
				end)
				tween:Play()

				for _, descendant in pairs(clone19:GetDescendants()) do
					if descendant:IsA("Beam") then
						task.spawn(function() -- line: 1175
							-- upvalues: TweenService (copy), descendant (copy)
							TweenService:Create(descendant, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
								Width0 = 0,
								Width1 = 0,
								TextureSpeed = 15
							}):Play()
						end)
					elseif descendant:IsA("ParticleEmitter") and descendant.Parent.Name == "Attachment" then
						descendant:Emit(descendant:GetAttribute("EmitCount"))
					end
				end

				task.wait(1)
				connection2:Disconnect()
				clone19:Destroy()
			end)
			clone14 = XOutside.Phase0.SliceBall:Clone()
			clone14:PivotTo(HumanoidRootPartCFrame)
			Util.SetParentOverrideWithColor(clone14, Model, Player, "ControlFruitVFXColor")

			local Flash2 = clone14.Main.Flash

			Flash2.Parent = Model
			Flash2.WorldCFrame = HumanoidRootPartCFrame
			VisualHelper:EmitAll(Flash2)
			u169 = HexsStormClass.new(clone14.Main, nil, Player)
			u169.YFactor = clone14.Main.Size.Y / 2

			for i = -1, 1, 0.2 do
				u169:AddHex(not (i > 0.3) and "Normal" or "Gradient", i, u169.YFactor * 2.5, i * 360, random:NextNumber(50, 450))
			end

			for v184 in u169.Data do
				v184.Size = v184.Size * 3.25
			end

			local Scale = clone14:GetScale()

			VisualHelper:TweenScale(clone14, TweenInfo.new(0.8, Enum.EasingStyle.Sine), Scale * 1.4)
			task.wait(0.8)
			VisualHelper:TweenScale(clone14, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.InOut), Scale * 0.3)
			task.wait(0.3)
			VisualHelper:EmitAll(Flash2)
			Debris(Flash2, 2)

			for v186 in u169.Data do
				VisualHelper:Tween(v186, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {
					Size = Vector3.new(0, 0, 0)
				})
			end

			task.delay(0.5, function() -- line: 1248
				-- upvalues: u169 (ref)
				u169 = nil
			end)
			clone14:Destroy()
			clone14 = nil
			EmitExplosion(CFrame.new(HumanoidRootPart.Position) * CFrame.new(0, -2.8, 0), nil, Player)
			Flash(Root, false, Player)
			RushMeshs(false, 1, CFrame.lookAt(EndCFrame.Position, HumanoidRootPart.Position))
			connection:Disconnect()
			clone13:Destroy()

			if ControlXShaderScreen then
				VisualHelper:Tween(ControlXShaderScreen.Image, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {
					ImageTransparency = 1
				})
				Debris(ControlXShaderScreen, 0.5)
			end
		end)
	end
end
