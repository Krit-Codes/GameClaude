-- ModuleScript: ReplicatedStorage.Modules.EchoConstants
-- Shared tuning values used by both server and client scripts.

local EchoConstants = {}

EchoConstants.RECORD_MAX_SECONDS = 8
EchoConstants.RECORD_RECHARGE_SECONDS = 12
EchoConstants.SAMPLE_INTERVAL = 0.05
EchoConstants.MAX_ECHOES_PER_PLAYER = 3

-- Standard public R15 default-avatar animation ids.
EchoConstants.ANIM_IDS = {
	Idle = "rbxassetid://507766388",
	Walk = "rbxassetid://913402923",
	Jump = "rbxassetid://507765000",
}

EchoConstants.COLOR_PULSE_COST = 0.34
EchoConstants.COLOR_PULSE_RANGE = 16
EchoConstants.COLOR_PULSE_DAMAGE = 15
EchoConstants.COLOR_PULSE_COOLDOWN = 1.5

EchoConstants.BOSS_MAX_HP = 300
EchoConstants.MAX_COLOR_SHARDS = 6

return EchoConstants
