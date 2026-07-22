-- Creates RemoteEvents, sets up leaderstats, loads/saves player data, and
-- runs the passive-income tick loop. Everything else (clicking, buying
-- upgrades, rebirthing) is handled by the other numbered scripts.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConstants = require(ReplicatedStorage.Modules.GameConstants)
local EconomyUtil = require(ServerScriptService.Modules.EconomyUtil)
local PlayerDataStore = require(ServerScriptService.Modules.PlayerDataStore)
local Replication = require(ServerScriptService.Modules.Replication)

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local function newRemoteEvent(name)
	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = remotes
	return event
end

newRemoteEvent("ClickEvent")
newRemoteEvent("BuyUpgradeEvent")
newRemoteEvent("RebirthEvent")
newRemoteEvent("MassRebirthEvent")
newRemoteEvent("DataUpdateEvent")

local function setupLeaderstats(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = 0
	rebirths.Parent = leaderstats

	local cash = Instance.new("StringValue")
	cash.Name = "Cash"
	cash.Value = "$0"
	cash.Parent = leaderstats
end

Players.PlayerAdded:Connect(function(player)
	setupLeaderstats(player)
	local state = PlayerDataStore.Load(player)
	Replication.PushUpdate(player, state)
end)

Players.PlayerRemoving:Connect(function(player)
	PlayerDataStore.Save(player)
	PlayerDataStore.Release(player)
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		PlayerDataStore.Save(player)
	end
end)

task.spawn(function()
	while true do
		task.wait(GameConstants.INCOME_TICK_SECONDS)
		for _, player in ipairs(Players:GetPlayers()) do
			local state = PlayerDataStore.Get(player)
			if state then
				local income = EconomyUtil.GetIncomePerSecond(state)
				if income > 0 then
					state.Money += income
					Replication.PushUpdate(player, state)
				end
			end
		end
	end
end)
