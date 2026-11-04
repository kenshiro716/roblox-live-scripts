local Teams = game:GetService("Teams")
local ServerStorage = game:GetService("ServerStorage")

local Server = script.Parent
local Config = require(Server.Config)
local ServerData = require(Server.ServerData)
local ServerSignals = require(ServerStorage.ServerSignals)

local TeamService = {}

function TeamService.IsValidTeam(teamName)
	return type(teamName) == "string" and Config.Teams[teamName] == true and Teams:FindFirstChild(teamName) ~= nil
end

function TeamService.Get(player)
	return player.Team and player.Team.Name or nil
end

function TeamService.GetCounts()
	local counts = {}
	for teamName in pairs(Config.Teams) do
		local team = Teams:FindFirstChild(teamName)
		counts[teamName] = team and #team:GetPlayers() or 0
	end
	return counts
end

function TeamService.AreAllies(first, second)
	return first ~= nil and second ~= nil and first.Team ~= nil and first.Team == second.Team
end

function TeamService.GetLastTeam(player)
	local extra = ServerData.GetExtra(player)
	local last = extra and extra.Flags.LastTeam
	if TeamService.IsValidTeam(last) then
		return last
	end
	return nil
end

TeamService.RESULT_OK = 0
TeamService.RESULT_IN_COMBAT = 1
TeamService.RESULT_INVALID = 2

function TeamService.Join(player, teamName)
	if not TeamService.IsValidTeam(teamName) then
		return TeamService.RESULT_INVALID
	end
	local previous = TeamService.Get(player)
	local alive = ServerData.GetCharacterState(player) ~= nil
	local joined = false
	if alive then
		local character = player.Character
		if character and character:GetAttribute("InCombat") == true then
			return TeamService.RESULT_IN_COMBAT
		end
		if previous == teamName then
			return TeamService.RESULT_OK
		end
		joined = ServerData.ChangeTeam(player, teamName)
	else
		joined = ServerData.SetTeam(player, teamName)
	end
	if not joined then
		return TeamService.RESULT_INVALID
	end
	local extra = ServerData.GetExtra(player)
	if extra then
		extra.Flags.LastTeam = teamName
	end
	ServerSignals.Get("TeamChanged"):Fire(player, teamName, previous)
	return TeamService.RESULT_OK
end

return TeamService
