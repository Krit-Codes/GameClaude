-- LocalScript: StarterPlayer.StarterPlayerScripts.04_FeedbackController
-- Screen-flash effects, boss health bar updates, and a live Color Meter
-- driven directly off the replicated Lighting.GlobalColorCorrection.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = playerGui:WaitForChild("EchoboundUI")
local flash = screenGui.Flash
local colorFill = screenGui.HUD.ColorContainer.Back.ColorFill
local bossHud = screenGui.BossHUD
local bossFill = bossHud.Back.BossHPFill
local bossName = bossHud.BossName

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local flashEvent = remotes:WaitForChild("FlashScreen")
local bossHudEvent = remotes:WaitForChild("BossHUD")

flashEvent.OnClientEvent:Connect(function(color, duration)
	flash.BackgroundColor3 = color or Color3.new(1, 1, 1)
	flash.BackgroundTransparency = 0.4
	TweenService:Create(flash, TweenInfo.new(duration or 0.5), { BackgroundTransparency = 1 }):Play()
end)

bossHudEvent.OnClientEvent:Connect(function(data)
	if typeof(data) ~= "table" then
		return
	end
	bossHud.Visible = data.visible and true or false
	if data.name then
		bossName.Text = data.name
	end
	if data.hp and data.maxHp and data.maxHp > 0 then
		local frac = math.clamp(data.hp / data.maxHp, 0, 1)
		TweenService:Create(bossFill, TweenInfo.new(0.3), { Size = UDim2.new(frac, 0, 1, 0) }):Play()
	end
end)

local colorCorrection = Lighting:WaitForChild("GlobalColorCorrection")
local function updateColorMeter()
	local frac = math.clamp(colorCorrection.Saturation + 1, 0, 1)
	colorFill.Size = UDim2.new(frac, 0, 1, 0)
end
colorCorrection:GetPropertyChangedSignal("Saturation"):Connect(updateColorMeter)
updateColorMeter()

print("[Echobound] Feedback controller ready.")
