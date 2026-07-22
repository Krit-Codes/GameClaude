# Rebirth Simulator

A Roblox **click-to-earn rebirth simulator**: click a button for money, spend
it on upgrades that boost your income, then **rebirth** to reset your
progress in exchange for a permanent money multiplier — the classic loop
behind games like this on Roblox.

## The loop

1. **Click** the big button to earn money (starts at $1/click).
2. **Buy upgrades** — some increase your click value, most add passive
   income per second. Each upgrade gets ~7% more expensive per level, so
   there's always another one worth saving for.
3. Once you've saved **$1,000**, you can **Rebirth**: your money and
   upgrades reset to zero, but you permanently gain **+10% money from
   everything** (clicks and passive income) for every rebirth you gain.
4. The number of rebirths you get is **however much money you have, divided
   by $1,000** — one button, one formula, no separate "bulk rebirth" action.
   Cash in at exactly $1,000 for **1 rebirth**. Keep saving instead and cash
   in at $2,000 for **2 rebirths** at once, or $1,000,000 for **1,000
   rebirths** at once. The longer you hold off, the bigger the payoff —
   that's the whole addictive tension of the loop.

Progress (money, upgrade levels, rebirths) is saved per-player with
`DataStoreService`, so players keep everything between sessions.

## What's in this repo

```
src/
  ReplicatedStorage/
    Modules/
      GameConstants.lua   -- ModuleScript (all tunable numbers in one place)
      UpgradeConfig.lua   -- ModuleScript (the list of upgrades, shared by client+server)
      NumberFormat.lua    -- ModuleScript ($1.23K / $4.56M / $7.89B formatting)
  ServerScriptService/
    Modules/
      EconomyUtil.lua      -- ModuleScript (cost/income/rebirth math)
      PlayerDataStore.lua  -- ModuleScript (DataStore load/save + in-memory cache)
      Replication.lua      -- ModuleScript (pushes state to leaderstats + client)
    01_Bootstrap.server.lua       -- Script (remotes, leaderstats, income tick loop)
    02_ClickHandler.server.lua    -- Script (handles click requests)
    03_UpgradeHandler.server.lua  -- Script (handles upgrade purchases)
    04_RebirthHandler.server.lua  -- Script (handles rebirthing)
    05_AutoSave.server.lua        -- Script (periodic background save)
  StarterPlayerScripts/
    01_UIBuilder.client.lua        -- LocalScript (builds the whole HUD)
    02_ClickController.client.lua  -- LocalScript (click button + top stat bar)
    03_ShopController.client.lua   -- LocalScript (upgrade shop cards)
    04_RebirthController.client.lua -- LocalScript (rebirth panel + confirm dialog)
```

The `.server.lua` / `.client.lua` suffixes are naming hints only — in Studio
you create the actual Instance type (`Script`, `LocalScript`, or
`ModuleScript`) as noted next to each file above.

## Setup in Roblox Studio (one-time)

In the **Explorer**, create this exact hierarchy and paste each file's
contents into the matching instance's `Source`:

- `ReplicatedStorage`
  - `Folder` named `Modules`
    - `ModuleScript` named `GameConstants` → paste `GameConstants.lua`
    - `ModuleScript` named `UpgradeConfig` → paste `UpgradeConfig.lua`
    - `ModuleScript` named `NumberFormat` → paste `NumberFormat.lua`

- `ServerScriptService`
  - `Folder` named `Modules`
    - `ModuleScript` named `EconomyUtil` → paste `EconomyUtil.lua`
    - `ModuleScript` named `PlayerDataStore` → paste `PlayerDataStore.lua`
    - `ModuleScript` named `Replication` → paste `Replication.lua`
  - `Script` named `01_Bootstrap` → paste `01_Bootstrap.server.lua`
  - `Script` named `02_ClickHandler` → paste `02_ClickHandler.server.lua`
  - `Script` named `03_UpgradeHandler` → paste `03_UpgradeHandler.server.lua`
  - `Script` named `04_RebirthHandler` → paste `04_RebirthHandler.server.lua`
  - `Script` named `05_AutoSave` → paste `05_AutoSave.server.lua`

