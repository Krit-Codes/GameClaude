-- Handles upgrade purchases. Cost and validity are always recomputed
-- server-side from the player's real state, never trusted from the client.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local EconomyUtil = require(ServerScriptService.Modules.EconomyUtil)
local PlayerDataStore = require(ServerScriptService.Modules.PlayerDataStore)
local Replication = require(ServerScriptService.Modules.Replication)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local buyUpgradeEvent = remotes:WaitForChild("BuyUpgradeEvent")

buyUpgradeEvent.OnServerEvent:Connect(function(player, upgradeId)
	if typeof(upgradeId) ~= "string" then
		return
	end

	local state = PlayerDataStore.Get(player)
	if not state then
		return
	end

	local upgrade = EconomyUtil.GetUpgradeById(upgradeId)
	if not upgrade then
		return
	end

	local level = state.Upgrades[upgradeId] or 0
	local cost = EconomyUtil.GetUpgradeCost(upgrade, level)

	if state.Money < cost then
		return
	end

	state.Money -= cost
	state.Upgrades[upgradeId] = level + 1
	Replication.PushUpdate(player, state)
end)
