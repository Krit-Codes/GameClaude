-- Handles the client's "I clicked the money button" request. Server-side
-- rate limiting stops a modified client from firing the remote faster than
-- humanly possible to farm money.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConstants = require(ReplicatedStorage.Modules.GameConstants)
local EconomyUtil = require(ServerScriptService.Modules.EconomyUtil)
local PlayerDataStore = require(ServerScriptService.Modules.PlayerDataStore)
local Replication = require(ServerScriptService.Modules.Replication)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local clickEvent = remotes:WaitForChild("ClickEvent")

local lastClickAt = {} -- [userId] = os.clock() of last accepted click

clickEvent.OnServerEvent:Connect(function(player)
	local state = PlayerDataStore.Get(player)
	if not state then
		return
	end

	local now = os.clock()
	local last = lastClickAt[player.UserId]
	if last and (now - last) < GameConstants.CLICK_RATE_LIMIT then
		return
	end
	lastClickAt[player.UserId] = now

	state.Money += EconomyUtil.GetClickValue(state)
	Replication.PushUpdate(player, state)
end)

Players.PlayerRemoving:Connect(function(player)
	lastClickAt[player.UserId] = nil
end)
