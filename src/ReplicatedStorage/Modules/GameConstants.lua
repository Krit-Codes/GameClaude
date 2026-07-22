-- Shared tuning values for both server and client.
return {
	BASE_CLICK_VALUE = 1, -- $ earned per click before upgrades/multiplier

	CLICK_RATE_LIMIT = 0.05, -- min seconds between accepted clicks (anti-exploit, ~20/sec)
	INCOME_TICK_SECONDS = 1, -- how often passive income is paid out

	REBIRTH_MONEY_PER_REBIRTH = 1000, -- $ per rebirth: rebirths gained = floor(Money / this)
	REBIRTH_MONEY_MULT_PER_REBIRTH = 0.1, -- +10% permanent money multiplier per rebirth

	AUTOSAVE_INTERVAL = 60, -- seconds between background autosaves

	DATASTORE_NAME = "RebirthSimulator_PlayerData_v1",
}
