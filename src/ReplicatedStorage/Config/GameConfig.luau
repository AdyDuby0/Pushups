return {
    MAX_PLAYERS         = 6,
    STARTING_CREDITS    = 500,
    INCOME_TICK_RATE    = 1,
    MARKET_FEE_PERCENT  = 5,
    MAX_MARKET_LISTINGS = 10,
    GEM_NODE_RESPAWN    = 300,
    SAVE_INTERVAL       = 60,
    LEADERBOARD_RATE    = 5,

    -- How much rarer gems benefit from higher core levels.
    -- income = gem.baseFuel × (core.baseMultiplier + gem.rarityTier × coreLevel × RESONANCE_SCALING)
    RESONANCE_SCALING   = 0.08,

    -- Minimum extraction time after drill/potion reductions (seconds)
    MIN_EXTRACT_TIME    = 0.4,

    -- Repeatable direct upgrades to the Power Core. Cheap, frequent, additive
    -- income multipliers for a fast-paced progression loop.
    -- next cost = floor(baseCost * growth ^ currentLevel)
    -- income is multiplied by (1 + sum(level * bonusPerLevel))
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
        CREDITS_SMALL   = 0,   -- 50,000 credits
        CREDITS_MEDIUM  = 0,   -- 500,000 credits
        CREDITS_LARGE   = 0,   -- 5,000,000 credits
        RARE_GEM_PACK   = 0,   -- 5 Neutronium + 10 Voidstone
        ENERGY_POTION   = 0,   -- instant Energy Surge potion
    },
}
