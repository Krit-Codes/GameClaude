-- Script: ServerScriptService.06_BossHollow
-- "The Hollow" — a procedurally-built, procedurally-animated boss that
-- steals the player's own recorded Echo pattern and throws it back at
-- them. Damaged by covering all three Resonance Pillars with Echoes
-- (reusing the core puzzle mechanic) or by unleashing a Color Pulse (F).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local EchoConstants = require(ReplicatedStorage.Modules.EchoConstants)
local PlayerState = require(script.Parent.Modules.PlayerState)
local OccupancyUtil = require(script.Parent.Modules.OccupancyUtil)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local playCutsceneEvent = remotes:WaitForChild("PlayCutscene")
local bossHudEvent = remotes:WaitForChild("BossHUD")
local flashEvent = remotes:WaitForChild("FlashScreen")
local notifyEvent = remotes:WaitForChild("Notify")
local colorPulseRequest = remotes:WaitForChild("ColorPulseRequest")

local vfxFolder = Workspace:WaitForChild("VFX")

local ARENA_CENTER = Vector3.new(0, 14, 330)
local ENTRY_POINT = CFrame.new(0, 2, 300)

local bossState = "idle" -- idle | intro | fighting | defeated
local bossHp = EchoConstants.BOSS_MAX_HP
local bossModel = nil
local corePart = nil
local fightConnections = {}
local lastPulseTime = {}

local function broadcastBossHud(visible)
	bossHudEvent:FireAllClients({
		visible = visible,
		name = "THE HOLLOW",
		hp = bossHp,
		maxHp = EchoConstants.BOSS_MAX_HP,
	})
end

local function buildHollow()
	local model = Instance.new("Model")
	model.Name = "TheHollow"

	local core = Instance.new("Part")
	core.Name = "Core"
	core.Shape = Enum.PartType.Ball
	core.Size = Vector3.new(7, 7, 7)
	core.Color = Color3.fromRGB(25, 10, 35)
	core.Material = Enum.Material.Neon
	core.Anchored = true
	core.CanCollide = false
	core.CFrame = CFrame.new(ARENA_CENTER)
	core.Parent = model

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(150, 60, 200)
	light.Range = 30
	light.Brightness = 3
	light.Parent = core

	model.PrimaryPart = core

	local tendrils = {}
	for i = 1, 6 do
		local tendril = Instance.new("Part")
		tendril.Name = "Tendril" .. i
		tendril.Size = Vector3.new(0.8, 0.8, 5)
		tendril.Color = Color3.fromRGB(60, 20, 80)
		tendril.Material = Enum.Material.Neon
		tendril.Anchored = true
		tendril.CanCollide = false
		tendril.Parent = model
		table.insert(tendrils, tendril)
	end

	model.Parent = vfxFolder
	return model, core, tendrils
end

