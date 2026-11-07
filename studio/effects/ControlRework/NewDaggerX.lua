
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Util = require(ReplicatedStorage:WaitForChild("Util"))
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CurrentCamera = workspace.CurrentCamera
local FX = require(ReplicatedStorage:WaitForChild("FX"))
local XDagger = FX:WaitForChild("ControlRework").XDagger
local XOutside = FX:WaitForChild("ControlRework").XOutside
local Shared = script.Parent.Shared
local Utility = Shared.Utility
local VisualHelper = require(Utility.VisualHelper)
local MathHelper = require(Utility.MathHelper)

require(Shared.Textures)

local Rocks = require(Shared.Rocks)
local ObjectClass = require(Shared:WaitForChild("ObjectClass"))

require(ReplicatedStorage.Effect)
require(ReplicatedStorage.CharacterTransparency)
require(Shared.HexsStormClass)

local ObjectExplosion = require(script.Parent:WaitForChild("ObjectExplosion"))
local v16 = require(ReplicatedStorage:WaitForChild("CustomCollisions")).new("Rocks")

local function RecolorControlColor(p1, color3: Color3) -- line: 31
	-- upvalues: Util (copy)
	if typeof(p1) ~= "Instance" or not p1:IsA("Player") or not p1.Parent then
		return color3
	end

	return Util.WrapColor3Constructor(color3, p1, "ControlFruitVFXColor")
end
local function RandomAngleFunc(n1: number) -- line: 38
	return CFrame.Angles(math.random() * 3.141592653589793 / n1, math.random() * 3.141592653589793 / n1, math.random() * 3.141592653589793 / n1)
end
local function DeleteImpactAfterDuration(p2) -- line: 42
	task.spawn(function() -- line: 43
		-- upvalues: p2 (copy)
		local n2 = 0

		for _, descendant in pairs(p2:GetDescendants()) do
			if descendant:IsA("ParticleEmitter") then
				n2 = math.max(n2, descendant.Lifetime.Max)
			end
		end

		task.wait(n2)
		p2:Destroy()
	end)
end
local function DarkSlash(cFrame: CFrame, n3: number?, b1: boolean?, n4: number?, p3) -- line: 55
	-- upvalues: XDagger (copy), Util (copy), VisualHelper (copy)
	local clone = XDagger.Phase0.DarkSlash:Clone()

	clone:ScaleTo(n4 or 1.65)

	local Slash = clone.Slash

	Slash.CFrame = cFrame
	Util.SetParentOverrideWithColor(Slash, workspace.Terrain, p3, "ControlFruitVFXColor")
	VisualHelper:Tween(Slash.Winds, TweenInfo.new(0.17, Enum.EasingStyle.Sine), {
		Orientation = Vector3.new(0, 360, 0)
	})

	for _, child in Slash.Winds:GetChildren() do
		child.Beam.Enabled = true
		VisualHelper:Tween(child.Beam, TweenInfo.new(0.17, Enum.EasingStyle.Sine), {
			Width0 = 0,
			Width1 = 0
		})
	end

	for _, descendant in Slash.Slash:GetDescendants() do
		if descendant:IsA("ParticleEmitter") then
			descendant.Rotation = NumberRange.new(n3 or 0)
			VisualHelper:Emit(descendant)
		end
	end

	VisualHelper:EmitAll(Slash, true)

	local SlashBeam = Slash.SlashBeam

	SlashBeam.Orientation = Vector3.new(0, 180, 0)

	if b1 then
		local v43 = VisualHelper.BeamsFlipBook.new(8, 60)

		v43:Insert(SlashBeam.BeamThunder)
		v43:Play()
		task.delay(1, v43.Destroy, v43)
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

	VisualHelper:Tween(Slash.PointLight, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {
		Brightness = 0
	})
	Debris(Slash, 2)

	local StaticSlash = Slash.StaticSlash

	StaticSlash.Beam.Enabled = true
	task.delay(0.025, function() -- line: 107
		-- upvalues: StaticSlash (copy)
		StaticSlash:Destroy()
	end)

	return Slash
end
local function EmitLiteExplosion(cFrame: CFrame, b2: boolean?, p4, p5) -- line: 114
	-- upvalues: XDagger (copy), Util (copy), VisualHelper (copy), MathHelper (copy)
	if not cFrame then
		return
	end

	local clone = XDagger.Phase0.LiteExplosion:Clone()

	clone:PivotTo(cFrame)
	Util.SetParentOverrideWithColor(clone, p4, p5, "ControlFruitVFXColor")
	VisualHelper:EmitAll(clone)
	Debris(clone, 6)

	if b2 then
		return
	end

	local v52 = clone.Main.Size.X / 2

	task.spawn(function() -- line: 134
		-- upvalues: cFrame (copy), v52 (copy), MathHelper (copy), XDagger (copy), Util (copy), p4 (copy), p5 (copy), VisualHelper (copy)
		for _ = 1, 3 do
			local v158 = cFrame * CFrame.Angles(0, math.random() * 3.141592653589793 * 2, 0) * CFrame.new(0, 1, -math.random(v52 + 5, v52 + 25))
			local v159 = MathHelper:RayCast(v158.Position, v158.UpVector * -10, {
				workspace._WorldOrigin,
				workspace.Characters,
				workspace.Enemies
			}, Enum.RaycastFilterType.Exclude)

			if v159 then
				local clone2 = XDagger.Phase0.BoltExplosion:Clone()

				clone2.CFrame = CFrame.lookAt(v159.Position, v159.Position + v159.Normal) * CFrame.Angles(-1.5707963267948966, 0, 0) * CFrame.new(0, 0.5, 0)
				Util.SetParentOverrideWithColor(clone2, p4, p5, "ControlFruitVFXColor")
				VisualHelper:EmitAll(clone2)
				Debris(clone2, 1)
			end

			task.wait(0.125)
		end
	end)
end
local function EmitLiteFloor(_: CFrame, _, _) -- line: 153
end
local function RushLink(vector3: Vector3, vector3_2: Vector3, p8, p9) -- line: 167
	-- upvalues: XDagger (copy), Util (copy), VisualHelper (copy)
	local Magnitude = (vector3 - vector3_2).Magnitude
	local clone = XDagger.Phase0.RushLine:Clone()

	clone.CFrame = CFrame.lookAt(vector3, vector3_2) * CFrame.new(0, 0, -(Magnitude / 2))
	clone.Size = Vector3.new(clone.Size.X, clone.Size.Y, Magnitude)
	Util.SetParentOverrideWithColor(clone, p8, p9, "ControlFruitVFXColor")

	local Beams = clone.Beams

	for i, child in Beams.Beams:GetChildren() do
		child.Enabled = true

		if child.Name == "Air" then
			VisualHelper:Tween(child, TweenInfo.new(0.55, Enum.EasingStyle.Sine), {
				Brightness = 0
			})
		else
			local v65 = child.Name == "Fade"

			VisualHelper:Tween(child, TweenInfo.new(if not v65 then 0.15 + i * 0.01 else 0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, not v65 and 0.075 or 0), {
				Width0 = 0,
				Width1 = 0
			})
		end
	end

	Beams.Drag.Position = Vector3.new(0, 0, 0)
	VisualHelper:Tween(Beams.Drag, TweenInfo.new(0.075, Enum.EasingStyle.Sine), {
		Position = Vector3.new(0, 1, -Magnitude)
	})
	VisualHelper:EmitAll(clone)
	Debris(clone, 1.5)

	return clone
