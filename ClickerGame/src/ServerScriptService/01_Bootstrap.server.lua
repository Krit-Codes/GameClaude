-- Script. Creates the RemoteEvents the clicker system runs on, and wires
-- up per-player load/save + leaderstats.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerState = require(ServerScriptService.Modules.PlayerState)

local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "ClickerRemotes"
remotesFolder.Parent = ReplicatedStorage

local function createRemote(name)
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotesFolder
	return remote
end

createRemote("ClickRequest")
createRemote("SellRequest")
createRemote("BuyUpgradeRequest")
createRemote("RebirthRequest")
createRemote("StatsUpdate")

Players.PlayerAdded:Connect(function(player)
	PlayerState.SetupLeaderstats(player)

	local state = PlayerState.Load(player)
	PlayerState.SyncLeaderstats(player, state)

	remotesFolder.StatsUpdate:FireClient(player, PlayerState.BuildPayload(state))
end)

Players.PlayerRemoving:Connect(function(player)
	PlayerState.Release(player)
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		PlayerState.Save(player)
	end
end)
