-- Script: ServerScriptService.08_FlingSystem
-- Flings players apart when their characters get within FLING_RANGE of
-- each other. Purely physics-based (AssemblyLinearVelocity), so it needs
-- no tagging or extra remotes -- just drop this script in and it works.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local FLING_RANGE = 5          -- studs of separation that triggers a fling
local FLING_FORCE = 90         -- horizontal launch speed (studs/sec)
local FLING_UPWARD_FORCE = 55  -- vertical launch speed (studs/sec)
local FLING_COOLDOWN = 1.5     -- seconds before the same pair can be flung again

local lastFlingTimes = {} -- [pairKey] = os.clock() of last fling

local function pairKey(userId1, userId2)
	if userId1 < userId2 then
		return userId1 .. "_" .. userId2
	end
	return userId2 .. "_" .. userId1
end

local function getRootPart(player)
	local character = player.Character
	if not character then
		return nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

local function flingApart(rootA, rootB)
	local direction = rootA.Position - rootB.Position
	direction = Vector3.new(direction.X, 0, direction.Z)
	if direction.Magnitude < 0.01 then
		-- Perfectly overlapping: pick a random horizontal direction so
		-- both players still get launched apart.
		direction = Vector3.new(math.random(-10, 10), 0, math.random(-10, 10))
	end
	direction = direction.Unit

	rootA.AssemblyLinearVelocity = (direction * FLING_FORCE) + Vector3.new(0, FLING_UPWARD_FORCE, 0)
	rootB.AssemblyLinearVelocity = (-direction * FLING_FORCE) + Vector3.new(0, FLING_UPWARD_FORCE, 0)
end

RunService.Heartbeat:Connect(function()
	local players = Players:GetPlayers()
	local now = os.clock()

	for i = 1, #players do
		local rootA = getRootPart(players[i])
		if rootA then
			for j = i + 1, #players do
				local rootB = getRootPart(players[j])
				if rootB then
					local key = pairKey(players[i].UserId, players[j].UserId)
					local lastFling = lastFlingTimes[key] or 0

					if now - lastFling >= FLING_COOLDOWN then
						local distance = (rootA.Position - rootB.Position).Magnitude
						if distance <= FLING_RANGE then
							lastFlingTimes[key] = now
							flingApart(rootA, rootB)
						end
					end
				end
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local removedId = tostring(player.UserId)
	for key in pairs(lastFlingTimes) do
		if key:find("^" .. removedId .. "_") or key:find("_" .. removedId .. "$") then
			lastFlingTimes[key] = nil
		end
	end
end)

print("[Echobound] Fling System active -- get within " .. FLING_RANGE .. " studs of another player to fling!")
