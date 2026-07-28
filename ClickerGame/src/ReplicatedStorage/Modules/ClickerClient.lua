-- ModuleScript. Client-side API for the clicker game.
-- Require this from any LocalScript in your GUI to wire up buttons and
-- read live stats, e.g.:
--
--   local ClickerClient = require(game.ReplicatedStorage.Modules.ClickerClient)
--   clickButton.Activated:Connect(ClickerClient.Click)
--   ClickerClient.OnStatsChanged(function(stats)
--       moneyLabel.Text = "Money: " .. stats.Money
--   end)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:WaitForChild("ClickerRemotes")
local clickRequest = remotes:WaitForChild("ClickRequest")
local sellRequest = remotes:WaitForChild("SellRequest")
local buyUpgradeRequest = remotes:WaitForChild("BuyUpgradeRequest")
local rebirthRequest = remotes:WaitForChild("RebirthRequest")
local statsUpdate = remotes:WaitForChild("StatsUpdate")

local ClickerClient = {}

-- Latest snapshot from the server:
-- { Clicks, Money, Rebirths, ClickPower, UpgradeLevel, NextUpgradeCost, RebirthGainPreview }
ClickerClient.Stats = nil

local listeners = {}

-- Registers a callback for whenever the server pushes new stats. Fires
-- immediately with the current snapshot if one is already known. Returns
-- a function that unsubscribes the callback.
function ClickerClient.OnStatsChanged(callback)
	table.insert(listeners, callback)
	if ClickerClient.Stats then
		callback(ClickerClient.Stats)
	end

	return function()
		local index = table.find(listeners, callback)
		if index then
			table.remove(listeners, index)
		end
	end
end

statsUpdate.OnClientEvent:Connect(function(stats)
	ClickerClient.Stats = stats
	for _, callback in ipairs(listeners) do
		callback(stats)
	end
end)

function ClickerClient.Click()
	clickRequest:FireServer()
end

-- percent must be one of ClickerConstants.SELL_PERCENT_OPTIONS (0.10, 0.25,
-- 0.50, 1.00) -- the server rejects anything else.
function ClickerClient.Sell(percent)
	sellRequest:FireServer(percent)
end

-- amount is a positive integer (buy up to that many levels, limited by
-- what's affordable) or the string "Max" (buy as many as affordable).
function ClickerClient.BuyUpgrade(amount)
	buyUpgradeRequest:FireServer(amount)
end

function ClickerClient.Rebirth()
	rebirthRequest:FireServer()
end

return ClickerClient
