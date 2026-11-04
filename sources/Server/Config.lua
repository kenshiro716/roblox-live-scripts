local ServerStorage = game:GetService("ServerStorage")

local Config = {}

local keys = ServerStorage:FindFirstChild("DatastoreKeys")
local playersKey = keys and keys:FindFirstChild("tblPlayers")

Config.DataStoreName = playersKey and playersKey.Value or "PlayerData_V1"
Config.AutoSaveInterval = 90
Config.SaveRetries = 5
Config.LockTimeout = 180
Config.GameVersion = "1.0.0"

Config.TemplateHostName = "ServerData"
Config.TemplateFolderName = "TemplateData"
Config.CloneHostGuis = true
Config.TeamSelectGuiName = "Main (minimal)"
Config.PersistedRoots = { "Data", "leaderstats" }

Config.Teams = { Pirates = true, Marines = true }
Config.StatNames = { "Melee", "Defense", "Sword", "Gun", "Demon Fruit" }
Config.StatCap = 2800
Config.MaxLevel = 2800
Config.PointsPerLevel = 3

Config.DefaultSpawnName = "Default"
Config.SpawnHeightOffset = 3
Config.SpawnPointMaxDistance = 1500
Config.RespawnDelay = 5
Config.HomeTeleportDelay = 5
Config.HomeTeleportCooldown = 30

Config.BaseHealth = 100
Config.HealthPerLevel = 4
Config.HealthPerDefense = 2.5
Config.BaseEnergy = 100
Config.EnergyPerDefense = 0.5
Config.EnergyRegenPerSecond = 4

Config.DodgeCostMin = 10
Config.DodgeCostMax = 100
Config.DodgeCooldown = 0.35
Config.DoubleJumpCost = 30
Config.DoubleJumpCostEvolved = 10
Config.DoubleJumpCooldown = 0.25

Config.PlayerAttributes = {
	PvpDisabled = true,
	LoadComplete = true,
	InSafeZone = false,
	InDangerZone = false,
	DangerLevel = 0,
	HasUnlockedMap = false,
	CurrentLocation = "",
	ExactLocation = "",
}

Config.CharacterAttributes = {
	AllCooldown = 0,
	BusoEnabled = false,
	DashLength = 1,
	DashLengthAir = 1,
	DashLengthGround = 1,
	DashSpeed = 1,
	DodgeBoost = 1,
	FlashstepCooldown = 0,
	FruitCooldown = 0,
	GunCooldown = 0,
	Hunger = 1,
	InCombat = false,
	MasterpieceAll = true,
	MeleeCooldown = 0,
	ObservationRange = 999,
	RaceEnergyHold = 15017.928,
	SkyJumpBoost = 1,
	SkyJumpCost = 1,
	SkyJumps = 9999,
	SpeedMultiplier = 1,
	SwordCooldown = 0,
	UnbreakableAll = true,
}

Config.DefaultSettings = {
	MobileSchemeMode = false,
	MobileSkillMode = 1,
}

Config.Limits = {
	CommF_ = { rate = 12, burst = 24 },
	CommE = { rate = 40, burst = 80 },
	NetRF = { rate = 15, burst = 30 },
	NetRE = { rate = 30, burst = 60 },
	Location = { rate = 2, burst = 4 },
}

Config.GrantedFruits = { "Dragon-Dragon" }
Config.CloneAllHostGuis = true

Config.ForcedGroups = {}

Config.Experiments = {
	TeamSelectionV1 = {
		default = "NoChange",
		groups = { NoChange = 100, AutoAssign = 0, PlayButton = 0, PirateButton = 0 },
	},
	FreshieNotifyV1 = {
		default = "Disabled",
		groups = { Disabled = 100, Enabled = 0 },
	},
	CombatEquipV1 = {
		default = "NormalFlow",
		groups = { NormalFlow = 100, StartEquipped = 0 },
	},
	QuestStatesV2 = {
		default = "Normal",
		groups = { Normal = 100, AutoQuestNoRetrack = 0 },
	},
}

return Config
