-- Script: ServerScriptService.07_NarrativeCutscenes
-- Plays a short establishing cutscene the first time each player spawns.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local playCutsceneEvent = remotes:WaitForChild("PlayCutscene")

local introShown = {}

local function playIntro(player)
	if introShown[player] then
		return
	end
	introShown[player] = true

	local character = player.Character
	if not character then
		return
	end
	local root = character:WaitForChild("HumanoidRootPart", 5)
	if not root then
		return
	end

	local basePos = root.Position

	local data = {
		waypoints = {
			{ cf = CFrame.new(basePos + Vector3.new(0, 25, 0), basePos), time = 3, speaker = "", text = "The Fracture: a memory that broke instead of fading." },
			{ cf = CFrame.new(basePos + Vector3.new(20, 8, 20), basePos), time = 3, speaker = "", text = "You are a Warden of Echoes. You can record your own actions..." },
			{ cf = CFrame.new(basePos + Vector3.new(-15, 6, 10), basePos), time = 3, speaker = "", text = "...and leave them behind as loops of light, to hold what you cannot hold alone." },
		},
	}

	playCutsceneEvent:FireClient(player, data)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.wait(1)
		playIntro(player)
	end)
end)

for _, player in ipairs(Players:GetPlayers()) do
	if player.Character then
		task.wait(1)
		playIntro(player)
	end
end

print("[Echobound] Narrative cutscenes online.")
