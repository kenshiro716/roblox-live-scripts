
local ReplicatedStorage = game:GetService("ReplicatedStorage")

game:GetService("TweenService")

local RunService = game:GetService("RunService")

game:GetService("StarterPlayer")
game:GetService("ServerStorage")

local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Shared = script.Parent.Parent.Shared
local Utility = Shared.Utility
local VisualHelper = require(Utility.VisualHelper)
local MathHelper = require(Utility.MathHelper)

require(Shared.Rocks)

local ObjectClass = require(Shared:WaitForChild("ObjectClass"))
local Camera = workspace.Camera
local Util = require(ReplicatedStorage:WaitForChild("Util"))
local Effect = require(ReplicatedStorage.Effect)
local FX = require(ReplicatedStorage:WaitForChild("FX"))
local Domain = FX:WaitForChild("ControlRework").Domain
local M1 = FX:WaitForChild("ControlRework").M1
local random = Random.new()
local n1 = 0

return function(p1) -- line: 49
	-- upvalues: ObjectClass (copy), Util (copy), Effect (copy), VisualHelper (copy), UserInputService (copy), Camera (copy), GuiService (copy), MathHelper (copy), RunService (copy), n1 (ref), M1 (copy), random (copy), Domain (copy)
	if not p1.DataModelId then
	end

	local v19 = ObjectClass.Stored[p1.DataModel] or ObjectClass.Selected
	local v20 = ObjectClass:IsSelectionLocked()
	local Player = p1.Player
	local _ = p1.Character

	if p1.ForceThrow then
		local DataModel = p1.DataModel
		local PlayerName = workspace._WorldOrigin["Cubes-Objects"]:FindFirstChild(Player.Name)

		if PlayerName then
			local DataModel2 = PlayerName:FindFirstChild(DataModel)

			if DataModel2 then
				local v26 = ObjectClass.Stored[DataModel2]

				if v26 then
					local Model = v26.Model

					if not Model.Parent then
						return
					end

					local Position = Model:GetPivot().Position
					local ShootPoint = p1.ShootPoint
					local v30, v31, v32 = Util.Ray(Position, (ShootPoint - Position).Unit * 700, {
						workspace._WorldOrigin,
						workspace.Characters,
						workspace.Enemies,
						workspace.CutParts
					})
					local t1 = {
						Instance = v30,
						Position = v31,
						Normal = v32
					}

					Util.Sound:Play(({
						"CTRLFRT_Fist_Release_Small_0",
						"CTRLFRT_Fist_Release_Medium_0",
						"CTRLFRT_Fist_Release_Large_0"
					})[Model:GetAttribute("SizeScale")] .. tostring(math.random(1, 4)), Model.PrimaryPart.Position)
					v26.ThrowData.RayCastResult = t1
					v26:Throw(function(p2) -- line: 93
						-- upvalues: Effect (copy), v26 (copy)
						Effect.new("ControlRework.ObjectExplosion"):play({
							Position = p2.Position,
							Normal = p2.Normal,
							Object = v26.Custom and v26.Custom or v26.Model.Main,
							Energized = v26.Energized,
							Scale = 2.15 * v26:GetLayoutSize(),
							IsCustom = not not v26.Custom
						})
						v26:Destroy()
					end)
				end
			end
		end
	end

	if p1.Action == "Deselect" or p1.Action == "Select" then
		if not v20 and (v19 and v19.__type == ObjectClass.__type) then
			v19[p1.Action](v19)

			if p1.Holding then
				local Holding = p1.Holding

				repeat
					task.wait()
				until not Holding or not Holding.Value

				local Model = v19.Model

				if not Model.Parent then
					return
				end

				local Mouse = require(game.ReplicatedStorage.Mouse)
				local Position = Model:GetPivot().Position
				local p = Mouse.Hit.p
				local v39, v40, v41 = Util.Ray(Position, (p - Position).Unit * 700, {
					workspace._WorldOrigin,
					workspace.Characters,
					workspace.Enemies,
					workspace.CutParts
				})
				local _ = {
					Instance = v39,
					Position = v40,
					Normal = v41
				}

				Util.Sound:Play(({
					"CTRLFRT_Fist_Release_Small_0",
					"CTRLFRT_Fist_Release_Medium_0",
					"CTRLFRT_Fist_Release_Large_0"
				})[Model:GetAttribute("SizeScale")] .. tostring(math.random(1, 4)), Model.PrimaryPart.Position)

				if Model:FindFirstChild("Main") then
					Model.Main:SetAttribute("SizeScale", Model:GetAttribute("SizeScale"))
				end

				v19:Throw(function(p3) -- line: 144
					-- upvalues: Effect (copy), v19 (copy)
					Effect.new("ControlRework.ObjectExplosion"):play({
						Position = p3.Position,
						Normal = p3.Normal,
						Object = v19.Custom and v19.Custom or v19.Model.Main,
						Energized = v19.Energized,
						Scale = 2.15 * v19:GetLayoutSize(),
						IsCustom = not not v19.Custom
					})
					v19:Destroy()
				end)
				ObjectClass:SetSelected(nil)
				ObjectClass:UnlockSelection()
			end

			return
		end
	elseif p1.Action == "SelectAll" then
		local t2 = {}

		for v44, v45 in ObjectClass.Stored do
			if p1.SelectedModels[v44.Name] then
				table.insert(t2, v45)
			end
		end

		local n2 = -1

		ObjectClass:MultipleSelect(t2, function(p4) -- line: 175
			-- upvalues: n2 (ref), t2 (copy), ObjectClass (copy), VisualHelper (copy)
			n2 += 1

			local v85 = n2 / #t2
			local ThrowData = p4.ThrowData
			local Model = p4.Model
			local v88 = p4.Maid:GiveTask(ObjectClass:CreateMouseArea(p4:GetLayoutSize(), p4.Player))

			v88.Main.Light:Destroy()

			local Scale = v88:GetScale()

			v88:ScaleTo(0.01)
			VisualHelper:TweenScale(v88, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, n2 * 0.07), Scale)
			ThrowData.MouseArea = v88
			ThrowData.MouseCFrameOffset = CFrame.Angles(0, 0, (math.rad(v85 * 360 + math.random(-35, 35))))
			ThrowData.MouseCFrameYOffset = CFrame.new(0, v85 * 155, 0)
			Model:SetAttribute("MouseCFrameOffset", ThrowData.MouseCFrameOffset)
			Model:SetAttribute("MouseCFrameYOffset", ThrowData.MouseCFrameYOffset)
		end)

		local connection = nil

		local function Update(p5) -- line: 204
			-- upvalues: UserInputService (copy), Camera (copy), GuiService (copy), MathHelper (copy), t2 (copy), connection (ref)
			local p = require(game.ReplicatedStorage.Mouse).Hit.p
			local MouseLocation = UserInputService:GetMouseLocation()
			local v93 = Camera:ScreenPointToRay(MouseLocation.X, MouseLocation.Y - GuiService:GetGuiInset().Y)
			local v94 = MathHelper:RayCast(v93.Origin, v93.Direction * 2000, {
				workspace._WorldOrigin,
				workspace.Characters,
				workspace.Enemies
			}, Enum.RaycastFilterType.Exclude)

			for _, v96 in t2 do
				if v96.IsThrowing then
					connection:Disconnect()
				end

				local ThrowData = v96.ThrowData
				local Position = v96:GetPivot().Position
				local v99 = v94 and CFrame.lookAt(v94.Position, v94.Position + v94.Normal) or CFrame.lookAt(p, Position)
				local v100 = 0 + ThrowData.MouseCFrameYOffset.Y
				local Position2 = (v99 * ThrowData.MouseCFrameOffset * ThrowData.MouseCFrameYOffset * CFrame.new(math.cos(v100) * 25, math.sin(v100) * 25, 0)).Position
				local v102 = MathHelper:RayCast(Position, CFrame.lookAt(Position, Position2).LookVector * 2000, {
					workspace._WorldOrigin,
					workspace.Characters,
					workspace.Enemies
				}, Enum.RaycastFilterType.Exclude)

				if not v102 then
					return
				end

				ThrowData.RayCastResult = v102
				ThrowData.MouseArea:PivotTo(CFrame.lookAt(v102.Position, v102.Position + v102.Normal) * CFrame.new(0, 0, -1) * CFrame.Angles(-1.5707963267948966, 0, 0))

				local SelectedUpdate = ThrowData.SelectedUpdate

				if not SelectedUpdate then
					return
				end

				SelectedUpdate(p5)
			end
		end

		connection = RunService.RenderStepped:Connect(function(dt) -- line: 240
			-- upvalues: Update (copy)
			Update(dt)
		end)

		local Holding = p1.Holding

		repeat
			task.wait()
		until not Holding or not Holding.Value

		if connection then
			connection:Disconnect()
		end

		for _, v51 in t2 do
			local Model = v51.Model

			if Model.Parent then
				local _ = Model:GetPivot().Position

				print(Model:GetFullName())
				Util.Sound:Play(({
					"CTRLFRT_Fist_Release_Small_0",
					"CTRLFRT_Fist_Release_Medium_0",
					"CTRLFRT_Fist_Release_Large_0"
				})[Model:GetAttribute("SizeScale")] .. tostring(math.random(1, 4)), Model.PrimaryPart.Position)
				v51:Throw(function(p6) -- line: 263
					-- upvalues: v51 (copy), Effect (copy)
					if not v51.Model.Parent then
						return
					end

					Effect.new("ControlRework.ObjectExplosion"):play({
						Position = p6.Position,
						Normal = p6.Normal,
						Object = v51.Custom and v51.Custom or v51.Model.Main,
						Energized = v51.Energized,
						Scale = 2.15 * v51:GetLayoutSize(),
						IsCustom = not not v51.Custom
					})
					v51:Destroy()
				end)
			end
		end

		ObjectClass:SetSelected(nil)
		ObjectClass:UnlockSelection()

		return
	end

	if v20 then
		return
	end

	n1 += 1

	local _ = p1.MousePos
	local MouseLocation = UserInputService:GetMouseLocation()

	Camera:ScreenPointToRay(MouseLocation.X, MouseLocation.Y - GuiService:GetGuiInset().Y)

	local RayCastResult = p1.RayCastResult

	if not p1.Proxy then
		return
	end

	if not RayCastResult then
		return
	end

	local Proxy = p1.Proxy
	local cFrame = CFrame.lookAt(RayCastResult.Position, RayCastResult.Position + RayCastResult.Normal)
	local cFrame2 = CFrame.Angles(-1.5707963267948966, 0, 0)
	local clone = M1.FloorPattern:Clone()

	Util.SetParentOverrideWithColor(clone, workspace._WorldOrigin, Player, "ControlFruitVFXColor")
	VisualHelper:SetEnableAll(clone, true)

	local v61 = ObjectClass.new(Player, cFrame, Proxy)

	local function EmitExpansionExplosion(n3: number) -- line: 340
		-- upvalues: M1 (copy), clone (copy), Util (copy), Player (copy), random (copy), VisualHelper (copy)
		local clone2 = M1.ExpansionExplosion:Clone()

		clone2:ScaleTo(n3 * 1.5)
		clone2:PivotTo(clone:GetPivot())
		Util.SetParentOverrideWithColor(clone2, workspace._WorldOrigin, Player, "ControlFruitVFXColor")
		clone2.Main.Layers.Orientation = Vector3.new(0, 1, 0) * random:NextNumber(-360, 360)

		for i, child in clone2.Main.Layers:GetChildren() do
			child.Orientation = child.Orientation * 1.5

			local Beam = child.Beam

			Beam.Width0 = Beam.Width0 * 2
			Beam.Width1 = Beam.Width1 * 2
			Beam.Enabled = true

			local v111 = random:NextNumber(0.2, 0.3)

			VisualHelper:Tween(child, TweenInfo.new(v111, Enum.EasingStyle.Linear), {
				Orientation = child.Orientation + Vector3.new(0, 450 * (i % 2 ~= 0 and -1 or 1))
			})
			VisualHelper:Tween(Beam, TweenInfo.new(v111, Enum.EasingStyle.Sine), {
				Width0 = 0,
				Width1 = 0
			})
		end

		for _, child in clone2.Main.CircleWinds:GetChildren() do
			local Beam = child.Beam

			Beam.Enabled = true
			VisualHelper:Tween(Beam, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {
				Width0 = 0,
				Width1 = 0
			})
		end

		VisualHelper:EmitAll(clone2)
		Util.Debris:AddItem(clone2, 2)
	end

	local Main = v61.Model.Main

	Main.Color = RayCastResult.Instance.Color
	Main.Material = RayCastResult.Instance.Material
	Main:SetAttribute("IsControlPart", true)

	local v64 = ObjectClass.TemplateModel.Main.Size / 3
	local Outline = Main.Outline
	local DecalTransparency = Outline.Decal.Transparency

	Outline.Decal.Transparency = 1

	local u67 = nil
	local thread = nil
	local u69 = nil
	local u70 = nil

	local function SmoothScaleTo(n4: number) -- line: 389
		-- upvalues: thread (ref), u67 (ref), clone (copy), cFrame (copy), v61 (copy), u69 (ref), v64 (copy), u70 (ref), cFrame2 (copy), VisualHelper (copy), Main (copy), EmitExpansionExplosion (copy)
		if thread then
			task.cancel(thread)
		end

		u67 = true
		clone:ScaleTo(n4)
		clone:PivotTo(cFrame * CFrame.new(0, 0, -1) * CFrame.Angles(-1.5707963267948966, 0, 0))
		v61:ScaleTo(n4)
		u69 = v64 * n4
		u70 = cFrame * CFrame.new(0, 0, -(u69.Y / 2 + 0))
		v61:PivotTo(cFrame * cFrame2)
		v61:SetSize((Vector3.new(0, 0, 0)))
		VisualHelper:Tween(Main, TweenInfo.new(0.15, Enum.EasingStyle.Back), {
			Size = u69 * Vector3.new(1.350000023841858, 0.30000001192092896, 1.350000023841858),
			CFrame = Main.CFrame * CFrame.new(0, u69.Y * 0.3 / 2, 0)
		})
		thread = task.delay(0.1, function() -- line: 406
			-- upvalues: VisualHelper (copy), Main (copy), u69 (ref), u70 (ref), cFrame2 (copy), u67 (ref)
			VisualHelper:Tween(Main, TweenInfo.new(0.25, Enum.EasingStyle.Back), {
				Size = u69,
				CFrame = u70 * cFrame2
			})
			task.wait(0.225)
			u67 = false
		end)
		EmitExpansionExplosion(n4)
	end

	SmoothScaleTo(1)

	local Holding = p1.Holding
	v61.Model:SetAttribute("SizeScale", 1)

	if Holding and Holding.Value then
		local clone3 = Domain.CameraEffectsHex:Clone()

		Util.SetParentOverrideWithColor(clone3, Camera, Player, "ControlFruitVFXColor")

		if p1.Player == game.Players.LocalPlayer then
			VisualHelper:SetEnableAll(clone3, true)
			VisualHelper:EmitAll(clone3)
		end

		p1.Holding.Changed:Once(function() -- line: 431
			-- upvalues: Holding (ref)
			Holding = false
		end)

		local n5 = 0
		local n6 = 1

		v61.Model:SetAttribute("SizeScale", n6)

		local t3 = {
			"CTRLFRT_Fist_CubeSpawn_Small_01",
			"CTRLFRT_Fist_CubeSpawn_Medium_01",
			"CTRLFRT_Fist_CubeSpawn_Large_01"
		}

		Util.Sound:Play(t3[n6], Main.Position)

		while Holding and Holding.Value do
			n5 += RunService.RenderStepped:Wait()
			clone3.CFrame = Camera.CFrame * CFrame.new(0, 0, -2.25) * CFrame.Angles(0, 1.5707963267948966, 0)

			if not (n5 < 0.4) then
				n5 = 0

				local v77 = v61:GetLayoutSize() + 1

				if not (v77 > 3) then
					v61:SetLayout(`{ v77 }x{ v77 }`)
					SmoothScaleTo(v77)
					n6 += 1
					Util.Sound:Play(t3[n6], Main.Position)
					v61.Model:SetAttribute("SizeScale", n6)
				end
			end
		end

		Util.Sound:Play(({
			"CTRLFRT_Fist_CubeLift_Small_01",
			"CTRLFRT_Fist_CubeLift_Medium_01",
			"CTRLFRT_Fist_CubeLift_Large_01"
		})[n6], Main.Position)
		clone3:Destroy()
	end

	while u67 do
		RunService.RenderStepped:Wait()
	end

	EmitExpansionExplosion(v61:GetScale() * 1.25)
	v61:Flash()
	VisualHelper:Tween(Main, TweenInfo.new(0.05, Enum.EasingStyle.Sine), {
		Size = u69 * Vector3.new(1, 1, 1) * 1.55,
		CFrame = Main.CFrame * CFrame.new(0, u69.Y * 0.3 / 2, 0)
	})
	task.wait(0.05)
	Outline.CFrame = Main.CFrame
	VisualHelper:Tween(Main, TweenInfo.new(0.18, Enum.EasingStyle.Sine), {
		Size = u69
	})
	VisualHelper:Tween(Outline.Decal, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {
		Transparency = DecalTransparency
	})
	v61:SwitchMode("Planing")
	v61:ToggleBodyPattern(true)
	v61.PlaningCFrame = cFrame * CFrame.new(0, 0, -(v61:GetSize().Y / 2 + math.random(35, 65))) * cFrame2 * CFrame.Angles(0, math.rad((math.random(360))), (math.rad((math.random(-25, 25)))))

	local PlaningCFrame = v61.PlaningCFrame
	local timestamp = tick()

	task.spawn(function() -- line: 499
		-- upvalues: v61 (copy), timestamp (copy), PlaningCFrame (copy)
		while v61 and v61.Model and v61.Model.Parent do
			local v116 = 1 - math.exp(-0.6 * task.wait())
			local v117 = time() - timestamp
			local v118 = v61:GetPivot():Lerp(PlaningCFrame, v116)

			v61:PivotTo(CFrame.new(v118.Position + Vector3.new(0, math.sin(v117 * 2) * 0.12, 0)) * CFrame.fromOrientation(v118:ToOrientation()))
		end
	end)
	task.spawn(function() -- line: 515
		-- upvalues: Proxy (copy), v61 (copy), Effect (copy)
		repeat
			task.wait()
		until not Proxy or not Proxy:IsDescendantOf(workspace) or Proxy:GetAttribute("Exploding")

		if Proxy:GetAttribute("Throwing") then
			return
		end

		if not v61.Model.Parent then
			return
		end

		if v61.IsThrowing then
			return
		end

		Effect.new("ControlRework.ObjectExplosion"):play({
			Object = v61.Model.Main,
			Energized = v61.Energized,
			Scale = 2.15 * v61:GetLayoutSize()
		})

		if v61 then
			v61:Destroy()
		end
	end)
	clone.Main.Lines.Enabled = false

	for _, child in clone.Main.Main:GetChildren() do
		child.Enabled = false
		child.TimeScale = 0.15
	end

	VisualHelper:SetEnableAll(clone.Main.Smokes)
	Util.Debris:AddItem(clone, 1)
end
