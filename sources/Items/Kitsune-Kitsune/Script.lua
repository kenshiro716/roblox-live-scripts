local players = game:GetService("Players")
local replicatedstorage = game:GetService("ReplicatedStorage")
local serverstorage = game:GetService("ServerStorage")

local effect = require(replicatedstorage:WaitForChild("Effect"))
local hitbox = require(serverstorage:WaitForChild("hitbox"))

local tool = script.Parent
local data = require(tool:WaitForChild("Data"))
local remote = tool:WaitForChild("RemoteEvent")
local remotefunction = tool:WaitForChild("RemoteFunction")
local effectholding = tool:FindFirstChild("effectholding")
if not effectholding then
	effectholding = Instance.new("BoolValue")
	effectholding.Name = "effectholding"
	effectholding.Parent = tool
end
local keyheld = false
local mousepos = tool:WaitForChild("MousePos")
local istransformed = tool:WaitForChild("IsTransformed")
local transformedrig = tool:WaitForChild("TransformedRigObject")
local movesettemplate = serverstorage:WaitForChild("MovesetTemplates"):WaitForChild(tool.Name)
local foxtemplate = replicatedstorage:WaitForChild("FX"):WaitForChild("Kitsune"):WaitForChild("Kitsune")

local maxhold = 3
local holdskills = { Z = true, X = true, C = true, F = true }
local foxheight = 6.6

local lastused = {}
local active = nil
local busyuntil = 0
local combo, lastm1 = 0, 0
local tails, lasthit = 0, 0
local transform = { container = nil, token = nil, hidden = {}, walkspeed = nil }
local passivecharacter, passiveconnection = nil, nil

local function getcharacter()
	local parent = tool.Parent
	if parent and parent:IsA("Model") and parent:FindFirstChildOfClass("Humanoid") then
		return parent
	end
	return nil
end

local function getowner()
	local parent = tool.Parent
	if parent and parent:IsA("Backpack") then
		return parent.Parent
	end
	local character = getcharacter()
	return character and players:GetPlayerFromCharacter(character)
end

local function toollevel()
	return tool:GetAttribute("Level") or (tool:FindFirstChild("Level") and tool.Level.Value) or 1
end

local function play(name, params)
	local ok, err = pcall(function()
		effect.new(name):replicate(params)
	end)
	if not ok then
		warn("[Kitsune] effect " .. name .. " failed: " .. tostring(err))
	end
end

local function setupmoveset(player)
	local playergui = player and player:FindFirstChildOfClass("PlayerGui")
	if not playergui then
		return
	end

	local modules = playergui:FindFirstChild("MovesetModules")
	if not modules then
		modules = Instance.new("Folder")
		modules.Name = "MovesetModules"
		modules.Parent = playergui
	end

	local entry = modules:FindFirstChild(tool.Name)
	if not entry then
		entry = Instance.new("Folder")
		entry.Name = tool.Name
		entry.Parent = modules
	end
	entry:SetAttribute("MovesetToolUid", tool:GetAttribute("MovesetToolUid"))

	if not entry:FindFirstChild("LegacyDataAggregate") then
		local aggregate = tool.Data:Clone()
		aggregate.Name = "LegacyDataAggregate"
		aggregate.Parent = entry
	end

	for _, moveset in ipairs(movesettemplate:GetChildren()) do
		if not entry:FindFirstChild(moveset.Name) then
			moveset:Clone().Parent = entry
		end
	end
end

local function tailids(count)
	local ids = {}
	for i = 1, count do
		table.insert(ids, i)
	end
	return ids
end

local function settails(count)
	local character = getcharacter() or passivecharacter
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not character:FindFirstChild("LowerTorso") then
		return
	end
	tails = count
	play("Kitsune.Tail", { Root = root, Ids = tailids(count), Tool = tool })
end

local function ragevalue(character)
	character = character or getcharacter() or passivecharacter
	if not character then
		return nil
	end
	local rage = character:FindFirstChild("Rage")
	if not rage then
		rage = Instance.new("NumberValue")
		rage.Name = "Rage"
		rage.Parent = character
	end
	return rage
end

local function tailsfor(amount)
	if amount >= 200 / 3 then
		return 3
	elseif amount >= 100 / 3 then
		return 2
	end
	return 1
end

