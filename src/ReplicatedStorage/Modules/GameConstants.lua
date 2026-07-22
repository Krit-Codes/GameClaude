-- Shared tuning values for both server and client.
return {
	BASE_CLICK_VALUE = 1, -- $ earned per click before upgrades/multiplier

	CLICK_RATE_LIMIT = 0.05, -- min seconds between accepted clicks (anti-exploit, ~20/sec)
	INCOME_TICK_SECONDS = 1, -- how often passive income is paid out

	REBIRTH_BASE_COST = 1000, -- cost of the 1st rebirth
	REBIRTH_COST_GROWTH = 1.5, -- each subsequent single rebirth costs 1.5x more
	REBIRTH_MONEY_MULT_PER_REBIRTH = 0.1, -- +10% permanent money multiplier per rebirth

	MASS_REBIRTH_UNLOCK_AMOUNT = 1000000, -- money needed to trigger a Mass Rebirth (spends all of it)
	MASS_REBIRTH_COUNT = 1000, -- rebirths granted instantly by Mass Rebirth

	AUTOSAVE_INTERVAL = 60, -- seconds between background autosaves

	DATASTORE_NAME = "RebirthSimulator_PlayerData_v1",
}
