# Clicker Game — click system

The core loop, with no GUI included on purpose — you build the interface,
this is just the system underneath it:

1. **Click** → adds `ClickPower` to your `Clicks` counter.
2. **Sell** → converts all of your `Clicks` into `Money` (1:1).
3. **Upgrade** → spend `Money` to permanently raise `ClickPower` for this
   life (cost rises each purchase).
4. **Rebirth** → once `Money >= 1000`, reset `Clicks`/`Money`/upgrades, but:
   - gain `floor(Money / 1000)` Rebirths, and
   - `ClickPower` gets **+1 flat per Rebirth** and **2x per Rebirth**
     (both effects stack across all your Rebirths).

## What's in this repo

```
src/
  ReplicatedStorage/
    Modules/
      ClickerConstants.lua -- ModuleScript, all tuning values in one place
      ClickerClient.lua    -- ModuleScript, the API your GUI calls into
  ServerScriptService/
    Modules/
      PlayerState.lua       -- ModuleScript, per-player save data + formulas
    01_Bootstrap.server.lua     -- Script, creates RemoteEvents + leaderstats
    02_ClickerService.server.lua -- Script, validates and runs every action
```

As with the rest of this repo, `.server.lua` is a `Script` and a plain
`.lua` under `Modules` is a `ModuleScript` — the suffix is just a naming
hint for you in Studio.

## Setup in Roblox Studio

1. `ReplicatedStorage`
   - `Folder` named `Modules`
     - `ModuleScript` named `ClickerConstants` → paste `ClickerConstants.lua`
     - `ModuleScript` named `ClickerClient` → paste `ClickerClient.lua`
2. `ServerScriptService`
   - `Folder` named `Modules`
     - `ModuleScript` named `PlayerState` → paste `PlayerState.lua`
   - `Script` named `01_Bootstrap` → paste `01_Bootstrap.server.lua`
   - `Script` named `02_ClickerService` → paste `02_ClickerService.server.lua`

Everything else — the `ClickerRemotes` folder and its RemoteEvents,
per-player `leaderstats` (`Clicks`/`Money`/`Rebirths`, visible in the
default Roblox player list) — is created automatically when the server
starts. Data is saved per-player via `DataStoreService`, so this only
works fully in a published place (Studio Play-solo still runs it, just
without persistence unless you enable API access + Studio access).

## Wiring up your GUI

From any `LocalScript` inside your GUI:

```lua
local ClickerClient = require(game.ReplicatedStorage.Modules.ClickerClient)

clickButton.Activated:Connect(ClickerClient.Click)
sellButton.Activated:Connect(ClickerClient.Sell)
upgradeButton.Activated:Connect(ClickerClient.BuyUpgrade)
rebirthButton.Activated:Connect(ClickerClient.Rebirth)

ClickerClient.OnStatsChanged(function(stats)
    -- stats = { Clicks, Money, Rebirths, ClickPower,
    --           UpgradeLevel, NextUpgradeCost, RebirthGainPreview }
    clicksLabel.Text = "Clicks: " .. stats.Clicks
    moneyLabel.Text = "Money: " .. stats.Money
    rebirthsLabel.Text = "Rebirths: " .. stats.Rebirths
    upgradeButton.Text = ("Upgrade (Cost: %d)"):format(stats.NextUpgradeCost)
    rebirthButton.Text = ("Rebirth (+%d)"):format(stats.RebirthGainPreview)
end)
```

`OnStatsChanged` fires immediately with the latest known stats (if any)
when you connect, and again every time the server processes an action —
so labels stay in sync without any polling.

## Tuning

Everything numeric — starting click power, upgrade cost/growth, the
rebirth divisor, the per-rebirth click bonus/multiplier — lives in
`ClickerConstants.lua`, so balancing the game doesn't require touching
the logic in `02_ClickerService.server.lua`.
