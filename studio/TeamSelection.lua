
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local GlobalUtil = require(ReplicatedStorage.GlobalUtil)
local TextUtil = require(ReplicatedStorage.Modules.Util.TextUtil)
local useClock = require(ReplicatedStorage.React.Hooks.useClock)
local useToggledState = require(ReplicatedStorage.React.Hooks.useToggledState)
local useViewportSize = require(ReplicatedStorage.React.Hooks.useViewportSize)
local tweenBinding = require(ReplicatedStorage.React.Util).tweenBinding
local LimbFlicker = require(ReplicatedStorage.Util.LimbFlicker)
local CONSTANTS = require(ReplicatedStorage.React.CONSTANTS)
local v12 = if not GlobalUtil.FFlags.IsUnitTest then require(game.ReplicatedStorage.Notification) else nil
local u13 = false

local function change(teamName: string)
    local player = Players.LocalPlayer
    if not player or u13 then return end
    u13 = true
    local function notify(text)
        if v12 then pcall(function() v12.new(text):Display() end) end
    end
    notify("Joining...")
    local accepted = false
    local deadline = os.clock() + 20
    repeat
        local ok, result = pcall(function()
            return ReplicatedStorage.Remotes.CommF_:InvokeServer("SetTeam2", teamName)
        end)
        if ok and result == 0 then
            accepted = true
            break
        end
        if ok and result ~= nil then break end
        task.wait(1)
    until os.clock() >= deadline or not player.Parent
    if accepted then
        local spawnDeadline = os.clock() + 20
        repeat
            local character = player.Character
            if character and character:IsDescendantOf(workspace:WaitForChild("Characters")) then
                u13 = false
                return
            end
            task.wait()
        until os.clock() >= spawnDeadline
    end
    u13 = false
    notify("<Color=Red>Unable to join yet. Please choose your team again.<Color=/>")
end
local function format(n1: number) -- line: 68
	-- upvalues: TextUtil (copy)
	return TextUtil.commaValue(n1)
end

local createElement = React.createElement

