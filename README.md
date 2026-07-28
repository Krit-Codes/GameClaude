# Echobound

A Roblox game about **recording loops of your own past self** and using them
to hold the present together.

## The idea

You're a Warden of Echoes, trapped in **The Fracture** — a memory that broke
instead of fading, drained of all color. Press **R** to record up to 8
seconds of your own movement. Press **R** again (or run out of Memory) and
that recording becomes a glowing **Echo**: a translucent copy of you that
loops the exact same actions forever. Echoes can hold pressure plates down
while you walk away, letting you split yourself across a puzzle to solve it
alone. Collect **Color Shards** to slowly restore the world's saturation from
dead grey back to full color, and finally confront **The Hollow** — a boss
that steals your last recorded Echo and throws it back at you as an attack.
You damage it by covering three Resonance Pillars with Echoes simultaneously
(the same trick from the puzzles, reused as a finale) or by unleashing a
Color Pulse burst with **F**.

It's a time-loop puzzle-platformer + boss fight, told through in-engine
camera cutscenes with letterboxing and typewriter dialogue, all built from
one self-contained set of scripts — **no manual level building required.**

### Controls
- **R** — start/stop recording an Echo
- **X** — dismiss all your Echoes
- **F** — Color Pulse (only useful near The Hollow, once you've collected shards)
- **E** (default) — interact with Proximity Prompts (shards, the boss gate)

## What's in this repo

```
src/
  ReplicatedStorage/
    Modules/
      EchoConstants.lua        -- ModuleScript (shared tuning values)
  ServerScriptService/
    Modules/
      PlayerState.lua          -- ModuleScript (server-only state)
      OccupancyUtil.lua        -- ModuleScript (plate/pillar occupancy checks)
    01_Bootstrap.server.lua        -- Script
    02_LevelBuilder.server.lua     -- Script
    03_EchoManager.server.lua      -- Script
    04_PuzzleSystem.server.lua     -- Script
    05_ColorRestoration.server.lua -- Script
    06_BossHollow.server.lua       -- Script
    07_NarrativeCutscenes.server.lua -- Script
    08_FlingSystem.server.lua      -- Script
    09_WalkSpeedBooster.server.lua -- Script
  StarterPlayerScripts/
    01_UIBuilder.client.lua          -- LocalScript
    02_RecordingController.client.lua -- LocalScript
    03_CutsceneController.client.lua  -- LocalScript
    04_FeedbackController.client.lua  -- LocalScript
```

The `.server.lua` / `.client.lua` suffixes are just naming hints for you —
in Studio you create the actual Instance type (`Script`, `LocalScript`, or
`ModuleScript`) as noted next to each file above.

## Setup in Roblox Studio (one-time)

1. **Set the avatar type to R15** (Home tab → Game Settings → Avatar → R15),
   so the built-in default animations play correctly on Echoes.
2. In the **Explorer**, create this exact hierarchy and paste each file's
   contents into the matching instance's `Source`:

   - `ServerScriptService`
     - `Script` named `01_Bootstrap` → paste `01_Bootstrap.server.lua`
     - `Script` named `02_LevelBuilder` → paste `02_LevelBuilder.server.lua`
     - `Script` named `03_EchoManager` → paste `03_EchoManager.server.lua`
     - `Script` named `04_PuzzleSystem` → paste `04_PuzzleSystem.server.lua`
     - `Script` named `05_ColorRestoration` → paste `05_ColorRestoration.server.lua`
     - `Script` named `06_BossHollow` → paste `06_BossHollow.server.lua`
     - `Script` named `07_NarrativeCutscenes` → paste `07_NarrativeCutscenes.server.lua`
     - `Script` named `08_FlingSystem` → paste `08_FlingSystem.server.lua`
     - `Script` named `09_WalkSpeedBooster` → paste `09_WalkSpeedBooster.server.lua`
     - `Folder` named `Modules`
       - `ModuleScript` named `PlayerState` → paste `PlayerState.lua`
       - `ModuleScript` named `OccupancyUtil` → paste `OccupancyUtil.lua`

   - `ReplicatedStorage`
     - `Folder` named `Modules`
       - `ModuleScript` named `EchoConstants` → paste `EchoConstants.lua`

   - `StarterPlayer` → `StarterPlayerScripts`
     - `LocalScript` named `01_UIBuilder` → paste `01_UIBuilder.client.lua`
     - `LocalScript` named `02_RecordingController` → paste `02_RecordingController.client.lua`
     - `LocalScript` named `03_CutsceneController` → paste `03_CutsceneController.client.lua`
     - `LocalScript` named `04_FeedbackController` → paste `04_FeedbackController.client.lua`

3. Delete the default `Baseplate` if you want (the LevelBuilder script
   creates its own spawn platform, so it's not required, just tidy).
4. Press **Play**. Everything else — RemoteEvents, the level geometry, the
   puzzle rooms, the Color Shrine, the boss arena, all lighting/mood — is
   generated automatically the moment the server starts.

No manual part placement, no manual tagging, no manual RemoteEvent creation.
Just the 12 script instances above.

## How the systems fit together

- **EchoConstants** (`ReplicatedStorage`) — single source of truth for
  timing/limits, required by both server and client code.
- **Bootstrap** — creates all `RemoteEvent`s under `ReplicatedStorage.Remotes`,
  workspace folders (`Echoes`, `Level`, `VFX`), leaderstats, and the
  desaturated mood lighting (`ColorCorrectionEffect` + `Atmosphere`).
- **LevelBuilder** — procedurally builds the spawn area, two Echo puzzle
  rooms, the Color Shrine (3 shards), the boss gate, and the arena
  (3 Resonance Pillars), tagging everything via `CollectionService` so the
  other systems just need to listen for tags — no manual wiring.
- **EchoManager** — validates client-recorded frames, clones the player's
  character into an anchored "ghost" puppet, and drives it every frame with
  `Model:PivotTo()` interpolated between recorded samples, switching between
  Idle/Walk `AnimationTrack`s based on movement speed.
- **PuzzleSystem** — generic: any `PressurePlate`/`PressureDoor` pair
  sharing a `GroupId` attribute opens the door once every plate in the group
  is occupied by the player or an Echo.
- **ColorRestoration** — shard pickups increment a saturation tween on the
  global `ColorCorrectionEffect` and add "Color Pulse" charge.
- **BossHollow** — builds and procedurally animates The Hollow (bobbing
  core + orbiting tendrils, no rig needed), runs its 3-phase attack pattern
  (shadow bolts → Echo Mimic replay of your own last recording → telegraphed
  arena pulses), and resolves damage from pillar coverage or Color Pulses.
- **FlingSystem** — checks every pair of players each frame and, when two
  characters get within `FLING_RANGE` studs of each other, launches both
  apart with an opposite horizontal + upward velocity impulse (with a
  per-pair cooldown so it doesn't spam).
- **WalkSpeedBooster** — sets every player's `Humanoid.WalkSpeed` to
  `WALK_SPEED` (32 by default, vs. the Roblox default of 16) on spawn.
- **NarrativeCutscenes** / **CutsceneController** — server sends a list of
  `{cframe, time, speaker, text}` waypoints; the client tweens the camera
  through them with letterbox bars and typewriter dialogue, then returns
  control to the player.
- **UIBuilder** / **RecordingController** / **FeedbackController** — all UI
  is built at runtime (no manual `ScreenGui` design needed) and kept in sync
  purely through `WaitForChild`, so load order between LocalScripts never
  matters.

## Extending it

Everything is tag- and attribute-driven, so adding content doesn't require
touching the systems:
- New puzzle: add parts tagged `PressurePlate`/`PressureDoor` sharing a new
  `GroupId` attribute in `LevelBuilder` (or even from a plugin/command bar).
- New shard: tag any part `ColorShard` and give it a `ProximityPrompt`.
- Raise `EchoConstants.MAX_ECHOES_PER_PLAYER` or add an upgrade shard that
  calls `PlayerState` to grant more echoes mid-run.
