-- Script. Grants upgrade levels for the Robux Game Passes, once per player,
-- ever. Only the server can be trusted to confirm a real purchase happened,
-- so this never trusts anything the client claims.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ClickerConstants = require(ReplicatedStorage.Modules.ClickerConstants)
local PlayerState = require(ServerScriptService.Modules.PlayerState)

local amountByGamePassId = {}
for amount, gamePassId in pairs(ClickerConstants.UPGRADE_GAME_PASS_IDS) do
	if gamePassId and gamePassId ~= 0 then
		amountByGamePassId[gamePassId] = amount
	end
end

local function grantUpgradeGamePass(player, gamePassId)
	local amount = amountByGamePassId[gamePassId]
	if not amount then
		return
	end

	local state = PlayerState.Get(player)
	if not state then
		return
	end

	if state.ClaimedGamePasses[gamePassId] then
		return -- already granted this pass to this player, don't double-grant
	end
	state.ClaimedGamePasses[gamePassId] = true

	state.UpgradeLevel += amount
	PlayerState.RecomputeClickPower(player)
	PlayerState.SyncLeaderstats(player, state)

	local remotes = ReplicatedStorage:WaitForChild("ClickerRemotes")
	remotes.StatsUpdate:FireClient(player, PlayerState.BuildPayload(state))
end

local function checkOwnedPassesForPlayer(player)
	for gamePassId in pairs(amountByGamePassId) do
		local ok, owns = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamePassId)
		end)
		if ok and owns then
			grantUpgradeGamePass(player, gamePassId)
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	local state = PlayerState.Get(player)
	while not state do
		task.wait()
		state = PlayerState.Get(player)
	end

	checkOwnedPassesForPlayer(player)
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
	if wasPurchased then
		grantUpgradeGamePass(player, gamePassId)
	end
end)
