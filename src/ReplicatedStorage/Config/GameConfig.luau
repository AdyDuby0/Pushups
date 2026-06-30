return {
    MAX_PLAYERS         = 6,
    STARTING_CREDITS    = 500,
    INCOME_TICK_RATE    = 1,
    MARKET_FEE_PERCENT  = 5,
    MAX_MARKET_LISTINGS = 10,
    SAVE_INTERVAL       = 60,
    LEADERBOARD_RATE    = 5,

    -- Admin (dev) menu access — restricted to exactly these UserIds.
    ADMIN_IDS = {
        [1318952312] = true,
    },

    -- Max shards of any single type a player can hold.
    INVENTORY_MAX = 20,

    -- How much rarer gems benefit from higher core levels.
    RESONANCE_SCALING   = 0.08,

    -- Drill gear + ExtractionRush potion reduce mineTime; cap the reduction.
    MIN_MINE_FRACTION   = 0.15,   -- fastest possible = 15% of base mineTime

    CORE_UPGRADES = {
        { key = "overclock",   name = "Overclock",         icon = "⚡", bonusPerLevel = 0.12, baseCost = 100,   growth = 1.13 },
        { key = "surge",       name = "Power Surge",       icon = "🔋", bonusPerLevel = 0.35, baseCost = 1500,  growth = 1.22 },
        { key = "singularity", name = "Singularity Drive", icon = "🌌", bonusPerLevel = 1.00, baseCost = 75000, growth = 1.30 },
    },

    -- Permanent, repeatable drill upgrades that cut mine time (credits-based).
    -- reductionPerLevel stacks additively with drill gear / potions, capped by
    -- MIN_MINE_FRACTION above. Combined max here is -85%, matching the cap.
    MINING_UPGRADES = {
        { key = "drilltuning", name = "Drill Tuning", icon = "⛏", reductionPerLevel = 0.025, baseCost = 300,  growth = 1.16, maxLevel = 16 },
        { key = "plasmabore",  name = "Plasma Bore",  icon = "🔩", reductionPerLevel = 0.05,  baseCost = 6000, growth = 1.24, maxLevel = 9  },
    },

    GAMEPASSES = {
        DOUBLE_INCOME   = 0,
        AUTO_EXTRACT    = 0,
        EXTRA_SLOTS     = 0,
        VIP             = 0,
    },
    -- Robux prices shown in Shop UI (for display only; real price set in Roblox dashboard)
    GAMEPASSES_ROBUX = {
        DOUBLE_INCOME   = 299,
        EXTRA_SLOTS     = 199,
        VIP             = 499,
    },
    PRODUCTS = {
        CREDITS_SMALL   = 0,
        CREDITS_MEDIUM  = 0,
        CREDITS_LARGE   = 0,
        RARE_GEM_PACK   = 0,
        ENERGY_POTION   = 0,
        GEM_SMALL       = 0,   -- 100 💎  (R$99)
        GEM_MEDIUM      = 0,   -- 500 💎  (R$399)
        GEM_LARGE       = 0,   -- 2000 💎 (R$1,199)
    },
    -- 💎 packs purchasable with Robux (shown in the Shop's "Buy Gems" section).
    -- productKey maps into PRODUCTS above; robux is the display price.
    GEM_PACKS = {
        { productKey = "GEM_SMALL",  amount = 100,  robux = 99   },
        { productKey = "GEM_MEDIUM", amount = 500,  robux = 399, bonus = "+11% bonus" },
        { productKey = "GEM_LARGE",  amount = 2000, robux = 1199, bonus = "+68% bonus — best value" },
    },
    -- 1 💎 → this many 💰 when converting in the shop
    GEM_TO_CREDITS_RATE = 5000,

    -- Premium temporary boosts purchasable with 💎
    PREMIUM_ITEMS = {
        {
            key         = "PremiumIncomeSurge",
            name        = "Income Surge",
            icon        = "⚡",
            description = "+200% income for 1 hour",
            gemCost     = 50,
            duration    = 3600,
            incomeBonus = 2.0,
        },
        {
            key              = "PremiumMiningRush",
            name             = "Mining Rush",
            icon             = "⛏",
            description      = "-75% mine time for 1 hour",
            gemCost          = 30,
            duration         = 3600,
            extractReduction = 0.75,
        },
        {
            key         = "PremiumCoreOverdrive",
            name        = "Core Overdrive",
            icon        = "🔋",
            description = "+500% income for 15 minutes",
            gemCost     = 40,
            duration    = 900,
            incomeBonus = 5.0,
        },
    },
}
