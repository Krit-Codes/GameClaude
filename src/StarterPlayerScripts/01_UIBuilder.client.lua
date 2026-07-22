-- Builds the entire HUD at runtime: top stat bar, the big click button (plus
-- a layer for floating "+$" popups), the upgrade shop, and the rebirth panel.
-- Other LocalScripts find these by name via WaitForChild, so load order
-- between this and the controller scripts never matters.

local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local COLOR_BG = Color3.fromRGB(18, 18, 26)
local COLOR_PANEL = Color3.fromRGB(28, 28, 40)
local COLOR_CARD = Color3.fromRGB(38, 38, 52)
local COLOR_ACCENT = Color3.fromRGB(85, 215, 120)
local COLOR_ACCENT_DIM = Color3.fromRGB(55, 140, 80)
local COLOR_TEXT = Color3.fromRGB(240, 240, 245)
local COLOR_SUBTEXT = Color3.fromRGB(170, 170, 185)

local function corner(radius, parent)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius or UDim.new(0, 12)
	c.Parent = parent
	return c
end

local function makeLabel(props)
	local label = Instance.new("TextLabel")
	label.Name = props.Name
	label.BackgroundTransparency = 1
	label.Font = props.Font or Enum.Font.GothamBold
	label.TextColor3 = props.Color or COLOR_TEXT
	label.TextSize = props.TextSize or 18
	label.TextXAlignment = props.XAlign or Enum.TextXAlignment.Left
	label.Text = props.Text or ""
	label.Size = props.Size
	label.Position = props.Position or UDim2.new()
	label.Parent = props.Parent
	return label
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RebirthUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = false
screenGui.Parent = playerGui

-- Top stat bar -----------------------------------------------------------

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.BackgroundColor3 = COLOR_PANEL
topBar.Size = UDim2.new(1, 0, 0, 90)
topBar.Position = UDim2.new(0, 0, 0, 0)
topBar.Parent = screenGui
corner(UDim.new(0, 0), topBar)

makeLabel({
	Name = "MoneyLabel",
	Parent = topBar,
	Text = "$0",
	TextSize = 34,
	Color = COLOR_ACCENT,
	Size = UDim2.new(0.5, 0, 0, 40),
	Position = UDim2.new(0, 20, 0, 8),
})

makeLabel({
	Name = "IncomeLabel",
	Parent = topBar,
	Text = "+$0/sec",
	TextSize = 16,
	Font = Enum.Font.Gotham,
	Color = COLOR_SUBTEXT,
	Size = UDim2.new(0.5, 0, 0, 20),
	Position = UDim2.new(0, 20, 0, 48),
})

makeLabel({
	Name = "RebirthLabel",
	Parent = topBar,
	Text = "Rebirths: 0  (x1.0 money)",
	TextSize = 16,
	Font = Enum.Font.Gotham,
	Color = COLOR_SUBTEXT,
	XAlign = Enum.TextXAlignment.Right,
	Size = UDim2.new(0.45, 0, 0, 20),
	Position = UDim2.new(0.55, -20, 0, 48),
})

-- Click button + popup layer ----------------------------------------------

local clickButton = Instance.new("TextButton")
clickButton.Name = "ClickButton"
clickButton.BackgroundColor3 = COLOR_ACCENT
clickButton.AutoButtonColor = true
clickButton.Size = UDim2.new(0, 220, 0, 220)
clickButton.Position = UDim2.new(0.5, -110, 0.55, -110)
clickButton.Font = Enum.Font.GothamBlack
clickButton.TextColor3 = Color3.fromRGB(10, 30, 15)
clickButton.TextSize = 26
clickButton.Text = "CLICK\n+$1"
clickButton.Parent = screenGui
corner(UDim.new(0.5, 0), clickButton)

local popupLayer = Instance.new("Frame")
popupLayer.Name = "PopupLayer"
popupLayer.BackgroundTransparency = 1
popupLayer.Size = UDim2.new(1, 0, 1, 0)
popupLayer.ZIndex = 5
popupLayer.Parent = screenGui

-- Shop panel ---------------------------------------------------------------

