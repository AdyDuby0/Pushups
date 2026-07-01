-- rarityTier (1-6) feeds into the resonance formula.
-- mineTime: seconds it takes to mine 1 shard from a permanent node.
-- Nodes never deplete; they always accept mining.
return {
    Crystite = {
        displayName = "Crystite Shard",
        rarity      = "Common",
        rarityTier  = 1,
        baseFuel    = 5,
        color       = Color3.fromRGB(100, 200, 255),
        mineTime    = 30,       -- 30 seconds
        tradeValue  = 30,
    },
    Voidstone = {
        displayName = "Voidstone Fragment",
        rarity      = "Uncommon",
        rarityTier  = 2,
        baseFuel    = 20,
        color       = Color3.fromRGB(150, 50, 255),
        mineTime    = 180,      -- 3 minutes
        tradeValue  = 150,
    },
    Neutronium = {
        displayName = "Neutronium Core",
        rarity      = "Rare",
        rarityTier  = 3,
        baseFuel    = 80,
        color       = Color3.fromRGB(255, 150, 0),
        mineTime    = 900,      -- 15 minutes
        tradeValue  = 700,
    },
    SingularityCore = {
        displayName = "Singularity Core",
        rarity      = "Legendary",
        rarityTier  = 4,
        baseFuel    = 350,
        color       = Color3.fromRGB(255, 50, 50),
        mineTime    = 3600,     -- 1 hour
        tradeValue  = 4000,
    },
    PrimordialEssence = {
        displayName = "Primordial Essence",
        rarity      = "Mythic",
        rarityTier  = 5,
        baseFuel    = 1500,
        color       = Color3.fromRGB(255, 180, 255),
        mineTime    = 10800,    -- 3 hours
        tradeValue  = 25000,
    },
    CosmicShard = {
        displayName = "Cosmic Shard",
        rarity      = "Cosmic",
        rarityTier  = 6,
        baseFuel    = 8000,
        color       = Color3.fromRGB(200, 255, 255),
        mineTime    = 21600,    -- 6 hours
        tradeValue  = 200000,
    },
}
