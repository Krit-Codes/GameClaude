-- Script. Handles the actual clicker gameplay: clicking, selling,
-- buying the click-power upgrade, and rebirthing. All validation lives
-- here since clients cannot be trusted.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ClickerConstants = require(ReplicatedStorage.Modules.ClickerConstants)
local PlayerState = require(ServerScriptService.Modules.PlayerState)

local remotes = ReplicatedStorage:WaitForChild("ClickerRemotes")
local clickRequest = remotes:WaitForChild("ClickRequest")
local sellRequest = remotes:WaitForChild("SellRequest")
local buyUpgradeRequest = remotes:WaitForChild("BuyUpgradeRequest")
local rebirthRequest = remotes:WaitForChild("RebirthRequest")
local statsUpdate = remotes:WaitForChild("StatsUpdate")

local function pushStats(player, state)
	PlayerState.SyncLeaderstats(player, state)
	statsUpdate:FireClient(player, PlayerState.BuildPayload(state))
end

clickRequest.OnServerEvent:Connect(function(player)
	local state = PlayerState.Get(player)
	if not state then
		return
	end

	local now = os.clock()
	if now - state.LastClickTime < ClickerConstants.MIN_CLICK_INTERVAL then
		return
	end
	state.LastClickTime = now

	state.Clicks += state.ClickPower
	pushStats(player, state)
end)

sellRequest.OnServerEvent:Connect(function(player)
	local state = PlayerState.Get(player)
	if not state or state.Clicks <= 0 then
		return
	end

	state.Money += state.Clicks
	state.Clicks = 0
	pushStats(player, state)
end)

buyUpgradeRequest.OnServerEvent:Connect(function(player)
	local state = PlayerState.Get(player)
	if not state then
		return
	end

	local cost = PlayerState.ComputeUpgradeCost(state)
	if state.Money < cost then
		return
	end

	state.Money -= cost
	state.UpgradeLevel += 1
	PlayerState.RecomputeClickPower(player)
	pushStats(player, state)
end)

rebirthRequest.OnServerEvent:Connect(function(player)
	local state = PlayerState.Get(player)
	if not state then
		return
	end

	local rebirthGain = math.floor(state.Money / ClickerConstants.REBIRTH_MONEY_DIVISOR)
	if rebirthGain < 1 then
		return
	end

	state.Rebirths += rebirthGain
	state.Clicks = 0
	state.Money = 0
	state.UpgradeLevel = 0
	PlayerState.RecomputeClickPower(player)
	pushStats(player, state)
end)
