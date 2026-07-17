-- ModuleScript: ServerScriptService.Modules.PlayerState
-- Shared server-only state, keyed by Player instance.

local PlayerState = {}

local recordings = {}   -- [player] = { frames = {...}, duration = number }
local activeEchoes = {}  -- [player] = { [echoModel] = true }
local colorCharge = {}   -- [player] = number 0..1
local echoCounter = {}   -- [player] = number of currently alive echoes

function PlayerState.init(player)
	recordings[player] = nil
	activeEchoes[player] = {}
	colorCharge[player] = 0
	echoCounter[player] = 0
end

function PlayerState.cleanup(player)
	recordings[player] = nil
	activeEchoes[player] = nil
	colorCharge[player] = nil
	echoCounter[player] = nil
end

function PlayerState.setRecording(player, frames, duration)
	recordings[player] = { frames = frames, duration = duration }
end

function PlayerState.getRecording(player)
	return recordings[player]
end

function PlayerState.addEcho(player, echoModel)
	if not activeEchoes[player] then
		activeEchoes[player] = {}
	end
	activeEchoes[player][echoModel] = true
	echoCounter[player] = (echoCounter[player] or 0) + 1
end

function PlayerState.removeEcho(player, echoModel)
	if activeEchoes[player] then
		activeEchoes[player][echoModel] = nil
	end
	echoCounter[player] = math.max(0, (echoCounter[player] or 1) - 1)
end

function PlayerState.getEchoCount(player)
	return echoCounter[player] or 0
end

function PlayerState.getEchoes(player)
	if not activeEchoes[player] then
		activeEchoes[player] = {}
	end
	return activeEchoes[player]
end

function PlayerState.getColorCharge(player)
	return colorCharge[player] or 0
end

function PlayerState.setColorCharge(player, value)
	colorCharge[player] = math.clamp(value, 0, 1)
end

function PlayerState.addColorCharge(player, delta)
	PlayerState.setColorCharge(player, PlayerState.getColorCharge(player) + delta)
end

return PlayerState
