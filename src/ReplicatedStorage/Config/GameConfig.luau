return {
    MAX_PLAYERS         = 6,
    STARTING_CREDITS    = 500,
    INCOME_TICK_RATE    = 1,
    MARKET_FEE_PERCENT  = 5,
    MAX_MARKET_LISTINGS = 10,
    SAVE_INTERVAL       = 60,
    LEADERBOARD_RATE    = 5,

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

    GAMEPASSES = {
        DOUBLE_INCOME   = 0,
        AUTO_EXTRACT    = 0,
        EXTRA_SLOTS     = 0,
        VIP             = 0,
    },
    PRODUCTS = {
        CREDITS_SMALL   = 0,
        CREDITS_MEDIUM  = 0,
        CREDITS_LARGE   = 0,
        RARE_GEM_PACK   = 0,
        ENERGY_POTION   = 0,
    },
}
