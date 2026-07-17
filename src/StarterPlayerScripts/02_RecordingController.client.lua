-- LocalScript: StarterPlayer.StarterPlayerScripts.02_RecordingController
-- R: toggle recording a movement loop. X: dismiss your Echoes.
-- F: unleash a Color Pulse (only relevant during the boss fight).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local EchoConstants = require(ReplicatedStorage.Modules.EchoConstants)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = playerGui:WaitForChild("EchoboundUI")
local memoryFill = screenGui.HUD.MemoryContainer.Back.MemoryFill
local echoLabel = screenGui.HUD.EchoCountLabel
local notifyLabel = screenGui.NotifyText

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local recordStopEvent = remotes:WaitForChild("RecordStop")
local dismissEvent = remotes:WaitForChild("DismissEchoes")
local notifyEvent = remotes:WaitForChild("Notify")
local echoHudEvent = remotes:WaitForChild("EchoHUD")
local colorPulseEvent = remotes:WaitForChild("ColorPulseRequest")

local isRecording = false
local frames = {}
local recordElapsed = 0
local memoryFraction = 1
local recordingVfx = nil
local lastSampleT = 0

local function getCharacter()
	return player.Character
end

local function updateMemoryBar()
	memoryFill.Size = UDim2.new(math.clamp(memoryFraction, 0, 1), 0, 1, 0)
	memoryFill.BackgroundColor3 = memoryFraction < 0.3 and Color3.fromRGB(220, 90, 90) or Color3.fromRGB(120, 170, 220)
end

local function startRecordingVfx()
	local character = getCharacter()
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "RecordingVfx"
	emitter.Color = ColorSequence.new(Color3.fromRGB(140, 190, 255))
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Lifetime = NumberRange.new(0.4, 0.6)
	emitter.Rate = 40
	emitter.Speed = NumberRange.new(2, 4)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Parent = root
	recordingVfx = emitter
end

local function stopRecordingVfx()
	if recordingVfx then
		recordingVfx:Destroy()
		recordingVfx = nil
	end
end

local function beginRecording()
	if memoryFraction <= 0.05 then
		return
	end
	local character = getCharacter()
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	isRecording = true
	frames = { { t = 0, cf = root.CFrame } }
	recordElapsed = 0
	lastSampleT = 0
	startRecordingVfx()
end

local function endRecording()
	if not isRecording then
		return
	end
	isRecording = false
	stopRecordingVfx()

	if #frames >= 2 then
		recordStopEvent:FireServer(frames, recordElapsed)
	end
	frames = {}
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.R then
		if isRecording then
			endRecording()
		else
			beginRecording()
		end
	elseif input.KeyCode == Enum.KeyCode.X then
		dismissEvent:FireServer()
	elseif input.KeyCode == Enum.KeyCode.F then
		colorPulseEvent:FireServer()
	end
end)

RunService.Heartbeat:Connect(function(dt)
	if isRecording then
		recordElapsed += dt
		memoryFraction = math.clamp(memoryFraction - dt / EchoConstants.RECORD_MAX_SECONDS, 0, 1)

		local character = getCharacter()
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and recordElapsed - lastSampleT >= EchoConstants.SAMPLE_INTERVAL then
			lastSampleT = recordElapsed
			table.insert(frames, { t = recordElapsed, cf = root.CFrame })
		end

		if recordElapsed >= EchoConstants.RECORD_MAX_SECONDS or memoryFraction <= 0 then
			endRecording()
		end
	else
		memoryFraction = math.clamp(memoryFraction + dt / EchoConstants.RECORD_RECHARGE_SECONDS, 0, 1)
	end
	updateMemoryBar()
end)

echoHudEvent.OnClientEvent:Connect(function(count, max)
	echoLabel.Text = string.format("Echoes: %d / %d", count, max)
end)

notifyEvent.OnClientEvent:Connect(function(text, duration)
	notifyLabel.Text = text
	notifyLabel.TextTransparency = 0
	TweenService:Create(notifyLabel, TweenInfo.new(duration or 3), { TextTransparency = 1 }):Play()
end)

print("[Echobound] Recording controller ready.")
