-- Rebirth / prestige. Reset your run (credits, core level, upgrades, slots,
-- gems, drill depth) in exchange for permanent Prestige Points that multiply
-- income forever. Points earned scale with how much you earned since the last
-- rebirth. Gear, premium currency, gamepasses, goals and codes are kept.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Config.GameConfig)

local RebirthManager = {}
local DataManager

function RebirthManager.Init(dm)
    DataManager = dm
end

-- Points the player would gain if they rebirthed right now
local function pendingPoints(data)
    local runEarned = math.max(0, (data.totalEarned or 0) - (data.prestigeBaseline or 0))
    return math.floor(math.sqrt(runEarned / GameConfig.PRESTIGE_DIVISOR))
end

function RebirthManager.Multiplier(data)
    return 1 + (data.prestige or 0) * GameConfig.PRESTIGE_BONUS
end

function RebirthManager.GetInfo(player)
    local data = DataManager.Get(player)
    if not data then return {} end
    local pending = pendingPoints(data)
    return {
        prestige   = data.prestige or 0,
        multiplier = RebirthManager.Multiplier(data),
        pending    = pending,
        nextMult   = 1 + ((data.prestige or 0) + pending) * GameConfig.PRESTIGE_BONUS,
        bonusPer   = GameConfig.PRESTIGE_BONUS,
        canRebirth = pending >= 1,
        runEarned  = math.max(0, (data.totalEarned or 0) - (data.prestigeBaseline or 0)),
    }
end

function RebirthManager.Rebirth(player)
    local data = DataManager.Get(player)
    if not data then return false, "No data" end

    local gain = pendingPoints(data)
    if gain < 1 then return false, "Earn more before you can rebirth" end

    data.prestige         = (data.prestige or 0) + gain
    data.prestigeBaseline = data.totalEarned or 0

    -- reset the run (keep gear, gemCurrency, gamepasses, goals, codes, stats)
    data.credits      = GameConfig.STARTING_CREDITS
    data.coreLevel    = 1
    data.coreSlots    = {}
    data.coreUpgrades = { overclock = 0, surge = 0, singularity = 0, drilltuning = 0, plasmabore = 0 }
    data.drill        = { gemType = "Crystite", depth = 1 }
    data.gems         = { Crystite = 1 }

    DataManager.Save(player)
    return true, {
        prestige   = data.prestige,
        gained     = gain,
        multiplier = RebirthManager.Multiplier(data),
    }
end

return RebirthManager
