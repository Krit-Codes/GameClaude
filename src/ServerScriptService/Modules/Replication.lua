-- Single place that pushes a player's current state out to their leaderstats
-- and their client UI, so every remote handler reports state the same way.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyUtil = require(script.Parent.EconomyUtil)
local NumberFormat = require(ReplicatedStorage.Modules.NumberFormat)

local Replication = {}

function Replication.PushUpdate(player, state)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local rebirthsStat = leaderstats:FindFirstChild("Rebirths")
		local cashStat = leaderstats:FindFirstChild("Cash")
		if rebirthsStat then
			rebirthsStat.Value = state.Rebirths
		end
		if cashStat then
			cashStat.Value = "$" .. NumberFormat.Format(state.Money)
		end
	end

	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	remotes.DataUpdateEvent:FireClient(player, {
		Money = state.Money,
		MoneyFormatted = NumberFormat.Format(state.Money),
		Rebirths = state.Rebirths,
		Upgrades = state.Upgrades,
		Multiplier = EconomyUtil.GetRebirthMultiplier(state.Rebirths),
		ClickValue = EconomyUtil.GetClickValue(state),
		IncomePerSecond = EconomyUtil.GetIncomePerSecond(state),
		RebirthsAvailable = EconomyUtil.GetRebirthsForMoney(state.Money),
	})
end

return Replication