local function setrage(amount)
	local rage = ragevalue()
	if not rage then
		return
	end
	rage.Value = math.clamp(amount, 0, 100)
	if not istransformed.Value then
		local count = tailsfor(rage.Value)
		if count ~= tails then
			settails(count)
		end
	end
end

local function addrage(amount)
	local rage = ragevalue()
	if rage then
		setrage(rage.Value + amount)
	end
end

local function onhitlanded(amount)
	lasthit = os.clock()
	if not istransformed.Value then
		addrage(amount * data.rage.gainperdamage)
	end
end

local endtransform

task.spawn(function()
	local step = 0.25
	while true do
		task.wait(step)
		local character = getcharacter() or (passivecharacter and passivecharacter.Parent and passivecharacter)
		local rage = character and character:FindFirstChild("Rage")
		if rage then
			if istransformed.Value then
				setrage(rage.Value - data.rage.transformdrainpersecond * step)
				if rage.Value <= 0 then
					endtransform(getowner())
				end
			elseif not istransformed.Value and rage.Value < 100 then
				setrage(rage.Value + 100 * step / 300)
			end
		end
	end
end)

local function eachtarget(selfcharacter, callback)
	for _, foldername in ipairs({ "Characters", "Enemies" }) do
		local folder = workspace:FindFirstChild(foldername)
		if folder then
			for _, model in ipairs(folder:GetChildren()) do
				if model ~= selfcharacter and model:IsA("Model") then
					local humanoid = model:FindFirstChildOfClass("Humanoid")
					local root = model:FindFirstChild("HumanoidRootPart")
					if humanoid and root and humanoid.Health > 0 then
						callback(model, humanoid, root)
					end
				end
			end
		end
	end
end

local function hit(humanoid, amount)
	local model = humanoid and humanoid.Parent
	local attacker = getcharacter() or passivecharacter
	if model and hitbox.damage(attacker, model, amount, { part = model:FindFirstChild("HumanoidRootPart"), source = tool.Name }) then
		onhitlanded(amount)
	end
end

local function damageradius(selfcharacter, position, radius, amount)
	for _, target in ipairs(hitbox.sphere(selfcharacter, position, radius)) do
		hit(target.humanoid, amount)
	end
end

local function damagealong(selfcharacter, from, to, radius, amount)
	for _, target in ipairs(hitbox.line(selfcharacter, from, to, radius)) do
		hit(target.humanoid, amount)
	end
end

local function firstalong(selfcharacter, from, to, radius)
	local target = hitbox.first(selfcharacter, from, to, radius)
	return target and target.root
end

local worldparams = RaycastParams.new()
worldparams.FilterType = Enum.RaycastFilterType.Exclude

local function ignorelist(character)
	return {
		character,
		workspace:FindFirstChild("_WorldOrigin"),
		workspace:FindFirstChild("Characters"),
		workspace:FindFirstChild("Enemies"),
	}
end

local function groundbelow(position, character)
	worldparams.FilterDescendantsInstances = ignorelist(character)
	local result = workspace:Raycast(position + Vector3.new(0, 30, 0), Vector3.new(0, -120, 0), worldparams)
	return result and result.Position or position
end

local function clamprange(origin, target, range)
	local offset = target - origin
	if offset.Magnitude > range then
		return origin + offset.Unit * range
	end
	return target
end

local function canuse(character, key)
	if active or os.clock() < busyuntil then
		return false
	end
	if toollevel() < (data.Lvl[key] or 1) then
		return false
	end
	if os.clock() - (lastused[key] or -math.huge) < (data.Cooldown[key] or 0) then
		return false
	end
	local stun = character:FindFirstChild("Stun")
	if stun and stun:IsA("ValueBase") and tonumber(stun.Value) and stun.Value > 0 then
		return false
	end
	return true
end

local function dashroot(root, cframe, duration)
	play("Kitsune.ClientDash", { Root = root, CFrame = cframe, Duration = duration, Linear = true })
end

local release

