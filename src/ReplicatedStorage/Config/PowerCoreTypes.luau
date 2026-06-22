-- 7 tiers. baseMultiplier feeds the resonance formula, not a flat multiplier.
-- Actual per-slot income = gem.baseFuel * (baseMultiplier + rarityTier * coreLevel * RESONANCE_SCALING)
-- This means rare gems scale exponentially better in high-tier cores.
-- upgradeCost = credits to advance FROM this tier to the next.
return {
    [1] = {
        name          = "Basic Core",
        maxSlots      = 2,
        baseMultiplier = 1.0,
        upgradeCost   = 5000,
        description   = "Your first power core. Handles common gems.",
    },
    [2] = {
        name          = "Charged Core",
        maxSlots      = 3,
        baseMultiplier = 1.3,
        upgradeCost   = 100000,
        description   = "Refined capacitors. Uncommon gems respond well.",
    },
    [3] = {
        name          = "Plasma Core",
        maxSlots      = 4,
        baseMultiplier = 1.8,
        upgradeCost   = 2000000,
        description   = "Plasma containment. Rare gems shine here.",
    },
    [4] = {
        name          = "Quantum Core",
        maxSlots      = 6,
        baseMultiplier = 2.8,
        upgradeCost   = 20000000,
        description   = "Quantum resonance. Legendary gems become devastating.",
    },
    [5] = {
        name          = "Singularity Engine",
        maxSlots      = 8,
        baseMultiplier = 4.5,
        upgradeCost   = 200000000,
        description   = "Near-infinite density. Mythic gems reach full potential.",
    },
    [6] = {
        name          = "Void Nexus",
        maxSlots      = 10,
        baseMultiplier = 7.0,
        upgradeCost   = 2000000000,
        description   = "A rift in spacetime. Only Cosmic Shards truly belong here.",
    },
    [7] = {
        name          = "Celestial Matrix",
        maxSlots      = 12,
        baseMultiplier = 11.0,
        upgradeCost   = nil,
        description   = "The apex. Nothing exists beyond this.",
    },
}