local function animateHollow(core, tendrils)
	local t = 0
	return RunService.Heartbeat:Connect(function(dt)
		t += dt
		local bob = math.sin(t * 1.5) * 1.5
		local corePos = ARENA_CENTER + Vector3.new(0, bob, 0)
		core.CFrame = CFrame.new(corePos) * CFrame.Angles(0, t * 0.6, 0)

		for i, tendril in ipairs(tendrils) do
			local angle = t * 1.2 + (i * (math.pi * 2 / #tendrils))
			local radius = 5 + math.sin(t * 2 + i) * 1
			local offset = Vector3.new(math.cos(angle) * radius, math.sin(t * 3 + i) * 2, math.sin(angle) * radius)
			local pos = corePos + offset
			tendril.CFrame = CFrame.new(pos, corePos)
		end
	end)
end

local function damagePlayer(player, amount)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		humanoid:TakeDamage(amount)
		flashEvent:FireClient(player, Color3.fromRGB(200, 40, 60), 0.4)
	end
end

local function getFightingPlayers()
	local result = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and (root.Position - ARENA_CENTER).Magnitude < 45 then
			table.insert(result, player)
		end
	end
	return result
end

local function fireShadowBolt(targetPlayer)
	if not corePart then
		return
	end
	local character = targetPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local bolt = Instance.new("Part")
	bolt.Name = "ShadowBolt"
	bolt.Shape = Enum.PartType.Ball
	bolt.Size = Vector3.new(2, 2, 2)
	bolt.Color = Color3.fromRGB(80, 20, 100)
	bolt.Material = Enum.Material.Neon
	bolt.Anchored = true
	bolt.CanCollide = false
	bolt.CFrame = corePart.CFrame
	bolt.Parent = vfxFolder

	local startPos = corePart.Position
	local elapsed = 0
	local travelTime = 1.6
	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		if not bolt.Parent then
			conn:Disconnect()
			return
		end
		elapsed += dt
		local alpha = math.clamp(elapsed / travelTime, 0, 1)
		local liveCharacter = targetPlayer.Character
		local liveRoot = liveCharacter and liveCharacter:FindFirstChild("HumanoidRootPart")
		local targetPos = liveRoot and liveRoot.Position or startPos
		bolt.CFrame = CFrame.new(startPos:Lerp(targetPos, alpha))
		if alpha >= 1 then
			if liveRoot and (liveRoot.Position - bolt.Position).Magnitude < 5 then
				damagePlayer(targetPlayer, 15)
			end
			bolt:Destroy()
			conn:Disconnect()
		end
	end)
	Debris:AddItem(bolt, travelTime + 1)
end

local function fireEchoMimic(targetPlayer)
	local recording = PlayerState.getRecording(targetPlayer)
	if not recording then
		return
	end

	local ghost = Instance.new("Part")
	ghost.Name = "EchoMimic"
	ghost.Size = Vector3.new(2, 2, 1)
	ghost.Color = Color3.fromRGB(120, 20, 140)
	ghost.Material = Enum.Material.Neon
	ghost.Transparency = 0.2
	ghost.Anchored = true
	ghost.CanCollide = false
	ghost.CFrame = recording.frames[1].cf
	ghost.Parent = vfxFolder

	local startTime = os.clock()
	local frames = recording.frames
	local duration = recording.duration
	local hitPlayers = {}

	local conn
	conn = RunService.Heartbeat:Connect(function()
		if not ghost.Parent then
			conn:Disconnect()
			return
		end
		local elapsed = os.clock() - startTime
		if elapsed >= duration then
			ghost:Destroy()
			conn:Disconnect()
			return
		end
		local idx = math.clamp(math.floor(elapsed / EchoConstants.SAMPLE_INTERVAL) + 1, 1, #frames)
		local nextIdx = math.min(idx + 1, #frames)
		local a, b = frames[idx], frames[nextIdx]
		local alpha = 0
		if b.t > a.t then
			alpha = math.clamp((elapsed - a.t) / (b.t - a.t), 0, 1)
		end
		local cf = a.cf:Lerp(b.cf, alpha)
		ghost.CFrame = cf

		for _, player in ipairs(getFightingPlayers()) do
			if not hitPlayers[player] then
				local pc = player.Character
				local pr = pc and pc:FindFirstChild("HumanoidRootPart")
				if pr and (pr.Position - cf.Position).Magnitude < 4 then
					hitPlayers[player] = true
					damagePlayer(player, 30)
				end
			end
		end
	end)
	Debris:AddItem(ghost, duration + 0.5)
end

local function telegraphPulse()
	local ring = Instance.new("Part")
	ring.Name = "PulseTelegraph"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(1, 44, 44)
	ring.CFrame = CFrame.new(ARENA_CENTER - Vector3.new(0, 13.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Color = Color3.fromRGB(200, 40, 60)
	ring.Material = Enum.Material.Neon
	ring.Transparency = 0.8
	ring.Anchored = true
	ring.CanCollide = false
	ring.Parent = vfxFolder

	TweenService:Create(ring, TweenInfo.new(1.5), { Transparency = 0.2 }):Play()

	task.delay(1.5, function()
		if bossState ~= "fighting" then
			ring:Destroy()
			return
		end
		for _, player in ipairs(getFightingPlayers()) do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root then
				local onPillar = false
				for _, pillar in ipairs(CollectionService:GetTagged("ResonancePillar")) do
					local flat = Vector3.new(root.Position.X, pillar.Position.Y, root.Position.Z)
					if (flat - pillar.Position).Magnitude < 4 then
						onPillar = true
						break
					end
				end
				local flatDist = Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(ARENA_CENTER.X, 0, ARENA_CENTER.Z)
				if not onPillar and flatDist.Magnitude < 26 then
					damagePlayer(player, 20)
				end
			end
		end
		flashEvent:FireAllClients(Color3.fromRGB(200, 40, 60), 0.5)
		ring:Destroy()
	end)
end

local function pillarBeamDamageLoop(dt)
	local pillars = CollectionService:GetTagged("ResonancePillar")
	if #pillars < 3 then
		return
	end

	local allCovered = true
	for _, pillar in ipairs(pillars) do
		local covered = false
		for _, p in ipairs(pillar:GetTouchingParts()) do
			if OccupancyUtil.isValidOccupant(p) then
				covered = true
				break
			end
		end
		if not covered then
			allCovered = false
			break
		end
	end

	if allCovered then
		bossHp = math.max(0, bossHp - 12 * dt)
		broadcastBossHud(true)
	end
end

local function startPhaseAttacks()
	local timers = { bolt = 0, mimic = 0, pulse = 0 }
	local conn = RunService.Heartbeat:Connect(function(dt)
		if bossState ~= "fighting" then
			return
		end

		pillarBeamDamageLoop(dt)

		local fighters = getFightingPlayers()
		if #fighters == 0 then
			return
		end

		local hpFrac = bossHp / EchoConstants.BOSS_MAX_HP

		timers.bolt += dt
		if timers.bolt >= 4 then
			timers.bolt = 0
			fireShadowBolt(fighters[math.random(1, #fighters)])
		end

		if hpFrac <= 0.66 then
			timers.mimic += dt
			if timers.mimic >= 7 then
				timers.mimic = 0
				fireEchoMimic(fighters[math.random(1, #fighters)])
			end
		end

		if hpFrac <= 0.33 then
			timers.pulse += dt
			if timers.pulse >= 9 then
				timers.pulse = 0
				telegraphPulse()
			end
		end

		if bossHp <= 0 then
			bossState = "defeated"
		end
	end)
	table.insert(fightConnections, conn)
end

local function endFight()
	for _, conn in ipairs(fightConnections) do
		conn:Disconnect()
	end
	fightConnections = {}
end

colorPulseRequest.OnServerEvent:Connect(function(player)
	if bossState ~= "fighting" or not corePart then
		return
	end
	local now = os.clock()
	if lastPulseTime[player] and now - lastPulseTime[player] < EchoConstants.COLOR_PULSE_COOLDOWN then
		return
	end
	local charge = PlayerState.getColorCharge(player)
	if charge < EchoConstants.COLOR_PULSE_COST then
		notifyEvent:FireClient(player, "Not enough restored Color to pulse.", 2)
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	if (root.Position - corePart.Position).Magnitude > EchoConstants.COLOR_PULSE_RANGE then
		notifyEvent:FireClient(player, "Too far from The Hollow.", 2)
		return
	end

	lastPulseTime[player] = now
	PlayerState.addColorCharge(player, -EchoConstants.COLOR_PULSE_COST)
	bossHp = math.max(0, bossHp - EchoConstants.COLOR_PULSE_DAMAGE)
	broadcastBossHud(true)
	flashEvent:FireAllClients(Color3.new(1, 1, 1), 0.3)
end)

local function playDeathSequence()
	bossState = "defeated"
	endFight()

	if bossModel then
		local core = bossModel:FindFirstChild("Core")
		if core then
			TweenService:Create(core, TweenInfo.new(2), { Size = Vector3.new(0.1, 0.1, 0.1), Transparency = 1 }):Play()
		end
		local modelRef = bossModel
		task.delay(2.2, function()
			modelRef:Destroy()
		end)
	end

	broadcastBossHud(false)
	flashEvent:FireAllClients(Color3.new(1, 1, 1), 1.2)

	for _, player in ipairs(Players:GetPlayers()) do
		notifyEvent:FireClient(player, "The Hollow dissolves. The Fracture remembers itself.", 5)
	end

	local victoryData = {
		waypoints = {
			{ cf = CFrame.new(ARENA_CENTER + Vector3.new(0, 10, 30), ARENA_CENTER), time = 3, speaker = "The Fracture", text = "Color returns where memory once was lost." },
			{ cf = CFrame.new(ARENA_CENTER + Vector3.new(20, 6, 0), ARENA_CENTER), time = 3, speaker = "", text = "You are the Warden of Echoes. This place remembers you." },
		},
	}
	for _, player in ipairs(Players:GetPlayers()) do
		playCutsceneEvent:FireClient(player, victoryData)
	end
end

local function startFight()
	bossState = "fighting"
	bossHp = EchoConstants.BOSS_MAX_HP
	local model, core, tendrils = buildHollow()
	bossModel = model
	corePart = core
	table.insert(fightConnections, animateHollow(core, tendrils))
	broadcastBossHud(true)
	startPhaseAttacks()

	task.spawn(function()
		while bossState == "fighting" do
			task.wait(0.5)
			if bossHp <= 0 then
				playDeathSequence()
				break
			end
		end
	end)
end

local function startIntro()
	bossState = "intro"

	local introData = {
		waypoints = {
			{ cf = CFrame.new(ARENA_CENTER + Vector3.new(0, 5, 40), ARENA_CENTER), time = 2.5, speaker = "???", text = "Another Warden. Another set of footsteps to steal." },
			{ cf = CFrame.new(ARENA_CENTER + Vector3.new(-25, 8, 5), ARENA_CENTER), time = 2.5, speaker = "The Hollow", text = "I remember everything you do. I will use it against you." },
			{ cf = CFrame.new(ARENA_CENTER + Vector3.new(0, 3, -20), ARENA_CENTER), time = 2, speaker = "", text = "Cover the three pillars with Echoes to wound it. Press F near it to unleash restored Color." },
		},
	}

	for _, player in ipairs(Players:GetPlayers()) do
		playCutsceneEvent:FireClient(player, introData)
	end

	task.delay(7.2, function()
		if bossState == "intro" then
			startFight()
		end
	end)
end

local function onBossGate(gate)
	local prompt = gate:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		return
	end
	prompt.Triggered:Connect(function(player)
		if bossState == "fighting" or bossState == "intro" then
			notifyEvent:FireClient(player, "The Hollow already stirs.", 2)
			return
		end
		if bossState == "defeated" then
			notifyEvent:FireClient(player, "The Hollow is already gone.", 2)
			return
		end
		local character = player.Character
		if character then
			character:PivotTo(ENTRY_POINT)
		end
		startIntro()
	end)
end

for _, gate in ipairs(CollectionService:GetTagged("BossGate")) do
	onBossGate(gate)
end
CollectionService:GetInstanceAddedSignal("BossGate"):Connect(onBossGate)

print("[Echobound] Boss Hollow online.")
