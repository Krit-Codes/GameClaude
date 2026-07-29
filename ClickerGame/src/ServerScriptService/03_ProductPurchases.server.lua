-- Script. Grants upgrade levels when a player buys one of the Robux
-- Developer Products. Only the server's ProcessReceipt callback can be
-- trusted to confirm a real payment happened -- the client never grants
-- anything itself.
--
-- IMPORTANT: only one script in the whole game can assign
-- MarketplaceService.ProcessReceipt. If you add another Developer Product
-- system later, merge its logic into this same callback instead of
-- overwriting it elsewhere.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ClickerConstants = require(ReplicatedStorage.Modules.ClickerConstants)
local PlayerState = require(ServerScriptService.Modules.PlayerState)

local amountByProductId = {}
for amount, productId in pairs(ClickerConstants.UPGRADE_PRODUCT_IDS) do
	amountByProductId[productId] = amount
end

local function grantUpgradeProduct(player, productId)
	local amount = amountByProductId[productId]
	if not amount then
		return false
	end

	local state = PlayerState.Get(player)
	if not state then
		return false
	end

	state.UpgradeLevel += amount
	PlayerState.RecomputeClickPower(player)
	PlayerState.SyncLeaderstats(player, state)

	local remotes = ReplicatedStorage:WaitForChild("ClickerRemotes")
	remotes.StatsUpdate:FireClient(player, PlayerState.BuildPayload(state))

	return true
end

MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- If they buy right as they join, wait for their data to finish loading.
	local state = PlayerState.Get(player)
	local waited = 0
	while not state and waited < 30 do
		task.wait(1)
		waited += 1
		state = PlayerState.Get(player)
	end

	if not state then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local granted = grantUpgradeProduct(player, receiptInfo.ProductId)
	if not granted then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end