- `StarterPlayer` → `StarterPlayerScripts`
  - `LocalScript` named `01_UIBuilder` → paste `01_UIBuilder.client.lua`
  - `LocalScript` named `02_ClickController` → paste `02_ClickController.client.lua`
  - `LocalScript` named `03_ShopController` → paste `03_ShopController.client.lua`
  - `LocalScript` named `04_RebirthController` → paste `04_RebirthController.client.lua`

Then press **Play**. RemoteEvents, leaderstats, and the entire UI are all
created automatically the moment the server starts — no manual GUI design
or RemoteEvent wiring needed.

**Note on testing DataStores:** `DataStoreService` doesn't work in Studio's
offline Play mode by default. In Studio, go to **Game Settings → Security**
and enable **Studio Access to API Services**, or test via **Publish to
Roblox** and playing the live game, to see saving/loading actually work.
Without that enabled, saves will silently fail (caught by the `pcall` in
`PlayerDataStore.lua`) and progress will reset each session.

## Tuning the game

Almost everything that controls the game's pacing lives in
`GameConstants.lua`:

- `BASE_CLICK_VALUE` — starting money per click.
- `REBIRTH_MONEY_PER_REBIRTH` — $ needed per rebirth; rebirths gained on cash-in
  is `floor(Money / REBIRTH_MONEY_PER_REBIRTH)` (1000 = $1,000 per rebirth).
- `REBIRTH_MONEY_MULT_PER_REBIRTH` — permanent money multiplier gained per
  rebirth (0.1 = +10%).

The upgrade lineup (names, costs, how much money/sec or click power each one
grants) lives in `UpgradeConfig.lua` — add a new entry there and it
automatically appears in the shop UI and counts toward income, no other
file needs to change.

## How the systems fit together

- **GameConstants** — single source of truth for every tunable number,
  required by both server and client code.
- **UpgradeConfig** — the shop's contents; server uses it for authoritative
  cost/income math, client uses the same table to build and label the shop
  cards, so they can never drift out of sync.
- **EconomyUtil** (server) — pure math: upgrade cost at a given level, total
  income/sec, click value, and the rebirth-count/multiplier formulas.
- **PlayerDataStore** (server) — loads each player's saved state on join,
  keeps the authoritative in-memory table every handler mutates directly,
  and saves it on leave/autosave/server shutdown.
- **Replication** (server) — the only place that pushes a player's state to
  their leaderstats and `DataUpdateEvent`, so every handler reports state
  the same way.
- **Bootstrap** — creates all `RemoteEvent`s under `ReplicatedStorage.Remotes`
  and `leaderstats` (`Rebirths`, `Cash`), loads/saves data on join/leave, and
  runs the once-per-second passive income loop.
- **ClickHandler** / **UpgradeHandler** / **RebirthHandler** — validate and
  apply one specific player action each, always recomputing cost/afford
  checks server-side (the client is never trusted).
- **UIBuilder** — builds the whole HUD (top stat bar, click button, shop
  panel, rebirth panel) at runtime; every other LocalScript finds pieces of
  it by name via `WaitForChild`, so load order never matters.
- **ClickController** / **ShopController** / **RebirthController** — each
  owns one part of the HUD, all independently listening to the same
  `DataUpdateEvent` to stay in sync.

## Extending it

- **New upgrade:** add one entry to `UpgradeConfig.lua` (`Id`, `Name`,
  `Description`, `BaseCost`, `CostGrowth`, `Effect`, `Type`). It shows up in
  the shop automatically.
- **Rebirth perks beyond a money multiplier** (e.g. unlocking new upgrades
  at certain rebirth counts): check `state.Rebirths` in `EconomyUtil` or add
  a `MinRebirths` field to upgrade entries and filter in `UpgradeConfig`-aware
  code.
- **Gamepasses / boosts:** multiply the value returned by
  `EconomyUtil.GetClickValue` / `GetIncomePerSecond` by an extra factor
  looked up from `MarketplaceService:UserOwnsGamePassAsync`.
