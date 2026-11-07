
local _ = game.Players.LocalPlayer
local _ = workspace._WorldOrigin

game:GetService("TweenService")

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FX = require(ReplicatedStorage:WaitForChild("FX"))
local Domain_Katsuo = FX:WaitForChild("ControlRework").Domain_Katsuo
local Dagger = FX:WaitForChild("ControlRework").Domain:WaitForChild("Dagger")
local Z_Katsuo = FX:WaitForChild("ControlRework").Z_Katsuo
local F_Katsuo = FX:WaitForChild("ControlRework").F_Katsuo
local C_Katsuo = FX:WaitForChild("ControlRework").C_Katsuo
local Util = require(ReplicatedStorage:WaitForChild("Util"))
local Shared = script.Parent.Shared
local Utility = Shared.Utility
local VisualHelper = require(Utility.VisualHelper)
local MathHelper = require(Utility.MathHelper)
local Textures = require(Shared.Textures)
local Rocks = require(Shared.Rocks)
local Dome = require(script.Parent.Domain.Dome)

require(game.ReplicatedStorage.Util.CameraShaker)
require(Shared.HexsStormClass)

local UIPromptAnimation = require(Shared:WaitForChild("UIPromptAnimation"))
local v20 = require(ReplicatedStorage:WaitForChild("CustomCollisions")).new("Rocks")
local CurrentCamera = workspace.CurrentCamera

local function RecolorControlColor(p1, color3: Color3) -- line: 39
	-- upvalues: Util (copy)
	if typeof(p1) ~= "Instance" or not p1:IsA("Player") or not p1.Parent then
		return color3
	end

	return Util.WrapColor3Constructor(color3, p1, "ControlFruitVFXColor")
end
local function EmitExplosion(p2, b1: boolean?, p3) -- line: 46
	-- upvalues: Util (copy), F_Katsuo (copy), VisualHelper (copy), C_Katsuo (copy), MathHelper (copy)
	if not p2 then
		return
	end

	local v29 = typeof(p2) == "RaycastResult"

	Util.CameraShaker:Shake("Fast")

	local v30 = v29 and CFrame.lookAt(p2.Position, p2.Position + p2.Normal) * CFrame.Angles(-1.5707963267948966, 0, 0) * CFrame.new(0, 0.5, 0) or p2
	local clone = F_Katsuo.Explosion:Clone()

	clone:PivotTo(v30)
	clone:ScaleTo(clone:GetScale() * 0.55)
	Util.SetParentOverrideWithColor(clone, workspace._WorldOrigin, p3, "ControlFruitVFXColor")

	if not v29 then
		clone.Main.GlowShape.Crater:Destroy()
	end

	VisualHelper:EmitAll(clone)
	Util.Debris:AddItem(clone, 6)

	local v32 = clone.Main.Size.X / 2
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

	Util.Debris:AddItem(Beams, 0.5)

	local clone2 = C_Katsuo.BallNeon:Clone()

	clone2.CFrame = v30
	clone2.Transparency = 0.94

	local color3 = Color3.fromRGB(89, 133, 255)

	clone2.Color = if typeof(p3) == "Instance" and (not not p3:IsA("Player") and p3.Parent) then Util.WrapColor3Constructor(color3, p3, "ControlFruitVFXColor") else color3
	clone2.Size = Vector3.new(1, 1, 1) * (clone.Main.Size.Y * 0.65)
	clone2.Parent = workspace._WorldOrigin
	VisualHelper:Tween(clone2, TweenInfo.new(0.14, Enum.EasingStyle.Sine), {
		Transparency = 1,
		Size = clone2.Size * 1.35
	})
	Util.Debris:AddItem(clone2, 0.14)

	local clone3 = C_Katsuo.BallNeon:Clone()

	clone3.CFrame = v30
	clone3.Transparency = 0.85

	local color3_2 = Color3.fromRGB(89, 133, 255)

	clone3.Color = if typeof(p3) == "Instance" and (not not p3:IsA("Player") and p3.Parent) then Util.WrapColor3Constructor(color3_2, p3, "ControlFruitVFXColor") else color3_2
	clone3.Size = Vector3.new(1, 1, 1) * clone.Main.Size.Y
	clone3.Parent = workspace._WorldOrigin
	VisualHelper:Tween(clone3, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {
		Transparency = 1,
		Size = clone3.Size * 1.6
	})
	Util.Debris:AddItem(clone3, 0.15)

	if b1 then
		return
	end

	for _, child in clone.Main.Boom:GetChildren() do
		if child.Name == "Smoke" then
			child:Destroy()
		end
	end

	task.spawn(function() -- line: 112
		-- upvalues: v30 (copy), v32 (copy), MathHelper (copy), F_Katsuo (copy), Util (copy), p3 (copy), VisualHelper (copy)
		for _ = 1, 3 do
			local v226 = v30 * CFrame.Angles(0, math.random() * 3.141592653589793 * 2, 0) * CFrame.new(0, 1, -math.random(v32 + 5, v32 + 25))
			local v227 = MathHelper:RayCast(v226.Position, v226.UpVector * -10, { workspace.Map }, Enum.RaycastFilterType.Include)

			if v227 then
				local clone4 = F_Katsuo.BoltExplosion:Clone()

				clone4.CFrame = CFrame.lookAt(v227.Position, v227.Position + v227.Normal) * CFrame.Angles(-1.5707963267948966, 0, 0) * CFrame.new(0, 0.5, 0)
				Util.SetParentOverrideWithColor(clone4, workspace._WorldOrigin, p3, "ControlFruitVFXColor")
				VisualHelper:EmitAll(clone4)
				Util.Debris:AddItem(clone4, 1)
			end

			task.wait(0.125)
		end
	end)
end