local shopPanel = Instance.new("Frame")
shopPanel.Name = "ShopPanel"
shopPanel.BackgroundColor3 = COLOR_PANEL
shopPanel.Size = UDim2.new(0, 320, 1, -220)
shopPanel.Position = UDim2.new(1, -340, 0, 110)
shopPanel.Parent = screenGui
corner(UDim.new(0, 16), shopPanel)

makeLabel({
	Name = "Title",
	Parent = shopPanel,
	Text = "UPGRADES",
	TextSize = 20,
	Color = COLOR_TEXT,
	XAlign = Enum.TextXAlignment.Center,
	Size = UDim2.new(1, 0, 0, 36),
	Position = UDim2.new(0, 0, 0, 8),
})

local shopList = Instance.new("ScrollingFrame")
shopList.Name = "List"
shopList.BackgroundTransparency = 1
shopList.BorderSizePixel = 0
shopList.Size = UDim2.new(1, -16, 1, -56)
shopList.Position = UDim2.new(0, 8, 0, 48)
shopList.CanvasSize = UDim2.new(0, 0, 0, 0)
shopList.AutomaticCanvasSize = Enum.AutomaticSize.Y
shopList.ScrollBarThickness = 6
shopList.Parent = shopPanel

local shopLayout = Instance.new("UIListLayout")
shopLayout.Padding = UDim.new(0, 8)
shopLayout.SortOrder = Enum.SortOrder.LayoutOrder
shopLayout.Parent = shopList

-- Rebirth panel --------------------------------------------------------------

local rebirthPanel = Instance.new("Frame")
rebirthPanel.Name = "RebirthPanel"
rebirthPanel.BackgroundColor3 = COLOR_PANEL
rebirthPanel.Size = UDim2.new(0, 420, 0, 190)
rebirthPanel.Position = UDim2.new(0.5, -210, 1, -200)
rebirthPanel.Parent = screenGui
corner(UDim.new(0, 16), rebirthPanel)

makeLabel({
	Name = "CostLabel",
	Parent = rebirthPanel,
	Text = "Rebirth Cost: $1,000",
	TextSize = 18,
	Color = COLOR_TEXT,
	XAlign = Enum.TextXAlignment.Center,
	Size = UDim2.new(1, -20, 0, 24),
	Position = UDim2.new(0, 10, 0, 10),
})

local progressBg = Instance.new("Frame")
progressBg.Name = "ProgressBarBG"
progressBg.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
progressBg.Size = UDim2.new(1, -40, 0, 18)
progressBg.Position = UDim2.new(0, 20, 0, 42)
progressBg.Parent = rebirthPanel
corner(UDim.new(1, 0), progressBg)

local progressFill = Instance.new("Frame")
progressFill.Name = "ProgressBarFill"
progressFill.BackgroundColor3 = COLOR_ACCENT
progressFill.Size = UDim2.new(0, 0, 1, 0)
progressFill.Parent = progressBg
corner(UDim.new(1, 0), progressFill)

local rebirthButton = Instance.new("TextButton")
rebirthButton.Name = "RebirthButton"
rebirthButton.BackgroundColor3 = COLOR_ACCENT_DIM
rebirthButton.Size = UDim2.new(1, -40, 0, 44)
rebirthButton.Position = UDim2.new(0, 20, 0, 72)
rebirthButton.Font = Enum.Font.GothamBold
rebirthButton.TextColor3 = COLOR_TEXT
rebirthButton.TextSize = 20
rebirthButton.Text = "REBIRTH"
rebirthButton.Parent = rebirthPanel
corner(UDim.new(0, 10), rebirthButton)

local massRebirthButton = Instance.new("TextButton")
massRebirthButton.Name = "MassRebirthButton"
massRebirthButton.BackgroundColor3 = Color3.fromRGB(215, 175, 60)
massRebirthButton.Size = UDim2.new(1, -40, 0, 44)
massRebirthButton.Position = UDim2.new(0, 20, 0, 124)
massRebirthButton.Font = Enum.Font.GothamBlack
massRebirthButton.TextColor3 = Color3.fromRGB(40, 30, 5)
massRebirthButton.TextSize = 20
massRebirthButton.Text = "MASS REBIRTH x1000 ($1,000,000)"
massRebirthButton.Visible = false
massRebirthButton.Parent = rebirthPanel
corner(UDim.new(0, 10), massRebirthButton)
