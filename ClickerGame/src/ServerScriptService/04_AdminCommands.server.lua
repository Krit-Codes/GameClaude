-- Script. Handles admin-only commands typed into the admin panel:
-- /announce <message>, /<amount> click <player>, /<amount> coins <player>,
-- /<amount> speed <player>, /<amount> jump <player>, /lowgravity,
-- /gamepassgive <name> <player>, /kick <player> [reason], /kill <player>,
-- /heal <player>, /rebirth <player>, /reset <player>, /save <player>,
-- /music on|off.
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

local forceMusicRemote = Instance.new("RemoteEvent")
forceMusicRemote.Name = "ForceMusic"
forceMusicRemote.Parent = adminRemotesFolder

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

local function getHumanoid(targetPlayer)
	local character = targetPlayer.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function handleSetHumanoidStat(targetName, statName, value)
	local targetPlayer = findPlayerByName(targetName)
	if not targetPlayer then
		return
	end
	local humanoid = getHumanoid(targetPlayer)
	if humanoid then
		humanoid[statName] = value
	end
end

local function handleKick(targetName, reason)
	local targetPlayer = findPlayerByName(targetName)
	if not targetPlayer then
		return
	end
	targetPlayer:Kick(reason ~= "" and reason or "Kicked by admin")
end

local function handleKill(targetName)
	local targetPlayer = findPlayerByName(targetName)
	if not targetPlayer then
		return
	end
	local humanoid = getHumanoid(targetPlayer)
	if humanoid then
		humanoid.Health = 0
	end
end

local function handleHeal(targetName)
	local targetPlayer = findPlayerByName(targetName)
	if not targetPlayer then
		return
	end
	local humanoid = getHumanoid(targetPlayer)
	if humanoid then
		humanoid.Health = humanoid.MaxHealth
	end
end

local function handleForceRebirth(targetName)
	local targetPlayer = findPlayerByName(targetName)
	if not targetPlayer then
		return
	end
	local state = PlayerState.Get(targetPlayer)
	if not state then
		return
	end
	state.Rebirths += 1
	state.Clicks = 0
	state.Money = 0
	state.UpgradeLevel = 0
	PlayerState.RecomputeClickPower(targetPlayer)
	pushStats(targetPlayer)
end

local function handleReset(targetName)
	local targetPlayer = findPlayerByName(targetName)
	if not targetPlayer then
		return
	end
	local state = PlayerState.Get(targetPlayer)
	if not state then
		return
	end
	state.Clicks = 0
	state.Money = 0
	state.UpgradeLevel = 0
	state.Rebirths = 0
	PlayerState.RecomputeClickPower(targetPlayer)
	pushStats(targetPlayer)
end

local function handleSave(targetName)
	local targetPlayer = findPlayerByName(targetName)
	if not targetPlayer then
		return
	end
	PlayerState.Save(targetPlayer)
end

local function handleMusic(state)
	if state == "on" then
		forceMusicRemote:FireAllClients(true)
	elseif state == "off" then
		forceMusicRemote:FireAllClients(false)
	end
end

local function handleLowGravity()
	if Workspace.Gravity == AdminConstants.LOW_GRAVITY then
		Workspace.Gravity = AdminConstants.DEFAULT_GRAVITY
	else
		Workspace.Gravity = AdminConstants.LOW_GRAVITY
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
	elseif commandWord == "lowgravity" then
		handleLowGravity()
	elseif commandWord == "gamepassgive" then
		handleGamepassGive(parts[2], parts[3])
	elseif commandWord == "kick" then
		handleKick(parts[2], table.concat(parts, " ", 3))
	elseif commandWord == "kill" then
		handleKill(parts[2])
	elseif commandWord == "heal" then
		handleHeal(parts[2])
	elseif commandWord == "rebirth" then
		handleForceRebirth(parts[2])
	elseif commandWord == "reset" then
		handleReset(parts[2])
	elseif commandWord == "save" then
		handleSave(parts[2])
	elseif commandWord == "music" then
		handleMusic(parts[2])
	elseif tonumber(commandWord) then
		local amount = tonumber(commandWord)
		local kind = parts[2]
		if kind == "click" or kind == "coins" then
			handleGrantAmount(kind, amount, parts[3])
		elseif kind == "speed" then
			handleSetHumanoidStat(parts[3], "WalkSpeed", amount)
		elseif kind == "jump" then
			handleSetHumanoidStat(parts[3], "JumpPower", amount)
		end
	end
end)
