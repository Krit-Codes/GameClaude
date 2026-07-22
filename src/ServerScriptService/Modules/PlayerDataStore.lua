-- Owns the authoritative in-memory state for every connected player and
-- persists it to DataStoreService. All money/upgrade/rebirth mutations in
-- the remote handlers go through the table returned by Get(), never a copy.

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConstants = require(ReplicatedStorage.Modules.GameConstants)

local store = DataStoreService:GetDataStore(GameConstants.DATASTORE_NAME)

local PlayerDataStore = {}
local cache = {} -- [userId] = state table

local function defaultState()
	return {
		Money = 0,
		Rebirths = 0,
		Upgrades = {},
	}
end

function PlayerDataStore.Load(player)
	local state = defaultState()

	local success, result = pcall(function()
		return store:GetAsync("Player_" .. player.UserId)
	end)

	if success and result then
		state.Money = result.Money or 0
		state.Rebirths = result.Rebirths or 0
		state.Upgrades = result.Upgrades or {}
	elseif not success then
		warn(("PlayerDataStore: failed to load data for %s: %s"):format(player.Name, tostring(result)))
	end

	cache[player.UserId] = state
	return state
end

function PlayerDataStore.Get(player)
	return cache[player.UserId]
end

function PlayerDataStore.Save(player)
	local state = cache[player.UserId]
	if not state then
		return
	end

	local success, err = pcall(function()
		store:SetAsync("Player_" .. player.UserId, state)
	end)

	if not success then
		warn(("PlayerDataStore: failed to save data for %s: %s"):format(player.Name, tostring(err)))
	end
end

function PlayerDataStore.Release(player)
	cache[player.UserId] = nil
end

return PlayerDataStore
