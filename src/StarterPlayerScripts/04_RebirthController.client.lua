-- Drives the rebirth panel: cost/progress display, enabling the Rebirth
-- button once affordable, revealing Mass Rebirth at $1,000,000, and a small
-- confirmation dialog before either action wipes money and upgrades.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NumberFormat = require(ReplicatedStorage.Modules.NumberFormat)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = playerGui:WaitForChild("RebirthUI")
local rebirthPanel = screenGui:WaitForChild("RebirthPanel")
local costLabel = rebirthPanel:WaitForChild("CostLabel")
local progressFill = rebirthPanel:WaitForChild("ProgressBarBG"):WaitForChild("ProgressBarFill")
local rebirthButton = rebirthPanel:WaitForChild("RebirthButton")
local massRebirthButton = rebirthPanel:WaitForChild("MassRebirthButton")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local rebirthEvent = remotes:WaitForChild("RebirthEvent")
local massRebirthEvent = remotes:WaitForChild("MassRebirthEvent")
local dataUpdateEvent = remotes:WaitForChild("DataUpdateEvent")

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

local pendingAction = nil

local function openConfirm(action, message)
	pendingAction = action
	confirmMessage.Text = message
	confirmDialog.Visible = true
end

yesButton.MouseButton1Click:Connect(function()
	if pendingAction == "rebirth" then
		rebirthEvent:FireServer()
	elseif pendingAction == "mass" then
		massRebirthEvent:FireServer()
	end
	confirmDialog.Visible = false
	pendingAction = nil
end)

noButton.MouseButton1Click:Connect(function()
	confirmDialog.Visible = false
	pendingAction = nil
end)

rebirthButton.MouseButton1Click:Connect(function()
	openConfirm("rebirth", "Rebirth now? This resets your money and upgrades, but permanently boosts all future earnings!")
end)

massRebirthButton.MouseButton1Click:Connect(function()
	openConfirm("mass", "Mass Rebirth? Spend $1,000,000 for 1000 instant Rebirths at once! This resets your money and upgrades.")
end)

dataUpdateEvent.OnClientEvent:Connect(function(snapshot)
	costLabel.Text = "Rebirth Cost: $" .. NumberFormat.Format(snapshot.RebirthCost)

	local progress = math.clamp(snapshot.Money / snapshot.RebirthCost, 0, 1)
	progressFill.Size = UDim2.new(progress, 0, 1, 0)

	if snapshot.Money >= snapshot.RebirthCost then
		rebirthButton.BackgroundColor3 = Color3.fromRGB(55, 140, 80)
	else
		rebirthButton.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
	end

	massRebirthButton.Visible = snapshot.CanMassRebirth
end)
