-- Wires up the big click button: fires the click remote and spawns a
-- floating "+$X" popup for feedback. Keeps its own copy of the current
-- click value in sync by listening to DataUpdateEvent directly.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local NumberFormat = require(ReplicatedStorage.Modules.NumberFormat)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = playerGui:WaitForChild("RebirthUI")
local clickButton = screenGui:WaitForChild("ClickButton")
local popupLayer = screenGui:WaitForChild("PopupLayer")
local topBar = screenGui:WaitForChild("TopBar")
local moneyLabel = topBar:WaitForChild("MoneyLabel")
local incomeLabel = topBar:WaitForChild("IncomeLabel")
local rebirthLabel = topBar:WaitForChild("RebirthLabel")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local clickEvent = remotes:WaitForChild("ClickEvent")
local dataUpdateEvent = remotes:WaitForChild("DataUpdateEvent")

local currentClickValue = 1

dataUpdateEvent.OnClientEvent:Connect(function(snapshot)
	currentClickValue = snapshot.ClickValue
	clickButton.Text = ("CLICK\n+$%s"):format(NumberFormat.Format(currentClickValue))

	moneyLabel.Text = "$" .. snapshot.MoneyFormatted
	incomeLabel.Text = "+$" .. NumberFormat.Format(snapshot.IncomePerSecond) .. "/sec"
	rebirthLabel.Text = ("Rebirths: %d  (x%.1f money)"):format(snapshot.Rebirths, snapshot.Multiplier)
end)

local function spawnPopup(amount)
	local popup = Instance.new("TextLabel")
	popup.BackgroundTransparency = 1
	popup.Font = Enum.Font.GothamBold
	popup.TextColor3 = Color3.fromRGB(120, 255, 150)
	popup.TextSize = 22
	popup.Text = "+$" .. NumberFormat.Format(amount)
	popup.Size = UDim2.new(0, 120, 0, 30)

	local offsetX = math.random(-40, 40)
	popup.Position = UDim2.new(
		clickButton.Position.X.Scale,
		clickButton.Position.X.Offset + clickButton.Size.X.Offset / 2 - 60 + offsetX,
		clickButton.Position.Y.Scale,
		clickButton.Position.Y.Offset
	)
	popup.Parent = popupLayer

	local tween = TweenService:Create(popup, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = popup.Position - UDim2.new(0, 0, 0, 70),
		TextTransparency = 1,
	})
	tween:Play()
	tween.Completed:Connect(function()
		popup:Destroy()
	end)
end

clickButton.MouseButton1Click:Connect(function()
	clickEvent:FireServer()
	spawnPopup(currentClickValue)
end)
