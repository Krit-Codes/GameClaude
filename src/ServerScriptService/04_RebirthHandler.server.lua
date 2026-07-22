-- Handles both rebirth paths:
--   RebirthEvent      -- one rebirth at the current (rising) cost
--   MassRebirthEvent  -- once you've saved $1,000,000, spend it for 1000
--                        rebirths at once -- the big addictive milestone payoff
-- Both reset Money and Upgrades and grant a permanent money multiplier via
-- the Rebirths counter (see EconomyUtil.GetRebirthMultiplier).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConstants = require(ReplicatedStorage.Modules.GameConstants)
local EconomyUtil = require(ServerScriptService.Modules.EconomyUtil)
local PlayerDataStore = require(ServerScriptService.Modules.PlayerDataStore)
local Replication = require(ServerScriptService.Modules.Replication)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local rebirthEvent = remotes:WaitForChild("RebirthEvent")
local massRebirthEvent = remotes:WaitForChild("MassRebirthEvent")

local function resetProgress(state)
	state.Money = 0
	state.Upgrades = {}
end

rebirthEvent.OnServerEvent:Connect(function(player)
	local state = PlayerDataStore.Get(player)
	if not state then
		return
	end

	local cost = EconomyUtil.GetRebirthCost(state.Rebirths)
	if state.Money < cost then
		return
	end

	resetProgress(state)
	state.Rebirths += 1
	Replication.PushUpdate(player, state)
end)

massRebirthEvent.OnServerEvent:Connect(function(player)
	local state = PlayerDataStore.Get(player)
	if not state then
		return
	end

	if state.Money < GameConstants.MASS_REBIRTH_UNLOCK_AMOUNT then
		return
	end

	resetProgress(state)
	state.Rebirths += GameConstants.MASS_REBIRTH_COUNT
	Replication.PushUpdate(player, state)
end)
