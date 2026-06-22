local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GearTypes = require(ReplicatedStorage.Config.GearTypes)

local GearManager = {}
local DataManager

function GearManager.Init(dm)
    DataManager = dm
end

-- Returns the lowercase data key for a gear category ("Conductor" → "conductor")
local function dataKey(category)
    return string.lower(category)
end

function GearManager.Craft(player, category, tier)
    local data = DataManager.Get(player)
    if not data then return false, "No data" end

    local categoryData = GearTypes[category]
    if not categoryData then return false, "Unknown gear category" end
    local gearData = categoryData[tier]
    if not gearData then return false, "Unknown tier" end

    local cost = gearData.craftCost
    if data.credits < cost.credits then return false, "Not enough credits" end

    for gemType, qty in pairs(cost) do
        if gemType ~= "credits" then
            if (data.gems[gemType] or 0) < qty then
                return false, "Need " .. qty .. " " .. gemType
            end
        end
    end

    -- Deduct resources
    data.credits -= cost.credits
    for gemType, qty in pairs(cost) do
        if gemType ~= "credits" then
            data.gems[gemType] = (data.gems[gemType] or 0) - qty
            if data.gems[gemType] <= 0 then data.gems[gemType] = nil end
        end
    end

    table.insert(data.craftedGear, { category = category, tier = tier })
    data.stats.gearsCreated += 1
    return true
end

function GearManager.Equip(player, category, tier)
    local data = DataManager.Get(player)
    if not data then return false, "No data" end

    -- Confirm player owns this gear piece
    local foundIdx
    for i, g in ipairs(data.craftedGear) do
        if g.category == category and g.tier == tier then
            foundIdx = i; break
        end
    end
    if not foundIdx then return false, "You don't own this gear" end

    local key = dataKey(category)

    -- Return currently equipped piece to backpack
    if data.gear[key] then
        table.insert(data.craftedGear, { category = category, tier = data.gear[key].tier })
    end

    table.remove(data.craftedGear, foundIdx)
    data.gear[key] = { tier = tier }
    return true
end

function GearManager.Unequip(player, category)
    local data = DataManager.Get(player)
    if not data then return false, "No data" end

    local key = dataKey(category)
    if not data.gear[key] then return false, "Nothing equipped in that slot" end

    table.insert(data.craftedGear, { category = category, tier = data.gear[key].tier })
    data.gear[key] = nil
    return true
end

return GearManager