return function(_: {[any]: any}) -- line: 74
	-- upvalues: Players (copy), React (copy), useToggledState (copy), useClock (copy), useViewportSize (copy), tweenBinding (copy), ReplicatedStorage (copy), LimbFlicker (copy), createElement (copy), CONSTANTS (copy), change (copy), TextUtil (copy)
	local LocalPlayer = Players.LocalPlayer
	local v22, v23 = React.useBinding(0)
	local v24, v25 = React.useBinding(0)
	local v26, v27 = React.useBinding(0)
	local v28, v29 = React.useBinding(0)
	local v30 = useToggledState(false)
	local v31 = useToggledState(false)
	local v32 = useToggledState(false)
	local v33 = useToggledState(false)
	local v34 = React.useRef(nil) 
	local v35 = React.useRef(nil)
	local v36 = React.useRef(nil)
	local v37 = React.useRef(nil)
	local v38 = useClock()
	local v39 = useViewportSize()
	local v40 = not (math.min(v39.X, v39.Y) <= 500) and 0.8 or 1

	React.useEffect(function() -- line: 92
		-- upvalues: v30 (copy), tweenBinding (copy), v22 (copy), v23 (copy), v36 (copy)
		local v75 = not v30.on and 0 or 1

		tweenBinding(v22, v23, v75, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

		if v36.current ~= nil then
			v36.current:AdjustWeight(math.max(v75, 0.001), 0.25)
		end
	end, { v30.on })
	React.useEffect(function() -- line: 107
		-- upvalues: v31 (copy), tweenBinding (copy), v24 (copy), v25 (copy)
		local v76 = not v31.on and 0 or 1

		tweenBinding(v24, v25, v76, 0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	end, { v31.on })
	React.useEffect(function() -- line: 119
		-- upvalues: v32 (copy), tweenBinding (copy), v26 (copy), v27 (copy), v37 (copy)
		local v77 = not v32.on and 0 or 1

		tweenBinding(v26, v27, v77, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

		if v37.current ~= nil then
			v37.current:AdjustWeight(math.max(v77, 0.001), 0.25)
		end
	end, { v32.on })
	React.useEffect(function() -- line: 134
		-- upvalues: v33 (copy), tweenBinding (copy), v28 (copy), v29 (copy)
		local v78 = not v33.on and 0 or 1

		tweenBinding(v28, v29, v78, 0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	end, { v33.on })

	local v41, v42 = React.useState({
		Bounty = 0,
		Honor = 0
	})

	React.useEffect(function() -- line: 147
		-- upvalues: LocalPlayer (copy), v42 (copy)
		local connection = nil
		local connection2 = nil
		local n2 = 0
		local n3 = 0

		if LocalPlayer ~= nil then
			n3 = LocalPlayer:GetAttribute("InitBounty") or 0
			n2 = LocalPlayer:GetAttribute("InitHonor") or 0

			local function update() -- line: 155
				-- upvalues: v42 (copy), n3 (ref), n2 (ref)
				v42({
					Bounty = n3,
					Honor = n2
				})
			end

			connection = LocalPlayer:GetAttributeChangedSignal("InitBounty"):Connect(function() -- line: 162
				-- upvalues: n3 (ref), LocalPlayer (copy), v42 (copy), n2 (ref)
				n3 = LocalPlayer:GetAttribute("InitBounty") or 0
				v42({
					Bounty = n3,
					Honor = n2
				})
			end)
			connection2 = LocalPlayer:GetAttributeChangedSignal("InitHonor"):Connect(function() -- line: 167
				-- upvalues: n2 (ref), LocalPlayer (copy), v42 (copy), n3 (ref)
				n2 = LocalPlayer:GetAttribute("InitHonor") or 0
				v42({
					Bounty = n3,
					Honor = n2
				})
			end)
			v42({
				Bounty = n3,
				Honor = n2
			})
		end

		return function() -- line: 175
			-- upvalues: connection (ref), connection2 (ref)
			if connection ~= nil then
				connection:Disconnect()
				connection = nil
			end

			if connection2 ~= nil then
				connection2:Disconnect()
				connection2 = nil
			end
		end
	end, { LocalPlayer })
	React.useEffect(function() -- line: 188
		-- upvalues: v34 (copy), ReplicatedStorage (copy), LimbFlicker (copy), v36 (copy)
		local u84 = false

		task.spawn(function() -- line: 190
			-- upvalues: v34 (copy), ReplicatedStorage (copy), u84 (ref), LimbFlicker (copy), v36 (copy)
			if v34.current then
				local MenuPirate = ReplicatedStorage:WaitForChild("MenuPirate", 20)

				if u84 then
					return
				end

				if MenuPirate then
					local clone = MenuPirate:Clone()

					LimbFlicker.fix(clone)

					local Model = v34.current:FindFirstChildOfClass("Model")

					if Model then
						Model:Destroy()
					end

					task.spawn(function() -- line: 204
						-- upvalues: clone (copy), v36 (copy)
						repeat
							task.wait()
						until clone.Parent and clone:IsDescendantOf(game)

						if clone:FindFirstChild("Animation") then
							return
						end

						local Animation = Instance.new("Animation")

						Animation.AnimationId = "rbxassetid://98267527930887"
						Animation.Parent = clone

						local Animation2 = Instance.new("Animation")

						Animation2.AnimationId = "rbxassetid://88965500360311"
						Animation2.Parent = clone

						local track = clone.Humanoid:LoadAnimation(Animation2)

						track.Looped = true
						v36.current = track
						track:Play(nil, 0.001, nil)
						clone.Humanoid:LoadAnimation(Animation):Play(0, 1, 1)
					end)
					clone.HumanoidRootPart.Anchored = true
					clone:PivotTo(CFrame.new(-0.1, -1.2, -4) * CFrame.Angles(0, -2.6179938779914944, 0))
					clone.Parent = v34.current
				end
			end
		end)

		return function() -- line: 234
			-- upvalues: u84 (ref), v36 (copy)
			u84 = true
			v36.current = nil
		end
	end, { v34.current })
	React.useEffect(function() -- line: 240
		-- upvalues: v35 (copy), ReplicatedStorage (copy), LimbFlicker (copy), v37 (copy)
		local u85 = false

		task.spawn(function() -- line: 242
			-- upvalues: v35 (copy), ReplicatedStorage (copy), u85 (ref), LimbFlicker (copy), v37 (copy)
			if v35.current then
				local MenuMarine = ReplicatedStorage:WaitForChild("MenuMarine", 20)

				if u85 then
					return
				end

				if MenuMarine then
					local clone = MenuMarine:Clone()

					LimbFlicker.fix(clone)

					local Model = v35.current:FindFirstChildOfClass("Model")

					if Model then
						Model:Destroy()
					end

					task.spawn(function() -- line: 256
						-- upvalues: clone (copy), v37 (copy)
						repeat
							task.wait()
						until clone.Parent and clone:IsDescendantOf(game)

						if clone:FindFirstChild("Animation") then
							return
						end

						local Animation = Instance.new("Animation")

						Animation.AnimationId = "rbxassetid://97948859490877"
						Animation.Parent = clone

						local Animation3 = Instance.new("Animation")

						Animation3.AnimationId = "rbxassetid://119789694900088"
						Animation3.Parent = clone

						local track = clone.Humanoid:LoadAnimation(Animation3)

						track.Looped = true
						v37.current = track
						track:Play(nil, 0.001, nil)
						clone.Humanoid:LoadAnimation(Animation):Play(0, 1, 1)
					end)
					clone.HumanoidRootPart.Anchored = true
					clone:PivotTo(CFrame.new(0.2, -3.6, -4) * CFrame.Angles(0, 2.6179938779914944, 0))
					clone.Parent = v35.current
				end
			end
		end)

		return function() -- line: 285
			-- upvalues: u85 (ref)
			u85 = true
		end
	end, { v35.current })

	local v43 = createElement
	local t2 = {
		BackgroundTransparency = CONSTANTS.ALPHA.INVISIBLE,
		Size = UDim2.fromScale(1, 1)
	}
	local t3 = {
		header = createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = CONSTANTS.COLOR.PALETTE.BLACK,
			BorderColor3 = CONSTANTS.COLOR.PALETTE.BLACK,
			BorderSizePixel = CONSTANTS.THICKNESS.OUTLINE.NONE,
			Position = UDim2.fromScale(0.5, 0.114202),
			Size = UDim2.fromScale(0.47326, 0.071708)
		}, {
			uIGradient = createElement("UIGradient", {
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.30137, 0),
					NumberSequenceKeypoint.new(0.701121, 0),
					NumberSequenceKeypoint.new(1, 1)
				})
			}),
			textLabel = createElement("TextLabel", {
				Text = "Pick A Side!",
				TextScaled = true,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = CONSTANTS.ALPHA.INVISIBLE,
				FontFace = CONSTANTS.FONT.FACE.DISPLAY,
				Position = UDim2.fromScale(0.5, 0.525),
				Size = UDim2.fromScale(0.9, 0.8),
				TextColor3 = CONSTANTS.COLOR.PALETTE.WHITE
			})
		}),
		playButton = createElement("TextButton", {
			LayoutOrder = 1,
			Text = "",
			TextScaled = true,
			AnchorPoint = Vector2.new(0, 1),
			BackgroundColor3 = CONSTANTS.COLOR.SECONDARY.BACKGROUND,
			BorderColor3 = CONSTANTS.COLOR.SECONDARY.BORDER,
			BorderSizePixel = CONSTANTS.THICKNESS.OUTLINE.REGULAR,
			FontFace = Font.new(CONSTANTS.FONT.FAMILY.SOURCE_SANS_PRO),
			Position = UDim2.fromScale(0.014652, 0.977836),
			Size = UDim2.fromScale(0.119049, 0.057567),
			TextColor3 = CONSTANTS.COLOR.PALETTE.BLACK,
			TextStrokeColor3 = CONSTANTS.COLOR.PALETTE.WHITE,
			ZIndex = CONSTANTS.LAYER.RAISED
		}, {
			trans = createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundColor3 = CONSTANTS.COLOR.SECONDARY.HIGHLIGHT,
				BorderSizePixel = CONSTANTS.THICKNESS.OUTLINE.NONE,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.96, 0.45)
			}),
			uISizeConstraint = createElement("UISizeConstraint", {
				MaxSize = Vector2.new(175, 55),
				MinSize = Vector2.new(32, 32)
			}),
			textLabel = createElement("TextLabel", {
				Text = "Fast Mode",
				TextScaled = true,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = CONSTANTS.ALPHA.INVISIBLE,
				FontFace = CONSTANTS.FONT.FACE.DISPLAY,
				Position = UDim2.fromScale(0.5, 0.55),
				Size = UDim2.fromScale(0.95, 0.75),
				TextColor3 = CONSTANTS.COLOR.PALETTE.BLACK,
				ZIndex = CONSTANTS.LAYER.RAISED
			}, {
				uIStroke = createElement("UIStroke", {
					Thickness = 0.05,
					StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
				}),
				textLabel = createElement("TextLabel", {
					Text = "Fast Mode",
					TextScaled = true,
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = CONSTANTS.ALPHA.INVISIBLE,
					FontFace = CONSTANTS.FONT.FACE.DISPLAY,
					Position = UDim2.fromScale(0.5, 0.425),
					Size = UDim2.fromScale(1, 1),
					TextColor3 = CONSTANTS.COLOR.PALETTE.WHITE
				}, {
					uIStroke = createElement("UIStroke", {
						Thickness = 0.05,
						StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
					})
				})
			})
		})
	}
	local v46 = createElement
	local t4 = {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = CONSTANTS.ALPHA.INVISIBLE,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.571421, 0.620159)
	}
	local t5 = {}
	local v49 = createElement
	local t6 = {
		LayoutOrder = -1,
		BackgroundTransparency = CONSTANTS.ALPHA.INVISIBLE,
		Size = UDim2.fromScale(1, 1)
	}
	local t7 = {
		uIAspectRatioConstraint = createElement("UIAspectRatioConstraint", {
			AspectRatio = 0.81
		})
	}
	local v52 = createElement
	local t8 = {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = CONSTANTS.ALPHA.INVISIBLE,
		Image = "rbxassetid://85220450463423",
		ImageRectOffset = v22:map(function(n4: number) -- line: 403
			return Vector2.new(not (n4 > 0.5) and 0 or 434, 0)
		end),
		ImageRectSize = Vector2.new(434, 512),
		Size = v24:map(function(n5: number) -- line: 407
			local v88 = math.lerp(1, 0.95, n5)

			return UDim2.fromScale(v88, v88)
		end),
		Position = v38:map(function(n6: number) -- line: 411
			-- upvalues: v22 (copy)
			return UDim2.fromScale(0.5, 0.5 + (math.sin(n6) * 0.01 + -0.05) * v22:getValue())
		end),
		[React.Event.MouseButton1Down] = function() -- line: 417
			-- upvalues: v31 (copy), change (copy)
			v31.enable()
			change("Pirates")
		end,
		[React.Event.MouseButton1Up] = v31.disable,
		[React.Event.MouseEnter] = v30.enable,
		[React.Event.MouseLeave] = v30.disable
	}
	local t9 = {
		uIAspectRatioConstraint = createElement("UIAspectRatioConstraint", {
			AspectRatio = 0.81
		}),
		brush = createElement("ImageLabel", {
			Image = "rbxassetid://97360618731415",
			BackgroundTransparency = CONSTANTS.ALPHA.INVISIBLE,
			ImageColor3 = CONSTANTS.COLOR.PALETTE.BLACK,
			Position = UDim2.fromScale(-0.078, 0.67),
			Size = UDim2.fromScale(1.01107, 0.189108),
			ZIndex = CONSTANTS.LAYER.RAISED
		}, {
			imageLabel = createElement("ImageLabel", {
				Image = "rbxassetid://97360618731415",
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = CONSTANTS.ALPHA.INVISIBLE,
				Position = UDim2.fromScale(0.48, 0.385),
				Size = UDim2.fromScale(1, 1)
			}, {
				uIGradient = createElement("UIGradient", {
					Rotation = -90,
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(99, 0, 0)),
						ColorSequenceKeypoint.new(0.455959, Color3.fromRGB(195, 0, 0)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 133, 133))
					})
				}),
				textLabel = createElement("TextLabel", {
					Text = "PIRATES",
					TextScaled = true,
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = CONSTANTS.ALPHA.INVISIBLE,
					FontFace = CONSTANTS.FONT.FACE.TITLE,
					Position = UDim2.fromScale(0.546076, 0.55),
					Size = UDim2.fromScale(0.734497, 0.8),
					TextColor3 = CONSTANTS.COLOR.PALETTE.BLACK
				}, {
					uIStroke = createElement("UIStroke", {
						Thickness = 0.035,
						StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
					}),
					textLabel = createElement("TextLabel", {
						Text = "PIRATES",
						TextScaled = true,
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundTransparency = CONSTANTS.ALPHA.INVISIBLE,
						FontFace = CONSTANTS.FONT.FACE.TITLE,
						Position = UDim2.fromScale(0.5, 0.45),
						Size = UDim2.fromScale(1, 1),
						TextColor3 = CONSTANTS.COLOR.PALETTE.WHITE
					}, {
						uIStroke = createElement("UIStroke", {
							Thickness = 0.035,
							StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
						})
					})
				})
			})
		})
	}
	local v55 = createElement
	local t10 = {
		TextScaled = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = CONSTANTS.ALPHA.INVISIBLE,
		FontFace = CONSTANTS.FONT.FACE.TITLE,
		Position = UDim2.fromScale(0.5, 0.905),
		Size = UDim2.fromScale(0.85, 0.0787426)
	}
	local Bounty = v41.Bounty

	t10.Text = `Bounty: ${ TextUtil.commaValue(Bounty) }`
	t10.TextColor3 = CONSTANTS.COLOR.PALETTE.BLACK
	t10.ZIndex = CONSTANTS.LAYER.RAISED

	local t11 = {
		uIStroke = createElement("UIStroke", {
			Thickness = 0.05,
			StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
		})
	}
	local v59 = createElement
	local t12 = {
		TextScaled = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = CONSTANTS.ALPHA.INVISIBLE,
		FontFace = CONSTANTS.FONT.FACE.TITLE,
		Position = UDim2.fromScale(0.5, 0.425),
		Size = UDim2.fromScale(1, 1)
	}
	local Bounty2 = v41.Bounty

	t12.Text = `Bounty: ${ TextUtil.commaValue(Bounty2) }`
	t12.TextColor3 = CONSTANTS.COLOR.PALETTE.WHITE
	t11.textLabel = v59("TextLabel", t12, {
		uIStroke = createElement("UIStroke", {
			Thickness = 0.05,
			StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
		})
	})
	t9.textLabel = v55("TextLabel", t10, t11)
	t9.imageLabel = createElement("ImageLabel", {
		Image = "rbxassetid://74108443213821",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = CONSTANTS.ALPHA.INVISIBLE,
		ImageColor3 = Color3.fromRGB(45, 0, 0),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1.3, 1.3),
		ZIndex = CONSTANTS.LAYER.BASE
	})
	t9.viewportFrame = createElement("ViewportFrame", {
		BackgroundColor3 = Color3.fromRGB(48, 2, 2),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = CONSTANTS.ALPHA.INVISIBLE,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.925, 1),
		ZIndex = CONSTANTS.LAYER.CONTENT
	}, {
		wm = createElement("WorldModel", {
			ref = v34
		}),
		uIGradient = createElement("UIGradient", {
			Rotation = 91.5,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.96264, 0),
				NumberSequenceKeypoint.new(0.965131, 1),
				NumberSequenceKeypoint.new(1, 1)
			})
		})
	})
	t9.description = createElement("TextLabel", {
		Text = "Defy the marines and battle pirates!\nCreate your own pirate crew!\nGet a high player bounty!",
		TextScaled = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = CONSTANTS.ALPHA.INVISIBLE,
		FontFace = CONSTANTS.FONT.FACE.TITLE,
		Position = UDim2.fromScale(0.5, 1.13055),
		Size = UDim2.fromScale(1.2, 0.221095),
		TextColor3 = CONSTANTS.COLOR.PALETTE.BLACK
	}, {
		uIStroke = createElement("UIStroke", {
			Thickness = 0.05,
			StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
		}),
		textLabel = createElement("TextLabel", {
			Text = "Defy the marines and battle pirates!\nCreate your own pirate crew!\nGet a high player bounty!",
			TextScaled = true,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = CONSTANTS.ALPHA.INVISIBLE,
			FontFace = CONSTANTS.FONT.FACE.TITLE,
			Position = UDim2.fromScale(0.5, 0.465),
			Size = UDim2.fromScale(1, 1),
			TextColor3 = CONSTANTS.COLOR.PALETTE.WHITE
		}, {
			uIStroke = createElement("UIStroke", {
				Thickness = 0.05,
				StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
			})
		})
	})
	t7.pirate = v52("ImageButton", t8, t9)
	t5.pirateFrame = v49("Frame", t6, t7)
	t5.uIListLayout = createElement("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalFlex = Enum.UIFlexAlignment.SpaceBetween,
		SortOrder = Enum.SortOrder.LayoutOrder
	})

	local v62 = createElement
	local t13 = {
		LayoutOrder = 1,
		BackgroundTransparency = CONSTANTS.ALPHA.INVISIBLE,
		Size = UDim2.fromScale(1, 1)
	}
	local t14 = {
		uIAspectRatioConstraint = createElement("UIAspectRatioConstraint", {
			AspectRatio = 0.81
		})
	}
	local v65 = createElement
	local t15 = {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = CONSTANTS.ALPHA.INVISIBLE,
		Image = "rbxassetid://117883459036704",
		ImageRectOffset = v26:map(function(n7: number) -- line: 608
			return Vector2.new(not (n7 > 0.5) and 0 or 433, 0)
		end),
		ImageRectSize = Vector2.new(433, 512),
		Size = v28:map(function(n8: number) -- line: 612
			local v92 = math.lerp(1, 0.95, n8)

			return UDim2.fromScale(v92, v92)
		end),
		Position = v38:map(function(n9: number) -- line: 616
			-- upvalues: v26 (copy)
			return UDim2.fromScale(0.5, 0.5 + (math.sin(n9) * 0.01 + -0.05) * v26:getValue())
		end),
		[React.Event.MouseButton1Down] = function() -- line: 622
			-- upvalues: v33 (copy), change (copy)
			v33.enable()
			change("Marines")
		end,
		[React.Event.MouseButton1Up] = v33.disable,
		[React.Event.MouseEnter] = v32.enable,
		[React.Event.MouseLeave] = v32.disable
	}
	local t16 = {
		uIAspectRatioConstraint = createElement("UIAspectRatioConstraint", {
			AspectRatio = 0.81
		})
	}
	local v68 = createElement
	local t17 = {
		TextScaled = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = CONSTANTS.ALPHA.INVISIBLE,
		FontFace = CONSTANTS.FONT.FACE.TITLE,
		Position = UDim2.fromScale(0.5, 0.905),
		Size = UDim2.fromScale(0.85, 0.0787426)
	}
	local Honor = v41.Honor

	t17.Text = `Honor: ${ TextUtil.commaValue(Honor) }`
	t17.TextColor3 = CONSTANTS.COLOR.PALETTE.BLACK
	t17.ZIndex = CONSTANTS.LAYER.RAISED

	local t18 = {
		uIStroke = createElement("UIStroke", {
			Thickness = 0.05,
			StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
		})
	}
	local v72 = createElement
	local t19 = {
		TextScaled = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = CONSTANTS.ALPHA.INVISIBLE,
		FontFace = CONSTANTS.FONT.FACE.TITLE,
		Position = UDim2.fromScale(0.5, 0.425),
		Size = UDim2.fromScale(1, 1)
	}
	local Honor2 = v41.Honor

	t19.Text = `Honor: ${ TextUtil.commaValue(Honor2) }`
	t19.TextColor3 = CONSTANTS.COLOR.PALETTE.WHITE
	t18.textLabel = v72("TextLabel", t19, {
		uIStroke = createElement("UIStroke", {
			Thickness = 0.05,
			StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
		})
	})
	t16.textLabel = v68("TextLabel", t17, t18)
	t16.imageLabel = createElement("ImageLabel", {
		Image = "rbxassetid://74108443213821",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = CONSTANTS.ALPHA.INVISIBLE,
		ImageColor3 = Color3.fromRGB(0, 17, 35),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1.3, 1.3),
		ZIndex = CONSTANTS.LAYER.BASE
	})
	t16.brush = createElement("ImageLabel", {
		Image = "rbxassetid://95362816320725",
		BackgroundTransparency = CONSTANTS.ALPHA.INVISIBLE,
		ImageColor3 = CONSTANTS.COLOR.PALETTE.BLACK,
		Position = UDim2.fromScale(0.108456, 0.67),
		Size = UDim2.fromScale(1.01107, 0.189108),
		ZIndex = CONSTANTS.LAYER.RAISED
	}, {
		imageLabel = createElement("ImageLabel", {
			Image = "rbxassetid://95362816320725",
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = CONSTANTS.ALPHA.INVISIBLE,
			Position = UDim2.fromScale(0.48, 0.385),
			Size = UDim2.fromScale(1, 1)
		}, {
			uIGradient = createElement("UIGradient", {
				Rotation = -90,
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 73, 170)),
					ColorSequenceKeypoint.new(0.455959, Color3.fromRGB(23, 121, 204)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(115, 185, 246))
				})
			}),
			textLabel = createElement("TextLabel", {
				Text = "MARINES",
				TextScaled = true,
				ZIndex = 4,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = CONSTANTS.ALPHA.INVISIBLE,
				FontFace = CONSTANTS.FONT.FACE.TITLE,
				Position = UDim2.fromScale(0.45, 0.55),
				Size = UDim2.fromScale(0.734497, 0.8),
				TextColor3 = CONSTANTS.COLOR.PALETTE.BLACK
			}, {
				uIStroke = createElement("UIStroke", {
					Thickness = 0.035,
					StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
				}),
				textLabel = createElement("TextLabel", {
					Text = "MARINES",
					TextScaled = true,
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = CONSTANTS.ALPHA.INVISIBLE,
					FontFace = CONSTANTS.FONT.FACE.TITLE,
					Position = UDim2.fromScale(0.5, 0.45),
					Size = UDim2.fromScale(1, 1),
					TextColor3 = CONSTANTS.COLOR.PALETTE.WHITE,
					ZIndex = CONSTANTS.LAYER.OVERLAY
				}, {
					uIStroke = createElement("UIStroke", {
						Thickness = 0.035,
						StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
					})
				})
			})
		})
	})
	t16.viewportFrame = createElement("ViewportFrame", {
		BackgroundColor3 = Color3.fromRGB(5, 38, 63),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = CONSTANTS.ALPHA.INVISIBLE,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.925, 1),
		ZIndex = CONSTANTS.LAYER.CONTENT
	}, {
		wm = createElement("WorldModel", {
			ref = v35
		}),
		uIGradient = createElement("UIGradient", {
			Rotation = 88.5,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.96264, 0),
				NumberSequenceKeypoint.new(0.965131, 1),
				NumberSequenceKeypoint.new(1, 1)
			})
		})
	})
	t16.description = createElement("TextLabel", {
		Text = "Team up on pirates!\nFaster, cheaper ships!\nClaim bounties!",
		TextScaled = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = CONSTANTS.ALPHA.INVISIBLE,
		FontFace = CONSTANTS.FONT.FACE.TITLE,
		Position = UDim2.fromScale(0.5, 1.131),
		Size = UDim2.fromScale(1.2, 0.221),
		TextColor3 = CONSTANTS.COLOR.PALETTE.BLACK
	}, {
		uIStroke = createElement("UIStroke", {
			Thickness = 0.05,
			StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
		}),
		textLabel = createElement("TextLabel", {
			Text = "Team up on pirates!\nFaster, cheaper ships!\nClaim bounties!",
			TextScaled = true,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = CONSTANTS.ALPHA.INVISIBLE,
			FontFace = CONSTANTS.FONT.FACE.TITLE,
			Position = UDim2.fromScale(0.5, 0.465),
			Size = UDim2.fromScale(1, 1),
			TextColor3 = CONSTANTS.COLOR.PALETTE.WHITE
		}, {
			uIStroke = createElement("UIStroke", {
				Thickness = 0.05,
				StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
			})
		})
	})
	t14.marine = v65("ImageButton", t15, t16)
	t5.marineFrame = v62("Frame", t13, t14)
	t5.folder = createElement("Folder", nil, {
		imageLabel = createElement("ImageLabel", {
			Image = "rbxassetid://74108443213821",
			ImageTransparency = 0.57,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = CONSTANTS.ALPHA.INVISIBLE,
			ImageColor3 = CONSTANTS.COLOR.PALETTE.BLACK,
			Position = UDim2.fromScale(0.5, 0.56865),
			Size = UDim2.fromScale(0.219939, 0.275495)
		}, {
			textLabel = createElement("TextLabel", {
				Text = "VS",
				TextScaled = true,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = CONSTANTS.ALPHA.INVISIBLE,
				FontFace = CONSTANTS.FONT.FACE.TITLE,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.860942, 0.586473),
				TextColor3 = CONSTANTS.COLOR.PALETTE.BLACK
			}, {
				uIStroke = createElement("UIStroke", {
					Thickness = 0.035,
					StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
				}),
				textLabel = createElement("TextLabel", {
					Text = "VS",
					TextScaled = true,
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = CONSTANTS.ALPHA.INVISIBLE,
					FontFace = CONSTANTS.FONT.FACE.TITLE,
					Position = UDim2.fromScale(0.5, 0.45),
					Size = UDim2.fromScale(1, 1),
					TextColor3 = CONSTANTS.COLOR.PALETTE.WHITE
				}, {
					uIStroke = createElement("UIStroke", {
						Thickness = 0.035,
						StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
					})
				})
			})
		})
	})
	t5.uIScale = createElement("UIScale", {
		Scale = v40
	})
	t5.uIAspectRatioConstraint = createElement("UIAspectRatioConstraint", {
		AspectRatio = 1.87537
	})
	t3.content = v46("Frame", t4, t5)

	return v43("Frame", t2, t3)
end
