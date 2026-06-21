-- Handles gem extraction from nodes.
-- Gem nodes in workspace must live in a Folder called "GemNodes".
-- Each node Part needs two Attributes set in Studio:
--   GemType  (string)  e.g. "Crystite"
--   Remaining (number) e.g. 50

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local GemTypes   = require(ReplicatedStorage.Config.GemTypes)

local GemManager = {}
local DataManager
local Remotes
local extractions = {}  -- userId -> { node, thread }

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

function GemManager.StartExtraction(player, node)
    if extractions[player.UserId] then
        return false, "Already extracting"
    end
    if not node or not node:IsA("BasePart") then
        return false, "Invalid node"
    end

    local gemType  = node:GetAttribute("GemType")
    local remaining = node:GetAttribute("Remaining") or 0

    if not gemType or remaining <= 0 then
        return false, "Node depleted or invalid"
    end
    if not GemTypes[gemType] then
        return false, "Unknown gem type"
    end

    local gemData = GemTypes[gemType]

    local thread = task.spawn(function()
        while true do
            task.wait(gemData.extractTime)

            remaining = node:GetAttribute("Remaining") or 0
            if remaining <= 0 then
                GemManager.StopExtraction(player)
                return
            end

            local data = DataManager.Get(player)
            if not data then return end

            data.gems[gemType]          = (data.gems[gemType] or 0) + 1
            data.stats.gemsCollected    += 1

            remaining -= 1
            node:SetAttribute("Remaining", remaining)

            if Remotes then
                Remotes.UpdateInventory:FireClient(player, data.gems)
                Remotes.GemExtracted:FireClient(player, gemType, remaining)
            end

            if remaining <= 0 then
                local nodeParent = node.Parent
                node.Parent = nil
                respawnNode(node, gemType)
                GemManager.StopExtraction(player)
                return
            end
        end
    end)

    extractions[player.UserId] = { node = node, thread = thread }
    return true
end

function GemManager.StopExtraction(player)
    local ext = extractions[player.UserId]
    if ext and ext.thread then
        task.cancel(ext.thread)
    end
    extractions[player.UserId] = nil
end

return GemManager
