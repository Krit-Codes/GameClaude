-- Script: ServerScriptService.05_ColorRestoration
-- Handles Color Shard pickups: increments leaderstats, feeds the
-- player's Color Pulse charge (used against The Hollow), and tweens the
-- world's global saturation back from -1 (dead grey) toward 0 (full color).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local EchoConstants = require(ReplicatedStorage.Modules.EchoConstants)
local PlayerState = require(script.Parent.Modules.PlayerState)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local flashEvent = remotes:WaitForChild("FlashScreen")
local notifyEvent = remotes:WaitForChild("Notify")

local colorCorrection = Lighting:WaitForChild("GlobalColorCorrection")

local totalShardsCollected = 0

local function restoreColorStep()
	totalShardsCollected += 1
	local frac = math.clamp(totalShardsCollected / EchoConstants.MAX_COLOR_SHARDS, 0, 1)
	local targetSaturation = -1 + frac
	TweenService:Create(colorCorrection, TweenInfo.new(1.2, Enum.EasingStyle.Sine), { Saturation = targetSaturation }):Play()
end

local function onShardTagged(shard)
	local prompt = shard:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		return
	end
	prompt.Triggered:Connect(function(player)
		if not shard.Parent then
			return
		end

		local leaderstats = player:FindFirstChild("leaderstats")
		local shardsStat = leaderstats and leaderstats:FindFirstChild("Color Shards")
		if shardsStat then
			shardsStat.Value += 1
		end

		PlayerState.addColorCharge(player, 1 / 3)
		restoreColorStep()
		flashEvent:FireAllClients(Color3.new(1, 1, 1), 0.6)
		notifyEvent:FireClient(player, "Memory restored. The world brightens.", 3)

		shard:Destroy()
	end)
end

for _, shard in ipairs(CollectionService:GetTagged("ColorShard")) do
	onShardTagged(shard)
end
CollectionService:GetInstanceAddedSignal("ColorShard"):Connect(onShardTagged)

print("[Echobound] Color restoration online.")
