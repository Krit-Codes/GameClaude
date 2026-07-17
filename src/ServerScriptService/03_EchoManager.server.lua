-- Script: ServerScriptService.03_EchoManager
-- Validates client-recorded movement loops, spawns "Echo" clones that
-- replay them forever, and animates them via PivotTo + AnimationTracks.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local EchoConstants = require(ReplicatedStorage.Modules.EchoConstants)
local PlayerState = require(script.Parent.Modules.PlayerState)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local recordStopEvent = remotes:WaitForChild("RecordStop")
local dismissEvent = remotes:WaitForChild("DismissEchoes")
local notifyEvent = remotes:WaitForChild("Notify")
local echoHudEvent = remotes:WaitForChild("EchoHUD")

local echoesFolder = Workspace:WaitForChild("Echoes")

local activeConnections = {} -- [echoModel] = RBXScriptConnection

local function notify(player, text, duration)
	notifyEvent:FireClient(player, text, duration or 3)
end

local function updateHud(player)
	echoHudEvent:FireClient(player, PlayerState.getEchoCount(player), EchoConstants.MAX_ECHOES_PER_PLAYER)
end

local function stripScripts(model)
	for _, inst in ipairs(model:GetDescendants()) do
		if inst:IsA("LocalScript") or inst:IsA("Script") or inst:IsA("Tool") then
			inst:Destroy()
		end
	end
end

local function anchorAll(model)
	for _, inst in ipairs(model:GetDescendants()) do
		if inst:IsA("BasePart") then
			inst.Anchored = true
			if inst.Name ~= "HumanoidRootPart" then
				-- keep visuals, slightly translucent so echoes read as "ghosts"
				inst.Transparency = math.clamp(inst.Transparency + 0.15, 0, 0.85)
			end
		end
	end
end

local function loadAnim(animator, id)
	local anim = Instance.new("Animation")
	anim.AnimationId = id
	local ok, track = pcall(function()
		return animator:LoadAnimation(anim)
	end)
	if ok then
		return track
	end
	return nil
end

local function despawnEcho(echoModel)
	local conn = activeConnections[echoModel]
	if conn then
		conn:Disconnect()
		activeConnections[echoModel] = nil
	end
	if echoModel.Parent then
		echoModel:Destroy()
	end
end

local function spawnEcho(player, frames, duration)
	local character = player.Character
	if not character then
		return
	end

	local clone = character:Clone()
	clone.Name = player.Name .. "_Echo"
	stripScripts(clone)
	anchorAll(clone)

	local humanoid = clone:FindFirstChildOfClass("Humanoid")
	local rootPart = clone:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart then
		clone:Destroy()
		return
	end
	humanoid.PlatformStand = true

	CollectionService:AddTag(clone, "Echo")

	clone.Parent = echoesFolder
	clone:PivotTo(frames[1].cf)

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local idleTrack = loadAnim(animator, EchoConstants.ANIM_IDS.Idle)
	local walkTrack = loadAnim(animator, EchoConstants.ANIM_IDS.Walk)
	if idleTrack then
		idleTrack.Looped = true
	end
	if walkTrack then
		walkTrack.Looped = true
	end

	local currentTrack = nil
	local function setTrack(track)
		if currentTrack == track then
			return
		end
		if currentTrack then
			currentTrack:Stop(0.2)
		end
		if track then
			track:Play(0.2)
		end
		currentTrack = track
	end

	PlayerState.addEcho(player, clone)
	updateHud(player)

	local startTime = os.clock()
	local frameCount = #frames

	local conn = RunService.Heartbeat:Connect(function()
		if not clone.Parent then
			return
		end
		local elapsed = (os.clock() - startTime) % duration
		local idx = math.clamp(math.floor(elapsed / EchoConstants.SAMPLE_INTERVAL) + 1, 1, frameCount)
		local nextIdx = math.min(idx + 1, frameCount)
		local frameA = frames[idx]
		local frameB = frames[nextIdx]
		local alpha = 0
		if frameB.t > frameA.t then
			alpha = math.clamp((elapsed - frameA.t) / (frameB.t - frameA.t), 0, 1)
		end
		local cf = frameA.cf:Lerp(frameB.cf, alpha)
		clone:PivotTo(cf)

		local dist = (frameB.cf.Position - frameA.cf.Position).Magnitude
		if dist > 0.05 then
			setTrack(walkTrack or idleTrack)
		else
			setTrack(idleTrack)
		end
	end)

	activeConnections[clone] = conn

	clone.AncestryChanged:Connect(function(_, parent)
		if not parent then
			despawnEcho(clone)
			PlayerState.removeEcho(player, clone)
			updateHud(player)
		end
	end)
end

recordStopEvent.OnServerEvent:Connect(function(player, rawFrames, rawDuration)
	if typeof(rawFrames) ~= "table" or typeof(rawDuration) ~= "number" then
		return
	end
	if PlayerState.getEchoCount(player) >= EchoConstants.MAX_ECHOES_PER_PLAYER then
		notify(player, "Max Echoes active — press X to dismiss one first.", 3)
		return
	end
	if #rawFrames < 2 then
		notify(player, "Recording too short.", 2)
		return
	end

	local duration = math.clamp(rawDuration, EchoConstants.SAMPLE_INTERVAL * 2, EchoConstants.RECORD_MAX_SECONDS + 1)

	-- Sanitize: only accept well-typed frames reasonably near the player.
	local clean = {}
	local character = player.Character
	local originPos = character and character.PrimaryPart and character.PrimaryPart.Position
	for _, f in ipairs(rawFrames) do
		if typeof(f) == "table" and typeof(f.t) == "number" and typeof(f.cf) == "CFrame" then
			if not originPos or (f.cf.Position - originPos).Magnitude < 400 then
				table.insert(clean, { t = math.clamp(f.t, 0, duration), cf = f.cf })
			end
		end
	end
	table.sort(clean, function(a, b)
		return a.t < b.t
	end)

	if #clean < 2 then
		notify(player, "Recording invalid.", 2)
		return
	end

	PlayerState.setRecording(player, clean, duration)
	spawnEcho(player, clean, duration)
	notify(player, "Echo spawned.", 2)
end)

dismissEvent.OnServerEvent:Connect(function(player)
	local echoes = PlayerState.getEchoes(player)
	local toRemove = {}
	for echoModel in pairs(echoes) do
		table.insert(toRemove, echoModel)
	end
	for _, echoModel in ipairs(toRemove) do
		despawnEcho(echoModel)
	end
	notify(player, "Echoes dismissed.", 2)
end)

Players.PlayerRemoving:Connect(function(player)
	for echoModel in pairs(PlayerState.getEchoes(player)) do
		despawnEcho(echoModel)
	end
end)

print("[Echobound] Echo manager online.")
