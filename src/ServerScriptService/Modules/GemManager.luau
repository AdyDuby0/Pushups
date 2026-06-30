-- Static-node mining model.
-- Nodes never deplete. Each click starts a timed single-mine session.
-- When the timer completes the player receives 1 shard (if under INVENTORY_MAX)
-- and the session automatically restarts. Click again to stop.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig  = require(ReplicatedStorage.Config.GameConfig)
local GemTypes    = require(ReplicatedStorage.Config.GemTypes)
local GearTypes   = require(ReplicatedStorage.Config.GearTypes)
local PotionTypes = require(ReplicatedStorage.Config.PotionTypes)

local GemManager = {}
local DataManager
local Remotes
local sessions = {}   -- userId -> { node, gemType, thread }

function GemManager.Init(dm, remotes)
    DataManager = dm
    Remotes     = remotes
end

-- Effective mine time after drill gear, permanent drill upgrades, potions,
-- and premium boosts. All reductions stack additively, capped by MIN_MINE_FRACTION.
local function effectiveMineTime(data, baseTime)
    local reduction = 0

    -- Drill gear
    if data.gear.drill then
        reduction += GearTypes.Drill[data.gear.drill.tier].timeReduction
    end

    -- Permanent repeatable drill upgrades (credits)
    for _, cfg in ipairs(GameConfig.MINING_UPGRADES) do
        local level = (data.coreUpgrades and data.coreUpgrades[cfg.key]) or 0
        reduction += level * cfg.reductionPerLevel
    end

    local now = os.time()

    -- Any active potion that grants extractReduction (DrillBoost, ExtractionRush, …)
    for potionType, expiresAt in pairs(data.activePotions) do
        if expiresAt > now then
            local pd = PotionTypes[potionType]
            if pd and pd.effects and pd.effects.extractReduction then
                reduction += pd.effects.extractReduction
            end
        end
    end

    -- Premium 💎 boosts
    for _, item in ipairs(GameConfig.PREMIUM_ITEMS) do
        local expiresAt = data.activePotions[item.key]
        if expiresAt and expiresAt > now and item.extractReduction then
            reduction += item.extractReduction
        end
    end

    reduction = math.min(reduction, 1 - GameConfig.MIN_MINE_FRACTION)
    return math.max(baseTime * (1 - reduction), 1)
end

-- Start the drill mining a given gem type. Each completed round adds 1 shard
-- (up to the inventory cap) and auto-loops until stopped.
function GemManager.StartMining(player, gemType)
    if sessions[player.UserId] then
        return false, "Already mining"
    end
    if not gemType or not GemTypes[gemType] then
        return false, "Unknown gem type"
    end

    local data0    = DataManager.Get(player)
    if not data0 then return false, "No data" end
    local initTime = effectiveMineTime(data0, GemTypes[gemType].mineTime)

    local thread = task.spawn(function()
        while true do
            local data = DataManager.Get(player)
            if not data then return end

            local waitTime = effectiveMineTime(data, GemTypes[gemType].mineTime)
            task.wait(waitTime)

            data = DataManager.Get(player)
            if not data then return end

            local held = data.gems[gemType] or 0
            if held < GameConfig.INVENTORY_MAX then
                data.gems[gemType]          = held + 1
                data.stats.gemsCollected    += 1
            end

            if Remotes then
                Remotes.UpdateInventory:FireClient(player, data.gems)
                local newHeld = data.gems[gemType] or 0
                Remotes.GemExtracted:FireClient(player, gemType, newHeld, waitTime)
            end
        end
    end)

    sessions[player.UserId] = { gemType = gemType, thread = thread }
    return true, initTime
end

function GemManager.StopMining(player)
    local s = sessions[player.UserId]
    if s and s.thread then task.cancel(s.thread) end
    sessions[player.UserId] = nil
end

function GemManager.IsMining(player)
    return sessions[player.UserId] ~= nil
end

-- Backward-compat alias
GemManager.StopExtraction = GemManager.StopMining

return GemManager
