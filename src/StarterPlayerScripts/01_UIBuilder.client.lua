-- LocalScript: StarterPlayer.StarterPlayerScripts.01_UIBuilder
-- Builds the entire HUD, boss health bar, cutscene letterbox bars,
-- dialogue box, and screen-flash overlay purely at runtime.

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "EchoboundUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- HUD ------------------------------------------------------------------
local hud = Instance.new("Frame")
hud.Name = "HUD"
hud.Size = UDim2.new(0, 260, 0, 90)
hud.Position = UDim2.new(0, 20, 0, 20)
hud.BackgroundTransparency = 1
hud.Parent = screenGui

local function makeMeter(name, order, color, labelText)
	local container = Instance.new("Frame")
	container.Name = name .. "Container"
	container.Size = UDim2.new(1, 0, 0, 22)
	container.Position = UDim2.new(0, 0, 0, (order - 1) * 30)
	container.BackgroundTransparency = 1
	container.Parent = hud

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, 0, 0, 14)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = labelText
	label.Parent = container

	local back = Instance.new("Frame")
	back.Name = "Back"
	back.Size = UDim2.new(1, 0, 0, 8)
	back.Position = UDim2.new(0, 0, 0, 16)
	back.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	back.BorderSizePixel = 0
	back.Parent = container

	local fill = Instance.new("Frame")
	fill.Name = name .. "Fill"
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.BackgroundColor3 = color
	fill.BorderSizePixel = 0
	fill.Parent = back

	return fill
end

makeMeter("Memory", 1, Color3.fromRGB(120, 170, 220), "Memory (R)")
makeMeter("Color", 2, Color3.fromRGB(220, 160, 90), "Color Restored")

local echoLabel = Instance.new("TextLabel")
echoLabel.Name = "EchoCountLabel"
echoLabel.Size = UDim2.new(1, 0, 0, 20)
echoLabel.Position = UDim2.new(0, 0, 0, 62)
echoLabel.BackgroundTransparency = 1
echoLabel.TextColor3 = Color3.new(1, 1, 1)
echoLabel.TextXAlignment = Enum.TextXAlignment.Left
echoLabel.Font = Enum.Font.GothamBold
echoLabel.TextScaled = true
echoLabel.Text = "Echoes: 0 / 3"
echoLabel.Parent = hud

-- Boss HUD ---------------------------------------------------------------
local bossHud = Instance.new("Frame")
bossHud.Name = "BossHUD"
bossHud.Size = UDim2.new(0, 500, 0, 60)
bossHud.AnchorPoint = Vector2.new(0.5, 0)
bossHud.Position = UDim2.new(0.5, 0, 0, 20)
bossHud.BackgroundTransparency = 1
bossHud.Visible = false
bossHud.Parent = screenGui

local bossName = Instance.new("TextLabel")
bossName.Name = "BossName"
bossName.Size = UDim2.new(1, 0, 0, 24)
bossName.BackgroundTransparency = 1
bossName.TextColor3 = Color3.fromRGB(200, 120, 220)
bossName.Font = Enum.Font.GothamBlack
bossName.TextScaled = true
bossName.Text = "THE HOLLOW"
bossName.Parent = bossHud

local bossBack = Instance.new("Frame")
bossBack.Name = "Back"
bossBack.Size = UDim2.new(1, 0, 0, 18)
bossBack.Position = UDim2.new(0, 0, 0, 28)
bossBack.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
bossBack.BorderSizePixel = 0
bossBack.Parent = bossHud

local bossFill = Instance.new("Frame")
bossFill.Name = "BossHPFill"
bossFill.Size = UDim2.new(1, 0, 1, 0)
bossFill.BackgroundColor3 = Color3.fromRGB(200, 60, 90)
bossFill.BorderSizePixel = 0
bossFill.Parent = bossBack

-- Letterbox bars -----------------------------------------------------------
local barTop = Instance.new("Frame")
barTop.Name = "BarTop"
barTop.Size = UDim2.new(1, 0, 0, 0)
barTop.Position = UDim2.new(0, 0, 0, 0)
barTop.BackgroundColor3 = Color3.new(0, 0, 0)
barTop.BorderSizePixel = 0
barTop.ZIndex = 10
barTop.Parent = screenGui

local barBottom = Instance.new("Frame")
barBottom.Name = "BarBottom"
barBottom.Size = UDim2.new(1, 0, 0, 0)
barBottom.AnchorPoint = Vector2.new(0, 1)
barBottom.Position = UDim2.new(0, 0, 1, 0)
barBottom.BackgroundColor3 = Color3.new(0, 0, 0)
barBottom.BorderSizePixel = 0
barBottom.ZIndex = 10
barBottom.Parent = screenGui

-- Dialogue box ---------------------------------------------------------
local dialogueBox = Instance.new("Frame")
dialogueBox.Name = "DialogueBox"
dialogueBox.Size = UDim2.new(0, 700, 0, 110)
dialogueBox.AnchorPoint = Vector2.new(0.5, 1)
dialogueBox.Position = UDim2.new(0.5, 0, 1, -60)
dialogueBox.BackgroundColor3 = Color3.new(0, 0, 0)
dialogueBox.BackgroundTransparency = 0.25
dialogueBox.Visible = false
dialogueBox.ZIndex = 11
dialogueBox.Parent = screenGui

local speakerName = Instance.new("TextLabel")
speakerName.Name = "SpeakerName"
speakerName.Size = UDim2.new(1, -20, 0, 24)
speakerName.Position = UDim2.new(0, 10, 0, 6)
speakerName.BackgroundTransparency = 1
speakerName.TextColor3 = Color3.fromRGB(180, 200, 255)
speakerName.Font = Enum.Font.GothamBold
speakerName.TextScaled = true
speakerName.TextXAlignment = Enum.TextXAlignment.Left
speakerName.ZIndex = 11
speakerName.Parent = dialogueBox

local dialogueText = Instance.new("TextLabel")
dialogueText.Name = "DialogueText"
dialogueText.Size = UDim2.new(1, -20, 0, 70)
dialogueText.Position = UDim2.new(0, 10, 0, 32)
dialogueText.BackgroundTransparency = 1
dialogueText.TextColor3 = Color3.new(1, 1, 1)
dialogueText.Font = Enum.Font.Gotham
dialogueText.TextScaled = true
dialogueText.TextWrapped = true
dialogueText.TextXAlignment = Enum.TextXAlignment.Left
dialogueText.TextYAlignment = Enum.TextYAlignment.Top
dialogueText.ZIndex = 11
dialogueText.Parent = dialogueBox

-- Flash overlay ----------------------------------------------------------
local flash = Instance.new("Frame")
flash.Name = "Flash"
flash.Size = UDim2.new(1, 0, 1, 0)
flash.BackgroundColor3 = Color3.new(1, 1, 1)
flash.BackgroundTransparency = 1
flash.ZIndex = 20
flash.Parent = screenGui

-- Notification -------------------------------------------------------------
local notifyLabel = Instance.new("TextLabel")
notifyLabel.Name = "NotifyText"
notifyLabel.Size = UDim2.new(0, 500, 0, 40)
notifyLabel.AnchorPoint = Vector2.new(0.5, 0)
notifyLabel.Position = UDim2.new(0.5, 0, 0, 100)
notifyLabel.BackgroundTransparency = 1
notifyLabel.TextColor3 = Color3.new(1, 1, 1)
notifyLabel.Font = Enum.Font.GothamBold
notifyLabel.TextScaled = true
notifyLabel.TextTransparency = 1
notifyLabel.Parent = screenGui

print("[Echobound] UI built.")
