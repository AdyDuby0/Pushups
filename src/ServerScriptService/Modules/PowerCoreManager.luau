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
    base = base * (1 + potionBonus)

    -- Repeatable core upgrades (overclock / surge)
    local upgradeBonus = 0
    for _, cfg in ipairs(GameConfig.CORE_UPGRADES) do
        local level = (data.coreUpgrades and data.coreUpgrades[cfg.key]) or 0
        upgradeBonus += level * cfg.bonusPerLevel
    end
    base = base * (1 + upgradeBonus)

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

-- Returns the client-facing list of repeatable core upgrades with live levels/costs
function PowerCoreManager.GetCoreUpgradeInfo(player)
    local data = DataManager.Get(player)
    local info = {}
    if not data then return info end
    for _, cfg in ipairs(GameConfig.CORE_UPGRADES) do
        local level = (data.coreUpgrades and data.coreUpgrades[cfg.key]) or 0
        table.insert(info, {
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

    local cfg
    for _, c in ipairs(GameConfig.CORE_UPGRADES) do
        if c.key == key then cfg = c break end
    end
    if not cfg then return false, "Unknown upgrade" end

    data.coreUpgrades = data.coreUpgrades or {}
    local level = data.coreUpgrades[key] or 0
    local cost  = math.floor(cfg.baseCost * cfg.growth ^ level)
    if data.credits < cost then return false, "Not enough credits" end

    data.credits          -= cost
    data.coreUpgrades[key]  = level + 1

    return true, {
        key        = key,
        level      = level + 1,
        nextCost   = math.floor(cfg.baseCost * cfg.growth ^ (level + 1)),
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
