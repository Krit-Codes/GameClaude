-- Script: ServerScriptService.09_WalkSpeedBooster
-- Gives every player a faster WalkSpeed the moment their character spawns.
-- Default Roblox WalkSpeed is 16 -- raise/lower WALK_SPEED to taste.

local Players = game:GetService("Players")

local WALK_SPEED = 32

local function onCharacterAdded(character)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.WalkSpeed = WALK_SPEED
end

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		onCharacterAdded(player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

print("[Echobound] WalkSpeed Booster active -- players move at " .. WALK_SPEED .. " studs/sec.")
