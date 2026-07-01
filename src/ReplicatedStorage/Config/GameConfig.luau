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

    -- Rebirth / prestige. Points gained = floor(sqrt(runEarned / DIVISOR)); each
    -- point permanently multiplies income by (1 + BONUS).
    PRESTIGE_DIVISOR = 10000,
    PRESTIGE_BONUS   = 0.10,

    -- ⚡ Core Charge (playtime reward): the core charges over CHARGE_INTERVAL
    -- seconds; claiming pays ~2 min of income (min CHARGE_BASE), grows each claim
    -- this session, and applies the Core Surge buff.
    CHARGE_INTERVAL = 300,
    CHARGE_BASE     = 1000,

    -- Timed income buffs (handled in GetIncomeRate + shown in the potion bar)
    BUFFS = {
        CoreSurge = { name = "Core Surge", icon = "⚡", color = Color3.fromRGB(255, 210, 90), incomeBonus = 0.5, duration = 90 },
    },

    -- 🌌 Cosmic Cache: a 7-day login streak. Streak resets if you miss > 48h.
    DAILY_REWARDS = {
        { credits = 1000, gems = { Crystite = 5 } },
        { gemCurrency = 15 },
        { gems = { Voidstone = 5 } },
        { gemCurrency = 30 },
        { gems = { Neutronium = 3 } },
        { gemCurrency = 50 },
        { gemCurrency = 100, gems = { SingularityCore = 1 } },
    },

    -- Goals / quests. metric is a stat name; reward = { credits, gemCurrency, gems }.
    GOALS = {
        { id = "mine50",   name = "Mine 50 gems",        metric = "gemsCollected",   target = 50,       reward = { credits = 2000 } },
        { id = "core3",    name = "Reach Core Lv 3",     metric = "coreLevel",       target = 3,        reward = { credits = 5000 } },
        { id = "craft3",   name = "Craft 3 gear pieces", metric = "gearsCreated",    target = 3,        reward = { credits = 8000 } },
        { id = "mine250",  name = "Mine 250 gems",       metric = "gemsCollected",   target = 250,      reward = { credits = 10000, gemCurrency = 10 } },
        { id = "trade10",  name = "Complete 10 trades",  metric = "tradesCompleted", target = 10,       reward = { credits = 6000 } },
        { id = "earn100k", name = "Earn 100K total",     metric = "totalEarned",     target = 100000,   reward = { gemCurrency = 20 } },
        { id = "core5",    name = "Reach Core Lv 5",     metric = "coreLevel",       target = 5,        reward = { credits = 20000, gemCurrency = 25 } },
        { id = "potion3",  name = "Use 3 potions",       metric = "potionsUsed",     target = 3,        reward = { credits = 5000 } },
        { id = "earn10m",  name = "Earn 10M total",      metric = "totalEarned",     target = 10000000, reward = { gemCurrency = 50 } },
    },

    -- Redeemable promo codes. Keys are UPPERCASE, no spaces. Reward fields:
    -- credits, gemCurrency, gems = { GemType = count }, and a msg shown on redeem.
    CODES = {
        RELEASE  = { credits = 50000, gemCurrency = 100, msg = "Launch bonus!" },
        WELCOME  = { credits = 10000, gemCurrency = 25,  msg = "Welcome, miner!" },
        GEMCORE  = { credits = 25000, msg = "Free credits!" },
        DRILL100 = { gemCurrency = 50, msg = "50 gems for you!" },
        LIKE1000 = { credits = 100000, gemCurrency = 50, msg = "Thanks for the likes!" },
    },

    -- Max shards of any single type a player can hold.
    INVENTORY_MAX = 20,

    -- How much rarer gems benefit from higher core levels.
    RESONANCE_SCALING   = 0.08,

    -- Drill gear + ExtractionRush potion reduce mineTime; cap the reduction.
    MIN_MINE_FRACTION   = 0.15,   -- fastest possible = 15% of base mineTime

    CORE_UPGRADES = {
        { key = "overclock",   name = "Overclock",         icon = "⚡", bonusPerLevel = 0.12, baseCost = 60,    growth = 1.12 },
        { key = "surge",       name = "Power Surge",       icon = "🔋", bonusPerLevel = 0.35, baseCost = 1500,  growth = 1.22 },
        { key = "singularity", name = "Singularity Drive", icon = "🌌", bonusPerLevel = 1.00, baseCost = 75000, growth = 1.30 },
    },

    -- Workshop: deep, uncapped credit sinks. kind drives what each does:
    --   income → +perLevel income   |   mining → -perLevel mine time
    --   market → +perLevel gem sell value
    WORKSHOP_UPGRADES = {
        { key = "corepower",  name = "Core Power",   icon = "💠", kind = "income", perLevel = 0.15, baseCost = 500,  growth = 1.15 },
        { key = "drillpower", name = "Drill Power",  icon = "⛏", kind = "mining", perLevel = 0.02, baseCost = 800,  growth = 1.17 },
        { key = "marketval",  name = "Market Value", icon = "📈", kind = "market", perLevel = 0.05, baseCost = 1200, growth = 1.16 },
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
