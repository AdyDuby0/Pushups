-- The plot drill. Each player has one drill instead of separate gem nodes.
-- The drill is set to mine a single gem type, chosen from the tiers its depth
-- has unlocked. Upgrading depth (with credits) unlocks the next rarer gem.
-- Mining-speed upgrades (Drill Tuning, Plasma Bore) also live on the drill.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local GemTypes   = require(ReplicatedStorage.Config.GemTypes)

local DrillManager = {}
local DataManager

-- Depth order: depth N unlocks gems of tier 1..N (rarer = deeper)
local DEPTH_GEMS = { "Crystite", "Voidstone", "Neutronium", "SingularityCore", "PrimordialEssence", "CosmicShard" }
local DEPTH_BASE_COST = 5000
local DEPTH_GROWTH    = 8      -- each depth level costs ~8× the last

function DrillManager.Init(dm)
    DataManager = dm
end

local function tierOf(gemType)
    for i, g in ipairs(DEPTH_GEMS) do
        if g == gemType then return i end
    end
    return nil
end

local function depthCost(targetDepth)
    return math.floor(DEPTH_BASE_COST * (DEPTH_GROWTH ^ (targetDepth - 2)))
end

local function ensureDrill(data)
    data.drill = data.drill or { gemType = "Crystite", depth = 1 }
    if not data.drill.gemType then data.drill.gemType = "Crystite" end
    if not data.drill.depth   then data.drill.depth = 1 end
    return data.drill
end

-- Client-facing drill state: selected gem, depth, unlocked gems, costs, and the
-- drill (mining-speed) upgrade list.
function DrillManager.GetInfo(player)
    local data = DataManager.Get(player)
    if not data then return {} end
    local drill = ensureDrill(data)
    local depth = math.clamp(drill.depth, 1, #DEPTH_GEMS)

    local unlocked = {}
    for i = 1, depth do
        local gt = DEPTH_GEMS[i]
        local gd = GemTypes[gt]
        table.insert(unlocked, {
            gemType     = gt,
            displayName = gd.displayName,
            mineTime    = gd.mineTime,
        })
    end

    local atMaxDepth = depth >= #DEPTH_GEMS

    local upgrades = {}
    for _, cfg in ipairs(GameConfig.MINING_UPGRADES) do
        local level = (data.coreUpgrades and data.coreUpgrades[cfg.key]) or 0
        local atMax = cfg.maxLevel ~= nil and level >= cfg.maxLevel
        table.insert(upgrades, {
            key               = cfg.key,
            name              = cfg.name,
            icon              = cfg.icon,
            level             = level,
            reductionPerLevel = cfg.reductionPerLevel,
            maxLevel          = cfg.maxLevel,
            atMax             = atMax,
            nextCost          = atMax and 0 or math.floor(cfg.baseCost * cfg.growth ^ level),
        })
    end

    return {
        gemType    = drill.gemType,
        depth      = depth,
        maxDepth   = #DEPTH_GEMS,
        unlocked   = unlocked,
        atMaxDepth = atMaxDepth,
        nextGem    = (not atMaxDepth) and GemTypes[DEPTH_GEMS[depth + 1]].displayName or nil,
        depthCost  = atMaxDepth and 0 or depthCost(depth + 1),
        upgrades   = upgrades,
    }
end

-- Set which gem the drill mines (must be within unlocked depth)
function DrillManager.SetGem(player, gemType)
    local data = DataManager.Get(player)
    if not data then return false, "No data" end
    local drill = ensureDrill(data)

    local tier = tierOf(gemType)
    if not tier then return false, "Unknown gem" end
    if tier > drill.depth then return false, "Drill deeper to unlock this gem" end

    drill.gemType = gemType
    return true, gemType
end

-- Increase drill depth, unlocking the next rarer gem
function DrillManager.UpgradeDepth(player)
    local data = DataManager.Get(player)
    if not data then return false, "No data" end
    local drill = ensureDrill(data)

    if drill.depth >= #DEPTH_GEMS then return false, "Drill is at maximum depth" end
    local cost = depthCost(drill.depth + 1)
    if data.credits < cost then return false, "Not enough credits" end

    data.credits -= cost
    drill.depth  += 1
    return true, {
        depth     = drill.depth,
        credits   = data.credits,
        unlocked  = DEPTH_GEMS[drill.depth],
    }
end

-- Current gem the drill is set to (used by the start-drilling handler)
function DrillManager.CurrentGem(player)
    local data = DataManager.Get(player)
    if not data then return nil end
    return ensureDrill(data).gemType
end

return DrillManager
