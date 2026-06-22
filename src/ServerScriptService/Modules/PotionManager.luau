local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PotionTypes = require(ReplicatedStorage.Config.PotionTypes)

local PotionManager = {}
local DataManager

function PotionManager.Init(dm)
    DataManager = dm
end

function PotionManager.Brew(player, potionType)
    local data = DataManager.Get(player)
    if not data then return false, "No data" end

    local pd = PotionTypes[potionType]
    if not pd then return false, "Unknown potion" end

    local cost = pd.craftCost
    if data.credits < cost.credits then return false, "Not enough credits" end

    for gemType, qty in pairs(cost) do
        if gemType ~= "credits" then
            if (data.gems[gemType] or 0) < qty then
                return false, "Need " .. qty .. " " .. gemType
            end
        end
    end

    data.credits -= cost.credits
    for gemType, qty in pairs(cost) do
        if gemType ~= "credits" then
            data.gems[gemType] = (data.gems[gemType] or 0) - qty
            if data.gems[gemType] <= 0 then data.gems[gemType] = nil end
        end
    end

    data.potionInventory[potionType] = (data.potionInventory[potionType] or 0) + 1
    return true
end

function PotionManager.Use(player, potionType)
    local data = DataManager.Get(player)
    if not data then return false, "No data" end

    local pd = PotionTypes[potionType]
    if not pd then return false, "Unknown potion" end

    if (data.potionInventory[potionType] or 0) < 1 then
        return false, "No potions of that type"
    end

    data.potionInventory[potionType] -= 1
    if data.potionInventory[potionType] <= 0 then
        data.potionInventory[potionType] = nil
    end

    -- Stack onto existing timer if still active
    local now = os.time()
    local existing = data.activePotions[potionType]
    local base = (existing and existing > now) and existing or now
    data.activePotions[potionType] = base + pd.duration

    data.stats.potionsUsed += 1
    return true, data.activePotions[potionType]
end

-- Returns remaining seconds for each active potion (cleans expired ones)
function PotionManager.GetActive(player)
    local data = DataManager.Get(player)
    if not data then return {} end

    local now    = os.time()
    local active = {}
    for pType, expiresAt in pairs(data.activePotions) do
        if expiresAt > now then
            active[pType] = expiresAt - now
        else
            data.activePotions[pType] = nil
        end
    end
    return active
end

return PotionManager
