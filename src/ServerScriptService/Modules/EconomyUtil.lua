-- Pure economy math: upgrade costs, income totals, click value, and the
-- rebirth-count/multiplier formulas. No state is stored here, only formulas,
-- so both the tick loop and the remote handlers can share one source of truth.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConstants = require(ReplicatedStorage.Modules.GameConstants)
local UpgradeConfig = require(ReplicatedStorage.Modules.UpgradeConfig)

local EconomyUtil = {}

function EconomyUtil.GetUpgradeById(id)
	for _, upgrade in ipairs(UpgradeConfig) do
		if upgrade.Id == id then
			return upgrade
		end
	end
	return nil
end

function EconomyUtil.GetUpgradeCost(upgrade, level)
	return math.floor(upgrade.BaseCost * (upgrade.CostGrowth ^ level))
end

function EconomyUtil.GetRebirthMultiplier(rebirths)
	return 1 + (rebirths * GameConstants.REBIRTH_MONEY_MULT_PER_REBIRTH)
end

function EconomyUtil.GetRebirthsForMoney(money)
	return math.floor(money / GameConstants.REBIRTH_MONEY_PER_REBIRTH)
end

function EconomyUtil.GetClickValue(state)
	local base = GameConstants.BASE_CLICK_VALUE
	for _, upgrade in ipairs(UpgradeConfig) do
		if upgrade.Type == "Click" then
			local level = state.Upgrades[upgrade.Id] or 0
			base += level * upgrade.Effect
		end
	end
	return base * EconomyUtil.GetRebirthMultiplier(state.Rebirths)
end

function EconomyUtil.GetIncomePerSecond(state)
	local total = 0
	for _, upgrade in ipairs(UpgradeConfig) do
		if upgrade.Type == "Income" then
			local level = state.Upgrades[upgrade.Id] or 0
			total += level * upgrade.Effect
		end
	end
	return total * EconomyUtil.GetRebirthMultiplier(state.Rebirths)
end

return EconomyUtil
