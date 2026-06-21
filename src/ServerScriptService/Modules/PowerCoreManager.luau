local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig  = require(ReplicatedStorage.Config.GameConfig)
local GemTypes    = require(ReplicatedStorage.Config.GemTypes)
local CoreTypes   = require(ReplicatedStorage.Config.PowerCoreTypes)

local PowerCoreManager = {}
local DataManager
local Remotes
local MonetizationManager  -- set after init to avoid circular require

function PowerCoreManager.Init(dm, remotes)
    DataManager = dm
    Remotes     = remotes
end

function PowerCoreManager.SetMonetization(m)
    MonetizationManager = m
end

function PowerCoreManager.GetIncomeRate(player)
    local data = DataManager.Get(player)
    if not data then return 0 end

    local coreData = CoreTypes[data.coreLevel]
    local base = 0

    for _, gemType in pairs(data.coreSlots) do
        if gemType and GemTypes[gemType] then
            base += GemTypes[gemType].fuelValue
        end
    end

    local income = base * coreData.multiplier

    if MonetizationManager and MonetizationManager.HasDoubleIncome(player) then
        income *= 2
    end

    return income
end

function PowerCoreManager.SlotGem(player, gemType, slotIndex)
    local data = DataManager.Get(player)
    if not data then return false, "No data" end

    local coreData = CoreTypes[data.coreLevel]

    local maxSlots = coreData.maxSlots
    if MonetizationManager and MonetizationManager.HasExtraSlots(player) then
        maxSlots += 2
    end

    if slotIndex < 1 or slotIndex > maxSlots then
        return false, "Invalid slot index"
    end
    if not data.gems[gemType] or data.gems[gemType] < 1 then
        return false, "No gem of that type"
    end

    -- Return whatever was previously in this slot
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
    if not coreData.upgradeCost then
        return false, "Already at max level"
    end
    if data.credits < coreData.upgradeCost then
        return false, "Not enough credits"
    end

    data.credits    -= coreData.upgradeCost
    data.coreLevel  += 1
    return true
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
                        data.credits                += income
                        data.totalEarned            += income
                        data.stats.creditsEarned    += income
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
