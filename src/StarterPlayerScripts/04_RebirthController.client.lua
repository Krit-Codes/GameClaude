-- Drives the rebirth panel. Rebirths gained = floor(Money / 1000), so the
-- status label and button both show a live preview of how many rebirths
-- you'd get *right now* -- the more you save, the bigger the payoff, all
-- from one button. A confirm dialog guards against accidentally wiping
-- progress with a stray click.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NumberFormat = require(ReplicatedStorage.Modules.NumberFormat)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = playerGui:WaitForChild("RebirthUI")
local rebirthPanel = screenGui:WaitForChild("RebirthPanel")
local statusLabel = rebirthPanel:WaitForChild("StatusLabel")
local progressFill = rebirthPanel:WaitForChild("ProgressBarBG"):WaitForChild("ProgressBarFill")
local rebirthButton = rebirthPanel:WaitForChild("RebirthButton")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local rebirthEvent = remotes:WaitForChild("RebirthEvent")
local dataUpdateEvent = remotes:WaitForChild("DataUpdateEvent")

local REBIRTH_MONEY_PER_REBIRTH = 1000

local latestRebirthsAvailable = 0

-- Confirmation dialog, built here since only this script needs it.

local confirmDialog = Instance.new("Frame")
confirmDialog.Name = "ConfirmDialog"
confirmDialog.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
confirmDialog.Size = UDim2.new(0, 380, 0, 160)
confirmDialog.Position = UDim2.new(0.5, -190, 0.5, -80)
confirmDialog.Visible = false
confirmDialog.ZIndex = 10
confirmDialog.Parent = screenGui

local dialogCorner = Instance.new("UICorner")
dialogCorner.CornerRadius = UDim.new(0, 14)
dialogCorner.Parent = confirmDialog

local confirmMessage = Instance.new("TextLabel")
confirmMessage.BackgroundTransparency = 1
confirmMessage.Font = Enum.Font.Gotham
confirmMessage.TextColor3 = Color3.fromRGB(240, 240, 245)
confirmMessage.TextSize = 16
confirmMessage.TextWrapped = true
confirmMessage.ZIndex = 10
confirmMessage.Size = UDim2.new(1, -30, 0, 80)
confirmMessage.Position = UDim2.new(0, 15, 0, 12)
confirmMessage.Parent = confirmDialog

local yesButton = Instance.new("TextButton")
yesButton.Font = Enum.Font.GothamBold
yesButton.TextColor3 = Color3.fromRGB(240, 240, 245)
yesButton.TextSize = 16
yesButton.Text = "Yes, rebirth!"
yesButton.BackgroundColor3 = Color3.fromRGB(55, 140, 80)
yesButton.ZIndex = 10
yesButton.Size = UDim2.new(0.45, 0, 0, 40)
yesButton.Position = UDim2.new(0.03, 0, 1, -52)
yesButton.Parent = confirmDialog

local yesCorner = Instance.new("UICorner")
yesCorner.CornerRadius = UDim.new(0, 8)
yesCorner.Parent = yesButton

local noButton = Instance.new("TextButton")
noButton.Font = Enum.Font.GothamBold
noButton.TextColor3 = Color3.fromRGB(240, 240, 245)
noButton.TextSize = 16
noButton.Text = "Not yet"
noButton.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
noButton.ZIndex = 10
noButton.Size = UDim2.new(0.45, 0, 0, 40)
noButton.Position = UDim2.new(0.52, 0, 1, -52)
noButton.Parent = confirmDialog

local noCorner = Instance.new("UICorner")
noCorner.CornerRadius = UDim.new(0, 8)
noCorner.Parent = noButton

yesButton.MouseButton1Click:Connect(function()
	rebirthEvent:FireServer()
	confirmDialog.Visible = false
end)

noButton.MouseButton1Click:Connect(function()
	confirmDialog.Visible = false
end)

rebirthButton.MouseButton1Click:Connect(function()
	if latestRebirthsAvailable < 1 then
		return
	end
	confirmMessage.Text = ("Rebirth now for +%d Rebirth%s? This resets your money and upgrades, but permanently boosts all future earnings!"):format(
		latestRebirthsAvailable,
		latestRebirthsAvailable == 1 and "" or "s"
	)
	confirmDialog.Visible = true
end)

dataUpdateEvent.OnClientEvent:Connect(function(snapshot)
	latestRebirthsAvailable = snapshot.RebirthsAvailable

	if latestRebirthsAvailable >= 1 then
		statusLabel.Text = ("Rebirth now for +%d Rebirth%s"):format(
			latestRebirthsAvailable,
			latestRebirthsAvailable == 1 and "" or "s"
		)
		rebirthButton.BackgroundColor3 = Color3.fromRGB(55, 140, 80)
	else
		local remaining = REBIRTH_MONEY_PER_REBIRTH - (snapshot.Money % REBIRTH_MONEY_PER_REBIRTH)
		statusLabel.Text = "Save $" .. NumberFormat.Format(remaining) .. " more for your first Rebirth"
		rebirthButton.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
	end

	local progress = (snapshot.Money % REBIRTH_MONEY_PER_REBIRTH) / REBIRTH_MONEY_PER_REBIRTH
	progressFill.Size = UDim2.new(progress, 0, 1, 0)
end)