end
local function EmitExplosion(p10, b3: boolean?, p11) -- line: 198
	-- upvalues: Util (copy), XOutside (copy), VisualHelper (copy), MathHelper (copy)
	if not p10 then
		return
	end

	local v69 = typeof(p10) == "RaycastResult"
	local Model = Instance.new("Model")

	Model.Parent = workspace._WorldOrigin
	Util.Debris:AddItem(Model, 10)
	Util.CameraShaker:Shake("Fast")

	local v71 = v69 and CFrame.lookAt(p10.Position, p10.Position + p10.Normal) * CFrame.Angles(-1.5707963267948966, 0, 0) * CFrame.new(0, 0.5, 0) or p10
	local clone = XOutside.Phase0.Explosion:Clone()

	clone:PivotTo(v71)
	Util.SetParentOverrideWithColor(clone, Model, p11, "ControlFruitVFXColor")

	if not v69 then
		clone.Main.GlowShape.Crater:Destroy()
	end

	VisualHelper:EmitAll(clone)
	Debris(clone, 6)

	local v73 = clone.Main.Size.X / 2
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

	local clone3 = XOutside.Phase0.BallNeon:Clone()

	clone3.CFrame = v71
	clone3.Transparency = 0.94

	local color3 = Color3.fromRGB(89, 133, 255)

	clone3.Color = if typeof(p11) == "Instance" and (not not p11:IsA("Player") and p11.Parent) then Util.WrapColor3Constructor(color3, p11, "ControlFruitVFXColor") else color3
	clone3.Size = Vector3.new(1, 1, 1) * (clone.Main.Size.Y * 0.65)
	clone3.Parent = Model
	VisualHelper:Tween(clone3, TweenInfo.new(0.14, Enum.EasingStyle.Sine), {
		Transparency = 1,
		Size = clone3.Size * 1.35
	})
	Debris(clone3, 0.14)

	local clone4 = XOutside.Phase0.BallNeon:Clone()

	clone4.CFrame = v71
	clone4.Transparency = 0.85

	local color3_2 = Color3.fromRGB(89, 133, 255)

	clone4.Color = if typeof(p11) == "Instance" and (not not p11:IsA("Player") and p11.Parent) then Util.WrapColor3Constructor(color3_2, p11, "ControlFruitVFXColor") else color3_2
	clone4.Size = Vector3.new(1, 1, 1) * clone.Main.Size.Y
	clone4.Parent = Model
	VisualHelper:Tween(clone4, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {
		Transparency = 1,
		Size = clone4.Size * 1.6
	})
	Debris(clone4, 0.15)

	if b3 then
		return
	end

	for _, child in clone.Main.Boom:GetChildren() do
		if child.Name == "Smoke" then
			child:Destroy()
		end
	end

	task.spawn(function() -- line: 267
		-- upvalues: v71 (copy), v73 (copy), MathHelper (copy), XOutside (copy), Util (copy), Model (copy), p11 (copy), VisualHelper (copy)
		for _ = 1, 3 do
			local v162 = v71 * CFrame.Angles(0, math.random() * 3.141592653589793 * 2, 0) * CFrame.new(0, 1, -math.random(v73 + 5, v73 + 25))
			local v163 = MathHelper:RayCast(v162.Position, v162.UpVector * -10, {
				workspace._WorldOrigin,
				workspace.Characters,
				workspace.Enemies
			}, Enum.RaycastFilterType.Exclude)

			if v163 then
				local clone5 = XOutside.Phase0.BoltExplosion:Clone()

				clone5.CFrame = CFrame.lookAt(v163.Position, v163.Position + v163.Normal) * CFrame.Angles(-1.5707963267948966, 0, 0) * CFrame.new(0, 0.5, 0)
				Util.SetParentOverrideWithColor(clone5, Model, p11, "ControlFruitVFXColor")
				VisualHelper:EmitAll(clone5)
				Debris(clone5, 1)
			end

			task.wait(0.125)
		end
	end)
end

function Debris(p12, n5: number) -- line: 286
	-- upvalues: Util (copy)
	Util.Debris:AddItem(p12, n5)
end

local random = Random.new()
local raycastParams = RaycastParams.new()

raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.FilterDescendantsInstances = {
	workspace._WorldOrigin,
	workspace.Characters,
	workspace.Enemies
}

