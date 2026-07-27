local ClickerConstants = {}

ClickerConstants.BASE_CLICK_POWER = 1

-- Repeatable "Click Power" upgrade, bought with Money
ClickerConstants.UPGRADE_BASE_COST = 10
ClickerConstants.UPGRADE_COST_MULTIPLIER = 1.15
ClickerConstants.UPGRADE_POWER_INCREMENT = 1

-- Rebirth
ClickerConstants.REBIRTH_MONEY_DIVISOR = 1000 -- Money / this = Rebirths gained
ClickerConstants.REBIRTH_FLAT_CLICK_BONUS = 1 -- +1 click power per Rebirth
ClickerConstants.REBIRTH_MULTIPLIER_PER_REBIRTH = 2 -- 2x click power per Rebirth

-- Basic anti-exploit throttle for the click remote
ClickerConstants.MIN_CLICK_INTERVAL = 0.05 -- seconds, ~20 clicks/sec cap

return ClickerConstants
