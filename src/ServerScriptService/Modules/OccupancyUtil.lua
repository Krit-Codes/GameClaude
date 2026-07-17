-- ModuleScript: ServerScriptService.Modules.OccupancyUtil
-- Helpers for detecting whether a plate/pillar is currently "held down"
-- by a live player character or a spawned Echo.

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local OccupancyUtil = {}

function OccupancyUtil.isValidOccupant(hitPart)
	if not hitPart or not hitPart:IsA("BasePart") then
		return false
	end
	local model = hitPart:FindFirstAncestorOfClass("Model")
	if not model then
		return false
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end
	if Players:GetPlayerFromCharacter(model) then
		return true
	end
	if CollectionService:HasTag(model, "Echo") then
		return true
	end
	return false
end

function OccupancyUtil.isPlateActive(part)
	for _, touching in ipairs(part:GetTouchingParts()) do
		if OccupancyUtil.isValidOccupant(touching) then
			return true
		end
	end
	return false
end

return OccupancyUtil