local function starthold(player, character, root, key)
	if not holdskills[key] or not canuse(character, key) then
		return
	end

	local token = { key = key, started = os.clock(), player = player, character = character, root = root }
	active = token
	effectholding.Value = true
	local fox = istransformed.Value

	if key == "Z" then
		if not fox then
			play("Kitsune.ZCharge", { player = player, hrp = root, holding = effectholding })
		end
	elseif key == "X" then
		play("Kitsune.X", { player = player, ID = 1, Character = character, HoldValue = effectholding })
	elseif key == "C" then
		play("Kitsune.CCharge", {
			player = player,
			hrp = root,
			holding = effectholding,
			transformed = fox,
			mutated = false,
			cutsceneTransition = false,
		})
	elseif key == "F" then
		play("Kitsune.FCharge", { player = player, hrp = root, transformed = fox, holding = effectholding })
	end

	task.spawn(function()
		local deadline = token.started + maxhold
		while active == token and keyheld and os.clock() < deadline do
			task.wait(0.03)
		end
		if active == token then
			release(player, character, root, key)
		end
	end)
end

function release(player, character, root, key)
	if not active or active.key ~= key then
		return
	end
	active = nil
	effectholding.Value = false
	lastused[key] = os.clock()

	local fox = istransformed.Value
	local origin = root.Position
	local target = mousepos.Value
	local flat = Vector3.new(target.X, origin.Y, target.Z)
	if (flat - origin).Magnitude < 0.5 then
		flat = origin + root.CFrame.LookVector
	end
	local forward = (flat - origin).Unit
	local right = forward:Cross(Vector3.yAxis).Unit

	if key == "Z" and not fox then
		busyuntil = os.clock() + 0.6
		for i = 1, 3 do
			task.delay((i - 1) * 0.12, function()
				local from = root.Position + Vector3.new(0, 1.5, 0)
				local aimat = mousepos.Value
				if (aimat - from).Magnitude < 1 then
					aimat = from + root.CFrame.LookVector * 50
				end
				local params = RaycastParams.new()
				params.FilterType = Enum.RaycastFilterType.Exclude
				params.FilterDescendantsInstances = { character, workspace:FindFirstChild("_WorldOrigin") }
				local result = workspace:Raycast(from, (aimat - from).Unit * 160, params)
				local goal = result and result.Position or (from + (aimat - from).Unit * 160)
				local model = result and result.Instance:FindFirstAncestorOfClass("Model")
				local humanoid = model and model:FindFirstChildOfClass("Humanoid")
				local victimroot = humanoid and humanoid.Health > 0 and model:FindFirstChild("HumanoidRootPart") or nil
				local travel = math.max((goal - from).Magnitude / 200, 0.15)

				play("Kitsune.Z", {
					player = player,
					hrp = root,
					originPos = from,
					goalPos = goal,
					index = i,
					raycastHitSomething = result ~= nil,
					victimRoot = victimroot,
					timeUntilImpact = travel,
					victimDetonateDelay = 1,
				})
				task.delay(travel, damageradius, character, goal, 7, data.damage.z)
			end)
		end
	elseif key == "Z" and fox then
		local goal = groundbelow(clamprange(origin, flat, 70), character) + Vector3.new(0, 3, 0)
		play("Kitsune.ZTransformed", {
			player = player,
			hrp = root,
			dashOriginPos = origin,
			dashTargetPos = goal,
			dashFor = 0.35,
		})
		dashroot(root, CFrame.lookAt(goal, goal + forward), 0.35)
		busyuntil = os.clock() + 0.6
		task.delay(0.35, damagealong, character, origin, goal, 10, data.damage.z * 3)
	elseif key == "X" then
		local legs, leglength, sway, perleg = 4, 16, 7, 0.11
		local points = {}
		for i = 0, legs do
			local along = origin + forward * leglength * i
			local side = (i == 0 or i == legs) and 0 or ((i % 2 == 1) and sway or -sway)
			local position = along + right * side
			if i > 0 then
				position = groundbelow(position, character) + Vector3.new(0, 3, 0)
			end
			local nextpos = origin + forward * leglength * (i + 1)
			points[i + 1] = CFrame.lookAt(position, Vector3.new(nextpos.X, position.Y, nextpos.Z))
		end

		play("Kitsune.X", { player = player, ID = 2, DashPoints = points, DurationPer = perleg })
		busyuntil = os.clock() + legs * perleg + 0.4
		for i = 2, #points do
			task.delay((i - 2) * perleg, function()
				dashroot(root, points[i], perleg)
				damagealong(character, points[i - 1].Position, points[i].Position, 7, data.damage.xleg)
			end)
		end
		task.delay(legs * perleg, function()
			local finish = points[#points]
			play("Kitsune.X", { player = player, ID = 3, CFrame = finish })
			damageradius(character, finish.Position, 14, data.damage.xend)
		end)
	elseif key == "C" then
		local goal = groundbelow(clamprange(origin, target, 120), character)
		local travel = math.max((goal - origin).Magnitude / 140, 0.2)
		local burnfor, explodeafter = 3, 0.6
		play("Kitsune.C", {
			player = player,
			hrp = root,
			originPos = origin,
			goalPos = goal,
			transformed = fox,
			fireDamageFor = burnfor,
			delayUntilExplosion = explodeafter,
			timeUntilImpact = travel,
		})
		busyuntil = os.clock() + 0.7
		task.delay(travel, damageradius, character, goal, 12, data.damage.cimpact)
		task.delay(travel + explodeafter, damageradius, character, goal, 20, data.damage.cexplosion)
		for burntick = 1, 6 do
			task.delay(travel + explodeafter + burntick * (burnfor / 6), damageradius, character, goal, 16, data.damage.cburn)
		end
	elseif key == "F" then
		local dashfor = 0.32
		local goal = clamprange(origin, flat, 70)
		local victimroot = firstalong(character, origin, goal, 7)
		if victimroot then
			goal = victimroot.Position - forward * 3
		end
		goal = groundbelow(goal, character) + Vector3.new(0, 3, 0)

		play(fox and "Kitsune.FTransformed" or "Kitsune.F", {
			player = player,
			hrp = root,
			originPos = origin,
			goalPos = goal,
			dashFor = dashfor,
		})
		dashroot(root, CFrame.lookAt(goal, goal + forward), dashfor)
		busyuntil = os.clock() + dashfor + 0.5

		task.delay(dashfor, function()
			if victimroot and victimroot.Parent then
				play("Kitsune.FHit", { player = player, hrp = root, transformed = fox, victimRoot = victimroot, index = 1 })
				local humanoid = victimroot.Parent:FindFirstChildOfClass("Humanoid")
				if humanoid then
					hit(humanoid, data.damage.f)
				end
			end
			play(fox and "Kitsune.FSlashesTransformed" or "Kitsune.FSlashes", {
				player = player,
				hrp = root,
				originPos = origin,
				goalPos = goal,
				missed = victimroot == nil,
			})
		end)
	end
end

local function m1(player, character, root, humanoid)
	if active or os.clock() < busyuntil then
		return
	end
	if os.clock() - (lastused.TAP or -math.huge) < data.Cooldown.TAP then
		return
	end
	lastused.TAP = os.clock()

	if os.clock() - lastm1 > 1.2 then
		combo = 0
	end
	lastm1 = os.clock()
	combo = combo % 5 + 1
	local final = combo == 5
	local fox = istransformed.Value

	play("Kitsune.M1Combo", {
		player = player,
		hrp = root,
		transformed = fox,
		index = combo,
		playerOnGround = humanoid.FloorMaterial ~= Enum.Material.Air,
	})

	if final then
		busyuntil = os.clock() + 0.5
	end
	local reach = fox and 12 or 5
	local center = root.Position + root.CFrame.LookVector * reach
	local radius = (fox and 12 or 8) + (final and 4 or 0)
	task.delay(0.12, damageradius, character, center, radius, final and data.damage.m1final or data.damage.m1)
end

local function setbodyhidden(character, hidden)
	if hidden then
		for _, d in ipairs(character:GetDescendants()) do
			local partoffox = transform.container and d:IsDescendantOf(transform.container)
			if not partoffox and (d:IsA("BasePart") or d:IsA("Decal")) and d.Transparency < 1 then
				transform.hidden[d] = d.Transparency
				d.Transparency = 1
			end
		end
	else
		for d, transparency in pairs(transform.hidden) do
			if d.Parent then
				d.Transparency = transparency
			end
		end
		table.clear(transform.hidden)
	end
end

local function buildfox(root)
	local container = Instance.new("Model")
	container.Name = "Kitsune"

	local fox = foxtemplate:Clone()
	fox.Name = "Kitsune"
	local stray = fox:FindFirstChildOfClass("Script")
	if stray then
		stray:Destroy()
	end
	for _, part in ipairs(fox:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.Massless = true
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
		end
	end

	local foxroot = fox.PrimaryPart or fox:FindFirstChild("RootPart")
	foxroot.CFrame = root.CFrame * CFrame.new(0, foxheight, 0)
	local weld = Instance.new("Weld")
	weld.Name = "foxweld"
	weld.Part0 = root
	weld.Part1 = foxroot
	weld.C0 = CFrame.new(0, foxheight, 0)
	weld.Parent = foxroot

	fox.Parent = container
	return container, fox
end

function endtransform(player, skipeffect)
	local container = transform.container
	transform.token = nil
	if not container then
		return
	end

	local character = container.Parent
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	transformedrig.Value = nil
	istransformed.Value = false
	if character then
		setbodyhidden(character, false)
	end
	if humanoid and transform.walkspeed then
		humanoid.WalkSpeed = transform.walkspeed
	end
	transform.walkspeed = nil
	container:Destroy()
	transform.container = nil

	lastused.V = os.clock()
	busyuntil = os.clock() + 0.8

	if not skipeffect and root then
		play("Kitsune.Untransform", { Root = root })
	end
	tails = 0
	setrage(0)
end

local function starttransform(player, character, root, humanoid)
	if transform.container or not canuse(character, "V") then
		return
	end
	local rage = ragevalue(character)
	if not rage or rage.Value < 100 then
		return
	end
	busyuntil = os.clock() + 1

	play("Kitsune.V", { Player = player, Root = root, Toggle = true, Tool = tool })
	play("Kitsune.Tail", { Root = root, Ids = {}, Tool = tool })

	local container, fox = buildfox(root)
	transform.container = container
	container.Parent = character
	transformedrig.Value = fox
	istransformed.Value = true
	setbodyhidden(character, true)
	transform.walkspeed = humanoid.WalkSpeed
	humanoid.WalkSpeed = humanoid.WalkSpeed * 1.35

	task.delay(0.15, damageradius, character, root.Position, 24, data.damage.v)

	local token = {}
	transform.token = token
	task.delay(data.transformduration or 40, function()
		if transform.token == token then
			endtransform(player)
		end
	end)
end

local function endpassive()
	if passiveconnection then
		passiveconnection:Disconnect()
		passiveconnection = nil
	end
	endtransform(getowner(), true)
	local character = passivecharacter
	passivecharacter = nil
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		play("Kitsune.Tail", { Root = root, Ids = {}, Tool = tool })
	end
	tails = 0
end

local function claimpassive(character)
	character:SetAttribute("passivefruit", tool.Name)
	if passivecharacter == character then
		return
	end
	endpassive()
	passivecharacter = character
	tails = 0
	local rage = ragevalue(character)
	setrage(rage and rage.Value or 0)
	passiveconnection = character:GetAttributeChangedSignal("passivefruit"):Connect(function()
		if character:GetAttribute("passivefruit") ~= tool.Name then
			endpassive()
		end
	end)
end

remote.OnServerEvent:Connect(function(player, value)
	if player ~= getowner() then
		return
	end
	if typeof(value) == "Vector3" then
		mousepos.Value = value
	elseif typeof(value) == "CFrame" then
		mousepos.Value = value.Position
	elseif type(value) == "boolean" then
		keyheld = value
	end
end)

remotefunction.OnServerInvoke = function(player, key)
	if player ~= getowner() or type(key) ~= "string" then
		return nil
	end
	local character = getcharacter()
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return nil
	end

	if holdskills[key] then
		if istransformed.Value and not active then
			addrage(-data.rage.skillcosttransformed)
		end
		starthold(player, character, root, key)
	elseif key == "TAP" then
		m1(player, character, root, humanoid)
	elseif key == "V" then
		if istransformed.Value then
			if os.clock() >= busyuntil then
				endtransform(player)
			end
		else
			starttransform(player, character, root, humanoid)
		end
	end
	return nil
end

tool.Equipped:Connect(function()
	local character = getcharacter()
	local player = character and players:GetPlayerFromCharacter(character)
	if not player then
		return
	end
	setupmoveset(player)
	claimpassive(character)
end)

tool.Unequipped:Connect(function()
	local token = active
	keyheld = false
	if token and token.root and token.root.Parent then
		release(token.player, token.character, token.root, token.key)
	end
	active = nil
	effectholding.Value = false
end)

tool.Destroying:Connect(function()
	endpassive()
end)

local function onancestry()
	local owner = getowner()
	if owner then
		setupmoveset(owner)
	end
end
tool.AncestryChanged:Connect(onancestry)
onancestry()