return function(p13) -- line: 296
	-- upvalues: CurrentCamera (copy), Util (copy), VisualHelper (copy), XDagger (copy), ObjectClass (copy), RunService (copy), RushLink (copy), EmitLiteExplosion (copy), raycastParams (copy), ObjectExplosion (copy), Rocks (copy), random (copy), XOutside (copy), MathHelper (copy), DarkSlash (copy), TweenService (copy), v16 (copy)
	if typeof(p13.Player) == "Instance" and (p13.Player:IsA("Player") and not p13.Player:FindFirstChild("PlayerGui") and p13.Player ~= game.Players.LocalPlayer) then
		Instance.new("Folder", p13.Player).Name = "PlayerGui"
	end

	local v86 = p13.Origin or (p13.Root and p13.Root.Position or (p13.hrp and p13.hrp.Position or (p13.Player and p13.Player.Character.PrimaryPart.Position or p13.player and p13.player.Character.PrimaryPart.Position)))

	assert(v86, "Origin Vector3 missing in: ", script:GetFullName())

	if (CurrentCamera.CFrame.Position - v86).Magnitude > 1200 then
		return
	end

	local Stage = p13.Stage

	if Stage == 1 then
		return
	end

	if Stage == 2 then
		local random2 = Random.new()
		local Model = Instance.new("Model", workspace._WorldOrigin)

		Util.Debris:AddItem(Model, 10)

		local StartCFrame = p13.StartCFrame
		local Root = p13.Root
		local Player = p13.Player
		local Character = p13.Character
		local Unit = StartCFrame.LookVector.Unit
		local Unit2 = Unit:Cross((if not (math.abs(Unit.Y) > 0.95) then Vector3.new(0, 1, 0) else Vector3.new(0, 0, 1))).Unit
		local v96 = Util.Maid.new()

		VisualHelper:Tween(CurrentCamera, TweenInfo.new(3, Enum.EasingStyle.Sine), {
			FieldOfView = 76
		})

		local clone = XDagger.Phase0.ShaderScreen:Clone()

		clone.Image.ImageTransparency = 1
		Util.SetParentOverrideWithColor(clone, p13.Player == game.Players.LocalPlayer and p13.Player:FindFirstChild("PlayerGui") or Model, Player, "ControlFruitVFXColor")
		VisualHelper:Tween(clone.Image, TweenInfo.new(0.6, Enum.EasingStyle.Sine), {
			ImageTransparency = 0.86
		})

		local clone6 = XDagger.Phase0.CameraEffects:Clone()

		Util.SetParentOverrideWithColor(clone6, CurrentCamera, Player, "ControlFruitVFXColor")

		if p13.Player == game.Players.LocalPlayer then
			VisualHelper:SetEnableAll(clone6, true)
			VisualHelper:EmitAll(clone6)
		end

		v96:GiveTask(clone6)
		v96:GiveTask(clone)

		local Attachment = Instance.new("Attachment", workspace.Terrain)

		Attachment.WorldCFrame = StartCFrame
		v96:GiveTask(Attachment)
		Root.Anchored = true
		Attachment.Destroying:Once(function() -- line: 364
			-- upvalues: Root (copy)
			Root.CFrame = CFrame.lookAt(Vector3.new(0, 0, 0), Root.CFrame.LookVector * Vector3.new(1, 0, 1)) + Root.Position
			Root.Anchored = false

			local Humanoid = Root.Parent:FindFirstChild("Humanoid")

			if Humanoid then
				Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			end
		end)
		v96:GiveTask(Attachment:GetPropertyChangedSignal("CFrame"):Connect(function() -- line: 374
			-- upvalues: Root (copy), Attachment (ref)
			Root.CFrame = Attachment.WorldCFrame
		end))
		v96:GiveTask(Model)

		local EndPoint = p13.EndPoint
		local MaxDistance = p13.MaxDistance
		local v102 = math.floor(MaxDistance / 33)
		local v103 = math.clamp(math.round((EndPoint - StartCFrame.Position).Magnitude / MaxDistance * v102), 1, v102)
		local t1 = {}
		local u105 = nil
		local n6 = 1

		for i = 1, v103 do
			local v108 = i / v103
			local v109 = StartCFrame.Position:Lerp(EndPoint, v108)
			local vector3 = Vector3.new(0, 0, 0)

			if i ~= v103 then
				vector3 = Unit2 * (n6 * 30 + random2:NextNumber(-4.5, 4.5))
				n6 *= -1
			end

			t1[i] = v109 + vector3
		end

		local n7 = 1
		local n8 = 0
		local n9 = 0
		local connection = nil
		local v115 = ObjectClass.TemplateModel.Main.Size / 6
		local StartCFramePosition = StartCFrame.Position
		local u117 = true
		local u118 = false
		local Highlight = Instance.new("Highlight")

		Highlight.Adornee = Character
		Highlight.FillTransparency = 1
		Highlight.OutlineTransparency = 1
		Highlight.DepthMode = Enum.HighlightDepthMode.Occluded

		local color3 = Color3.fromRGB(30, 56, 100)

		Highlight.FillColor = if typeof(Player) == "Instance" and (not not Player:IsA("Player") and Player.Parent) then Util.WrapColor3Constructor(color3, Player, "ControlFruitVFXColor") else color3
		Highlight.Parent = Model

		local u121 = nil
		local n10 = 1

		connection = RunService.Heartbeat:Connect(function(dt) -- line: 469
			-- upvalues: n9 (ref), n8 (ref), t1 (copy), connection (ref), u118 (ref), n7 (ref), Unit (copy), Util (copy), Model (copy), ObjectClass (copy), Player (copy), v115 (copy), StartCFramePosition (ref), u121 (ref), Character (copy), n10 (ref), Root (copy), RushLink (copy), EmitLiteExplosion (copy), u117 (ref), VisualHelper (copy), raycastParams (copy), Attachment (ref), Highlight (copy), ObjectExplosion (copy), XDagger (copy), Rocks (copy), random (copy), u105 (ref)
			n9 += dt

			if n9 < 0.06 then
				return
			end

			n9 = 0

			if n8 >= #t1 then
				connection:Disconnect()
				u118 = true

				return
			end

			if n7 > #t1 then
				return
			end

			local v167 = t1[n7]
			local v168 = t1[n7 + 1] or v167 + Unit
			local v169, v170, v171 = Util.Ray(v167 + Vector3.new(0, 1, 0), Vector3.new(-0, -600, -0), {
				workspace._WorldOrigin,
				workspace.Characters,
				workspace.Enemies
			})
			local t2 = {
				Instance = v169 or nil,
				Normal = v171 or Vector3.new(0, 1, 0),
				Position = v170
			}

			if not v169 then
				local Part = Instance.new("Part")

				Part.BrickColor = BrickColor.new("Black")
				Part.Material = Enum.Material.Slate
				Part.Transparency = 1
				Part.CanCollide = false
				Part.Anchored = true
				Part.Parent = Model
				t2.Instance = Part
			end

			local cFrame = CFrame.lookAt(v170, v170 + v171)
			local v175 = ObjectClass.new(Player, cFrame)

			v175:RemoveDragable()

			local Main = v175.Model.Main

			Main.CanCollide = false
			Main.Color = t2.Instance.Color
			Main.Material = t2.Instance.Material
			Main.CanQuery = false
			Main.Outline:Destroy()
			v175:SetLayout(`{ 1 }x{ 1 }`)
			v175:ScaleTo(1)

			local _ = v170.Y
			local _ = v168.Y
			local v179 = math.random(5, 10)
			local v180 = v115 * 1
			local _ = cFrame * CFrame.new(0, 0, -(v180.Y / 2 + v179)).Position
			local v182 = v167 + v171 * (v180.Y / 2 + v179)
			local cFrame2 = CFrame.Angles(math.rad((math.random(-10, 10))), 0, math.random() * 3.141592653589793)
			local cFrame3 = CFrame.lookAt(v182, StartCFramePosition)

			v175:PivotTo(cFrame)
			v175:SetSize((Vector3.new(0, 0, 0)))

			local v185 = StartCFramePosition

			task.delay(0.125, function() -- line: 548
				-- upvalues: v175 (copy), u121 (ref), Util (copy), Character (copy), n10 (ref), Root (copy), RushLink (copy), v185 (copy), v182 (copy), Model (copy), Player (copy), EmitLiteExplosion (copy), u117 (ref), VisualHelper (copy), Main (copy), v180 (copy), cFrame3 (copy), raycastParams (copy), StartCFramePosition (ref), Attachment (ref), n8 (ref), Highlight (copy), ObjectExplosion (copy)
				v175:SwitchMode("Planing")
				v175:ToggleBodyPattern(true)

				if not u121 then
					u121 = Util.Anims:Get(Character, "CRDaggerXLoopFly")
					u121.Looped = true
					u121.Priority = Enum.AnimationPriority.Action2
					u121:Play()
				end

				Util.Sound:Play("X_CubeDash_Dash_0" .. tostring(n10), Root)
				n10 += 1

				if n10 > 4 then
					n10 = 1
				end

				RushLink(v185, v182, Model, Player)
				EmitLiteExplosion(Root.CFrame * CFrame.new(0, -2.8, 0), u117, Model, Player)
				u117 = false
				VisualHelper:Tween(Main, TweenInfo.new(0.082, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, true), {
					Size = v180 * 1.2
				})

				local v272 = cFrame3 * CFrame.new(0, 0, -v180.Y / 2 - 3) * CFrame.Angles(-1.5707963267948966, 0, 0)
				local v273 = u117 and workspace:Raycast(Root.Position, v272.Position - Root.Position, raycastParams) or workspace:Raycast(StartCFramePosition, v272.Position - StartCFramePosition, raycastParams)

				if v273 then
					v272 = v272 - v272.Position + v273.Position
				end

				VisualHelper:Tween(Attachment, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {
					WorldCFrame = v272
				})
				n8 += 1
				task.wait(0.035)

				local _ = v272 * CFrame.new(0, -2.8, 0)
				local _ = Model
				local _ = Player

				Highlight.FillTransparency = 0.75
				VisualHelper:Tween(Highlight, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
					FillTransparency = 1
				})
				task.wait(0.5)
				ObjectExplosion({
					Energized = false,
					Object = v175.Model.Main,
					Scale = 2.15 * v175:GetLayoutSize(),
					IsSliceModel = v175:IsSliceModel()
				})
				v175:Destroy()
			end)

			local _ = cFrame * CFrame.new(0, 0, -1) * CFrame.Angles(-1.5707963267948966, 0, 0)

			VisualHelper:Tween(Main, TweenInfo.new(0.145, Enum.EasingStyle.Sine), {
				Size = v180,
				CFrame = cFrame3 * cFrame2
			})

			local v187 = CFrame.lookAt(v170, v170 + v171) * CFrame.Angles(-1.5707963267948966, 0, 0) * CFrame.new(0, 0.5, 0)
			local clone7 = XDagger.Phase0.PushExplosionFast:Clone()

			clone7:PivotTo(v187)
			Util.SetParentOverrideWithColor(clone7, Model, Player, "ControlFruitVFXColor")
			VisualHelper:EmitAll(clone7)
			Util.Debris:AddItem(clone7, 3)

			local clone8 = XDagger.Phase0.BallNeon:Clone()

			clone8.CFrame = v187
			clone8.Transparency = 0.95

			local v190 = Player
			local color3_3 = Color3.fromRGB(89, 133, 255)

			clone8.Color = if typeof(v190) == "Instance" and (not not v190:IsA("Player") and v190.Parent) then Util.WrapColor3Constructor(color3_3, v190, "ControlFruitVFXColor") else color3_3
			clone8.Size = Vector3.new(1, 1, 1) * (clone7.Main.Size.Y * 0.65)
			clone8.Parent = Model
			VisualHelper:Tween(clone8, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
				Transparency = 1,
				Size = clone8.Size * 4
			})
			Debris(clone8, 0.2)

			local Beams = clone7.Main.Beams

			VisualHelper:Tween(Beams, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
				WorldCFrame = Beams.WorldCFrame * CFrame.Angles(0, 3.141592653589793, 0)
			})

			for _, descendant in Beams:GetDescendants() do
				if descendant:IsA("Beam") then
					descendant.Enabled = true
					VisualHelper:Tween(descendant, TweenInfo.new(0.15 + math.random(3) * 0.025, Enum.EasingStyle.Sine), {
						Width0 = 0,
						Width1 = 0
					})
				end
			end

			Debris(Beams, 0.5)

			local v195 = clone7.Main.Size.X / 2

			Rocks:CircleRocks(v187.Position, 13, v195 * 0.7, Vector3.new(6.199999809265137, 1.2000000476837158, 2), 0, { workspace.Terrain })
			Rocks:CircleRocks(v187.Position, 5, v195 * 1.05, Vector3.new(5, 1.7999999523162842, 3.200000047683716), 0, { workspace.Terrain })

			for _ = 1, 3 do
				Rocks:AirRocks(v187, Vector3.new(random:NextNumber(6.5, 9), 2, random:NextNumber(6.5, 9)), false, math.random(90, 130), 1, 1, 3, t2.Instance.Color, t2.Instance.Material)
			end

			local AirMeshHuge = clone7.AirMeshHuge
			local SuperFlash = clone7.SuperFlash
			local Flash = clone7.Flash
			local AirHard = clone7.AirHard

			VisualHelper:Tween(AirMeshHuge.Mesh, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
				Scale = AirMeshHuge.Mesh.Scale * 1.9
			})
			VisualHelper:Tween(AirMeshHuge.Decal, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
				Transparency = 1
			})
			Debris(AirMeshHuge, 0.3)
			VisualHelper:Tween(AirHard, TweenInfo.new(0.325, Enum.EasingStyle.Sine), {
				CFrame = AirHard.CFrame * CFrame.Angles(0, 3.141592653589793, 0)
			})
			VisualHelper:Tween(AirHard.Decal, TweenInfo.new(0.325, Enum.EasingStyle.Sine), {
				Transparency = 1
			})
			VisualHelper:Tween(AirHard.Mesh, TweenInfo.new(0.325, Enum.EasingStyle.Sine), {
				Scale = AirHard.Mesh.Scale * 2
			})
			Debris(AirHard, 0.5)
			VisualHelper:Tween(Flash.Decal, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
				Transparency = 1
			})
			VisualHelper:Tween(Flash.Mesh, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
				Scale = Flash.Mesh.Scale * 2.5
			})
			Debris(Flash, 0.4)

			local v201 = SuperFlash.Mesh.Scale * 2.6
			local Mesh = SuperFlash.Mesh

			Mesh.Scale = Mesh.Scale / 2
			VisualHelper:Tween(SuperFlash, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {
				CFrame = SuperFlash.CFrame * CFrame.new(0, -7, 0)
			})
			VisualHelper:Tween(SuperFlash.Decal, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {
				Transparency = 1
			})
			VisualHelper:Tween(SuperFlash.Mesh, TweenInfo.new(0.55, Enum.EasingStyle.Sine), {
				Scale = v201
			})
			Debris(SuperFlash, 0.7)
			StartCFramePosition = v182
			u105 = v175
			n7 += 1
		end)

		repeat
			task.wait()
		until u118

		task.wait(0.1)

		local EnemyChar = p13.EnemyChar
		local v124 = EnemyChar and EnemyChar:FindFirstChild("HumanoidRootPart")

		if EnemyChar and v124 then
			local UpCFrame = p13.UpCFrame
			local PushCFrame = p13.PushCFrame
			local EnemyCFrame = p13.EnemyCFrame
			local v128, v129, v130 = Util.Ray(UpCFrame.Position, Vector3.new(-0, -600, -0), {
				workspace._WorldOrigin,
				workspace.Characters,
				workspace.Enemies
			})
			local t3 = {
				Instance = v128 or nil,
				Normal = v130 or Vector3.new(0, 1, 0),
				Position = v129
			}

			if not v128 then
				local Part = Instance.new("Part")

				Part.BrickColor = BrickColor.new("Black")
				Part.Material = Enum.Material.Slate
				Part.Transparency = 1
				Part.CanCollide = false
				Part.Anchored = true
				Part.Parent = Model
				t3.Instance = Part
			end

			if not (t3.Position.Y < -2) then
			end

			local cFrame = CFrame.lookAt(v129, v129 + v130)
			local v134 = ObjectClass.new(Player, cFrame)

			v134:RemoveDragable()

			local Main = v134.Model.Main

			Main.CanCollide = false
			Main.Color = t3.Instance.Color
			Main.Material = t3.Instance.Material
			Main.CanQuery = false
			Main.Outline:Destroy()
			v134:SetLayout(`{ 1 }x{ 1 }`)
			v134:ScaleTo(1)

			local v136 = v115 * 2
			local cFrame4 = CFrame.Angles(math.rad((math.random(-10, 10))), 0, math.random() * 3.141592653589793)

			v134:PivotTo(cFrame)
			v134:SetSize((Vector3.new(0, 0, 0)))
			VisualHelper:Tween(v124, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {
				CFrame = EnemyCFrame
			})
			task.delay(0.1, function() -- line: 784
				-- upvalues: v134 (copy), RushLink (copy), Root (copy), UpCFrame (copy), Model (copy), Player (copy), EmitLiteExplosion (copy), u117 (ref), VisualHelper (copy), Main (copy), v136 (copy), raycastParams (copy), StartCFramePosition (ref), Util (copy), n10 (ref), Attachment (ref), u121 (ref), Character (copy), PushCFrame (copy), XOutside (copy), UpCFrame (copy), ObjectExplosion (copy), v124 (copy), p13 (copy), XDagger (copy), clone (ref), MathHelper (copy), Highlight (copy), CurrentCamera (copy), RunService (copy), clone6 (ref), DarkSlash (copy), random (copy), TweenService (copy), v16 (copy), v96 (copy)
				v134:SwitchMode("Planing")
				v134:ToggleBodyPattern(true)
				RushLink(Root.Position, UpCFrame.Position, Model, Player)
				EmitLiteExplosion(Root.CFrame * CFrame.new(0, -2.8, 0), u117, Model, Player)
				u117 = false
				VisualHelper:Tween(Main, TweenInfo.new(0.082, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, true), {
					Size = v136 * 1.2
				})

				local v203 = UpCFrame * CFrame.new(0, 0, -v136.Y / 2 - 3) * CFrame.Angles(-1.5707963267948966, 0, 0)
				local v204 = u117 and workspace:Raycast(Root.Position, v203.Position - Root.Position, raycastParams) or workspace:Raycast(StartCFramePosition, v203.Position - StartCFramePosition, raycastParams)

				if v204 then
					v203 = v203 - v203.Position + v204.Position
				end

				Util.Sound:Play("X_CubeDash_Dash_0" .. tostring(n10), Root)
				VisualHelper:Tween(Attachment, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {
					WorldCFrame = v203
				})
				task.spawn(function() -- line: 808
					-- upvalues: u121 (ref), Util (copy), Character (copy)
					task.wait(0.1)

					if u121 then
						u121:Stop()
						u121 = nil
					end

					u121 = Util.Anims:Get(Character, "CRDaggerXLoopRock")
					u121.Looped = true
					u121.Priority = Enum.AnimationPriority.Action2
					u121:Play()
				end)
				task.wait(0.2)
				Util.Sound:Play("X_CubeDash_BungieOffFloatingRock_01", Root)

				local v205 = PushCFrame

				RushLink(Root.Position, v205.Position, nil, Player)

				if u121 then
					u121:Stop()
				end

				local v206 = Util.Anims:Get(Character, "CRDaggerXRockJump")

				v206.Looped = false
				v206.Priority = Enum.AnimationPriority.Action3
				v206:Play()
				VisualHelper:Tween(Attachment, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {
					WorldCFrame = v205
				})

				local clone9 = XOutside.Phase1.EndImpact:Clone()

				Util.ResizeModel(clone9, 2.25)
				clone9.CFrame = CFrame.lookAt(UpCFrame.Position, v205.Position) * CFrame.Angles(1.5707963267948966, 0, 0)
				Util.SetParentOverrideWithColor(clone9, Model, Player, "ControlFruitVFXColor")
				task.spawn(function() -- line: 848
					-- upvalues: ObjectExplosion (copy), v134 (copy)
					ObjectExplosion({
						Energized = false,
						Object = v134.Model.Main,
						Scale = 2.15 * v134:GetLayoutSize(),
						IsSliceModel = v134:IsSliceModel()
					})
					v134:Destroy()
				end)
				task.spawn(function() -- line: 43
					-- upvalues: clone9 (copy)
					local n11 = 0

					for _, descendant in pairs(clone9:GetDescendants()) do
						if descendant:IsA("ParticleEmitter") then
							n11 = math.max(n11, descendant.Lifetime.Max)
						end
					end

					task.wait(n11)
					clone9:Destroy()
				end)

				for _, descendant in pairs(clone9:GetDescendants()) do
					if descendant:IsA("ParticleEmitter") then
						task.spawn(function() -- line: 862
							-- upvalues: descendant (copy)
							if descendant:GetAttribute("EmitDelay") ~= 0 then
								task.wait(descendant:GetAttribute("EmitDelay"))
							end

							descendant:Emit(descendant:GetAttribute("EmitCount"))
						end)
					end
				end

				task.wait(0.1)

				if Attachment then
					Attachment:Destroy()
				end

				VisualHelper:Tween(v124, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {
					CFrame = p13.EnemyCFrame2
				})
				task.spawn(function() -- line: 882
					-- upvalues: XDagger (copy), v205 (copy), Util (copy), Player (copy), VisualHelper (copy)
					local clone10 = XDagger.Phase0.Impact:Clone()

					clone10:PivotTo(v205)
					Util.SetParentOverrideWithColor(clone10, workspace.Terrain, Player, "ControlFruitVFXColor")
					Debris(clone10, 1.5)

					local Beams = clone10.Main.Beams

					VisualHelper:Tween(Beams, TweenInfo.new(0.15, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {
						Orientation = Beams.Orientation + Vector3.new(0, 360, 0)
					})

					for _, descendant in Beams:GetDescendants() do
						if descendant:IsA("Beam") then
							local v284 = descendant:GetAttribute("Width0") or descendant.Width0
							local v285 = descendant:GetAttribute("Width1") or descendant.Width0

							descendant:SetAttribute("Width0", v284)
							descendant:SetAttribute("Width1", v285)
							descendant.Width0 = v284
							descendant.Width1 = v285
							descendant.Enabled = true
							VisualHelper:Tween(descendant, TweenInfo.new(0.1 + math.random(3) * 0.025, Enum.EasingStyle.Sine), {
								Width0 = 0,
								Width1 = 0
							})
						end
					end

					VisualHelper:EmitAll(clone10)

					local Meshs = clone10.Main.Meshs
					local AirMeshHuge = Meshs.AirMeshHuge
					local AirMeshStorm = Meshs.AirMeshStorm
					local SuperFlash = Meshs.SuperFlash
					local Flash = Meshs.Flash

					VisualHelper:Tween(AirMeshHuge.Mesh, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
						Scale = AirMeshHuge.Mesh.Scale * Vector3.new(4, 1, 4)
					})
					VisualHelper:Tween(AirMeshHuge.Decal, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
						Transparency = 1
					})
					Debris(AirMeshHuge, 1)
					VisualHelper:Tween(AirMeshStorm.Mesh, TweenInfo.new(0.35, Enum.EasingStyle.Sine), {
						Scale = AirMeshStorm.Mesh.Scale * Vector3.new(3, 1, 3)
					})
					VisualHelper:Tween(AirMeshStorm.Decal, TweenInfo.new(0.35, Enum.EasingStyle.Sine), {
						Transparency = 1
					})
					VisualHelper:Tween(AirMeshStorm, TweenInfo.new(0.35, Enum.EasingStyle.Sine), {
						CFrame = AirMeshStorm.CFrame * CFrame.Angles(0, 3.141592653589793, 0)
					})
					Debris(AirMeshStorm, 1)
					VisualHelper:Tween(Flash.Decal, TweenInfo.new(0.26, Enum.EasingStyle.Sine), {
						Transparency = 1
					})
					VisualHelper:Tween(Flash.Mesh, TweenInfo.new(0.26, Enum.EasingStyle.Sine), {
						Scale = Flash.Mesh.Scale * Vector3.new(3.5, 1, 3.5)
					})
					Debris(Flash, 1)

					local v291 = SuperFlash.Mesh.Scale * 2.25
					local Mesh = SuperFlash.Mesh

					Mesh.Scale = Mesh.Scale / 2
					VisualHelper:Tween(SuperFlash.Decal, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {
						Transparency = 1
					})
					VisualHelper:Tween(SuperFlash.Mesh, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {
						Scale = v291
					})
					Debris(SuperFlash, 1)
				end)

				local v210 = Util.Anims:Get(Character, "CRDaggerXHit")

				v210.Looped = false
				v210.Priority = Enum.AnimationPriority.Action4
				v210:Play()

				if clone then
					VisualHelper:Tween(clone.Image, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {
						ImageTransparency = 1
					})
					Debris(clone, 0.5)
				end

				local _, v212 = v205:ToEulerAnglesYXZ()
				local v213 = MathHelper:RayCast(v205.Position + Vector3.new(0, 0.10000000149011612, 0), Vector3.new(-0, -200, -0), {
					workspace._WorldOrigin,
					workspace.Characters,
					workspace.Enemies
				}, Enum.RaycastFilterType.Exclude)
				local v214 = not v213 and MathHelper:RayCast(StartCFramePosition, v205.LookVector * 1, {
					workspace._WorldOrigin,
					workspace.Characters,
					workspace.Enemies
				}, Enum.RaycastFilterType.Exclude)
				local u215 = if not v213 then if not v214 then v205 * CFrame.new(0, 0, -1) else CFrame.lookAt(v214.Position, v214.Position + v214.Normal) * CFrame.new(0, 0, -3) * CFrame.Angles(-1.5707963267948966, v212 + 3.141592653589793, 0) else CFrame.new(v213.Position + Vector3.new(0, 3, 0)) * CFrame.Angles(0, v212, 0)

				Util.Sound:Play("X_CubeDash_SlashFinisher_02", u215)
				EmitLiteExplosion(v205 * CFrame.new(0, -2.8, 0), nil, nil, Player)
				Highlight.FillTransparency = 0.4
				VisualHelper:Tween(Highlight, TweenInfo.new(0.25, Enum.EasingStyle.Sine), {
					FillTransparency = 1
				})
				Debris(Highlight, 0.6)

				local clone11 = XDagger.Phase0.Indicator:Clone()

				clone11.CFrame = v205
				Util.SetParentOverrideWithColor(clone11, workspace.Terrain, Player, "ControlFruitVFXColor")

				local Beam = clone11.Beam
				local BeamBrightness = Beam.Brightness

				Beam.Brightness = 0
				VisualHelper:Tween(Beam, TweenInfo.new(0.25, Enum.EasingStyle.Sine), {
					Brightness = BeamBrightness
				})
				VisualHelper:Tween(CurrentCamera, TweenInfo.new(0.25, Enum.EasingStyle.Sine), {
					FieldOfView = 60
				})
				task.wait(0.1)

				local clone12 = XDagger.Phase0.DoubleNeonEye:Clone()

				clone12.Anchored = false
				clone12.Weld.Part0 = Character.Head
				Util.SetParentOverrideWithColor(clone12, workspace.Terrain, Player, "ControlFruitVFXColor")
				VisualHelper:SetEnableAll(clone12, true)

				local clone13 = XDagger.Phase0.Handle:Clone()

				clone13.Anchored = false
				clone13.Weld.Part1 = Root
				Util.SetParentOverrideWithColor(clone13, workspace.Terrain, Player, "ControlFruitVFXColor")
				VisualHelper:Tween(clone13.Beams, TweenInfo.new(0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {
					Orientation = clone13.Beams.Orientation - Vector3.new(0, 360, 0)
				})
				VisualHelper:SetEnableAll(clone13, true)

				local v221 = p13.StartTime or workspace:GetServerTimeNow()
				local u222 = workspace:GetServerTimeNow() - v221

				RunService.RenderStepped:Connect(function(dt) -- line: 1017
					-- upvalues: u222 (ref), clone6 (ref), CurrentCamera (copy)
					u222 += dt

					if clone6 then
						clone6.CFrame = CurrentCamera.CFrame * CFrame.new(0, 0, -2.25) * CFrame.Angles(0, 1.5707963267948966, 0)
					end
				end)

				local t4 = {
					{
						Angle = 0,
						Rotation = 0,
						Scale = 5
					},
					{
						Angle = 90,
						Rotation = 95,
						Scale = 4
					},
					{
						Angle = 45,
						Rotation = 100,
						Scale = 4
					},
					{
						Angle = -45,
						Rotation = -100,
						Scale = 4
					},
					{
						Angle = 0,
						Rotation = 0,
						Scale = 5
					}
				}

				task.spawn(function() -- line: 1034
					-- upvalues: t4 (copy), DarkSlash (copy), u215 (ref), Player (copy), v205 (copy), Model (copy)
					for v294, v295 in t4 do
						DarkSlash(u215 * CFrame.new(0, 0, -35) * CFrame.Angles(0, 3.141592653589793, (math.rad(v295.Angle))), v295.Rotation, true, 12 + v295.Scale * 0.1, Player)

						if v294 % 3 == 0 then
							local _ = v205 * CFrame.new(0, -2.8, 0)
							local _ = Model
							local _ = Player
						end

						task.wait(0.018)
					end
				end)

				local clone14 = XDagger.Phase0.GroundSlice:Clone()

				clone14:PivotTo(v205 * CFrame.new(0, -2, -clone14.Main.Size.Z / 2 - 2.5))
				Util.SetParentOverrideWithColor(clone14, workspace.Terrain, Player, "ControlFruitVFXColor")
				VisualHelper:SetEnableAll(clone14.Main, true, true)
				task.spawn(function() -- line: 1059
					-- upvalues: VisualHelper (copy), clone14 (copy), CurrentCamera (copy)
					for _ = 1, 3 do
						VisualHelper:EmitAll(clone14.FloorImpactFast)
						task.wait(0.16)
					end

					VisualHelper:Tween(CurrentCamera, TweenInfo.new(0.15, Enum.EasingStyle.Back), {
						FieldOfView = 55
					})
				end)

				local children = clone14.Slices:GetChildren()

				for v226, v227 in children do
					local Size = v227.Size

					v227.Size = Vector3.new(0, 0, 0)
					task.delay(v226 * 0.02, function() -- line: 1075
						-- upvalues: VisualHelper (copy), v227 (copy), v226 (copy), Size (copy), XDagger (copy), Util (copy), Player (copy), random (copy)
						VisualHelper:EmitAll(v227)

						local v300 = v226 % 2 ~= 0 and 1 or -1
						local v301 = Vector3.new(0, 0, 1) * Size.Z / 2 * v300
						local clone15 = XDagger.Phase0.Vault.SliceGroundBeam:Clone()

						Util.SetParentOverrideWithColor(clone15, v227, Player, "ControlFruitVFXColor")

						local Left = clone15.Left
						local Right = clone15.Right
						local v305 = v301 * -1
						local vector3 = Vector3.new(0, 0, 0)

						Left.Position = v305
						Right.Position = vector3

						local v307 = random:NextNumber(0.5, 2)
						local Beam2 = clone15.Beam

						Beam2.Width0 = Beam2.Width0 * v307
						Beam2.Width1 = Beam2.Width1 * v307
						Beam2.Enabled = true
						VisualHelper:Tween(clone15.Right, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {
							Position = v301
						})
						VisualHelper:Tween(Beam2, TweenInfo.new(0.125, Enum.EasingStyle.Quad), {
							Width0 = 0,
							Width1 = 0
						})
						task.wait(0.05)
						VisualHelper:Tween(v227, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
							Size = Size
						})
						task.wait(0.045)
						VisualHelper:EmitAll(v227)
						task.wait(0.025)
						VisualHelper:SetEnableAll(v227, true, true)
					end)
				end

				task.wait(#children * 0.02 + 0.125)

				local clone16 = XDagger.Phase0.StormBeamPattern:Clone()

				clone16:PivotTo(clone14:GetPivot())
				clone16:ScaleTo(4)
				Util.SetParentOverrideWithColor(clone16, workspace.Terrain, Player, "ControlFruitVFXColor")

				for _, child in clone16.Main:GetChildren() do
					if child:IsA("Attachment") then
						child.Orientation = child.Orientation * 1.15

						local Beam3 = child.Beam

						Beam3.Brightness = Beam3.Brightness * 1.75
						Beam3.Enabled = true
						VisualHelper:Tween(child, TweenInfo.new(0.7, Enum.EasingStyle.Sine), {
							Orientation = child.Orientation + Vector3.new(0, 515, 0)
						})
						VisualHelper:Tween(Beam3, TweenInfo.new(0.7, Enum.EasingStyle.Sine), {
							Brightness = 0,
							Width0 = Beam3.Width0 * 0.2,
							Width1 = Beam3.Width1 * 0.2
						})
					end
				end

				VisualHelper:TweenScale(clone16, TweenInfo.new(0.7, Enum.EasingStyle.Sine), clone16:GetScale() + 0.5)
				Debris(clone16, 0.7)
				VisualHelper:Tween(Beam, TweenInfo.new(0.35, Enum.EasingStyle.Sine), {
					Brightness = 0
				})
				Debris(clone11, 0.4)

				local clone17 = XDagger.Phase0.NeonRotation:Clone()

				clone17:ScaleTo(1.2)
				clone17.Main.Anchored = false
				clone17.Main.Weld.Part0 = Root
				Util.SetParentOverrideWithColor(clone17, workspace.Terrain, Player, "ControlFruitVFXColor")
				clone17.Main.Layers.Orientation = Vector3.new(0, 1, 0) * random:NextNumber(-360, 360)

				for i, child in clone17.Main.Layers:GetChildren() do
					child.Orientation = child.Orientation * 1.5
					child.Position = child.Position * 1.5

					local Beam4 = child.Beam
					local v237 = Beam4.Width0 / 2
					local v238 = Beam4.Width1 / 2

					Beam4.Width0 = v237
					Beam4.Width1 = v238
					Beam4.Enabled = true

					local v239 = random:NextNumber(0.12, 0.22)

					VisualHelper:Tween(child, TweenInfo.new(v239, Enum.EasingStyle.Linear), {
						Orientation = child.Orientation + Vector3.new(0, 450 * (i % 2 ~= 0 and -1 or 1))
					})
					VisualHelper:Tween(Beam4, TweenInfo.new(v239, Enum.EasingStyle.Sine), {
						Width0 = 0,
						Width1 = 0
					})
				end

				Debris(clone17, 2)

				local _ = v205 * CFrame.new(0, -2.8, 0)
				local _ = Model
				local _ = Player

				task.wait(0.125)

				for _, v244 in children do
					VisualHelper:SetEnableAll(v244, false, true)
				end

				task.spawn(function() -- line: 1170
					-- upvalues: XDagger (copy), v205 (copy), clone14 (copy), Util (copy), Model (copy), Player (copy), TweenService (copy)
					local clone18 = XDagger.Phase1.GroundAura:Clone()

					clone18.CFrame = v205 * CFrame.new(0, -2, -clone14.Main.Size.Z / 2 - 2.5)
					Util.SetParentOverrideWithColor(clone18, Model, Player, "ControlFruitVFXColor")

					for _, descendant in pairs(clone18:GetDescendants()) do
						if descendant:IsA("ParticleEmitter") then
							task.spawn(function() -- line: 1179
								-- upvalues: descendant (copy)
								descendant.Enabled = true
								task.wait(0.35)
								descendant.Enabled = false
							end)
						end
					end

					clone18.Aura2.Size = Vector3.new(5, 1, 5)
					TweenService:Create(clone18.Aura2, TweenInfo.new(0.35, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
						Size = Vector3.new(350, 1, 350)
					}):Play()
				end)
				task.wait(0.1)
				VisualHelper:Tween(CurrentCamera, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {
					FieldOfView = 70
				})
				VisualHelper:EmitAll(clone14.FloorImpactEnd)
				task.wait(0.065)

				if v213 or v214 then
					local clone19 = XDagger.Phase0.GroundSliceExplosion:Clone()

					clone19:PivotTo(clone14:GetPivot())
					Util.SetParentOverrideWithColor(clone19, workspace.Terrain, Player, "ControlFruitVFXColor")
					VisualHelper:EmitAll(clone19)
					Debris(clone19, 2.5)

					local AirMeshHuge = clone19.AirMeshHuge
					local AirMeshStorm = clone19.AirMeshStorm
					local SuperFlash = clone19.SuperFlash
					local Flash = clone19.Flash
					local AirHard = clone19.AirHard

					VisualHelper:Tween(AirMeshHuge.Mesh, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
						Scale = AirMeshHuge.Mesh.Scale * 2.3
					})
					VisualHelper:Tween(AirMeshHuge.Decal, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
						Transparency = 1
					})
					Debris(AirMeshHuge, 1)
					VisualHelper:Tween(AirMeshStorm.Mesh, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
						Scale = AirMeshStorm.Mesh.Scale * 3
					})
					VisualHelper:Tween(AirMeshStorm.Decal, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
						Transparency = 1
					})
					VisualHelper:Tween(AirMeshStorm, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
						CFrame = AirMeshStorm.CFrame * CFrame.Angles(0, 3.141592653589793, 0)
					})
					Debris(AirMeshStorm, 1)
					VisualHelper:Tween(AirHard, TweenInfo.new(0.25, Enum.EasingStyle.Sine), {
						CFrame = AirHard.CFrame * CFrame.Angles(0, 3.141592653589793, 0)
					})
					VisualHelper:Tween(AirHard.Decal, TweenInfo.new(0.25, Enum.EasingStyle.Sine), {
						Transparency = 1
					})
					VisualHelper:Tween(AirHard.Mesh, TweenInfo.new(0.25, Enum.EasingStyle.Sine), {
						Scale = AirHard.Mesh.Scale * 3
					})
					Debris(AirHard, 1)
					VisualHelper:Tween(Flash.Decal, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
						Transparency = 1
					})
					VisualHelper:Tween(Flash.Mesh, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
						Scale = Flash.Mesh.Scale * 4.5
					})
					Debris(Flash, 1)

					local v251 = SuperFlash.Mesh.Scale * 2.6
					local Mesh = SuperFlash.Mesh

					Mesh.Scale = Mesh.Scale / 2
					VisualHelper:Tween(SuperFlash, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {
						CFrame = SuperFlash.CFrame * CFrame.new(0, -7, 0)
					})
					VisualHelper:Tween(SuperFlash.Decal, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {
						Transparency = 1
					})
					VisualHelper:Tween(SuperFlash.Mesh, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {
						Scale = v251
					})
					Debris(SuperFlash, 1)

					local t5 = {
						Rate = 10,
						MaxRange = clone14.Main.Size.Z / 2,
						SideMaxRange = clone14.Main.Size.X / 2,
						Templates = XDagger.Phase0.Rocks:GetChildren()
					}

					for i = 1, t5.Rate do
						local v255 = v205 * CFrame.new(random:NextNumber(-t5.SideMaxRange, t5.SideMaxRange), 1, -(i / t5.Rate * t5.MaxRange + math.random(25)))
						local v256 = MathHelper:RayCast(v255.Position, v255.UpVector * -5, {
							Character,
							workspace.Terrain
						})

						if v256 and v256.Instance and v256.Instance:IsA("BasePart") then
							local cFrame5 = CFrame.lookAt(v256.Position, v256.Position + v256.Normal)
							local cFrame6 = CFrame.Angles(math.random() * 3.141592653589793 / 5, math.random() * 3.141592653589793 / 5, math.random() * 3.141592653589793 / 5)
							local clone20 = t5.Templates[math.random(#t5.Templates)]:Clone()
							clone20.PrimaryPart = clone20.PrimaryPart or clone20:FindFirstChildWhichIsA("BasePart", true)

							clone20.PrimaryPart.Color = v256.Instance.Color
							clone20.PrimaryPart.Material = v256.Instance.Material
							clone20:ScaleTo(1 + math.random() * 3)
							clone20:PivotTo(cFrame5 * CFrame.new(0, 0, clone20.PrimaryPart.Size.Y * 1.2) * cFrame6)
							clone20.Parent = workspace.Terrain
							VisualHelper:Tween(clone20.PrimaryPart, TweenInfo.new(0.1, Enum.EasingStyle.Linear), {
								CFrame = cFrame5 * CFrame.new(0, 0, -clone20.PrimaryPart.Size.Y - math.random(1, 30)) * cFrame6 * CFrame.Angles(math.random() * 3.141592653589793 / 5, math.random() * 3.141592653589793 / 5, math.random() * 3.141592653589793 / 5)
							})
							task.delay(0.105, function() -- line: 1280
								-- upvalues: clone20 (copy), v16 (copy), cFrame5 (copy), VisualHelper (copy)
								clone20.PrimaryPart.Anchored = false
								clone20.PrimaryPart.CanCollide = true
								v16:ApplyCollision(clone20, nil, true)
								clone20.PrimaryPart.AssemblyLinearVelocity = cFrame5.LookVector * math.random(40, 200)
								clone20.PrimaryPart.AssemblyAngularVelocity = Vector3.new(math.random(-1, 1), math.random(-1, 1), math.random(-1, 1)) * 2.5
								task.delay(0.5, function() -- line: 1290
									-- upvalues: clone20 (copy)
									for _, descendant in pairs(clone20.PrimaryPart:GetDescendants()) do
										if descendant:IsA("ParticleEmitter") then
											descendant.Enabled = false
										end
									end
								end)
								task.wait(1 + math.random() * 1)

								for _, descendant in pairs(clone20.PrimaryPart:GetDescendants()) do
									if descendant:IsA("ParticleEmitter") then
										descendant.Enabled = false
									elseif descendant:IsA("MeshPart") or descendant:IsA("BasePart") then
										VisualHelper:Tween(descendant, TweenInfo.new(0.25, Enum.EasingStyle.Linear), {
											Size = Vector3.new(0, 0, 0)
										})
									elseif descendant:IsA("Decal") then
										VisualHelper:Tween(descendant, TweenInfo.new(0.1, Enum.EasingStyle.Linear), {
											Transparency = 1
										})
									end
								end

								VisualHelper:Tween(clone20.PrimaryPart, TweenInfo.new(0.25, Enum.EasingStyle.Linear), {
									Size = Vector3.new(0, 0, 0)
								})
							end)
						end
					end
				else
					clone14.FinalToggle.Floor.Smoke:Destroy()
					clone14.FinalToggle.Floor.SmokeRotation:Destroy()
				end

				VisualHelper:SetEnableAll(clone14.FinalToggle, true)

				for _, v261 in children do
					local SliceGroundBeam = v261.SliceGroundBeam

					VisualHelper:Tween(v261, TweenInfo.new(0.115, Enum.EasingStyle.Back), {
						Size = v261.Size * Vector3.new(1.75, 1, 1.75)
					})

					local Left = SliceGroundBeam.Left

					Left.Position = Left.Position * 1.4

					local Right = SliceGroundBeam.Right

					Right.Position = Right.Position * 1.4

					local UpBeam = SliceGroundBeam.UpBeam

					UpBeam.Enabled = true

					local FadeBeam = SliceGroundBeam.FadeBeam

					FadeBeam.Enabled = true

					local v267 = v261.Size.Z * 0.028
					local v268 = UpBeam.Width0 * v267
					local v269 = UpBeam.Width1 * v267

					UpBeam.Width0 = 0
					UpBeam.Width1 = 0
					FadeBeam.Width0 = 0
					FadeBeam.Width1 = 0
					VisualHelper:Tween(UpBeam, TweenInfo.new(0.0425, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, true), {
						Width0 = v268,
						Width1 = v269
					})
					VisualHelper:Tween(FadeBeam, TweenInfo.new(0.04, Enum.EasingStyle.Sine), {
						Width0 = v268 * 1.06,
						Width1 = v269 * 1.06
					})
					VisualHelper:Tween(FadeBeam, TweenInfo.new(0.27, Enum.EasingStyle.Sine), {
						Brightness = 0
					})
					VisualHelper:SetEnableAll(v261, true, true)
					task.wait(0.0055)
					task.delay(0.1, function() -- line: 1354
						-- upvalues: VisualHelper (copy), v261 (copy)
						VisualHelper:SetEnableAll(v261, false, true)
					end)
				end

				task.wait(0.1)

				for v270, v271 in children do
					VisualHelper:Tween(v271, TweenInfo.new(0.3 + v270 * 0.075, Enum.EasingStyle.Sine), {
						Size = v271.Size * Vector3.new(0, 1, 1)
					})
				end

				task.wait(0.07)
				VisualHelper:EmitAll(clone14.FloorImpactEnd)
				VisualHelper:SetEnableAll(clone14.Main, false, true)
				task.wait(0.15)
				VisualHelper:EmitAll(clone14.FloorImpactFast)
				VisualHelper:SetEnableAll(clone14.FinalToggle, false)
				Debris(clone14, 2)
				VisualHelper:SetEnableAll(clone13, false)
				Debris(clone13, 1.5)
				VisualHelper:SetEnableAll(clone12, false)
				Debris(clone12, 1)
				clone11:Destroy()
				task.wait(0.2)
				v96:DoCleaning()
			end)

			local _ = cFrame * CFrame.new(0, 0, -1) * CFrame.Angles(-1.5707963267948966, 0, 0)

			VisualHelper:Tween(Main, TweenInfo.new(0.145, Enum.EasingStyle.Sine), {
				Size = v136,
				CFrame = UpCFrame * cFrame4
			})

			local v139 = CFrame.lookAt(v129, v129 + v130) * CFrame.Angles(-1.5707963267948966, 0, 0) * CFrame.new(0, 0.5, 0)
			local clone21 = XDagger.Phase0.PushExplosionFast:Clone()

			clone21:PivotTo(v139)
			Util.SetParentOverrideWithColor(clone21, Model, Player, "ControlFruitVFXColor")
			VisualHelper:EmitAll(clone21)
			Util.Debris:AddItem(clone21, 3)

			local clone22 = XDagger.Phase0.BallNeon:Clone()

			clone22.CFrame = v139
			clone22.Transparency = 0.95

			local color3_4 = Color3.fromRGB(89, 133, 255)

			clone22.Color = if typeof(Player) == "Instance" and (not not Player:IsA("Player") and Player.Parent) then Util.WrapColor3Constructor(color3_4, Player, "ControlFruitVFXColor") else color3_4
			clone22.Size = Vector3.new(1, 1, 1) * (clone21.Main.Size.Y * 0.65)
			clone22.Parent = Model
			VisualHelper:Tween(clone22, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
				Transparency = 1,
				Size = clone22.Size * 4
			})
			Debris(clone22, 0.2)

			local Beams = clone21.Main.Beams

			VisualHelper:Tween(Beams, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
				WorldCFrame = Beams.WorldCFrame * CFrame.Angles(0, 3.141592653589793, 0)
			})

			for _, descendant in Beams:GetDescendants() do
				if descendant:IsA("Beam") then
					descendant.Enabled = true
					VisualHelper:Tween(descendant, TweenInfo.new(0.15 + math.random(3) * 0.025, Enum.EasingStyle.Sine), {
						Width0 = 0,
						Width1 = 0
					})
				end
			end

			Debris(Beams, 0.5)

			local v146 = clone21.Main.Size.X / 2

			Rocks:CircleRocks(v139.Position, 13, v146 * 0.7, Vector3.new(6.199999809265137, 1.2000000476837158, 2), 0, { workspace.Terrain })
			Rocks:CircleRocks(v139.Position, 5, v146 * 1.05, Vector3.new(5, 1.7999999523162842, 3.200000047683716), 0, { workspace.Terrain })

			for _ = 1, 3 do
				Rocks:AirRocks(v139, Vector3.new(random:NextNumber(6.5, 9), 2, random:NextNumber(6.5, 9)), false, math.random(90, 130), 1, 1, 3, t3.Instance.Color, t3.Instance.Material)
			end

			local AirMeshHuge = clone21.AirMeshHuge
			local SuperFlash = clone21.SuperFlash
			local Flash = clone21.Flash
			local AirHard = clone21.AirHard

			VisualHelper:Tween(AirMeshHuge.Mesh, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
				Scale = AirMeshHuge.Mesh.Scale * 1.9
			})
			VisualHelper:Tween(AirMeshHuge.Decal, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
				Transparency = 1
			})
			Debris(AirMeshHuge, 0.3)
			VisualHelper:Tween(AirHard, TweenInfo.new(0.325, Enum.EasingStyle.Sine), {
				CFrame = AirHard.CFrame * CFrame.Angles(0, 3.141592653589793, 0)
			})
			VisualHelper:Tween(AirHard.Decal, TweenInfo.new(0.325, Enum.EasingStyle.Sine), {
				Transparency = 1
			})
			VisualHelper:Tween(AirHard.Mesh, TweenInfo.new(0.325, Enum.EasingStyle.Sine), {
				Scale = AirHard.Mesh.Scale * 2
			})
			Debris(AirHard, 0.5)
			VisualHelper:Tween(Flash.Decal, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
				Transparency = 1
			})
			VisualHelper:Tween(Flash.Mesh, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
				Scale = Flash.Mesh.Scale * 2.5
			})
			Debris(Flash, 0.4)

			local v152 = SuperFlash.Mesh.Scale * 2.6
			local Mesh = SuperFlash.Mesh

			Mesh.Scale = Mesh.Scale / 2
			VisualHelper:Tween(SuperFlash, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {
				CFrame = SuperFlash.CFrame * CFrame.new(0, -7, 0)
			})
			VisualHelper:Tween(SuperFlash.Decal, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {
				Transparency = 1
			})
			VisualHelper:Tween(SuperFlash.Mesh, TweenInfo.new(0.55, Enum.EasingStyle.Sine), {
				Scale = v152
			})
			Debris(SuperFlash, 0.7)
		else
			if u121 then
				u121:Stop()
			end

			if Attachment then
				Attachment:Destroy()
			end

			v96:DoCleaning()
		end
	end
end
