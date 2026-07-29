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

-- Developer Products that instantly grant upgrade levels for Robux.
-- Repeatable -- buying one again grants that many levels again. Keyed by
-- how many upgrade levels each product grants.
ClickerConstants.UPGRADE_PRODUCT_IDS = {
	[1] = 3612208343,  -- Upgrade1Robux
	[5] = 3612208409,  -- Upgrade5Robux
	[10] = 3612208455, -- Upgrade10Robux
}

return ClickerConstants
