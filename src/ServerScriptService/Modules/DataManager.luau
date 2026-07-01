local DataStoreService  = game:GetService("DataStoreService")
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("GameConfig"))

local STORE = DataStoreService:GetDataStore("GemPowerCoreV2")

local DEFAULT_DATA = {
    credits         = GameConfig.STARTING_CREDITS,
    gemCurrency     = 0,          -- premium 💎 currency
    totalEarned     = 0,
    gems            = { Crystite = 1 },   -- spawn with 1 shard to slot immediately
    coreLevel       = 1,
    coreSlots       = {},
    -- Repeatable core upgrades: { upgradeKey = level }
    coreUpgrades    = { overclock = 0, surge = 0, singularity = 0, drilltuning = 0, plasmabore = 0 },
    -- The plot drill: which gem it's set to mine, and how deep it can reach.
    drill           = { gemType = "Crystite", depth = 1 },
    -- Redeemed promo codes: { CODE = true }
    redeemedCodes   = {},
    -- Gear: one piece per category, nil means nothing equipped
    gear = {
        conductor   = nil,   -- { tier = N } or nil
        amplifier   = nil,
        capacitor   = nil,
        drill       = nil,
    },
    craftedGear     = {},    -- [{ category="Conductor", tier=1 }, ...]
    potionInventory = {},    -- { potionType = count }
    activePotions   = {},    -- { potionType = expiresAtUnixTime }
    stats = {
        gemsCollected   = 0,
        creditsEarned   = 0,
        tradesCompleted = 0,
        gearsCreated    = 0,
        potionsUsed     = 0,
    },
}

local DataManager = {}
local cache = {}

local function deepCopy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do copy[k] = deepCopy(v) end
    return copy
end

local function mergeMissing(data, defaults)
    for k, v in pairs(defaults) do
        if data[k] == nil then
            data[k] = deepCopy(v)
        elseif type(v) == "table" and type(data[k]) == "table" then
            mergeMissing(data[k], v)
        end
    end
end

function DataManager.Load(player)
    local key = "p_" .. player.UserId
    local ok, result = pcall(STORE.GetAsync, STORE, key)
    local data
    if ok and result then
        data = result
        mergeMissing(data, DEFAULT_DATA)
    else
        data = deepCopy(DEFAULT_DATA)
        if not ok then warn("[DataManager] Load failed for", player.Name, result) end
    end
    cache[player.UserId] = data
    return data
end

function DataManager.Save(player)
    local data = cache[player.UserId]
    if not data then return end
    local key = "p_" .. player.UserId
    local ok, err = pcall(STORE.SetAsync, STORE, key, data)
    if not ok then warn("[DataManager] Save failed for", player.Name, err) end
end

function DataManager.Get(player)
    return cache[player.UserId]
end

function DataManager.Unload(player)
    DataManager.Save(player)
    cache[player.UserId] = nil
end

task.spawn(function()
    while true do
        task.wait(GameConfig.SAVE_INTERVAL)
        for _, p in ipairs(Players:GetPlayers()) do
            task.spawn(DataManager.Save, p)
        end
    end
end)

game:BindToClose(function()
    for _, p in ipairs(Players:GetPlayers()) do
        DataManager.Save(p)
    end
end)

return DataManager
