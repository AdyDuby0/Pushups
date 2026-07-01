local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig  = require(ReplicatedStorage.Config.GameConfig)
local GemTypes    = require(ReplicatedStorage.Config.GemTypes)
local CoreTypes   = require(ReplicatedStorage.Config.PowerCoreTypes)
local GearTypes   = require(ReplicatedStorage.Config.GearTypes)
local PotionTypes = require(ReplicatedStorage.Config.PotionTypes)

local PowerCoreManager = {}
local DataManager
local Remotes
local MonetizationManager

function PowerCoreManager.Init(dm, remotes)
    DataManager = dm
    Remotes     = remotes
end

function PowerCoreManager.SetMonetization(m)
    MonetizationManager = m
end

-- Returns the effective max slots for a player's current setup
function PowerCoreManager.GetMaxSlots(player)
    local data = DataManager.Get(player)
    if not data then return 0 end
    local base = CoreTypes[data.coreLevel].maxSlots
    if data.gear.capacitor then
        base += GearTypes.Capacitor[data.gear.capacitor.tier].extraSlots
    end
    if MonetizationManager and MonetizationManager.HasExtraSlots(player) then
        base += 2
    end
    return base
end

-- Core income formula:
-- per-slot = gem.baseFuel * (1 + amplifierBonus) * (core.baseMultiplier + gem.rarityTier * coreLevel * RESONANCE_SCALING)
-- total    = sum(per-slot) * (1 + conductorBonus) * potionMultiplier * gampassMultiplier
function PowerCoreManager.GetIncomeRate(player)
    local data = DataManager.Get(player)
    if not data then return 0 end

    local coreData = CoreTypes[data.coreLevel]
    local RS = GameConfig.RESONANCE_SCALING

    -- Gear bonuses
    local amplifierBonus  = data.gear.amplifier  and GearTypes.Amplifier[data.gear.amplifier.tier].fuelBonus    or 0
    local conductorBonus  = data.gear.conductor  and GearTypes.Conductor[data.gear.conductor.tier].incomeBonus  or 0

    -- Sum per-slot income
    local base = 0
    for _, gemType in pairs(data.coreSlots) do
        if gemType and GemTypes[gemType] then
            local gem       = GemTypes[gemType]
            local resonance = coreData.baseMultiplier + gem.rarityTier * data.coreLevel * RS
            local fuel      = gem.baseFuel * (1 + amplifierBonus)
            base += fuel * resonance
        end
    end

    -- Conductor
    base = base * (1 + conductorBonus)

    -- Active potions + premium boosts
    local now = os.time()
    local potionBonus = 0
    for potionType, expiresAt in pairs(data.activePotions) do
        if expiresAt > now then
            local pd = PotionTypes[potionType]
            if pd and pd.effects.incomeBonus then
                potionBonus += pd.effects.incomeBonus
            end
        end
    end
    for _, item in ipairs(GameConfig.PREMIUM_ITEMS) do
        local expiresAt = data.activePotions[item.key]
        if expiresAt and expiresAt > now and item.incomeBonus then
            potionBonus += item.incomeBonus
        end
    end
    for key, cfg in pairs(GameConfig.BUFFS) do
        local expiresAt = data.activePotions[key]
        if expiresAt and expiresAt > now and cfg.incomeBonus then
            potionBonus += cfg.incomeBonus
        end
    end
    base = base * (1 + potionBonus)

    -- Repeatable core upgrades (overclock / surge)
    local upgradeBonus = 0
    for _, cfg in ipairs(GameConfig.CORE_UPGRADES) do
        local level = (data.coreUpgrades and data.coreUpgrades[cfg.key]) or 0
        upgradeBonus += level * cfg.bonusPerLevel
    end
    for _, cfg in ipairs(GameConfig.WORKSHOP_UPGRADES) do
        if cfg.kind == "income" then
            local level = (data.coreUpgrades and data.coreUpgrades[cfg.key]) or 0
            upgradeBonus += level * cfg.perLevel
        end
    end
    base = base * (1 + upgradeBonus)

    -- Prestige multiplier (permanent, from rebirths)
    base = base * (1 + (data.prestige or 0) * GameConfig.PRESTIGE_BONUS)

    -- Gamepasses
    if MonetizationManager then
        if MonetizationManager.HasDoubleIncome(player) then base *= 2 end
        if MonetizationManager.HasVIP(player)          then base *= 1.5 end
    end

    return base
