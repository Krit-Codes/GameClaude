-- Handles rebirthing. Rebirths gained = floor(Money / REBIRTH_MONEY_PER_REBIRTH),
-- so saving $1,000 gives 1 rebirth, $2,000 gives 2 at once, $1,000,000 gives
-- 1,000 at once -- one button, one formula, and it's always worth saving more
-- before cashing in. Resets Money and Upgrades; grants a permanent money
-- multiplier via the Rebirths counter (see EconomyUtil.GetRebirthMultiplier).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local EconomyUtil = require(ServerScriptService.Modules.EconomyUtil)
local PlayerDataStore = require(ServerScriptService.Modules.PlayerDataStore)
local Replication = require(ServerScriptService.Modules.Replication)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local rebirthEvent = remotes:WaitForChild("RebirthEvent")

rebirthEvent.OnServerEvent:Connect(function(player)
	local state = PlayerDataStore.Get(player)
	if not state then
		return
	end

	local rebirthsGained = EconomyUtil.GetRebirthsForMoney(state.Money)
	if rebirthsGained < 1 then
		return
	end

	state.Money = 0
	state.Upgrades = {}
	state.Rebirths += rebirthsGained
	Replication.PushUpdate(player, state)
end)
