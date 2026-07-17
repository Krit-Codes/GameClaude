-- Script: ServerScriptService.02_LevelBuilder
-- Procedurally builds the entire vertical-slice level: spawn area, two
-- Echo puzzle rooms, a Color Shrine, and the boss arena. No manual
-- building in Studio is required.

local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local level = Workspace:WaitForChild("Level")

local GRAY = Color3.fromRGB(90, 90, 95)
local DARK = Color3.fromRGB(35, 35, 40)

local function part(name, size, cframe, color, material, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent or level
	return p
end

local function sign(text, cframe)
	local pole = part("SignPole", Vector3.new(0.6, 6, 0.6), cframe, DARK, Enum.Material.Metal)

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "SignGui"
	billboard.Size = UDim2.new(0, 280, 0, 100)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = pole

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 0.35
	label.BackgroundColor3 = Color3.new(0, 0, 0)
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.Parent = billboard

	return pole
end

-------------------------------------------------------------------------
-- Spawn platform
-------------------------------------------------------------------------
part("SpawnPlatform", Vector3.new(44, 2, 44), CFrame.new(0, -1, 0), GRAY, Enum.Material.Concrete)

local spawnLocation = Instance.new("SpawnLocation")
spawnLocation.Name = "MainSpawn"
spawnLocation.Size = Vector3.new(6, 1, 6)
spawnLocation.CFrame = CFrame.new(0, 0.5, 10)
spawnLocation.Anchored = true
spawnLocation.CanCollide = true
spawnLocation.Transparency = 1
spawnLocation.Duration = 0
spawnLocation.Parent = level

sign("R = Record Echo\nX = Dismiss Echoes\nHold a plate, record, then walk away.\nThe Echo holds it for you.", CFrame.new(0, 3, 0))

-------------------------------------------------------------------------
-- Puzzle Room 1 (single plate)
-------------------------------------------------------------------------
part("Corridor1", Vector3.new(10, 1, 30), CFrame.new(0, -0.5, 30), GRAY, Enum.Material.Concrete)
part("PuzzleRoom1Floor", Vector3.new(34, 1, 34), CFrame.new(0, -0.5, 60), GRAY, Enum.Material.Concrete)

local plate1 = part("Plate_Puzzle1_A", Vector3.new(6, 0.5, 6), CFrame.new(-9, 0.25, 60), Color3.fromRGB(120, 170, 200), Enum.Material.Neon)
plate1:SetAttribute("GroupId", "puzzle1")
CollectionService:AddTag(plate1, "PressurePlate")

local door1 = part("Door_Puzzle1", Vector3.new(10, 10, 1), CFrame.new(0, 4.5, 76), Color3.fromRGB(120, 170, 200), Enum.Material.ForceField)
door1:SetAttribute("GroupId", "puzzle1")
door1.CanCollide = true
door1.Transparency = 0.15
CollectionService:AddTag(door1, "PressureDoor")

sign("This door needs the plate\nheld down. Record yourself\nstanding on it, then walk away.", CFrame.new(-9, 3, 66))

-------------------------------------------------------------------------
-- Puzzle Room 2 (two plates)
-------------------------------------------------------------------------
part("Corridor2", Vector3.new(10, 1, 30), CFrame.new(0, -0.5, 92), GRAY, Enum.Material.Concrete)
part("PuzzleRoom2Floor", Vector3.new(46, 1, 40), CFrame.new(0, -0.5, 140), GRAY, Enum.Material.Concrete)

local plate2a = part("Plate_Puzzle2_A", Vector3.new(6, 0.5, 6), CFrame.new(-16, 0.25, 132), Color3.fromRGB(200, 150, 120), Enum.Material.Neon)
plate2a:SetAttribute("GroupId", "puzzle2")
CollectionService:AddTag(plate2a, "PressurePlate")

local plate2b = part("Plate_Puzzle2_B", Vector3.new(6, 0.5, 6), CFrame.new(16, 0.25, 148), Color3.fromRGB(200, 150, 120), Enum.Material.Neon)
plate2b:SetAttribute("GroupId", "puzzle2")
CollectionService:AddTag(plate2b, "PressurePlate")

local door2 = part("Door_Puzzle2", Vector3.new(14, 12, 1), CFrame.new(0, 5.5, 160), Color3.fromRGB(200, 150, 120), Enum.Material.ForceField)
door2:SetAttribute("GroupId", "puzzle2")
door2.CanCollide = true
door2.Transparency = 0.15
CollectionService:AddTag(door2, "PressureDoor")

sign("Two plates, two Echoes.\nRecord one loop per plate.", CFrame.new(0, 3, 140))

-------------------------------------------------------------------------
-- Color Shrine
-------------------------------------------------------------------------
part("Corridor3", Vector3.new(10, 1, 20), CFrame.new(0, -0.5, 172), GRAY, Enum.Material.Concrete)
part("ShrineFloor", Vector3.new(40, 1, 40), CFrame.new(0, -0.5, 210), DARK, Enum.Material.Slate)

local shardPositions = {
	Vector3.new(-10, 4, 202),
	Vector3.new(0, 6, 212),
	Vector3.new(10, 4, 220),
}

for i, pos in ipairs(shardPositions) do
	local shard = Instance.new("Part")
	shard.Name = "ColorShard_" .. i
	shard.Shape = Enum.PartType.Ball
	shard.Size = Vector3.new(2, 2, 2)
	shard.Material = Enum.Material.Neon
	shard.Color = Color3.fromHSV((i - 1) / #shardPositions, 0.8, 1)
	shard.Anchored = true
	shard.CanCollide = false
	shard.CFrame = CFrame.new(pos)
	shard.Parent = level
	CollectionService:AddTag(shard, "ColorShard")

	local light = Instance.new("PointLight")
	light.Color = shard.Color
	light.Range = 16
	light.Brightness = 2
	light.Parent = shard

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Restore Memory"
	prompt.ObjectText = "Color Shard"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 10
	prompt.Parent = shard

	local bobTween = TweenService:Create(
		shard,
		TweenInfo.new(1.6 + i * 0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ CFrame = CFrame.new(pos + Vector3.new(0, 2, 0)) }
	)
	bobTween:Play()
end

-------------------------------------------------------------------------
-- Boss Gate + Arena
-------------------------------------------------------------------------
part("Corridor4", Vector3.new(10, 1, 40), CFrame.new(0, -0.5, 250), DARK, Enum.Material.Slate)

local bossGate = part("BossGate", Vector3.new(12, 14, 2), CFrame.new(0, 6.5, 270), Color3.fromRGB(140, 40, 160), Enum.Material.ForceField)
bossGate.CanCollide = true
CollectionService:AddTag(bossGate, "BossGate")

local gatePrompt = Instance.new("ProximityPrompt")
gatePrompt.ActionText = "Enter the Hollow's Domain"
gatePrompt.ObjectText = "The Fracture's Heart"
gatePrompt.HoldDuration = 1
gatePrompt.MaxActivationDistance = 12
gatePrompt.Parent = bossGate

local arenaFloor = Instance.new("Part")
arenaFloor.Name = "BossArenaFloor"
arenaFloor.Shape = Enum.PartType.Cylinder
arenaFloor.Size = Vector3.new(4, 60, 60)
arenaFloor.CFrame = CFrame.new(0, -1, 330) * CFrame.Angles(0, 0, math.rad(90))
arenaFloor.Color = DARK
arenaFloor.Material = Enum.Material.Slate
arenaFloor.Anchored = true
arenaFloor.Parent = level

for i = 1, 3 do
	local angle = (i - 1) * (math.pi * 2 / 3)
	local pos = Vector3.new(math.cos(angle) * 20, 0.1, 330 + math.sin(angle) * 20)
	local pillar = part("ResonancePillar_" .. i, Vector3.new(3, 0.4, 3), CFrame.new(pos), Color3.fromRGB(90, 200, 220), Enum.Material.Neon)
	CollectionService:AddTag(pillar, "ResonancePillar")
end

print("[Echobound] Level geometry built.")
