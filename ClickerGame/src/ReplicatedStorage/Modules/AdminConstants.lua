local AdminConstants = {}

-- Only this exact Roblox username can use admin commands. Usernames CAN be
-- changed by the account holder -- if that ever happens this silently stops
-- matching, so swap to a UserId check instead if that's a concern.
AdminConstants.ADMIN_USERNAME = "blxfruits1232"

AdminConstants.DEFAULT_GRAVITY = 196.2

-- Named grants usable via "/gamepassgive <Name> <Player>" (case-insensitive
-- keys). Each maps to how many upgrade levels to instantly grant. Add more
-- entries here as you add more named passes/rewards.
AdminConstants.GAMEPASS_GRANTS = {
	["upgrade1"] = 1,
	["upgrade5"] = 5,
	["upgrade10"] = 10,
}

return AdminConstants
