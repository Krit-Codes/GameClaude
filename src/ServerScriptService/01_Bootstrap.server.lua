-- Script: ServerScriptService.01_Bootstrap
-- Creates RemoteEvents, workspace folders, leaderstats, and sets the
-- desaturated "Fracture" mood lighting that the Color Restoration system
-- later brightens as the player progresses.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local PlayerState = require(script.Parent.Modules.PlayerState)

-- Remotes ---------------------------------------------------------------
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local function newRemote(name)
	local re = Instance.new("RemoteEvent")
	re.Name = name
	re.Parent = remotes
	return re
end

newRemote("RecordStop")          -- Client -> Server: (frames, duration)
newRemote("DismissEchoes")       -- Client -> Server: ()
newRemote("PlayCutscene")        -- Server -> Client: (cutsceneData)
newRemote("BossHUD")             -- Server -> Client: (data)
newRemote("ColorPulseRequest")   -- Client -> Server: ()
newRemote("Notify")              -- Server -> Client: (text, duration)
newRemote("EchoHUD")             -- Server -> Client: (count, max)
newRemote("FlashScreen")         -- Server -> Client: (color, duration)

-- Workspace containers ------------------------------------------------------
local function ensureFolder(name, parent)
	local f = parent:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = parent
	end
	return f
end

ensureFolder("Echoes", Workspace)
ensureFolder("Level", Workspace)
ensureFolder("VFX", Workspace)

-- Lighting / mood ------------------------------------------------------------
Lighting.Ambient = Color3.fromRGB(40, 40, 45)
Lighting.OutdoorAmbient = Color3.fromRGB(60, 60, 65)
Lighting.Brightness = 2
Lighting.ClockTime = 21
Lighting.FogEnd = 900
Lighting.FogColor = Color3.fromRGB(20, 20, 25)

local colorCorrection = Lighting:FindFirstChild("GlobalColorCorrection")
if not colorCorrection then
	colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Name = "GlobalColorCorrection"
	colorCorrection.Saturation = -1
	colorCorrection.Contrast = 0.05
	colorCorrection.Parent = Lighting
end

local atmosphere = Lighting:FindFirstChild("GlobalAtmosphere")
if not atmosphere then
	atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "GlobalAtmosphere"
	atmosphere.Density = 0.3
	atmosphere.Offset = 0.25
	atmosphere.Color = Color3.fromRGB(150, 150, 160)
	atmosphere.Decay = Color3.fromRGB(20, 20, 25)
	atmosphere.Glare = 0.1
	atmosphere.Haze = 1.5
	atmosphere.Parent = Lighting
end

-- Player setup ----------------------------------------------------------------
local function onPlayerAdded(player)
	PlayerState.init(player)

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local shards = Instance.new("IntValue")
	shards.Name = "Color Shards"
	shards.Value = 0
	shards.Parent = leaderstats
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

Players.PlayerRemoving:Connect(function(player)
	PlayerState.cleanup(player)
end)

print("[Echobound] Bootstrap complete.")
