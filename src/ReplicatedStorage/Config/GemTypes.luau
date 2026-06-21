-- Each gem type: fuel value = credits/second when slotted into a core
return {
    Crystite = {
        displayName = "Crystite Shard",
        rarity      = "Common",
        fuelValue   = 10,
        color       = Color3.fromRGB(100, 200, 255),
        nodeYield   = 50,    -- gems per node before depleted
        extractTime = 2,     -- seconds per gem extracted
        tradeValue  = 50,    -- suggested market base price
    },
    Voidstone = {
        displayName = "Voidstone Fragment",
        rarity      = "Uncommon",
        fuelValue   = 35,
        color       = Color3.fromRGB(150, 50, 255),
        nodeYield   = 30,
        extractTime = 4,
        tradeValue  = 200,
    },
    Neutronium = {
        displayName = "Neutronium Core",
        rarity      = "Rare",
        fuelValue   = 100,
        color       = Color3.fromRGB(255, 150, 0),
        nodeYield   = 15,
        extractTime = 8,
        tradeValue  = 800,
    },
    SingularityCore = {
        displayName = "Singularity Core",
        rarity      = "Legendary",
        fuelValue   = 500,
        color       = Color3.fromRGB(255, 50, 50),
        nodeYield   = 5,
        extractTime = 20,
        tradeValue  = 5000,
    },
}
