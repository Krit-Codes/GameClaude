-- Script. Handles admin-only commands typed into the admin panel:
-- /announce <message>, /<amount> click <player>, /<amount> coins <player>,
-- /0gravity, /gamepassgive <name> <player>.
--
-- Security: the Player argument on OnServerEvent is provided by Roblox
-- itself and cannot be spoofed by the client, so checking player.Name here
-- is authoritative even though the admin panel GUI exists in every client.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local AdminConstants = require(ReplicatedStorage.Modules.AdminConstants)
local PlayerState = require(ServerScriptService.Modules.PlayerState)

local clickerRemotes = ReplicatedStorage:WaitForChild("ClickerRemotes")

local adminRemotesFolder = Instance.new("Folder")
adminRemotesFolder.Name = "AdminRemotes"
adminRemotesFolder.Parent = ReplicatedStorage

local adminCommandRemote = Instance.new("RemoteEvent")
adminCommandRemote.Name = "AdminCommand"
adminCommandRemote.Parent = adminRemotesFolder

local announcementRemote = Instance.new("RemoteEvent")
announcementRemote.Name = "Announcement"
announcementRemote.Parent = adminRemotesFolder

local isAdminFunction = Instance.new("RemoteFunction")
isAdminFunction.Name = "IsAdmin"
isAdminFunction.Parent = adminRemotesFolder

isAdminFunction.OnServerInvoke = function(player)
	return player.Name == AdminConstants.ADMIN_USERNAME
end

local function findPlayerByName(name)
	if not name then
		return nil
	end
	local lowerName = name:lower()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Name:lower() == lowerName then
			return plr
		end
	end
	return nil
end

local function pushStats(targetPlayer)
	local state = PlayerState.Get(targetPlayer)
	if not state then
		return
	end
	PlayerState.SyncLeaderstats(targetPlayer, state)
	clickerRemotes.StatsUpdate:FireClient(targetPlayer, PlayerState.BuildPayload(state))
end

local function handleAnnounce(parts)
	local message = table.concat(parts, " ", 2)
	if message == "" then
		return
	end
	announcementRemote:FireAllClients(message)
end

local function handleGrantAmount(kind, amount, targetName)
	local targetPlayer = findPlayerByName(targetName)
	if not targetPlayer then
		return
	end

	local state = PlayerState.Get(targetPlayer)
	if not state then
		return
	end

	if kind == "click" then
		state.Clicks += amount
	elseif kind == "coins" then
		state.Money += amount
	else
		return
	end

	pushStats(targetPlayer)
end

local function handleZeroGravity()
	if Workspace.Gravity == 0 then
		Workspace.Gravity = AdminConstants.DEFAULT_GRAVITY
	else
		Workspace.Gravity = 0
	end
end

local function handleGamepassGive(gamepassName, targetName)
	if not gamepassName then
		return
	end

	local targetPlayer = findPlayerByName(targetName)
	if not targetPlayer then
		return
	end

	local amount = AdminConstants.GAMEPASS_GRANTS[gamepassName:lower()]
	if not amount then
		return
	end

	local state = PlayerState.Get(targetPlayer)
	if not state then
		return
	end

	state.UpgradeLevel += amount
	PlayerState.RecomputeClickPower(targetPlayer)
	pushStats(targetPlayer)
end

adminCommandRemote.OnServerEvent:Connect(function(player, rawText)
	if player.Name ~= AdminConstants.ADMIN_USERNAME then
		warn("[Admin] Rejected command from non-admin: " .. player.Name)
		return
	end

	if type(rawText) ~= "string" or rawText:sub(1, 1) ~= "/" then
		return
	end

	local parts = rawText:sub(2):split(" ")
	local commandWord = parts[1]
	if not commandWord then
		return
	end

	if commandWord == "announce" then
		handleAnnounce(parts)
	elseif commandWord == "0gravity" then
		handleZeroGravity()
	elseif commandWord == "gamepassgive" then
		handleGamepassGive(parts[2], parts[3])
	elseif tonumber(commandWord) then
		handleGrantAmount(parts[2], tonumber(commandWord), parts[3])
	end
end)
