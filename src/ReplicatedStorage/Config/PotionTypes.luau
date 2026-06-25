-- Consumable potions. Players brew them from gems or buy from market.
-- effect keys used by PowerCoreManager and GemManager at runtime.
-- duration in seconds. craftCost same format as GearTypes.
return {
    EnergySurge = {
        displayName = "Energy Surge",
        description = "+50% income for 1 hour",
        icon        = "⚡",
        color       = Color3.fromRGB(255, 160, 0),
        duration    = 3600,
        effects     = { incomeBonus = 0.50 },
        craftCost   = { credits = 5000,  Voidstone = 5 },
    },
    DrillBoost = {
        displayName = "Drill Boost",
        description = "−35% mine time for 20 min",
        icon        = "⛏",
        color       = Color3.fromRGB(120, 220, 255),
        duration    = 1200,
        effects     = { extractReduction = 0.35 },
        craftCost   = { credits = 1500 },   -- credits only: accessible early
    },
    ExtractionRush = {
        displayName = "Extraction Rush",
        description = "−50% extraction time for 30 min",
        icon        = "⛏",
        color       = Color3.fromRGB(0, 210, 255),
        duration    = 1800,
        effects     = { extractReduction = 0.50 },
        craftCost   = { credits = 8000,  Neutronium = 2 },
    },
    NodeBounty = {
        displayName = "Node Bounty",
        description = "Twice as many gems per tick for 1 hour",
        icon        = "💎",
        color       = Color3.fromRGB(80, 255, 120),
        duration    = 3600,
        effects     = { gemYieldBonus = 1 },   -- adds 1 extra gem per tick
        craftCost   = { credits = 12000, SingularityCore = 1 },
    },
    CosmicFocus = {
        displayName = "Cosmic Focus",
        description = "+100% income for 30 min",
        icon        = "🌌",
        color       = Color3.fromRGB(180, 80, 255),
        duration    = 1800,
        effects     = { incomeBonus = 1.00 },
        craftCost   = { credits = 50000, PrimordialEssence = 1 },
    },
}
