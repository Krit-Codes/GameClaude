-- Builds one card per entry in UpgradeConfig and keeps each card's level,
-- cost, and afford-state in sync with the server via DataUpdateEvent.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UpgradeConfig = require(ReplicatedStorage.Modules.UpgradeConfig)
local NumberFormat = require(ReplicatedStorage.Modules.NumberFormat)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = playerGui:WaitForChild("RebirthUI")
local shopList = screenGui:WaitForChild("ShopPanel"):WaitForChild("List")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local buyUpgradeEvent = remotes:WaitForChild("BuyUpgradeEvent")
local dataUpdateEvent = remotes:WaitForChild("DataUpdateEvent")

local function getCost(upgrade, level)
	return math.floor(upgrade.BaseCost * (upgrade.CostGrowth ^ level))
end

local cards = {} -- [upgradeId] = { Root, LevelLabel, CostLabel, BuyButton }

for i, upgrade in ipairs(UpgradeConfig) do
	local card = Instance.new("Frame")
	card.Name = upgrade.Id
	card.LayoutOrder = i
	card.BackgroundColor3 = Color3.fromRGB(38, 38, 52)
	card.Size = UDim2.new(1, 0, 0, 84)
	card.Parent = shopList

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = card

	local nameLabel = Instance.new("TextLabel")
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextColor3 = Color3.fromRGB(240, 240, 245)
	nameLabel.TextSize = 16
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Text = upgrade.Name
	nameLabel.Size = UDim2.new(1, -20, 0, 20)
	nameLabel.Position = UDim2.new(0, 10, 0, 6)
	nameLabel.Parent = card

	local levelLabel = Instance.new("TextLabel")
	levelLabel.BackgroundTransparency = 1
	levelLabel.Font = Enum.Font.Gotham
	levelLabel.TextColor3 = Color3.fromRGB(170, 170, 185)
	levelLabel.TextSize = 13
	levelLabel.TextXAlignment = Enum.TextXAlignment.Left
	levelLabel.Text = "Level 0 -- +$0/sec"
	levelLabel.Size = UDim2.new(1, -20, 0, 16)
	levelLabel.Position = UDim2.new(0, 10, 0, 26)
	levelLabel.Parent = card

	local buyButton = Instance.new("TextButton")
	buyButton.Font = Enum.Font.GothamBold
	buyButton.TextColor3 = Color3.fromRGB(240, 240, 245)
	buyButton.TextSize = 15
	buyButton.BackgroundColor3 = Color3.fromRGB(55, 140, 80)
	buyButton.Text = "Buy -- $" .. NumberFormat.Format(upgrade.BaseCost)
	buyButton.Size = UDim2.new(1, -20, 0, 30)
	buyButton.Position = UDim2.new(0, 10, 0, 48)
	buyButton.Parent = card

	local buyCorner = Instance.new("UICorner")
	buyCorner.CornerRadius = UDim.new(0, 8)
	buyCorner.Parent = buyButton

	buyButton.MouseButton1Click:Connect(function()
		buyUpgradeEvent:FireServer(upgrade.Id)
	end)

	cards[upgrade.Id] = {
		LevelLabel = levelLabel,
		BuyButton = buyButton,
	}
end

dataUpdateEvent.OnClientEvent:Connect(function(snapshot)
	for _, upgrade in ipairs(UpgradeConfig) do
		local card = cards[upgrade.Id]
		local level = snapshot.Upgrades[upgrade.Id] or 0
		local cost = getCost(upgrade, level)
		local totalEffect = level * upgrade.Effect

		card.LevelLabel.Text = ("Level %d -- %s"):format(level, upgrade.Description:format(NumberFormat.Format(totalEffect)))
		card.BuyButton.Text = "Buy -- $" .. NumberFormat.Format(cost)

		if snapshot.Money >= cost then
			card.BuyButton.BackgroundColor3 = Color3.fromRGB(55, 140, 80)
		else
			card.BuyButton.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
		end
	end
end)
