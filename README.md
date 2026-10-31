# Umbra Client

A standalone Fabric utility client for anarchy servers, for **Minecraft 26.2**.

- Fabric Loader 0.19.3+, Fabric API (26.2), Java 25
- ClickGUI (Right Shift), HUD, chat commands, keybinds, saved config
- 33 modules across Combat, Movement, Render, Player, World and Misc

## Building

You need **JDK 25** installed.

```bash
./gradlew build          # Linux / macOS
gradlew.bat build        # Windows
```

The mod jar is written to `build/libs/umbra-client-1.0.0.jar`.

**No JDK?** Push this folder to a GitHub repo. The included workflow (`.github/workflows/build.yml`)
builds it on every push. Open the run under the **Actions** tab and download the `umbra-client` artifact.

## Installing

1. Install the [Fabric Loader](https://fabricmc.net/use/) for Minecraft 26.2.
2. Put `umbra-client-1.0.0.jar` and **Fabric API** for 26.2 in your `.minecraft/mods` folder.
3. Launch the Fabric profile.

## Controls

| Action | How |
| --- | --- |
| Open ClickGUI | **Right Shift** (rebindable in Options → Controls → Umbra Client) |
| Toggle module | Left click it |
| Open module settings | Right click it |
| Bind a module | Middle click it, or expand it and click the **Bind** row, then press a key. Esc/Backspace/Delete clears the bind |
| Move a panel | Drag its header. Right click a header to collapse it. Scroll to move all panels |
| Number setting | Click or drag the slider |
| Mode setting | Left click for next, right click for previous |

## Commands

The prefix is `.` by default. Commands never reach the server.

```
.help                              list commands
.<module>  /  .toggle <module>     toggle a module
.bind <module> <key>               e.g. .bind KillAura r   .bind Freecam f6
.unbind <module>   .binds
.set <module> <setting> <value>    e.g. .set CrystalAura MinDamage 8
.settings <module>                 list a module's settings
.modules                           list modules (green = on)
.friend add|del|list <name>        friends are skipped by KillAura/CrystalAura and shown green
.config save|load [name]           extra config profiles
.prefix <char>
.vclip <blocks>   .hclip <blocks>  teleport up/down or forward
.coords                            copy your coordinates
```

Config lives in `.minecraft/config/umbra/default.json` and is saved when you close the GUI,
every minute, and on exit.

## Modules

**Combat**
- **KillAura** — attacks nearby players/mobs. Range, target types, priority, silent rotations, cooldown sync.
- **CrystalAura** — places and breaks end crystals on the nearest enemy. Min damage, max self damage, anti-suicide, auto-switch. Damage is an estimate (vanilla formula + raycast exposure, armor ignored).
- **AutoTotem** — keeps a totem in your offhand. *Smart* mode holds a crystal or gapple until health drops.
- **Surround** — rings your feet with obsidian. Centers you, disables when you jump.
- **Criticals** — packet criticals (Packet/Strict).
- **Velocity** — cancels or scales knockback and explosion push.
- **AutoArmor** — fills empty armor slots, optional elytra preference.
- **AutoLog** — disconnects at low health, when out of totems, or when a non-friend shows up.

**Movement**
- **Flight** — velocity flight with anti-kick, or creative-style abilities flight.
- **ElytraFly** — *Control* (fly where you look, hover with no input) or *Boost*. Auto-opens the elytra.
- **Speed** — strafe bunny-hop or on-ground speed.
- **NoFall** — packet or landing mode.
- **Step** — step up to 10 blocks.
- **Jesus** — walk on water and lava.
- **Sprint** — always sprint, optionally in all directions.

**Render**
- **HUD** — watermark, module list, coordinates with nether conversion, FPS/ping/speed, armor and totem count.
- **ClickGUI** — bindable GUI entry.
- **ESP** — boxes through walls (players, friends, mobs, items, crystals).
- **Tracers** — lines from your crosshair to entities.
- **Nametags** — name, ping, health, distance and held item, visible through walls.
- **Fullbright** — client-side night vision.
- **Freecam** — packet freecam with no-clip. Your body stays put server-side; turning it off snaps you back.
- **XRay** — outlines ores and spawners within a radius. Servers with anti-xray (2b2t has it) hide buried ores, so this mostly finds exposed ones.
- **StashESP** — outlines chests, shulkers, ender chests and barrels, with a chat alert when lots are loaded (stash finding).

**Player**
- **AutoEat** — eats when hungry, gapples when low. Skips chorus fruit and other bad food.
- **FastPlace** — no right-click delay (all items, blocks, crystals or XP bottles).
- **AutoRespawn** — instant respawn, prints death coordinates.
- **ChestStealer** — empties chests/shulkers you open.
- **AutoReplenish** — refills low hotbar stacks from your inventory.

**World**
- **Scaffold** — places blocks under you, with tower and extend.
- **Nuker** — breaks blocks around you (All / Flatten / Smash), multi-break in creative.

**Misc**
- **AutoReconnect** — reconnects after a kick.
- **Spammer** — sends lines from `config/umbra/spammer.txt` on a timer.

## Adding a module

1. Create a class extending `dev.umbra.module.Module` in the right category package.
2. Declare settings as fields with `bool(...)`, `number(...)`, `mode(...)`.
3. Override the hooks you need: `onTick`, `onEnable`/`onDisable`, `onPacketSend`/`onPacketReceive`
   (return `true` to cancel), `onRenderLines` (world boxes/lines), `onRenderLabels` (world text), `onHud`.
4. Register it in `ModuleManager`'s constructor.

## Project layout

```
src/main/java/dev/umbra/
  Umbra.java              entrypoint: events, keybinds, render hooks
  module/                 Module base, ModuleManager, and the modules by category
  setting/                Bool / Number / Mode settings
  gui/ClickGuiScreen.java panel GUI
  command/                chat commands
  mixin/                  packet hook, right-click delay + FPS accessor, freecam no-clip
  util/                   config, inventory, world/rotation helpers, line drawing, block scanner
```

## Notes

- 26.2 ships unobfuscated, so the project uses Mojang names directly and has no mappings line.
- Only use this on servers that allow hacked clients (anarchy servers). Other servers will ban you.