end

function PowerCoreManager.SlotGem(player, gemType, slotIndex)
    local data = DataManager.Get(player)
    if not data then return false, "No data" end

    local maxSlots = PowerCoreManager.GetMaxSlots(player)
    if slotIndex < 1 or slotIndex > maxSlots then
        return false, "Invalid slot index"
    end
    if not data.gems[gemType] or data.gems[gemType] < 1 then
        return false, "No gem of that type"
    end

    local existing = data.coreSlots[slotIndex]
    if existing then
        data.gems[existing] = (data.gems[existing] or 0) + 1
    end

    data.gems[gemType] -= 1
    if data.gems[gemType] <= 0 then data.gems[gemType] = nil end
    data.coreSlots[slotIndex] = gemType
    return true
end

function PowerCoreManager.UnslotGem(player, slotIndex)
    local data = DataManager.Get(player)
    if not data then return false, "No data" end

    local gemType = data.coreSlots[slotIndex]
    if not gemType then return false, "Slot is empty" end

    data.coreSlots[slotIndex] = nil
    data.gems[gemType] = (data.gems[gemType] or 0) + 1
    return true
end

-- Empty every slot, returning the gems to the inventory
function PowerCoreManager.ClearSlots(player)
    local data = DataManager.Get(player)
    if not data then return false, "No data" end
    for i, gemType in pairs(data.coreSlots) do
        if gemType then
            data.gems[gemType] = (data.gems[gemType] or 0) + 1
            data.coreSlots[i] = nil
        end
    end
    return true, { coreSlots = data.coreSlots, gems = data.gems }
end

-- Clear, then fill every slot with the strongest gems available, stepping down
-- a rank whenever a higher one runs out.
function PowerCoreManager.AutoFillBest(player)
    local data = DataManager.Get(player)
    if not data then return false, "No data" end

    -- return slotted gems to the inventory first
    for i, gemType in pairs(data.coreSlots) do
        if gemType then
            data.gems[gemType] = (data.gems[gemType] or 0) + 1
            data.coreSlots[i] = nil
        end
    end

    -- rank gems strongest-first (rarity, then fuel)
    local order = {}
    for gt, gd in pairs(GemTypes) do
        table.insert(order, { t = gt, tier = gd.rarityTier or 0, fuel = gd.baseFuel or 0 })
    end
    table.sort(order, function(a, b)
        if a.tier ~= b.tier then return a.tier > b.tier end
        return a.fuel > b.fuel
    end)

    local maxSlots = PowerCoreManager.GetMaxSlots(player)
    for slot = 1, maxSlots do
        for _, g in ipairs(order) do
            if (data.gems[g.t] or 0) > 0 then
                data.coreSlots[slot] = g.t
                data.gems[g.t] -= 1
                if data.gems[g.t] <= 0 then data.gems[g.t] = nil end
                break
            end
        end
    end
    return true, { coreSlots = data.coreSlots, gems = data.gems }
end

function PowerCoreManager.UpgradeCore(player)
    local data = DataManager.Get(player)
    if not data then return false, "No data" end

    local coreData = CoreTypes[data.coreLevel]
    if not coreData.upgradeCost then return false, "Already at max level" end
    if data.credits < coreData.upgradeCost then return false, "Not enough credits" end

    data.credits   -= coreData.upgradeCost
    data.coreLevel += 1
    return true
end

-- Find an upgrade config by key across the income, mining and workshop lists.
local function findUpgradeCfg(key)
    for _, c in ipairs(GameConfig.CORE_UPGRADES) do
        if c.key == key then return c, "income" end
    end
    for _, c in ipairs(GameConfig.MINING_UPGRADES) do
        if c.key == key then return c, "mining" end
    end
    for _, c in ipairs(GameConfig.WORKSHOP_UPGRADES) do
        if c.key == key then return c, c.kind end
    end
    return nil
