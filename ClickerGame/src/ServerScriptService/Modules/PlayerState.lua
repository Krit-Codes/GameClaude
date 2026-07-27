-- ModuleScript. Owns each player's clicker save-data: loading/saving it
-- via DataStoreService, deriving ClickPower/upgrade cost from it, and
-- mirroring it onto leaderstats.

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClickerConstants = require(ReplicatedStorage.Modules.ClickerConstants)

local clickerStore = DataStoreService:GetDataStore("ClickerGame_v1")

local PlayerState = {}
PlayerState._data = {} -- [player] = state table

local function computeClickPower(state)
	local base = ClickerConstants.BASE_CLICK_POWER + (state.UpgradeLevel * ClickerConstants.UPGRADE_POWER_INCREMENT)
	local rebirthBonus = state.Rebirths * ClickerConstants.REBIRTH_FLAT_CLICK_BONUS
	local rebirthMultiplier = ClickerConstants.REBIRTH_MULTIPLIER_PER_REBIRTH ^ state.Rebirths
	return (base + rebirthBonus) * rebirthMultiplier
end

local function computeUpgradeCost(state)
	return math.floor(ClickerConstants.UPGRADE_BASE_COST * (ClickerConstants.UPGRADE_COST_MULTIPLIER ^ state.UpgradeLevel))
end

PlayerState.ComputeClickPower = computeClickPower
PlayerState.ComputeUpgradeCost = computeUpgradeCost

function PlayerState.Load(player)
	local default = {
		Clicks = 0,
		Money = 0,
		Rebirths = 0,
		UpgradeLevel = 0,
	}

	local saved
	local ok, err = pcall(function()
		saved = clickerStore:GetAsync("Player_" .. player.UserId)
	end)
	if not ok then
		warn("[ClickerGame] Failed to load data for " .. player.Name .. ": " .. tostring(err))
	end

	local state = saved or default
	state.ClickPower = computeClickPower(state)
	state.LastClickTime = 0
	PlayerState._data[player] = state
	return state
end

function PlayerState.Save(player)
	local state = PlayerState._data[player]
	if not state then
		return
	end

	local ok, err = pcall(function()
		clickerStore:SetAsync("Player_" .. player.UserId, {
			Clicks = state.Clicks,
			Money = state.Money,
			Rebirths = state.Rebirths,
			UpgradeLevel = state.UpgradeLevel,
		})
	end)
	if not ok then
		warn("[ClickerGame] Failed to save data for " .. player.Name .. ": " .. tostring(err))
	end
end

function PlayerState.Release(player)
	PlayerState.Save(player)
	PlayerState._data[player] = nil
end

function PlayerState.Get(player)
	return PlayerState._data[player]
end

function PlayerState.RecomputeClickPower(player)
	local state = PlayerState._data[player]
	if not state then
		return
	end
	state.ClickPower = computeClickPower(state)
end

-- Creates the default Roblox leaderboard entries so progress is visible
-- immediately, even before a custom GUI reads from ClickerClient.
function PlayerState.SetupLeaderstats(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local clicks = Instance.new("IntValue")
	clicks.Name = "Clicks"
	clicks.Parent = leaderstats

	local money = Instance.new("IntValue")
	money.Name = "Money"
	money.Parent = leaderstats

	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Parent = leaderstats

	leaderstats.Parent = player
	return leaderstats
end

function PlayerState.SyncLeaderstats(player, state)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end
	leaderstats.Clicks.Value = math.floor(state.Clicks)
	leaderstats.Money.Value = math.floor(state.Money)
	leaderstats.Rebirths.Value = state.Rebirths
end

-- Builds the payload sent to the client: raw state plus everything a GUI
-- needs to render (next upgrade cost, rebirth preview) without having to
-- know the game's constants/formulas itself.
function PlayerState.BuildPayload(state)
	return {
		Clicks = state.Clicks,
		Money = state.Money,
		Rebirths = state.Rebirths,
		UpgradeLevel = state.UpgradeLevel,
		ClickPower = state.ClickPower,
		NextUpgradeCost = computeUpgradeCost(state),
		RebirthGainPreview = math.floor(state.Money / ClickerConstants.REBIRTH_MONEY_DIVISOR),
	}
end

return PlayerState
