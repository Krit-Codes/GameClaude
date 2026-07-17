-- LocalScript: StarterPlayer.StarterPlayerScripts.03_CutsceneController
-- Takes camera control, tweens through waypoints, shows letterbox bars
-- and a typewriter dialogue box, then hands control back to the player.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = playerGui:WaitForChild("EchoboundUI")
local barTop = screenGui.BarTop
local barBottom = screenGui.BarBottom
local dialogueBox = screenGui.DialogueBox
local speakerLabel = dialogueBox.SpeakerName
local dialogueLabel = dialogueBox.DialogueText

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local playCutsceneEvent = remotes:WaitForChild("PlayCutscene")

local camera = Workspace.CurrentCamera

local function typewrite(label, text, duration)
	label.Text = ""
	local length = #text
	if length == 0 then
		return
	end
	local perChar = duration / length
	for i = 1, length do
		label.Text = string.sub(text, 1, i)
		task.wait(perChar)
	end
end

local function setControlEnabled(enabled)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	if enabled then
		humanoid.WalkSpeed = 16
		humanoid.JumpPower = 50
		humanoid.AutoRotate = true
	else
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.AutoRotate = false
	end
end

local function playCutscene(data)
	if typeof(data) ~= "table" or typeof(data.waypoints) ~= "table" or #data.waypoints == 0 then
		return
	end

	setControlEnabled(false)
	camera.CameraType = Enum.CameraType.Scriptable

	TweenService:Create(barTop, TweenInfo.new(0.4), { Size = UDim2.new(1, 0, 0, 60) }):Play()
	TweenService:Create(barBottom, TweenInfo.new(0.4), { Size = UDim2.new(1, 0, 0, 60) }):Play()
	task.wait(0.4)

	camera.CFrame = data.waypoints[1].cf

	for _, wp in ipairs(data.waypoints) do
		local segmentTime = wp.time or 2
		local tween = TweenService:Create(camera, TweenInfo.new(segmentTime, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			CFrame = wp.cf,
		})

		if wp.text and wp.text ~= "" then
			dialogueBox.Visible = true
			speakerLabel.Text = wp.speaker or ""
			tween:Play()
			local typeDuration = math.min(segmentTime * 0.7, 2.2)
			typewrite(dialogueLabel, wp.text, typeDuration)
			local remaining = segmentTime - typeDuration
			if remaining > 0 then
				task.wait(remaining)
			end
			dialogueBox.Visible = false
		else
			tween:Play()
			tween.Completed:Wait()
		end
	end

	TweenService:Create(barTop, TweenInfo.new(0.4), { Size = UDim2.new(1, 0, 0, 0) }):Play()
	TweenService:Create(barBottom, TweenInfo.new(0.4), { Size = UDim2.new(1, 0, 0, 0) }):Play()
	task.wait(0.4)

	camera.CameraType = Enum.CameraType.Custom
	local character = player.Character
	camera.CameraSubject = character and character:FindFirstChildOfClass("Humanoid")
	setControlEnabled(true)
end

playCutsceneEvent.OnClientEvent:Connect(function(data)
	task.spawn(playCutscene, data)
end)

print("[Echobound] Cutscene controller ready.")