end

-- Player's gem sell-value multiplier (from Workshop "Market Value")
function PowerCoreManager.GetSellMultiplier(player)
    local data = DataManager.Get(player)
    if not data then return 1 end
    local mult = 1
    for _, cfg in ipairs(GameConfig.WORKSHOP_UPGRADES) do
        if cfg.kind == "market" then
            mult += ((data.coreUpgrades and data.coreUpgrades[cfg.key]) or 0) * cfg.perLevel
        end
    end
    return mult
end

-- Workshop upgrade list for the UI
function PowerCoreManager.GetWorkshopInfo(player)
    local data = DataManager.Get(player)
    local info = {}
    if not data then return info end
    for _, cfg in ipairs(GameConfig.WORKSHOP_UPGRADES) do
        local level = (data.coreUpgrades and data.coreUpgrades[cfg.key]) or 0
        table.insert(info, {
            key      = cfg.key,
            name     = cfg.name,
            icon     = cfg.icon,
            kind     = cfg.kind,
            level    = level,
            perLevel = cfg.perLevel,
            nextCost = math.floor(cfg.baseCost * cfg.growth ^ level),
        })
    end
    return info
end

-- Returns the client-facing list of repeatable income upgrades (mining-speed
-- upgrades now live on the drill — see DrillManager).
function PowerCoreManager.GetCoreUpgradeInfo(player)
    local data = DataManager.Get(player)
    local info = {}
    if not data then return info end

    for _, cfg in ipairs(GameConfig.CORE_UPGRADES) do
        local level = (data.coreUpgrades and data.coreUpgrades[cfg.key]) or 0
        table.insert(info, {
            kind          = "income",
            key           = cfg.key,
            name          = cfg.name,
            icon          = cfg.icon,
            level         = level,
            bonusPerLevel = cfg.bonusPerLevel,
            nextCost      = math.floor(cfg.baseCost * cfg.growth ^ level),
        })
    end

    return info
end

function PowerCoreManager.BuyCoreUpgrade(player, key)
    local data = DataManager.Get(player)
    if not data then return false, "No data" end

    local cfg = findUpgradeCfg(key)
    if not cfg then return false, "Unknown upgrade" end

    data.coreUpgrades = data.coreUpgrades or {}
    local level = data.coreUpgrades[key] or 0
    if cfg.maxLevel and level >= cfg.maxLevel then return false, "Max level" end

    local cost  = math.floor(cfg.baseCost * cfg.growth ^ level)
    if data.credits < cost then return false, "Not enough credits" end

    data.credits          -= cost
    data.coreUpgrades[key]  = level + 1

    local newLevel = level + 1
    local atMax    = cfg.maxLevel ~= nil and newLevel >= cfg.maxLevel
    return true, {
        key        = key,
        level      = newLevel,
        atMax      = atMax,
        nextCost   = atMax and 0 or math.floor(cfg.baseCost * cfg.growth ^ newLevel),
        credits    = data.credits,
        incomeRate = PowerCoreManager.GetIncomeRate(player),
    }
end

function PowerCoreManager.StartIncomeLoop()
    task.spawn(function()
        while true do
            task.wait(GameConfig.INCOME_TICK_RATE)
            for _, player in ipairs(Players:GetPlayers()) do
                local data = DataManager.Get(player)
                if data then
                    local income = PowerCoreManager.GetIncomeRate(player)
                    if income > 0 then
                        data.credits             += income
                        data.totalEarned         += income
                        data.stats.creditsEarned += income
                        if Remotes then
                            Remotes.UpdateHUD:FireClient(player, {
                                credits     = data.credits,
                                totalEarned = data.totalEarned,
                                incomeRate  = income,
                                coreLevel   = data.coreLevel,
                            })
                        end
                    end
                end
            end
        end
    end)
end

return PowerCoreManager
