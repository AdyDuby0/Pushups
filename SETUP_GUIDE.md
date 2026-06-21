# GemPowerCore — Setup Guide

Follow this exactly when you get home to your Windows machine.

---

## STEP 1 — Install the tools

1. Install **Git for Windows**: https://git-scm.com/download/win  
2. Install **Aftman** (Roblox toolchain manager):  
   Download the `.exe` from https://github.com/LPGhatguy/aftman/releases  
   Run it once — it adds itself to PATH.
3. Open **PowerShell** (not Command Prompt) and run:
   ```
   aftman install
   ```
   This reads the `aftman.toml` file and installs **Rojo** automatically.

---

## STEP 2 — Clone this repo

```
git clone https://github.com/adyduby0/pushups.git
cd pushups
git checkout claude/roblox-game-dev-3mqnrt
```

---

## STEP 3 — Install the Rojo plugin into Roblox Studio

1. Open **Roblox Studio**
2. Go to **Plugins → Manage Plugins → Search "Rojo"**  
   Or install it directly from: https://create.roblox.com/store/asset/13916111
3. Restart Studio after installing

---

## STEP 4 — Start Rojo and connect Studio

1. In PowerShell, inside the repo folder:
   ```
   rojo serve
   ```
   You'll see: `Rojo server listening on port 34872`

2. In Roblox Studio, click the **Rojo** plugin button → **Connect**
3. You should see all scripts appear in the Explorer panel immediately

---

## STEP 5 — Enable API Services in Studio

1. Go to **Home → Game Settings → Security**
2. Enable **Enable Studio Access to API Services** (needed for DataStore to work in Studio testing)

---

## STEP 6 — Build the map in Studio

The scripts are wired. Now you need to build the actual 3D world. Here's what to create:

### Workspace structure needed:

```
Workspace/
├── Plots/
│   ├── Plot1   (Model with a Part named "Spawn" inside)
│   ├── Plot2
│   ├── Plot3
│   ├── Plot4
│   ├── Plot5
│   └── Plot6
└── GemNodes/
    ├── CrystiteNode  (Part with Attributes: GemType="Crystite", Remaining=50)
    ├── VoidstoneNode (Part with Attributes: GemType="Voidstone", Remaining=30)
    └── etc.
```

### How to set Attributes on a Part:
1. Click the Part in Explorer
2. In Properties panel → scroll down to **Attributes**
3. Click the **+** button → add `GemType` (string) and `Remaining` (number)

### Map layout suggestion:
- **Center island**: Shopping District (decorative, portal/telepad to plots later)
- **6 outer pads**: one per player plot — space them 150+ studs apart
- **Gem field zone**: scatter 10–20 gem node Parts around the map
- Sci-fi theme: use **Neon** material for nodes, dark grey/metal for the plots

### Server player limit:
1. **Home → Game Settings → Places → Edit → Max Players = 6**

---

## STEP 7 — Configure Monetization (do this AFTER publishing)

1. Publish the game: **File → Publish to Roblox As...**
2. Go to https://create.roblox.com → your game → **Monetization**

### Create these Gamepasses:
| Name | Price (Robux) | Description |
|------|--------------|-------------|
| Double Income | 299 | 2× income from your Power Core |
| Auto Extract | 199 | Automatically mines nearby gem nodes |
| Extra Slots | 149 | +2 gem slots on any core tier |
| VIP | 99 | Glowing aura + 1.5× bonus |

### Create these Developer Products:
| Name | Price | Description |
|------|-------|-------------|
| 10K Credits | 49 | Instant 10,000 credits |
| 100K Credits | 149 | Instant 100,000 credits |
| 1M Credits | 399 | Instant 1,000,000 credits |
| Rare Gem Pack | 249 | 5 Neutronium + 10 Voidstone |

3. Copy each ID from Roblox and paste them into:
   `src/ReplicatedStorage/Config/GameConfig.luau`
   under `GAMEPASSES` and `PRODUCTS`

---

## STEP 8 — Test it

1. In Studio: **Play → Server** (test with 2 clients to see the leaderboard work)
2. Check the Output window for errors
3. Verify:
   - [ ] Credits tick up every second when gems are slotted
   - [ ] Leaderboard updates and shows all players
   - [ ] Clicking a gem node starts extraction
   - [ ] Market listings appear for all players
   - [ ] Power Core upgrade panel works

---

## What's already done (all the code):

| File | What it does |
|------|-------------|
| `GameConfig.luau` | All tunable numbers in one place |
| `GemTypes.luau` | 4 gem tiers: Crystite / Voidstone / Neutronium / Singularity Core |
| `PowerCoreTypes.luau` | 5 core tiers with slots + multipliers |
| `DataManager.luau` | Saves/loads all player data via DataStore |
| `PlotManager.luau` | Assigns players to plot pads and teleports them in |
| `PowerCoreManager.luau` | Passive income loop, slotting gems, upgrading cores |
| `GemManager.luau` | Extraction loop, node depletion and respawn |
| `MarketManager.luau` | Full player-to-player gem market with fees |
| `MonetizationManager.luau` | Gamepass checks + developer product processing |
| `Main.server.luau` | Wires everything together, handles all remote calls |
| `Main.client.luau` | Client entry, click-to-extract interaction |
| `HUD.luau` | Top bar (credits, income), live leaderboard, notifications |
| `PlotUI.luau` | Power Core panel: slots, inventory, upgrade button |
| `MarketUI.luau` | Market panel: buy listings, list your own gems |

---

## Next steps to discuss when you're back:

- Visual design of the Power Core model on each plot
- Prestige/rebirth system (reset for permanent multiplier — huge retention driver)
- Auto-miner structures that players build on their plot
- Daily challenge system to drive return visits
- Trading Power Cores between players (not just gems)
