-- Four gear categories, four tiers each.
-- Players craft gear with credits + gems; only one piece per category can be equipped.
-- craftCost keys: "credits" (number) + any gem type names (number)
return {
    -- Conductor: multiplies TOTAL income after resonance is calculated
    Conductor = {
        [1] = { name = "Conductor Mk.I",   incomeBonus = 0.15, craftCost = { credits = 10000,     Crystite  = 20 } },
        [2] = { name = "Conductor Mk.II",  incomeBonus = 0.35, craftCost = { credits = 200000,    Voidstone = 8  } },
        [3] = { name = "Conductor Mk.III", incomeBonus = 0.70, craftCost = { credits = 4000000,   Neutronium = 4 } },
        [4] = { name = "Conductor Mk.IV",  incomeBonus = 1.20, craftCost = { credits = 60000000,  SingularityCore = 2 } },
    },
    -- Amplifier: boosts the baseFuel of every slotted gem before resonance
    Amplifier = {
        [1] = { name = "Amplifier Mk.I",   fuelBonus = 0.10, craftCost = { credits = 8000,      Crystite  = 30 } },
        [2] = { name = "Amplifier Mk.II",  fuelBonus = 0.28, craftCost = { credits = 160000,    Voidstone = 12 } },
        [3] = { name = "Amplifier Mk.III", fuelBonus = 0.60, craftCost = { credits = 3000000,   Neutronium = 6 } },
        [4] = { name = "Amplifier Mk.IV",  fuelBonus = 1.10, craftCost = { credits = 50000000,  SingularityCore = 3 } },
    },
    -- Capacitor: adds extra gem slots on top of the core's base slots
    Capacitor = {
        [1] = { name = "Capacitor Mk.I",   extraSlots = 1, craftCost = { credits = 15000,     Voidstone  = 6  } },
        [2] = { name = "Capacitor Mk.II",  extraSlots = 2, craftCost = { credits = 300000,    Neutronium = 4  } },
        [3] = { name = "Capacitor Mk.III", extraSlots = 3, craftCost = { credits = 6000000,   SingularityCore = 2 } },
        [4] = { name = "Capacitor Mk.IV",  extraSlots = 4, craftCost = { credits = 80000000,  PrimordialEssence = 1 } },
    },
    -- Drill: reduces extraction time per gem
    Drill = {
        [1] = { name = "Drill Mk.I",   timeReduction = 0.20, craftCost = { credits = 5000,     Crystite  = 25 } },
        [2] = { name = "Drill Mk.II",  timeReduction = 0.38, craftCost = { credits = 100000,   Voidstone = 10 } },
        [3] = { name = "Drill Mk.III", timeReduction = 0.55, craftCost = { credits = 2000000,  Neutronium = 5 } },
        [4] = { name = "Drill Mk.IV",  timeReduction = 0.70, craftCost = { credits = 40000000, SingularityCore = 4 } },
    },
}
