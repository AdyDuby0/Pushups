local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig  = require(ReplicatedStorage.Config.GameConfig)
local GemTypes    = require(ReplicatedStorage.Config.GemTypes)
local GearTypes   = require(ReplicatedStorage.Config.GearTypes)
local PotionTypes = require(ReplicatedStorage.Config.PotionTypes)

local GemManager = {}
local DataManager
local Remotes
local extractions = {}   -- userId -> { node, thread }

function GemManager.Init(dm, remotes)
    DataManager = dm
    Remotes     = remotes
end

local function respawnNode(node, gemType)
    task.delay(GameConfig.GEM_NODE_RESPAWN, function()
        if node and node.Parent == nil then
            node:SetAttribute("Remaining", GemTypes[gemType].nodeYield)
            node.Parent = workspace:FindFirstChild("GemNodes")
        end
    end)
end

-- Compute effective extraction time considering drill gear and potion
local function effectiveExtractTime(data, baseTime)
    local reduction = 0
    if data.gear.drill then
        reduction += GearTypes.Drill[data.gear.drill.tier].timeReduction
    end
    local now = os.time()
    if data.activePotions.ExtractionRush and data.activePotions.ExtractionRush > now then
        reduction += PotionTypes.ExtractionRush.effects.extractReduction
    end
    reduction = math.min(reduction, 0.85)  -- cap at 85% so there's always a floor
    return math.max(baseTime * (1 - reduction), GameConfig.MIN_EXTRACT_TIME)
end

-- How many gems per tick (Node Bounty potion doubles it)
local function gemsPerTick(data)
    local now = os.time()
    local bonus = 0
    if data.activePotions.NodeBounty and data.activePotions.NodeBounty > now then
        bonus += PotionTypes.NodeBounty.effects.gemYieldBonus
    end
    return 1 + bonus
end

function GemManager.StartExtraction(player, node)
    if extractions[player.UserId] then
        return false, "Already extracting"
    end
    if not node or not node:IsA("BasePart") then
        return false, "Invalid node"
    end

    local gemType   = node:GetAttribute("GemType")
    local remaining = node:GetAttribute("Remaining") or 0

    if not gemType or remaining <= 0       then return false, "Node depleted" end
    if not GemTypes[gemType]               then return false, "Unknown gem type" end

    local gemData = GemTypes[gemType]

    local data0      = DataManager.Get(player)
    local initWait   = effectiveExtractTime(data0, gemData.extractTime)

    local thread = task.spawn(function()
        while true do
            local data = DataManager.Get(player)
            if not data then return end

            local waitTime = effectiveExtractTime(data, gemData.extractTime)
            task.wait(waitTime)

            -- Re-read in case node was depleted by another process
            remaining = node:GetAttribute("Remaining") or 0
            if remaining <= 0 then
                GemManager.StopExtraction(player)
                if Remotes then
                    Remotes.Notification:FireClient(player, "Node depleted. Find another source.")
                end
                return
            end

            data = DataManager.Get(player)
            if not data then return end

            local yield    = gemsPerTick(data)
            local nextWait = effectiveExtractTime(data, gemData.extractTime)
            data.gems[gemType]          = (data.gems[gemType] or 0) + yield
            data.stats.gemsCollected    += yield

            remaining = math.max(remaining - 1, 0)
            node:SetAttribute("Remaining", remaining)

            if Remotes then
                Remotes.UpdateInventory:FireClient(player, data.gems)
                Remotes.GemExtracted:FireClient(player, gemType, remaining, yield, nextWait)
            end

            if remaining <= 0 then
                node.Parent = nil
                respawnNode(node, gemType)
                GemManager.StopExtraction(player)
                if Remotes then
                    Remotes.Notification:FireClient(player, "Node exhausted. Respawns in 5 minutes.")
                end
                return
            end
        end
    end)

    extractions[player.UserId] = { node = node, thread = thread }
    return true, initWait
end

function GemManager.StopExtraction(player)
    local ext = extractions[player.UserId]
    if ext and ext.thread then
        task.cancel(ext.thread)
    end
    extractions[player.UserId] = nil
end

return GemManager