return function(p4) -- line: 131
	-- upvalues: CurrentCamera (copy), Util (copy), EmitExplosion (copy), Dome (copy), VisualHelper (copy), Domain_Katsuo (copy), RunService (copy), MathHelper (copy), Z_Katsuo (copy), Dagger (copy), Textures (copy), UIPromptAnimation (copy), v20 (copy), Rocks (copy)
	if typeof(p4.Player) == "Instance" and (p4.Player:IsA("Player") and not p4.Player:FindFirstChild("PlayerGui") and p4.Player ~= game.Players.LocalPlayer) then
		Instance.new("Folder", p4.Player).Name = "PlayerGui"
	end

	local v43 = p4.Origin or (p4.Root and p4.Root.Position or (p4.hrp and p4.hrp.Position or (p4.Player and p4.Player.Character.PrimaryPart.Position or p4.player and p4.player.Character.PrimaryPart.Position)))

	assert(v43, "Origin Vector3 missing in: ", script:GetFullName())

	if (CurrentCamera.CFrame.Position - v43).Magnitude > 1200 then
		return
	end

	local Root = p4.Root
	local Character = p4.Character
	local Player = p4.Player

	if p4.ShiftRoom then
		Util.Sound:Play("X_Reassembly_03", Root.Position)
		EmitExplosion(Root.CFrame, nil, Player)

		return
	end

	if p4.Pulse then
		local v47 = Dome({
			Stage = "FromPlayer",
			Player = Player
		})

		if v47 then
			v47:Pulse(Color3.fromRGB(170, 0, 255), 1, 0.16, 6, true)
		end

		return
	end

	if p4.Aura then
		local AuraActive = Character:GetAttribute("AuraActive")

		if p4.AURA_OFF then
			AuraActive = p4.AURA_OFF
		end

		Character:SetAttribute("AuraActive", not AuraActive)

		if AuraActive then
			return
		end

		local v49 = VisualHelper:BuildUniqueName(Character, "AuraObject")

		for _, child in workspace._WorldOrigin:GetChildren() do
			if v49 == child.Name then
				child:Destroy()
			end
		end

		if Root:FindFirstChild("AuraObject") then
			for _, descendant in Root:GetDescendants() do
				if descendant.Name == "AuraObject" or descendant.Name == "AuraObject_" then
					descendant:Destroy()
				end
			end
		end

		local n1 = 0
		local n2 = 0
		local t1 = {}
		local v57 = nil

		for _, child in Domain_Katsuo.Aura:GetChildren() do
			if child:IsA("BasePart") then
				local clone = child:Clone()

				clone.Name = v49
				Util.SetParentOverrideWithColor(clone, workspace._WorldOrigin, Player, "ControlFruitVFXColor")
				VisualHelper:SetEnableAll(clone, true)

				local Weld = Instance.new("Weld")

				Weld.Part0 = clone
				Weld.Part1 = Character[child.Name]
				Weld.Parent = clone

				if child.Name == "HumanoidRootPart" then
					v57 = clone
				end

				table.insert(t1, clone)
			end
		end

		for _, child in Character:GetChildren() do
			if child:IsA("BasePart") then
				for _, child2 in Domain_Katsuo.Aura.Particles:GetChildren() do
					local clone = child2:Clone()

					clone.Name = "AuraObject_"
					clone.Enabled = true
					Util.SetParentOverrideWithColor(clone, child, Player, "ControlFruitVFXColor")
					table.insert(t1, clone)
				end
			end
		end

		local Ground = v57.Ground

		Ground.Parent = workspace.Terrain
		table.insert(t1, Ground)

		local u68 = false
		local clone = Domain_Katsuo.Aura.RockSmoke:Clone()

		Util.SetParentOverrideWithColor(clone, workspace.Terrain, Player, "ControlFruitVFXColor")

		local Model = Instance.new("Model")

		Model.Name = "RockAura"
		Model.Parent = workspace.Terrain

		local u71 = Util.Sound:Play("CTRLFRT_CharacterIdle_Loop_01", Root)
		local InCutscene = _G.InCutscene
		local connection = nil

		connection = RunService.Heartbeat:Connect(function(dt) -- line: 240
			-- upvalues: InCutscene (ref), t1 (copy), VisualHelper (copy), u71 (ref), Util (copy), Root (copy), n2 (ref), n1 (ref), Character (copy), connection (ref), clone (copy), Model (copy), MathHelper (copy), Ground (copy), u68 (ref), Domain_Katsuo (copy), Player (copy)
			if InCutscene ~= _G.InCutscene then
				for _, v231 in t1 do
					if v231:IsA("ParticleEmitter") then
						v231.Enabled = not _G.InCutscene
					else
						VisualHelper:SetEnableAll(v231, not _G.InCutscene)
					end

					if _G.InCutscene then
						if u71 then
							Util.Sound:FadeOut(u71, 0.1)
							u71 = nil
						end
					elseif u71 == nil then
						u71 = Util.Sound:Play("CTRLFRT_CharacterIdle_Loop_01", Root)
					end
				end

				InCutscene = _G.InCutscene

				return
			end

			if _G.InCutscene then
				n2 = 0

				return
			end

			n1 += dt
			n2 += dt

			if not Character:GetAttribute("AuraActive") or not Character:IsDescendantOf(workspace) then
				for _, v233 in t1 do
					if v233:IsA("ParticleEmitter") then
						v233.Enabled = false
					else
						VisualHelper:SetEnableAll(v233, false)
					end

					if u71 then
						Util.Sound:FadeOut(u71, 0.2)
					end

					v233.Name = "#Ignore"
					Util.Debris:AddItem(v233, 2)
				end

				connection:Disconnect()
				clone:Destroy()
				Util.Debris:AddItem(Model, 5)

				return
			end

			local v234 = MathHelper:RayCast(Root.Position, Vector3.new(0, -Root.Size.Y * 4), { workspace.Map }, Enum.RaycastFilterType.Include)

			if v234 then
				Ground.WorldPosition = v234.Position + Vector3.new(0, 0.10000000149011612, 0)

				if not u68 then
					u68 = true
					VisualHelper:SetEnableAll(Ground, u68)
				end

				if n2 > 0.85 then
					n2 = 0

					local v235 = Root.CFrame * CFrame.Angles(0, math.random() * 3.141592653589793 * 2, 0) * CFrame.new(0, 0, math.random(10, 15))
					local v236 = MathHelper:RayCast(v235.Position, v235.UpVector * -5, { workspace.Map }, Enum.RaycastFilterType.Include)

					if not v236 then
						return
					end

					clone.WorldPosition = v236.Position
					VisualHelper:EmitAll(clone)

					local clone5 = Domain_Katsuo.RockAura:Clone()

					clone5.Color = v236.Instance.Color
					clone5.Material = v236.Material
					clone5.Size = clone5.Size * (1.15 + math.random() * 0.85)
					clone5.CFrame = CFrame.new(v236.Position)
					clone5.Parent = Model

					local clone5Color = clone5.Color
					local clone5Material = clone5.Material
					local clone5Size = clone5.Size
					local clone5CFrame = clone5.CFrame

					clone5.Size = Vector3.new(0, 0, 0)
					VisualHelper:Tween(clone5, TweenInfo.new(0.15, Enum.EasingStyle.Back), {
						Size = clone5Size * Vector3.new(1.7000000476837158, 0.30000001192092896, 1.7000000476837158),
						CFrame = clone5.CFrame * CFrame.new(0, clone5Size.Y * 0.3 / 2, 0)
					})
					task.wait(0.1)
					VisualHelper:Tween(clone5, TweenInfo.new(0.25, Enum.EasingStyle.Back), {
						Size = clone5Size,
						CFrame = clone5CFrame * CFrame.new(0, clone5Size.Y / 2, 0)
					})
					task.wait(0.225)

					local v242 = Player
					local color3 = Color3.fromRGB(103, 144, 255)
					local v244 = if typeof(v242) == "Instance" and (not not v242:IsA("Player") and v242.Parent) then Util.WrapColor3Constructor(color3, v242, "ControlFruitVFXColor") else color3
					local Neon = Enum.Material.Neon

					clone5.Color = v244
					clone5.Material = Neon
					VisualHelper:Tween(clone5, TweenInfo.new(0.075, Enum.EasingStyle.Sine), {
						Size = clone5Size * Vector3.new(1, 1, 1) * 1.55,
						CFrame = v235 * CFrame.new(0, clone5Size.Y * 1.55 / 2, 0)
					})
					task.wait(0.075)
					clone5.Color = clone5Color
					clone5.Material = clone5Material
					VisualHelper:Tween(clone5, TweenInfo.new(0.18, Enum.EasingStyle.Sine), {
						Size = clone5Size
					})
					VisualHelper:Tween(clone5, TweenInfo.new(0.35, Enum.EasingStyle.Sine), {
						CFrame = v235 * CFrame.new(0, math.random(2, 7), 0) * CFrame.Angles(math.random() * 3.141592653589793 / 2.5, math.random() * 3.141592653589793 / 2.5, math.random() * 3.141592653589793 / 2.5)
					})
					task.wait(0.35)
					VisualHelper:Tween(clone5, TweenInfo.new(2, Enum.EasingStyle.Sine), {
						Position = clone5.Position + Vector3.new(math.random(-1, 1), math.random(3, 5), math.random(-1, 1))
					})
					task.wait(2)
					clone5.CanCollide = true
					clone5.Anchored = false
					task.wait(0.3)
					VisualHelper:SetEnableAll(clone5, false)
					VisualHelper:Tween(clone5, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {
						Size = Vector3.new(0, 0, 0)
					})
					Util.Debris:AddItem(clone5, 0.5)

					return
				end
			elseif u68 then
				u68 = false
				VisualHelper:SetEnableAll(Ground, u68)
			end
		end)

		return
	end

	if p4.Dagger then
		local Dagger2 = p4.Dagger

		if Dagger2 == "Equip" then
			if p4.Override then
				if p4.CurrentMode == "Fist" then
					local Model = Instance.new("Model")

					Model.Name = Character.Name .. "ControlFists"
					Model.Parent = workspace._WorldOrigin

					local function HandleWinds(p5, b2: boolean?) -- line: 383
						-- upvalues: Z_Katsuo (copy), Util (copy), Player (copy), VisualHelper (copy)
						local clone = Z_Katsuo.Vault.DaggerWinds:Clone()

						clone.Orientation = Vector3.new(0, 0, not b2 and 180 or 0)
						Util.SetParentOverrideWithColor(clone, b2 and p5.RootPart or p5, Player, "ControlFruitVFXColor")
						VisualHelper:Tween(clone, TweenInfo.new(0.8, Enum.EasingStyle.Linear), {
							Orientation = clone.Orientation + Vector3.new(0, 1750, 0)
						})

						for _, descendant in clone:GetDescendants() do
							if descendant:IsA("Beam") then
								descendant.Enabled = true
								VisualHelper:Tween(descendant, TweenInfo.new(0.55 + math.random(3) * 0.055, Enum.EasingStyle.Sine), {
									Width0 = 0,
									Width1 = 0
								})
							end
						end

						Util.Debris:AddItem(clone, 1.5)
					end

					for v77, v78 in {
						Left = CFrame.Angles(3.141592653589793, 0, 0),
						Right = CFrame.Angles(0, 0, -3.141592653589793)
					} do
						local clone = Z_Katsuo.HandsHandle:Clone()

						clone.Name = `{ v77 }HandleMode`
						clone.Weld.C0 = v78
						clone.Weld.Part1 = Character[`{ v77 }Hand`]
						Util.SetParentOverrideWithColor(clone, Model, Player, "ControlFruitVFXColor")
						HandleWinds(clone)
						VisualHelper:EmitAll(clone)

						for _, child in Z_Katsuo.ArmGrids:GetChildren() do
							local clone6 = child:Clone()

							clone6.Name = "ArmGrid"
							Util.SetParentOverrideWithColor(clone6, Model, Player, "ControlFruitVFXColor")

							local Weld = Instance.new("Weld")

							Weld.Part0 = clone6
							Weld.Part1 = Character[`{ v77 }{ child.Name }`]
							Weld.Parent = clone6
						end
					end

					return
				end

				if workspace._WorldOrigin:FindFirstChild("ControlDaggers" .. Character.Name) then
					return
				end
			elseif not p4.FromRoom and p4.CurrentMode and p4.CurrentMode == "Dagger" then
				local v84 = Util.Anims:Get(Character, "CRFistToDagger")

				v84.Priority = Enum.AnimationPriority.Action4
				v84.Looped = false
				v84:Play()
				Util.Sound:Play("C_Daggers_Appear_Transformed_01", Root)
				task.wait(0.45)

				local v85 = workspace._WorldOrigin:FindFirstChild(Character.Name .. "ControlFists")

				if v85 then
					v85:Destroy()
				end
			else
				task.wait(0.1)
			end

			local v86 = p4.Directions or {
				"Left",
				"Right"
			}
			local Model = Instance.new("Model")

			Model.Name = "ControlDaggers" .. Character.Name
			Model.Parent = workspace._WorldOrigin

			local UpperTorso = Root.Parent:FindFirstChild("UpperTorso")

			if UpperTorso then
				UpperTorso:GetPropertyChangedSignal("Transparency"):Connect(function() -- line: 454
					-- upvalues: Model (copy), UpperTorso (copy)
					for _, child in Model:GetChildren() do
						for _, child3 in child:GetChildren() do
							if child3:IsA("BasePart") and child3.Name ~= "RootPart" then
								child3.Transparency = not (UpperTorso.Transparency >= 1) and 0 or 1
							end
						end
					end
				end)
			end

			for _, v90 in v86 do
				local v91 = Character[`{ v90 }Hand`]
				local v92 = Domain_Katsuo:FindFirstChild(`Dagger{ v90 }`)
				local clone = Dagger:Clone()

				clone.Name = `{ v90 }Dagger`
				clone.RootPart.Motor6D:Destroy()

				local Humanoid = Instance.new("Humanoid")

				Humanoid.BreakJointsOnDeath = false
				Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
				Humanoid.EvaluateStateMachine = false
				Humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
				Humanoid.RequiresNeck = false
				Humanoid.Parent = clone

				local clone7 = v92.RootPart.RootPart:Clone()

				clone7.Part1 = clone.RootPart
				clone7.Part0 = v91
				clone7.Parent = v91
				clone.Destroying:Connect(function() -- line: 492
					-- upvalues: clone7 (copy)
					clone7:Destroy()
				end)
				Util.SetParentOverrideWithColor(clone, Model, Player, "ControlFruitVFXColor")

				local v96 = Util.Anims:Get(clone, "CRDaggerAnim")

				v96.Priority = Enum.AnimationPriority.Idle
				v96.Looped = true
				v96:Play()

				local Highlight = Instance.new("Highlight")

				Highlight.Adornee = clone
				Highlight.FillTransparency = 0
				Highlight.OutlineTransparency = 1
				Highlight.DepthMode = Enum.HighlightDepthMode.Occluded

				local color3 = Color3.fromRGB(14, 27, 47)

				Highlight.FillColor = if typeof(Player) == "Instance" and (not not Player:IsA("Player") and Player.Parent) then Util.WrapColor3Constructor(color3, Player, "ControlFruitVFXColor") else color3
				Highlight.Parent = clone
				VisualHelper:Tween(Highlight, TweenInfo.new(0.7, Enum.EasingStyle.Sine), {
					FillTransparency = 1
				})
				task.spawn(function() -- line: 513
					-- upvalues: Domain_Katsuo (copy), Util (copy), clone (copy), Player (copy), VisualHelper (copy), Highlight (copy)
					local clone8 = Domain_Katsuo.Vault.DaggerWinds:Clone()

					Util.SetParentOverrideWithColor(clone8, clone.RootPart, Player, "ControlFruitVFXColor")
					VisualHelper:Tween(clone8, TweenInfo.new(0.8, Enum.EasingStyle.Linear), {
						Orientation = clone8.Orientation + Vector3.new(0, 1750, 0)
					})

					for _, descendant in clone8:GetDescendants() do
						if descendant:IsA("Beam") then
							descendant.Enabled = true
							VisualHelper:Tween(descendant, TweenInfo.new(0.55 + math.random(3) * 0.055, Enum.EasingStyle.Sine), {
								Width0 = 0,
								Width1 = 0
							})
						end
					end

					Util.Debris:AddItem(clone8, 1.5)
					VisualHelper:EmitAll(clone.RootPart)
					task.wait(0.7)
					Highlight:Destroy()
				end)
			end

			return
		end

		if Dagger2 == "Unequip" then
			local v99 = workspace._WorldOrigin:FindFirstChild("ControlDaggers" .. Character.Name)

			if p4.Override and not p4.CurrentMode then
				local v100 = workspace._WorldOrigin:FindFirstChild(Character.Name .. "ControlFists")

				if v100 then
					v100:Destroy()
				end
			end

			if v99 then
				v99.Name = "Destroying"

				local v101 = false

				if p4.Override and p4.CurrentMode == "Fist" then
					v101 = true
				end

				if p4.CurrentMode and p4.CurrentMode == "Fist" and not p4.Override then
					local v102 = Util.Anims:Get(Character, "CRDaggerToFist")

					v102.Priority = Enum.AnimationPriority.Action4
					v102.Looped = false
					v102:Play()
					v101 = true
					Util.Sound:Play("C_Daggers_Disappear_Transformed_01", Root)
					task.wait(0.4666666666666667)
					Util.Sound:Play("C_HandsMode_Switch_01", Root)
				else
					local v103 = workspace._WorldOrigin:FindFirstChild(Character.Name .. "ControlFists")

					if v103 then
						v103:Destroy()
					end
				end

				for i = 1, 2 do
					local v105 = v99:FindFirstChild(`{ i ~= 1 and "Right" or "Left" }Dagger`)

					if v105 then
						for _, child in pairs(v105:GetChildren()) do
							if child:IsA("BasePart") or child:IsA("MeshPart") then
								child.Transparency = 1
							end
						end

						task.spawn(function() -- line: 587
							-- upvalues: Domain_Katsuo (copy), Util (copy), v105 (copy), Player (copy), VisualHelper (copy)
							local clone = Domain_Katsuo.Vault.DaggerWinds:Clone()

							Util.SetParentOverrideWithColor(clone, v105.RootPart, Player, "ControlFruitVFXColor")

							for _, descendant in clone:GetDescendants() do
								if descendant:IsA("Beam") then
									descendant.Enabled = true
									VisualHelper:Tween(descendant, TweenInfo.new(0.55 + math.random(3) * 0.055, Enum.EasingStyle.Sine), {
										Width0 = 0,
										Width1 = 0
									})
								end
							end

							Util.Debris:AddItem(clone, 1.5)
							VisualHelper:EmitAll(v105.RootPart)
						end)
					end
				end

				if v101 then
					local Model = Instance.new("Model")

					Model.Name = Character.Name .. "ControlFists"
					Model.Parent = workspace._WorldOrigin

					local function HandleWinds(p6, b3: boolean?) -- line: 613
						-- upvalues: Z_Katsuo (copy), Util (copy), Player (copy), VisualHelper (copy)
						local clone = Z_Katsuo.Vault.DaggerWinds:Clone()

						clone.Orientation = Vector3.new(0, 0, not b3 and 180 or 0)
						Util.SetParentOverrideWithColor(clone, b3 and p6.RootPart or p6, Player, "ControlFruitVFXColor")
						VisualHelper:Tween(clone, TweenInfo.new(0.8, Enum.EasingStyle.Linear), {
							Orientation = clone.Orientation + Vector3.new(0, 1750, 0)
						})

						for _, descendant in clone:GetDescendants() do
							if descendant:IsA("Beam") then
								descendant.Enabled = true
								VisualHelper:Tween(descendant, TweenInfo.new(0.55 + math.random(3) * 0.055, Enum.EasingStyle.Sine), {
									Width0 = 0,
									Width1 = 0
								})
							end
						end

						Util.Debris:AddItem(clone, 1.5)
					end

					for v110, v111 in {
						Left = CFrame.Angles(3.141592653589793, 0, 0),
						Right = CFrame.Angles(0, 0, -3.141592653589793)
					} do
						local clone = Z_Katsuo.HandsHandle:Clone()

						clone.Name = `{ v110 }HandleMode`
						clone.Weld.C0 = v111
						clone.Weld.Part1 = Character[`{ v110 }Hand`]
						Util.SetParentOverrideWithColor(clone, Model, Player, "ControlFruitVFXColor")
						HandleWinds(clone)
						VisualHelper:EmitAll(clone)

						for _, child in Z_Katsuo.ArmGrids:GetChildren() do
							local clone9 = child:Clone()

							clone9.Name = "ArmGrid"
							Util.SetParentOverrideWithColor(clone9, Model, Player, "ControlFruitVFXColor")

							local Weld = Instance.new("Weld")

							Weld.Part0 = clone9
							Weld.Part1 = Character[`{ v110 }{ child.Name }`]
							Weld.Parent = clone9
						end
					end
				end

				task.wait(2)
				v99:Destroy()
			end
		end

		return
	end

	local Duration = p4.Duration

	if not Duration then
		return
	end

	local random = Random.new()
	local timestamp = tick()
	local Model = Instance.new("Model", workspace._WorldOrigin)

	Util.Debris:AddItem(Model, 15)

	local Model2 = Instance.new("Model", Model)

	Util.Sound:Play("CTRLFRT_Z_Activate_CloseToPlayer_01", Root.Position)

	local v122 = Util.Anims:Get(Character, "CRRoomOpeningStart")

	v122.Looped = false
	v122.Priority = Enum.AnimationPriority.Action3
	v122:Play()

	local v123 = Util.Anims:Get(Character, "CRRoomOpeningLoop")

	v123.Looped = true
	v123.Priority = Enum.AnimationPriority.Action
	v123:Play()

	local clone = Domain_Katsuo.EndFloorStarCollide:Clone()

	clone.CFrame = Root.CFrame * CFrame.new(0, 100000, 0)
	Util.SetParentOverrideWithColor(clone, Model2, p4.Player, "ControlFruitVFXColor")

	local clone10 = Domain_Katsuo.DarkNeonRotation:Clone()

	clone10:ScaleTo(clone10:GetScale() + 0.8)
	clone10.Main.Weld.Part0 = Root
	Util.SetParentOverrideWithColor(clone10, Model2, p4.Player, "ControlFruitVFXColor")

	local clone11 = Domain_Katsuo.DoubleNeonEye:Clone()

	clone11.Weld.Part0 = Character.Head
	clone11.Name = VisualHelper:BuildUniqueName(Character, "Double-Neon-Eye")
	Util.SetParentOverrideWithColor(clone11, Model2, p4.Player, "ControlFruitVFXColor")

	local clone12 = Domain_Katsuo.ShaderScreen:Clone()

	clone12.Image.ImageTransparency = 1
	clone12.Name = VisualHelper:BuildUniqueName(Character, "Shader-Screen")
	Util.SetParentOverrideWithColor(clone12, p4.Player == game.Players.LocalPlayer and p4.Player:FindFirstChild("PlayerGui") or Model, p4.Player, "ControlFruitVFXColor")
	VisualHelper:Tween(clone12.Image, TweenInfo.new(0.6, Enum.EasingStyle.Sine), {
		ImageTransparency = 0.8
	})
	VisualHelper:SetEnableAll(clone11, true)

	local Main = clone.BeamAura.Beams.Main

	Main.Enabled = true

	local thread = task.spawn(function() -- line: 725
		-- upvalues: Textures (copy), Main (copy)
		while true do
			for _, v267 in Textures.Aura do
				Main.Texture = v267
				task.wait(0.016666666666666666)
			end
		end
	end)
	local clone13 = Domain_Katsuo.StarCollide:Clone()

	clone13.Weld.Part0 = Root
	Util.SetParentOverrideWithColor(clone13, Model2, p4.Player, "ControlFruitVFXColor")

	local clone14 = Domain_Katsuo.FloorStarCollide:Clone()

	clone14.CFrame = Root.CFrame * CFrame.new(0, -2.8, 0)
	Util.SetParentOverrideWithColor(clone14, Model2, p4.Player, "ControlFruitVFXColor")

	local v132 = MathHelper:GroundRayCast(Character)

	if not v132 then
		clone14.Smokes:Destroy()
		clone14.SmokesToggle:Destroy()
		clone.Smokes:Destroy()
	end

	UIPromptAnimation(Player)
	VisualHelper:EmitAll(clone13)
	Util.Debris:AddItem(clone13, 2)
	VisualHelper:EmitAll(clone14)
	VisualHelper:SetEnableAll(clone14.Init.Toggle, true)
	VisualHelper:SetEnableAll(clone13, true, true)

	if v132 then
		VisualHelper:SetEnableAll(clone14.SmokesToggle, true)
	end

	local CircleBeam = clone14.CircleBeam

	VisualHelper:Tween(CircleBeam, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
		Position = CircleBeam.Position + Vector3.new(0, 5, 0)
	})

	for _, child in CircleBeam.Beams:GetChildren() do
		child.Enabled = true
		VisualHelper:Tween(child, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
			Brightness = 0,
			Width0 = 0,
			Width1 = 0
		})
	end

	local Trails = clone14.Trails

	VisualHelper:Tween(Trails, TweenInfo.new(1.4, Enum.EasingStyle.Sine), {
		Orientation = Trails.Orientation + Vector3.new(0, 550, 0)
	})

	for _, child in Trails:GetChildren() do
		VisualHelper:Tween(child, TweenInfo.new(1.4, Enum.EasingStyle.Sine), {
			Position = child.Position * 0.3
		})
	end

	VisualHelper:SetEnableAll(clone14.Storm, true)
	VisualHelper:EmitAll(clone14.Storm)

	for _, child in clone14.Storm:GetChildren() do
		VisualHelper:Tween(child, TweenInfo.new(random:NextNumber(2, 3.5), Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {
			Orientation = child.Orientation + Vector3.new(0, 360 * (child.Name ~= "Mid" and 1 or -1))
		})
	end

	local Circle = clone14.Circle

	Circle.Main.ManualWeld:Destroy()
	Circle.Parent = workspace._WorldOrigin
	Util.Debris:AddItem(Circle, 5)
	VisualHelper:SetEnableAll(Circle.Main.Init.Toggle, true)
	VisualHelper:TweenScale(Circle, TweenInfo.new(1.5, Enum.EasingStyle.Sine), Circle:GetScale() + 0.1)

	for _, child in Circle.Main.CircleWinds.Beams:GetChildren() do
		child.Enabled = true

		local childBrightness = child.Brightness

		child.Brightness = 0
		VisualHelper:Tween(child, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
			Brightness = childBrightness
		})
		task.delay(0.2, function() -- line: 817
			-- upvalues: VisualHelper (copy), child (copy)
			VisualHelper:Tween(child, TweenInfo.new(0.8, Enum.EasingStyle.Sine), {
				Brightness = 0
			})
		end)

		if child.Name ~= "Beam0" then
			VisualHelper:Tween(child, TweenInfo.new(1, Enum.EasingStyle.Sine), {
				Width0 = child.Width0 / 2,
				Width1 = child.Width0 / 2
			})
		end
	end

	local SuperCircle = clone14.SuperCircle

	SuperCircle.Main.ManualWeld:Destroy()
	SuperCircle.Parent = workspace._WorldOrigin
	Util.Debris:AddItem(SuperCircle, 5)
	VisualHelper:TweenScale(SuperCircle, TweenInfo.new(0.3, Enum.EasingStyle.Sine), SuperCircle:GetScale() + 1.2)

	for _, child in SuperCircle.Main.CircleWinds.Beams:GetChildren() do
		child.Enabled = true
		VisualHelper:Tween(child, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {
			Width0 = 0,
			Width1 = 0
		})
	end

	Util.Debris:AddItem(clone14, 4)

	local StormBeam = clone14.StormBeam

	StormBeam:PivotTo(clone14.CFrame)

	local Scale = StormBeam:GetScale()

	StormBeam:ScaleTo(Scale - 0.15)
	VisualHelper:TweenScale(StormBeam, TweenInfo.new(0.65, Enum.EasingStyle.Sine), Scale + 0.05)

	for _, child in StormBeam.Main:GetChildren() do
		local Beam = child.Beam

		Beam.Brightness = Beam.Brightness * 2.75
		Beam.TextureSpeed = Beam.TextureSpeed * -1
		Beam.Enabled = true

		local v153 = (child:GetAttribute("Time") or 0.3) + 0.4
		local v154 = Vector3.new(0, 1, 0) * ((child:GetAttribute("Orientation") or 0) * -1.65)

		VisualHelper:Tween(child, TweenInfo.new(v153 + 0.1, Enum.EasingStyle.Sine), {
			Orientation = child.Orientation + v154
		})
		VisualHelper:Tween(Beam, TweenInfo.new(v153, Enum.EasingStyle.Sine), {
			Brightness = 0
		})
	end

	task.wait(0.3)

	local clone15 = Domain_Katsuo.EndStarCollide:Clone()

	clone15.Weld.Part0 = Root
	Util.SetParentOverrideWithColor(clone15, Model2, p4.Player, "ControlFruitVFXColor")
	VisualHelper:SetEnableAll(clone15, true, true)
	VisualHelper:SetEnableAll(clone15.Init.Sinal, true)
	VisualHelper:EmitAll(clone15.Init)

	local clone16 = Domain_Katsuo.CameraEffects:Clone()

	clone16.Name = VisualHelper:BuildUniqueName(Character, "Camera-Effects")
	Util.SetParentOverrideWithColor(clone16, CurrentCamera, p4.Player, "ControlFruitVFXColor")

	if p4.Player == game.Players.LocalPlayer then
		VisualHelper:SetEnableAll(clone16, true)
		VisualHelper:EmitAll(clone16)
	else
		VisualHelper:SetEnableAll(clone16, false)
	end

	local Engaged = clone16.UI.Engaged

	Engaged.Particle.Enabled = false

	local Loading = clone16.UI.Loading

	task.delay(0.85, function() -- line: 899
		-- upvalues: p4 (copy), Engaged (copy), Loading (copy)
		if p4.Player == game.Players.LocalPlayer then
			Engaged.Particle:Emit(1)
			Engaged.Particle.Enabled = true
			Loading:Destroy()
		end
	end)

	local clone17 = Domain_Katsuo.BoltExplosion:Clone()

	Util.SetParentOverrideWithColor(clone17, Model, p4.Player, "ControlFruitVFXColor")

	local u160 = nil
	local n3 = 0
	local n4 = 0
	local children = Domain_Katsuo.Rocks:GetChildren()
	local connection = RunService.RenderStepped:Connect(function(dt) -- line: 917
		-- upvalues: n3 (ref), clone16 (copy), CurrentCamera (copy), clone (copy), u160 (ref), Root (copy), MathHelper (copy), Character (copy), children (copy), Model (copy), v20 (copy), Domain_Katsuo (copy), Util (copy), p4 (copy), VisualHelper (copy), Rocks (copy), n4 (ref), clone17 (copy)
		n3 += dt
		clone16.CFrame = CurrentCamera.CFrame * CFrame.new(0, 0, -2.25) * CFrame.Angles(0, 1.5707963267948966, 0)

		local BigTrailBolt = clone.BigTrailBolt

		BigTrailBolt.Orientation = BigTrailBolt.Orientation + Vector3.new(0, 650 * dt)

		if u160 or n3 < 0.1 then
			return
		end

		n3 = 0

		local v270 = CFrame.new(Root.Position) * CFrame.Angles(0, math.rad((math.random(360))), 0) * CFrame.new(0, 0, -math.random(15, 22))
		local v271 = MathHelper:RayCast(v270.Position, v270.UpVector * -10, {
			Character,
			workspace._WorldOrigin
		})

		if v271 then
			local clone18 = children[math.random(#children)]:Clone()

			clone18.Position = v271.Position
			clone18.Orientation = Vector3.new(math.random(360), math.random(360), math.random(360))
			clone18.Color = v271.Instance.Color
			clone18.Size = clone18.Size * math.random(1, 2)
			clone18.Material = v271.Instance.Material
			clone18.Parent = Model
			v20:ApplyCollision(clone18, nil, true)

			local clone19 = Domain_Katsuo.Vault.RockBack:Clone()

			Util.SetParentOverrideWithColor(clone19, clone18, p4.Player, "ControlFruitVFXColor")
			VisualHelper:EmitAll(clone19)

			local clone20 = Domain_Katsuo.RockSmoke:Clone()

			clone20.CFrame = CFrame.lookAt(v271.Position, v271.Normal + v271.Position) * CFrame.Angles(-1.5707963267948966, 0, 0)
			clone20.Parent = Model

			for _, child in clone20.Main:GetChildren() do
				VisualHelper:Emit(child, ColorSequence.new(clone18.Color))
			end

			Util.Debris:AddItem(clone20, 1.5)

			local v277 = 0.8 + math.random(5) * 0.1

			VisualHelper:Tween(clone18, TweenInfo.new(v277), {
				Transparency = 0.5,
				Size = Vector3.new(0, 0, 0),
				Position = clone18.Position + Vector3.new(0, math.random(5, 18)),
				Orientation = clone18.Orientation + Vector3.new(math.random(-180, 180), math.random(-180, 180), math.random(-180, 180))
			})
			Util.Debris:AddItem(clone18, v277)
			Rocks:AirRocks(clone18.CFrame, Vector3.new(2, 0.20000000298023224, 2), false, 60, 0.2, 0.3, 2, clone18.Color, clone18.Material)
			Rocks:AirRocks(clone18.CFrame, Vector3.new(1, 1, 1) * math.random(2), false, math.random(35, 75), 0.1, 0.2, 15, clone18.Color, clone18.Material)
		end

		n4 += 55

		local v278 = CFrame.new(Root.Position) * CFrame.Angles(0, math.rad(n4 + math.random(-90, 90)), 0) * CFrame.new(0, 0, -math.random(20, 45))
		local v279 = MathHelper:RayCast(v278.Position, v278.UpVector * -10, {
			Character,
			workspace._WorldOrigin
		})

		if not v279 then
			return
		end

		clone17.CFrame = CFrame.new(v279.Position + Vector3.new(0, 0.05000000074505806, 0))
		VisualHelper:EmitAll(clone17)
	end)

	task.wait(0.1)

	if v132 then
		VisualHelper:SetEnableAll(clone14.SmokesToggle, false)
	end

	VisualHelper:SetEnableAll(clone13, false, true)
	VisualHelper:SetEnableAll(clone14.Storm, false)
	VisualHelper:SetEnableAll(Circle.Main.Init.Toggle, false)
	VisualHelper:SetEnableAll(clone14.Init.Toggle, false)
	clone13.Init.Sinal:Destroy()

	local clone21 = Domain_Katsuo.BallNeon:Clone()

	clone21.CFrame = Root.CFrame
	clone21.Transparency = 0.9

	local Player2 = p4.Player
	local color3 = Color3.fromRGB(35, 94, 255)

	clone21.Color = if typeof(Player2) == "Instance" and (not not Player2:IsA("Player") and Player2.Parent) then Util.WrapColor3Constructor(color3, Player2, "ControlFruitVFXColor") else color3
	clone21.Size = Vector3.new(1.5, 1.5, 1.5)
	clone21.Parent = Model
	VisualHelper:Tween(clone21, TweenInfo.new(0.18, Enum.EasingStyle.Sine), {
		Size = Vector3.new(12, 12, 12),
		Transparency = 1
	})
	Util.Debris:AddItem(clone21, 0.18)

	local clone22 = Domain_Katsuo.FloorSpawn:Clone()

	clone22.CFrame = Root.CFrame * CFrame.new(0, -2.8, 0)
	Util.SetParentOverrideWithColor(clone22, Model, p4.Player, "ControlFruitVFXColor")

	if not MathHelper:GroundRayCast(Character) then
		clone22.SmokeRotation:Destroy()
	end

	Util.Debris:AddItem(clone22, 2.15)
	VisualHelper:Tween(clone22.CircleWinds, TweenInfo.new(0.25, Enum.EasingStyle.Sine), {
		Orientation = clone22.CircleWinds.Orientation + Vector3.new(0, 180, 0)
	})
	VisualHelper:EmitAll(clone22)
	clone22.PointLight.Enabled = true
	VisualHelper:Tween(clone22.PointLight, TweenInfo.new(0.25, Enum.EasingStyle.Sine), {
		Brightness = 0
	})

	for _, child in clone22.CircleWinds:GetChildren() do
		local Beam = child.Beam

		Beam.Enabled = true
		VisualHelper:Tween(Beam, TweenInfo.new(0.25, Enum.EasingStyle.Sine), {
			Width0 = 0,
			Width1 = 0
		})
	end

	Util.Debris:AddItem(clone10, 2)
	clone10.Main.Layers.Orientation = Vector3.new(0, 1, 0) * random:NextNumber(-360, 360)

	for i, child in clone10.Main.Layers:GetChildren() do
		local Beam = child.Beam

		Beam.Enabled = true

		local v175 = child.Name == "NeonLayer"
		local v176 = v175 and random:NextNumber(0.4, 0.6) or random:NextNumber(0.18, 0.3)

		VisualHelper:Tween(child, TweenInfo.new(v176, Enum.EasingStyle.Linear), {
			Orientation = child.Orientation + Vector3.new(0, 700 * (i % 2 ~= 0 and 1 or -1))
		})

		if v175 then
			VisualHelper:Tween(Beam, TweenInfo.new(v176, Enum.EasingStyle.Sine), {
				Brightness = 0
			})
		else
			VisualHelper:Tween(Beam, TweenInfo.new(v176, Enum.EasingStyle.Sine), {
				Width0 = 0,
				Width1 = 0
			})
		end
	end

	clone.CFrame = Root.CFrame * CFrame.new(0, -2.8, 0)
	VisualHelper:EmitAll(clone)
	VisualHelper:SetEnableAll(clone.Init.Toggle, true)
	VisualHelper:Tween(clone.Ball.Decal, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {
		Transparency = 1
	})
	VisualHelper:Tween(clone.Ball.Mesh, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {
		Scale = clone.Ball.Mesh.Scale * 1.3
	})
	clone.StormBall.CFrame = Root.CFrame * CFrame.new(0, 5, 0)
	VisualHelper:Tween(clone.StormBall, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {
		CFrame = clone.StormBall.CFrame * CFrame.Angles(0, 2.9670597283903604, 0)
	})
	VisualHelper:Tween(clone.StormBall.Decal, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {
		Transparency = 1
	})
	VisualHelper:Tween(clone.StormBall.Mesh, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {
		Scale = clone.StormBall.Mesh.Scale * 1.3
	})

	local CircleBeam2 = clone.CircleBeam

	VisualHelper:Tween(CircleBeam2, TweenInfo.new(0.35, Enum.EasingStyle.Sine), {
		Position = CircleBeam2.Position + Vector3.new(0, 5, 0)
	})

	for _, child in CircleBeam2.Beams:GetChildren() do
		child.Enabled = true
		VisualHelper:Tween(child, TweenInfo.new(0.35, Enum.EasingStyle.Sine), {
			Brightness = 0,
			Width0 = 0,
			Width1 = 0
		})
	end

	for _, child in clone.Beams:GetChildren() do
		local Beam = child.Beam

		Beam.Enabled = true

		local v183 = Beam.Brightness * 1.15

		Beam.Brightness = 0
		VisualHelper:Tween(Beam, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {
			Brightness = v183
		})
		VisualHelper:Tween(child, TweenInfo.new(random:NextNumber(0.2, 0.4), Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {
			Orientation = child.Orientation + Vector3.new(0, 360 * math.sign(Beam.TextureSpeed))
		})
	end

	local CircleBeam2_2 = clone.CircleBeam2

	VisualHelper:Tween(CircleBeam2_2, TweenInfo.new(0.12, Enum.EasingStyle.Sine), {
		Position = CircleBeam2_2.Position + Vector3.new(0, 17, 0)
	})

	for _, child in CircleBeam2_2.Beams:GetChildren() do
		child.Enabled = true
		VisualHelper:Tween(child, TweenInfo.new(0.12, Enum.EasingStyle.Sine), {
			Brightness = 0,
			Width0 = 0,
			Width1 = 0
		})
	end

	local Trails2 = clone.Trails

	VisualHelper:Tween(Trails2, TweenInfo.new(1.4, Enum.EasingStyle.Sine), {
		Orientation = Trails2.Orientation + Vector3.new(0, 550, 0)
	})

	for _, child in Trails2:GetChildren() do
		VisualHelper:Tween(child, TweenInfo.new(1.4, Enum.EasingStyle.Sine), {
			Position = child.Position * 0.45
		})
	end

	local thread2 = task.spawn(function() -- line: 1150
		-- upvalues: clone (copy), VisualHelper (copy), Util (copy)
		while true do
			for i = -1, 1, 2 do
				local clone23 = clone.TrailBoltTemplate:Clone()

				clone23.Name = "Ignore"
				clone23.Orientation = Vector3.new(0, 360, 0) * -i
				clone23.Parent = clone

				local Point = clone23.Point

				Point.Trail.Enabled = true
				VisualHelper:Tween(Point, TweenInfo.new(0.25, Enum.EasingStyle.Sine), {
					Position = Point.Position * 1.3
				})
				VisualHelper:Tween(clone23, TweenInfo.new(0.25, Enum.EasingStyle.Sine), {
					Orientation = clone23.Orientation + Vector3.new(0, i * 500),
					Position = clone23.Position + Vector3.new(0, math.random(5, 15))
				})
				Util.Debris:AddItem(clone23, 1)
				task.wait(0.15)
			end

			local clone24 = clone.TrailBoltTemplate:Clone()

			clone24.Name = "Ignore"

			local Point = clone24.Point
			local Trail = Point.Trail

			Point.Position = Point.Position * 1.5
			Point.Point1.Position = Vector3.new(0, 5, 0)
			Trail.Lifetime = Trail.Lifetime * 0.3
			Trail.Brightness = Trail.Brightness * 0.5
			Trail.Enabled = true
			clone24.Parent = clone
			VisualHelper:Tween(Point, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
				Position = Point.Position * 0.5
			})
			VisualHelper:Tween(clone24, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
				Orientation = clone24.Orientation + Vector3.new(0, 1200, 0),
				Position = clone24.Position + Vector3.new(0, math.random(15, 20))
			})
			Util.Debris:AddItem(clone24, 1)
		end
	end)

	task.spawn(function() -- line: 1193
		-- upvalues: random (copy), clone15 (copy), Domain_Katsuo (copy), Util (copy), p4 (copy), VisualHelper (copy), MathHelper (copy)
		for _ = 1, 10 do
			local v287 = random:NextNumber(0.2, 0.5)
			local WorldCFrame = clone15.Init.WorldCFrame
			local clone25 = Domain_Katsuo.Vault.TrailSpecs:Clone()

			Util.SetParentOverrideWithColor(clone25, workspace.Terrain, p4.Player, "ControlFruitVFXColor")
			clone25.CFrame = WorldCFrame
			Util.Debris:AddItem(clone25, v287 + 0.5)

			local WorldCFramePosition = WorldCFrame.Position
			local v291 = CFrame.new(WorldCFrame.Position) * CFrame.Angles(math.rad((math.random(-90, 90))), 0, (math.rad((math.random(-90, 90))))) * CFrame.new(0, math.random(15, 35), 0).Position
			local Magnitude = (WorldCFramePosition - v291).Magnitude
			local cFrame = CFrame.lookAt(WorldCFramePosition, v291)
			local v294 = cFrame * CFrame.new(math.random(-35, 35), math.random(-35, 35), -Magnitude * 0.25).Position
			local v295 = cFrame * CFrame.new(math.random(-35, 35), math.random(-35, 35), -Magnitude * 0.75).Position

			VisualHelper:TweenNumberValue(1, TweenInfo.new(v287, Enum.EasingStyle.Sine), function(n5: number) -- line: 1214
				-- upvalues: clone25 (copy), MathHelper (copy), WorldCFramePosition (copy), v294 (copy), v295 (copy), v291 (copy)
				clone25.Position = MathHelper:CubicBezier(n5, WorldCFramePosition, v294, v295, v291)
			end)
			task.wait(0.03)
		end
	end)
	VisualHelper:SetEnableAll(clone.Storm, true)
	VisualHelper:EmitAll(clone.Storm)

	for _, child in clone.Storm:GetChildren() do
		VisualHelper:Tween(child, TweenInfo.new(random:NextNumber(2, 3.5), Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {
			Orientation = child.Orientation + Vector3.new(0, 360 * (child.Name ~= "Mid" and 1 or -1))
		})
	end

	local Circle2 = clone.Circle

	Circle2.Main.ManualWeld:Destroy()
	Circle2.Parent = workspace._WorldOrigin
	Util.Debris:AddItem(Circle2, 5)
	VisualHelper:TweenScale(Circle2, TweenInfo.new(1.5, Enum.EasingStyle.Sine), Circle2:GetScale() + 1.1)
	VisualHelper:SetEnableAll(Circle2.Main.Init.Toggle, true)
	task.delay(0.5, function() -- line: 1241
		-- upvalues: VisualHelper (copy), Circle2 (copy)
		VisualHelper:SetEnableAll(Circle2.Main.Init.Toggle, false)
	end)

	for _, child in Circle2.Main.CircleWinds.Beams:GetChildren() do
		child.Enabled = true

		local childBrightness = child.Brightness

		child.Brightness = 0
		VisualHelper:Tween(child, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
			Brightness = childBrightness
		})
		task.delay(0.2, function() -- line: 1253
			-- upvalues: VisualHelper (copy), child (copy)
			VisualHelper:Tween(child, TweenInfo.new(0.6, Enum.EasingStyle.Sine), {
				Brightness = 0
			})
		end)

		if child.Name ~= "Beam0" then
			VisualHelper:Tween(child, TweenInfo.new(0.8, Enum.EasingStyle.Sine), {
				Width0 = child.Width0 / 2,
				Width1 = child.Width0 / 2
			})
		end
	end

	local SuperCircle2 = clone.SuperCircle

	SuperCircle2.Main.ManualWeld:Destroy()
	SuperCircle2.Parent = workspace._WorldOrigin
	Util.Debris:AddItem(SuperCircle2, 5)
	VisualHelper:TweenScale(SuperCircle2, TweenInfo.new(0.3, Enum.EasingStyle.Sine), SuperCircle2:GetScale() + 1.2)

	for _, child in SuperCircle2.Main.CircleWinds.Beams:GetChildren() do
		child.Enabled = true
		VisualHelper:Tween(child, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {
			Width0 = 0,
			Width1 = 0
		})
	end

	local EndCircle = clone.EndCircle

	EndCircle.Main.ManualWeld:Destroy()
	EndCircle.Parent = workspace._WorldOrigin
	Util.Debris:AddItem(EndCircle, 5)
	VisualHelper:TweenScale(EndCircle, TweenInfo.new(0.6, Enum.EasingStyle.Sine), EndCircle:GetScale() + 4.7)

	for _, child in EndCircle.Main.CircleWinds.Beams:GetChildren() do
		child.Enabled = true
		VisualHelper:Tween(child, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 0.3), {
			Width0 = 0,
			Width1 = 0,
			Brightness = 0
		})
	end

	Util.Debris:AddItem(clone, 4)

	local StormBeam2 = clone.StormBeam

	StormBeam2:PivotTo(clone.CFrame)

	local Scale2 = StormBeam2:GetScale()

	StormBeam2:ScaleTo(Scale2 - 0.15)
	VisualHelper:TweenScale(StormBeam2, TweenInfo.new(0.65, Enum.EasingStyle.Sine), Scale2 + 0.05)

	for _, child in StormBeam2.Main:GetChildren() do
		local Beam = child.Beam

		Beam.Brightness = Beam.Brightness * 2.75
		Beam.TextureSpeed = Beam.TextureSpeed * -1
		Beam.Enabled = true

		local v208 = (child:GetAttribute("Time") or 0.3) + 0.4
		local v209 = Vector3.new(0, 1, 0) * ((child:GetAttribute("Orientation") or 0) * -1.65)

		VisualHelper:Tween(child, TweenInfo.new(v208 + 0.1, Enum.EasingStyle.Sine), {
			Orientation = child.Orientation + v209
		})
		VisualHelper:Tween(Beam, TweenInfo.new(v208, Enum.EasingStyle.Sine), {
			Brightness = 0
		})
	end

	Util.Debris:AddItem(clone, 4)

	for _, child in clone.StormBeamPattern.Main:GetChildren() do
		if child:IsA("Attachment") then
			local Beam = child.Beam

			Beam.Brightness = Beam.Brightness * 0.5
			Beam.Enabled = true
			VisualHelper:Tween(child, TweenInfo.new(1, Enum.EasingStyle.Sine), {
				Orientation = child.Orientation + Vector3.new(0, 45, 0)
			})
			VisualHelper:Tween(Beam, TweenInfo.new(1, Enum.EasingStyle.Sine), {
				Brightness = 0,
				Width0 = Beam.Width0 * 0.5,
				Width1 = Beam.Width1 * 0.5
			})
		end
	end

	for _, child in clone.BeamAura.Beams:GetChildren() do
		child.Enabled = true

		local childBrightness = child.Brightness

		child.Brightness = 0
		VisualHelper:Tween(child, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
			Brightness = childBrightness
		})
		VisualHelper:Tween(child, TweenInfo.new(1, Enum.EasingStyle.Sine), {
			Width0 = child.Width0 * 1.15,
			Width1 = child.Width1 * 1.15
		})
	end

	task.spawn(function() -- line: 1345
		-- upvalues: Domain_Katsuo (copy), Util (copy), p4 (copy), Root (copy), MathHelper (copy), Character (copy), Model (copy), VisualHelper (copy), RunService (copy), random (copy)
		local clone26 = Domain_Katsuo.Vault.BoltCollide:Clone()

		Util.SetParentOverrideWithColor(clone26, workspace.Terrain, p4.Player, "ControlFruitVFXColor")

		for i = 1, 25 do
			local v298 = CFrame.new(Root.Position - Vector3.new(0, 2.799999952316284, 0)) * CFrame.Angles(0, math.rad(i * 25 + math.random(-60, 60)), 0)
			local v299 = v298 * CFrame.new(0, 0, 10).Position
			local v300 = v298 * CFrame.new(0, 0, 20 + math.random(2, 10)).Position
			local v301 = MathHelper:RayCast(v300, CFrame.new(v300).UpVector * -5, {
				Character,
				Model
			})

			if v301 then
				local Position = v301.Position
				local Magnitude = (v299 - Position).Magnitude
				local cFrame = CFrame.lookAt(v299, Position)
				local v305 = cFrame * CFrame.new(math.random(-4, 4), math.random(2, 8) + (i % 4 ~= 0 and 0 or 15), -Magnitude * 0.25).Position
				local v306 = cFrame * CFrame.new(math.random(-4, 4), math.random(2, 8), -Magnitude * 0.75).Position
				local clone27 = Domain_Katsuo.Vault.NeonTrail:Clone()

				Util.SetParentOverrideWithColor(clone27, workspace.Terrain, p4.Player, "ControlFruitVFXColor")
				clone27.WorldPosition = v299
				Util.Debris:AddItem(clone27, 3)
				task.spawn(function() -- line: 1379
					-- upvalues: MathHelper (copy), v299 (copy), v305 (copy), v306 (copy), Position (ref), VisualHelper (copy), clone27 (copy), i (copy), RunService (copy), Domain_Katsuo (copy), random (copy), Util (copy), Model (copy), p4 (copy), clone26 (copy), v301 (copy)
					local v317 = math.random(8, 20)

					for j = 1, v317 do
						local v319 = j / v317
						local v320 = MathHelper:CubicBezier(v319, v299, v305, v306, Position)

						VisualHelper:Tween(clone27, TweenInfo.new(0.01, Enum.EasingStyle.Sine), {
							WorldPosition = v320 + v320.Unit * (1 + math.noise(v320.X * 0.1, v320.Z * 0.1, i * 0.1)) + Vector3.new(math.random(-1, 1), math.random(-1, 1), math.random(-1, 1)) * 0.6
						})
						RunService.PreSimulation:Wait()

						if j == v317 and i % 2 == 0 then
							local clone28 = Domain_Katsuo.SingleSpark:Clone()

							clone28.Main.Trail.Lifetime = 0.05
							clone28.CFrame = CFrame.new(v320 + Vector3.new(0, 0.30000001192092896, 0)) * CFrame.Angles(math.rad((random:NextNumber(-45, 45))), 0, (math.rad((random:NextNumber(-45, 45)))))
							Util.SetParentOverrideWithColor(clone28, Model, p4.Player, "ControlFruitVFXColor")
							clone28.AssemblyLinearVelocity = clone28.CFrame.UpVector * -random:NextNumber(25, 45)
							clone28.AssemblyAngularVelocity = Vector3.new(random:NextNumber(-20, 20), random:NextNumber(-20, 20), random:NextNumber(-20, 20))
							VisualHelper:EmitAll(clone28.Main)
							VisualHelper:Tween(clone28.Main.PointLight, TweenInfo.new(2.3, Enum.EasingStyle.Sine), {
								Brightness = 0
							})
							Util.Debris:AddItem(clone28, 3)
							clone26.CFrame = CFrame.lookAt(v301.Position, v301.Position + v301.Normal) * CFrame.new(0, 0, -0.05)
							VisualHelper:EmitAll(clone26)
						end
					end
				end)
				task.wait(0.035)
			end
		end

		Util.Debris:AddItem(clone26, 2)
	end)
	task.spawn(function() -- line: 1421
		-- upvalues: Root (copy), Domain_Katsuo (copy), Util (copy), Model (copy), p4 (copy), VisualHelper (copy)
		local RootCFrame = Root.CFrame

		for _ = 1, 3 do
			local clone29 = Domain_Katsuo.CosmicWaves:Clone()

			clone29:PivotTo(RootCFrame)
			Util.SetParentOverrideWithColor(clone29, Model, p4.Player, "ControlFruitVFXColor")
			VisualHelper:TweenScale(clone29, TweenInfo.new(0.3, Enum.EasingStyle.Sine), clone29:GetScale() + 0.6)
			VisualHelper:Tween(clone29.PrimaryPart, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {
				CFrame = clone29:GetPivot() * CFrame.new(0, 20, 0)
			})

			for _, child in clone29.Main.CircleWinds.Beams:GetChildren() do
				child.Enabled = true
				VisualHelper:Tween(child, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {
					Width0 = 3,
					Width1 = 3,
					Brightness = 0
				})
			end

			Util.Debris:AddItem(clone29, 0.7)

			local clone30 = Domain_Katsuo.CosmicWaves:Clone()

			clone30:PivotTo(RootCFrame * CFrame.new(0, -3, 0))
			clone30:ScaleTo(clone30:GetScale() + 1.45)
			Util.SetParentOverrideWithColor(clone30, Model, p4.Player, "ControlFruitVFXColor")
			VisualHelper:Tween(clone30.PrimaryPart, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {
				CFrame = clone30:GetPivot() * CFrame.new(0, 7, 0)
			})

			for _, child in clone30.Main.CircleWinds.Beams:GetChildren() do
				child.Enabled = true
				child.Width0 = child.Width0 / 2
				child.Width1 = child.Width1 / 2
				VisualHelper:Tween(child, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {
					Width0 = 0,
					Width1 = 0,
					Brightness = 0
				})
			end

			Util.Debris:AddItem(clone30, 0.5)
			task.wait(0.3)
		end
	end)

	while Duration > tick() - timestamp and (not p4.Holding or p4.Holding.Value) do
		task.wait(0.03333333333333333)
	end

	if v123 then
		v123:Stop()
	end

	local v216 = Util.Anims:Get(Character, "CRRoomOpeningEnd")

	v216.Looped = false
	v216.Priority = Enum.AnimationPriority.Action4
	v216:Play()
	Util.Debris:AddItem(clone17, 3)
	VisualHelper:Tween(clone.BigTrailBolt.Point, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {
		Position = Vector3.new(0, 0, 0)
	})
	u160 = true
	VisualHelper:SetEnableAll(clone16.UI, false)
	task.delay(1, function() -- line: 1482
		-- upvalues: thread (copy)
		task.cancel(thread)
	end)

	for _, child in clone.BeamAura.Beams:GetChildren() do
		if child.Name == "Back" then
			VisualHelper:Tween(child, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {
				Width0 = 0,
				Width1 = 0
			})
		else
			VisualHelper:Tween(child, TweenInfo.new(0.25, Enum.EasingStyle.Sine), {
				Brightness = 0
			})
		end
	end

	task.cancel(thread2)

	for _, child in clone.Beams:GetChildren() do
		VisualHelper:Tween(child.Beam, TweenInfo.new(0.35, Enum.EasingStyle.Sine), {
			Brightness = 0
		})
	end

	clone15.Init.Sinal:Destroy()
	VisualHelper:SetEnableAll(clone15, false, true)
	Util.Debris:AddItem(clone15, 3)
	VisualHelper:SetEnableAll(clone.Init.Toggle, false)
	VisualHelper:SetEnableAll(clone.Storm, false)

	local ByUniqueName = VisualHelper:FindByUniqueName(Character, "Shader-Screen", Player:FindFirstChild("PlayerGui"))

	if ByUniqueName then
		ByUniqueName.Name = "Ignore"
		VisualHelper:Tween(ByUniqueName.Image, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {
			ImageTransparency = 1
		})
		Util.Debris:AddItem(ByUniqueName, 0.5)
	end

	local ByUniqueName2 = VisualHelper:FindByUniqueName(Character, "Double-Neon-Eye", Model2)

	if ByUniqueName2 then
		ByUniqueName2.Name = "Ignore"
		VisualHelper:SetEnableAll(ByUniqueName2, false)
		Util.Debris:AddItem(ByUniqueName2, 1)
	end

	for _, child in Domain_Katsuo.CameraComplement:GetChildren() do
		Util.SetParentOverrideWithColor(child:Clone(), clone16, p4.Player, "ControlFruitVFXColor")
	end

	VisualHelper:SetEnableAll(clone16, false)
	task.wait(1)
	connection:Disconnect()
	clone16:Destroy()
end
