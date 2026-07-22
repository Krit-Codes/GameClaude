-- Periodically saves every connected player's data so progress survives a
-- server crash, not just a clean leave (which 01_Bootstrap already covers).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConstants = require(ReplicatedStorage.Modules.GameConstants)
local PlayerDataStore = require(ServerScriptService.Modules.PlayerDataStore)

task.spawn(function()
	while true do
		task.wait(GameConstants.AUTOSAVE_INTERVAL)
		for _, player in ipairs(Players:GetPlayers()) do
			PlayerDataStore.Save(player)
		end
	end
end)
