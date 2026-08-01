-- Script: ServerScriptService.08_EchoScriptDemo  (OPTIONAL — not part of the
-- required Studio setup in the main README; add it only if you want to see
-- EchoScript run live).
--
-- Runs examples/intro_cutscene.echo (embedded below, since scripts in a
-- running game can't read files off the repo) through the EchoScript
-- interpreter with a minimal host API that just prints, so you can watch it
-- execute in the server output. A real integration would swap this host API
-- for one that fires the existing `PlayCutscene` remote / tweens the camera,
-- the way 07_NarrativeCutscenes.server.lua does by hand — see
-- docs/EchoScript.md for the embedding pattern.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EchoScript = require(ReplicatedStorage.Modules.EchoScript.EchoScript)

local SOURCE = [[
fn beat(dx, dy, dz, holdSeconds, line) {
	moveCamera(dx, dy, dz, holdSeconds)
	if len(line) > 0 {
		say(line)
	}
	wait(holdSeconds)
}

say("The Fracture awakens.")

beat(0, 25, 0, 3, "The Fracture: a memory that broke instead of fading.")
beat(20, 8, 20, 3, "You are a Warden of Echoes. You can record your own actions...")
beat(-15, 6, 10, 3, "...and leave them behind as loops of light, to hold what you cannot hold alone.")

let shardsFound = 0
if shardsFound == 0 {
	say("Find the Color Shards. The world remembers what you restore.")
} else {
	say("Welcome back, Warden.")
}
]]

local hostApi = {
	say = function(text)
		print("[EchoScript demo] say: " .. tostring(text))
	end,
	moveCamera = function(dx, dy, dz, seconds)
		print(string.format("[EchoScript demo] moveCamera offset=(%s, %s, %s) over %ss", tostring(dx), tostring(dy), tostring(dz), tostring(seconds)))
	end,
	wait = function(seconds)
		-- Skip the real wait so the demo prints instantly at server start;
		-- a real cutscene host API would call task.wait(seconds) here.
	end,
}

local ok, resultOrErr = EchoScript.run(SOURCE, hostApi)
if ok then
	print("[EchoScript demo] finished successfully.")
else
	warn("[EchoScript demo] failed: " .. tostring(resultOrErr))
end
