local ClickerConstants = {}

ClickerConstants.BASE_CLICK_POWER = 1

-- Repeatable "Click Power" upgrade, bought with Money.
-- Cost grows linearly: level N costs UPGRADE_BASE_COST + UPGRADE_COST_STEP * N.
ClickerConstants.UPGRADE_BASE_COST = 10
ClickerConstants.UPGRADE_COST_STEP = 34 -- +34 coins per level bought
ClickerConstants.UPGRADE_POWER_INCREMENT = 0.34 -- +0.34 click power per level bought

-- Rebirth
ClickerConstants.REBIRTH_MONEY_DIVISOR = 1000 -- Money / this = Rebirths gained
ClickerConstants.REBIRTH_FLAT_CLICK_BONUS = 1 -- +1 click power per Rebirth
ClickerConstants.REBIRTH_MULTIPLIER_PER_REBIRTH = 2 -- 2x click power per Rebirth

-- Basic anti-exploit throttle for the click remote
ClickerConstants.MIN_CLICK_INTERVAL = 0.05 -- seconds, ~20 clicks/sec cap

-- Whitelisted fractions for partial-sell (Sell 10%/25%/50%/100% buttons).
-- The server only accepts one of these exact values from SellRequest.
ClickerConstants.SELL_PERCENT_OPTIONS = { 0.10, 0.25, 0.50, 1.00 }

-- Hard safety cap on how many levels a single "Max" upgrade purchase can
-- loop through, so a bugged/exploited request can't hang the server.
ClickerConstants.MAX_UPGRADE_PURCHASE_SAFETY_CAP = 100000

-- Game Passes that instantly grant upgrade levels for Robux (one-time per
-- player). Replace these placeholder IDs with your real Game Pass IDs from
-- the Creator Dashboard. Keyed by how many upgrade levels the pass grants.
ClickerConstants.UPGRADE_GAME_PASS_IDS = {
	[1] = 0,  -- Upgrade1Robux -- replace with your real Game Pass ID
	[5] = 0,  -- Upgrade5Robux -- replace with your real Game Pass ID
	[10] = 0, -- Upgrade10Robux -- replace with your real Game Pass ID
}

return ClickerConstants
