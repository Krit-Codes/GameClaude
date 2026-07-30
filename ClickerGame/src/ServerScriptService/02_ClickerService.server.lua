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

local allowedSellPercents = {}
for _, percent in ipairs(ClickerConstants.SELL_PERCENT_OPTIONS) do
	allowedSellPercents[percent] = true
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

sellRequest.OnServerEvent:Connect(function(player, percent)
	local state = PlayerState.Get(player)
	if not state or state.Clicks <= 0 then
		return
	end

	if not allowedSellPercents[percent] then
		return
	end

	local amountToSell = state.Clicks * percent
	if amountToSell <= 0 then
		return
	end

	state.Money += amountToSell
	state.Clicks -= amountToSell
	pushStats(player, state)
end)

-- amount is either a positive integer (buy up to that many levels, limited
-- by what's affordable) or the string "Max" (buy as many as affordable).
buyUpgradeRequest.OnServerEvent:Connect(function(player, amount)
	local state = PlayerState.Get(player)
	if not state then
		return
	end

	local purchaseLimit
	if amount == "Max" then
		purchaseLimit = ClickerConstants.MAX_UPGRADE_PURCHASE_SAFETY_CAP
	elseif type(amount) == "number" and amount >= 1 then
		purchaseLimit = math.floor(amount)
	else
		return
	end

	local purchased = 0
	for _ = 1, purchaseLimit do
		local cost = PlayerState.ComputeUpgradeCost(state)
		if state.Money < cost then
			break
		end

		state.Money -= cost
		state.UpgradeLevel += 1
		purchased += 1
	end

	if purchased <= 0 then
		return
	end

	PlayerState.RecomputeClickPower(player)
	pushStats(player, state)
end)

-- amount is one of ClickerConstants.REBIRTH_TIER_AMOUNTS (1, 5, or 10) for a
-- fixed-tier rebirth, or the string "Max" to convert all eligible Money.
rebirthRequest.OnServerEvent:Connect(function(player, amount)
	local state = PlayerState.Get(player)
	if not state then
		return
	end

	local rebirthGain
	if amount == "Max" then
		rebirthGain = math.floor(state.Money / ClickerConstants.REBIRTH_MONEY_DIVISOR)
	elseif ClickerConstants.REBIRTH_TIER_AMOUNTS[amount] then
		rebirthGain = amount
	else
		return
	end

	if rebirthGain < 1 then
		return
	end

	local requiredMoney = rebirthGain * ClickerConstants.REBIRTH_MONEY_DIVISOR
	if state.Money < requiredMoney then
		return
	end

	state.Rebirths += rebirthGain
	state.Clicks = 0
	state.Money = 0
	state.UpgradeLevel = 0
	PlayerState.RecomputeClickPower(player)
	pushStats(player, state)
end)
