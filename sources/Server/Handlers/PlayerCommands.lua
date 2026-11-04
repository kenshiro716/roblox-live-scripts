local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Server = script.Parent.Parent
local Config = require(Server.Config)
local Util = require(Server.Util)

return function(Router, ServerData)
	local TeamService = require(Server.TeamService)

	local function joinTeam(player, teamName)
		if not ServerData.WaitReady(player, 20) then
			error(Router.CLIENT_ERROR .. " Player data still not ready", 0)
		end
		return TeamService.Join(player, teamName)
	end

	Router.commF("SetTeam", joinTeam, { requireData = false, rate = 1, burst = 3 })
	Router.commF("SetTeam2", joinTeam, { requireData = false, rate = 1, burst = 3 })

	Router.commF("SetLastSpawnPoint", function(player, name)
		return ServerData.SetLastSpawnPoint(player, name)
	end, { rate = 2, burst = 4 })

	Router.commF("SetSpawnPoint", function(player)
		return ServerData.SetSpawnPoint(player)
	end, { rate = 1, burst = 3 })

	Router.commF("TeleportToSpawn", function(player)
		return ServerData.TeleportToSpawn(player)
	end, { rate = 1, burst = 2 })

	Router.commF("EnablePvp", function(player)
		return ServerData.EnablePvp(player)
	end, { rate = 1, burst = 2 })

	Router.commF("AddPoint", function(player, statName, amount)
		return ServerData.AddPoint(player, statName, amount)
	end, { rate = 10, burst = 20 })

	Router.commF("getInventory", function(player)
		local extra = ServerData.GetExtra(player)
		return extra and table.clone(extra.Inventory) or {}
	end, { rate = 10, burst = 20 })

	Router.commF("GetFruits", function(player)
		local ServerStorage = game:GetService("ServerStorage")
		local extra = ServerData.GetExtra(player)
		local items = ServerStorage:FindFirstChild("Items")
		local result = {}
		local seen = {}

		local function build(name)
			local entry = { Name = name, OnSale = false, Offsale = false, Rarity = 1, Price = 0, HasPermanent = true }
			local tool = items and items:FindFirstChild(name)
			local dataModule = tool and tool:FindFirstChild("Data")
			if dataModule and dataModule:IsA("ModuleScript") then
				local ok, value = pcall(require, dataModule)
				if ok and type(value) == "table" and type(value.Lvl) == "table" and type(value.Cost) == "table" and type(value.Cooldown) == "table" and type(value.Cap) == "number" then
					entry.Data = value
				end
			end
			return entry
		end

		if extra then
			for name, count in pairs(extra.Fruits) do
				if type(count) == "number" and count > 0 and not seen[name] then
					seen[name] = true
					table.insert(result, build(name))
				end
			end
		end
		for _, name in ipairs(Config.GrantedFruits) do
			if not seen[name] then
				seen[name] = true
				table.insert(result, build(name))
			end
		end
		local equipped = ServerData.Get(player, "DevilFruit")
		if type(equipped) == "string" and equipped ~= "" and not seen[equipped] then
			seen[equipped] = true
			table.insert(result, build(equipped))
		end
		return result
	end, { rate = 10, burst = 20 })

	Router.remote("GetSetting", function(player, name, prop)
		return ServerData.GetSetting(player, name, prop)
	end, { rate = 10, burst = 20 })

	Router.remote("ChangeSetting", function(player, name, value)
		ServerData.ChangeSetting(player, name, value)
	end, { rate = 5, burst = 10 })

	Router.remote("Location", function(player, region)
		local tag = player:FindFirstChild("LocationTag")
		if not tag or not tag:IsA("ObjectValue") then
			return
		end
		if region == nil then
			tag.Value = nil
			player:SetAttribute("CurrentLocation", "")
			player:SetAttribute("ExactLocation", "")
			return
		end
		if typeof(region) ~= "Instance" or not region:IsA("BasePart") then
			return
		end
		local origin = workspace:FindFirstChild("_WorldOrigin")
		local regions = origin and origin:FindFirstChild("EnemyRegions")
		if not regions or region.Parent ~= regions then
			return
		end
		local root = Util.getRoot(player)
		if not root then
			return
		end
		local mesh = region:FindFirstChild("Mesh")
		local radius = region.Size.X / 2
		if mesh and mesh:IsA("SpecialMesh") then
			radius = region.Size.X * mesh.Scale.X / 2
		end
		if (root.Position - region.Position).Magnitude > radius + 100 then
			return
		end
		tag.Value = region
		player:SetAttribute("CurrentLocation", region.Name)
		player:SetAttribute("ExactLocation", region:GetAttribute("ExactLocation") or region.Name)
	end, { rate = 2, burst = 4 })

	Router.commE("Dodge", function(player, _, cost, _, stamp)
		local state = ServerData.GetCharacterState(player)
		if not state or not Util.isAlive(player) then
			return
		end
		if state.busy.Value or state.stun.Value > 0 then
			return
		end
		if not Util.isNumber(cost) or not Util.isNumber(stamp) then
			return
		end
		if math.abs(workspace:GetServerTimeNow() - stamp) > 5 then
			return
		end
		local now = os.clock()
		if now - state.lastDodge < Config.DodgeCooldown then
			return
		end
		cost = Util.clamp(cost, Config.DodgeCostMin, Config.DodgeCostMax)
		if ServerData.SpendEnergy(player, cost) then
			state.lastDodge = now
		end
	end)

	Router.commE("DoubleJump", function(player)
		local state = ServerData.GetCharacterState(player)
		if not state or not Util.isAlive(player) then
			return
		end
		if state.busy.Value or state.stun.Value > 0 then
			return
		end
		local now = os.clock()
		if now - state.lastJump < Config.DoubleJumpCooldown then
			return
		end
		local race = ServerData.GetValueObject(player, "Race")
		local evolved = race ~= nil and race:FindFirstChild("Evolved") ~= nil
		local cost = evolved and Config.DoubleJumpCostEvolved or Config.DoubleJumpCost
		if ServerData.SpendEnergy(player, cost) then
			state.lastJump = now
		end
	end)

	Router.commF("getFish", function(player)
		local extra = ServerData.GetExtra(player)
		return extra and table.clone(extra.Fish) or {}
	end, { rate = 10, burst = 20 })

	Router.commF("getTitles", function(player)
		local extra = ServerData.GetExtra(player)
		local result = {}
		if extra then
			for name, owned in pairs(extra.Titles) do
				if owned then
					table.insert(result, { Name = name })
				end
			end
			table.sort(result, function(a, b)
				return a.Name < b.Name
			end)
		end
		return result
	end, { rate = 10, burst = 20 })

	Router.commF("GetUnlockables", function(player)
		local extra = ServerData.GetExtra(player)
		return extra and table.clone(extra.Unlockables) or {}
	end, { rate = 10, burst = 20 })

	local fruitDataCache = nil

	Router.remote("GetFruitData", function(player)
		if fruitDataCache then
			return fruitDataCache
		end
		local items = ServerStorage:FindFirstChild("Items")
		if not items then
			error("bad folder")
		end
		local TableUtil = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TableUtil"))
		local result = {}
		for _, tool in ipairs(items:GetChildren()) do
			if tool:IsA("Tool") and tool.ToolTip == "Blox Fruit" then
				local dataModule = tool:FindFirstChild("Data")
				if dataModule and dataModule:IsA("ModuleScript") then
					local data = TableUtil.deepCopy(require(dataModule))
					TableUtil.deepFreeze(data)
					result[tool.Name] = data
				end
			end
		end
		table.freeze(result)
		fruitDataCache = result
		return result
	end, { className = "RemoteFunction", requireData = false, rate = 2, burst = 4 })
end
