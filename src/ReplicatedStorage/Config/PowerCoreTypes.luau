-- Each tier: unlockCost = credits to research it, upgradeCost = credits to advance to next
return {
    [1] = {
        name        = "Basic Core",
        maxSlots    = 2,
        multiplier  = 1.0,
        unlockCost  = 0,
        upgradeCost = 1000,
        description = "Your first power core. Gets the job done.",
    },
    [2] = {
        name        = "Charged Core",
        maxSlots    = 4,
        multiplier  = 1.5,
        unlockCost  = 1000,
        upgradeCost = 5000,
        description = "Enhanced capacitors. 50% more output.",
    },
    [3] = {
        name        = "Plasma Core",
        maxSlots    = 6,
        multiplier  = 2.5,
        unlockCost  = 5000,
        upgradeCost = 25000,
        description = "Plasma containment. Serious output now.",
    },
    [4] = {
        name        = "Quantum Core",
        maxSlots    = 8,
        multiplier  = 5.0,
        unlockCost  = 25000,
        upgradeCost = 100000,
        description = "Quantum entanglement. Five times baseline.",
    },
    [5] = {
        name        = "Singularity Engine",
        maxSlots    = 12,
        multiplier  = 15.0,
        unlockCost  = 100000,
        upgradeCost = nil,   -- max tier
        description = "The pinnacle. Makes others look obsolete.",
    },
}
