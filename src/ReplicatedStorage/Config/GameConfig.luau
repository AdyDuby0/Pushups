return {
    MAX_PLAYERS         = 6,
    STARTING_CREDITS    = 500,
    INCOME_TICK_RATE    = 1,       -- seconds between income ticks
    MARKET_FEE_PERCENT  = 5,       -- % fee taken from each sale
    MAX_MARKET_LISTINGS = 10,      -- max active listings per player
    GEM_NODE_RESPAWN    = 300,     -- 5 minutes before a depleted node respawns
    SAVE_INTERVAL       = 60,      -- auto-save every 60 seconds
    LEADERBOARD_RATE    = 5,       -- leaderboard refresh rate (seconds)

    -- Fill these in AFTER publishing your game on Roblox
    GAMEPASSES = {
        DOUBLE_INCOME   = 0,   -- 2x income multiplier
        AUTO_EXTRACT    = 0,   -- auto-mines nearby gem nodes
        EXTRA_SLOTS     = 0,   -- +2 gem slots on any core tier
        VIP             = 0,   -- cosmetic aura + 1.5x bonus
    },
    PRODUCTS = {
        CREDITS_SMALL   = 0,   -- grants 10,000 credits
        CREDITS_MEDIUM  = 0,   -- grants 100,000 credits
        CREDITS_LARGE   = 0,   -- grants 1,000,000 credits
        RARE_GEM_PACK   = 0,   -- grants 5 Neutronium + 10 Voidstone
    },
}
