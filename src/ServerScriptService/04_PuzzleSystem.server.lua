-- Script: ServerScriptService.04_PuzzleSystem
-- Generic pressure-plate/door system, matched by a "GroupId" attribute.
-- Polls instead of relying purely on Touched/TouchEnded, which is more
-- robust when an Echo standing on a plate gets destroyed mid-contact.

local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local OccupancyUtil = require(script.Parent.Modules.OccupancyUtil)

local doorsByGroup = {}  -- [groupId] = { doors = {}, plates = {} }
local doorOpenState = {} -- [door] = bool

local function getGroup(groupId)
	if not doorsByGroup[groupId] then
		doorsByGroup[groupId] = { doors = {}, plates = {} }
	end
	return doorsByGroup[groupId]
end

local function registerDoor(door)
	local groupId = door:GetAttribute("GroupId")
	if not groupId then
		return
	end
	table.insert(getGroup(groupId).doors, door)
	doorOpenState[door] = false
end

local function registerPlate(plate)
	local groupId = plate:GetAttribute("GroupId")
	if not groupId then
		return
	end
	table.insert(getGroup(groupId).plates, plate)
end

for _, d in ipairs(CollectionService:GetTagged("PressureDoor")) do
	registerDoor(d)
end
for _, p in ipairs(CollectionService:GetTagged("PressurePlate")) do
	registerPlate(p)
end
CollectionService:GetInstanceAddedSignal("PressureDoor"):Connect(registerDoor)
CollectionService:GetInstanceAddedSignal("PressurePlate"):Connect(registerPlate)

local function setDoorOpen(door, open)
	if doorOpenState[door] == open then
		return
	end
	doorOpenState[door] = open
	local goal = open and { Transparency = 1 } or { Transparency = 0.15 }
	TweenService:Create(door, TweenInfo.new(0.6, Enum.EasingStyle.Quad), goal):Play()
	door.CanCollide = not open
end

local accum = 0
RunService.Heartbeat:Connect(function(dt)
	accum += dt
	if accum < 0.2 then
		return
	end
	accum = 0

	for _, group in pairs(doorsByGroup) do
		if #group.plates > 0 then
			local allActive = true
			for _, plate in ipairs(group.plates) do
				if not plate.Parent or not OccupancyUtil.isPlateActive(plate) then
					allActive = false
					break
				end
			end
			for _, door in ipairs(group.doors) do
				if door.Parent then
					setDoorOpen(door, allActive)
				end
			end
		end
	end
end)

print("[Echobound] Puzzle system online.")
