-- NPC Gem Exchange: a sell-only market with dynamic, stock-chart prices.
--   • Each gem type has a live price that starts at its tradeValue (the ceiling).
--   • Selling pushes the price DOWN — each unit sold is worth a bit less than the
--     last (geometric decay), so dumping a big stack has diminishing returns.
--   • A recovery loop eases every price back toward its base over time, so prices
--     rebound during inactivity.
-- Prices are global (shared by all players) and broadcast on every sell and tick.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GemTypes = require(ReplicatedStorage.Config.GemTypes)

local GemMarketManager = {}
local DataManager
local Remotes

local SELL_DECAY    = 0.97   -- price multiplier per unit sold
local PRICE_FLOOR   = 0.30   -- price can't fall below this fraction of base
local RECOVERY_RATE = 0.05   -- each tick, ease this fraction back toward base
local RECOVERY_TICK = 5      -- seconds between recovery/broadcast ticks
local HIST_LEN      = 18     -- price points kept for the sparkline

local prices  = {}   -- gemType -> current price (float)
local history = {}   -- gemType -> array of recent prices (float)

local function baseOf(gemType)
    return GemTypes[gemType].tradeValue
end

function GemMarketManager.Init(dm, remotes)
    DataManager = dm
    Remotes     = remotes
    for gemType, gd in pairs(GemTypes) do
        prices[gemType]  = gd.tradeValue
        history[gemType] = {}
        for i = 1, HIST_LEN do history[gemType][i] = gd.tradeValue end
    end
end

local function pushHistory(gemType)
    local h = history[gemType]
    table.insert(h, prices[gemType])
    while #h > HIST_LEN do table.remove(h, 1) end
end

-- Snapshot of all prices for the client (integers + base/floor + sparkline)
function GemMarketManager.GetPrices()
    local snap = {}
    for gemType, price in pairs(prices) do
        local base = baseOf(gemType)
        local hist = {}
        for i, v in ipairs(history[gemType]) do hist[i] = math.floor(v) end
        snap[gemType] = {
            price   = math.floor(price),
            base    = base,
            floor   = math.floor(base * PRICE_FLOOR),
            history = hist,
        }
    end
    return snap
end

local function broadcast()
    if not Remotes then return end
    local snap = GemMarketManager.GetPrices()
    for _, p in ipairs(Players:GetPlayers()) do
        Remotes.UpdateGemMarket:FireClient(p, snap)
    end
end

-- Sell up to `qty` of a gem at the current (decaying) price.
function GemMarketManager.Sell(player, gemType, qty)
    local data = DataManager.Get(player)
    if not data then return false, "No data" end
    if not GemTypes[gemType] then return false, "Unknown gem" end

    qty = math.floor(tonumber(qty) or 0)
    if qty < 1 then return false, "Invalid quantity" end

    local held = data.gems[gemType] or 0
    if held < 1 then return false, "You have none to sell" end
    if qty > held then qty = held end   -- "Sell All" convenience

    local floorPrice = baseOf(gemType) * PRICE_FLOOR
    local p = prices[gemType]

    -- Geometric per-unit payout: first unit at full price, each next a bit less
    local payout = 0
    for _ = 1, qty do
        payout += p
        p = math.max(p * SELL_DECAY, floorPrice)
    end
    payout = math.floor(payout)
    prices[gemType] = math.max(p, floorPrice)

    -- Deduct gems, pay out credits
    data.gems[gemType] = held - qty
    if data.gems[gemType] <= 0 then data.gems[gemType] = nil end
    data.credits             += payout
    data.totalEarned         += payout
    data.stats.creditsEarned += payout
    data.stats.tradesCompleted = (data.stats.tradesCompleted or 0) + 1

    pushHistory(gemType)
    broadcast()

    if Remotes then
        Remotes.UpdateInventory:FireClient(player, data.gems)
        Remotes.UpdateHUD:FireClient(player, {
            credits     = data.credits,
            totalEarned = data.totalEarned,
        })
    end

    return true, {
        payout  = payout,
        qty     = qty,
        price   = math.floor(prices[gemType]),
        credits = data.credits,
    }
end

function GemMarketManager.StartLoop()
    task.spawn(function()
        while true do
            task.wait(RECOVERY_TICK)
            for gemType, price in pairs(prices) do
                local base = baseOf(gemType)
                if price < base - 0.5 then
                    prices[gemType] = price + (base - price) * RECOVERY_RATE
                end
                pushHistory(gemType)
            end
            broadcast()
        end
    end)
end

return GemMarketManager
