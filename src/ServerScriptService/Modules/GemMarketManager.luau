-- NPC Gem Exchange with a simple simulated stock market.
-- Each gem's price is tracked as a PERCENTAGE of its base tradeValue:
--   • base   = 100%
--   • floor  = 50%
--   • ceiling = 150 + tier*50  (Crystite 200%, Voidstone 250% … Cosmic 450%)
-- The percentage random-walks each tick, gently reverts toward 100%, and drops
-- when players sell — so it behaves like a fluctuating market chart.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GemTypes   = require(ReplicatedStorage.Config.GemTypes)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)

local GemMarketManager = {}
local DataManager
local Remotes

local LOWER_PCT   = 50
local BASE_PCT    = 100
local REVERT_RATE = 0.04    -- pull back toward base each tick
local VOLATILITY  = 3.5     -- random swing (± pct) each tick
local SELL_IMPACT = 0.9     -- pct the price drops per unit sold
local TICK        = 4       -- seconds between market updates
local HIST_LEN    = 24      -- points kept for the chart

local pct     = {}   -- gemType -> current percentage
local history = {}   -- gemType -> array of recent percentages

local function upperPct(gemType)
    local tier = GemTypes[gemType].rarityTier or 1
    return 150 + tier * 50
end

function GemMarketManager.Init(dm, remotes)
    DataManager = dm
    Remotes     = remotes
    for gt in pairs(GemTypes) do
        pct[gt] = BASE_PCT
        history[gt] = {}
        for i = 1, HIST_LEN do history[gt][i] = BASE_PCT end
    end
end

local function pushHistory(gt)
    local h = history[gt]
    table.insert(h, pct[gt])
    while #h > HIST_LEN do table.remove(h, 1) end
end

function GemMarketManager.GetPrices()
    local snap = {}
    for gt, p in pairs(pct) do
        local gd = GemTypes[gt]
        local hist = {}
        for i, v in ipairs(history[gt]) do hist[i] = math.floor(v) end
        snap[gt] = {
            pct        = math.floor(p),
            lower      = LOWER_PCT,
            upper      = upperPct(gt),
            base       = BASE_PCT,
            unit       = math.max(1, math.floor(gd.tradeValue * p / 100)),
            tradeValue = gd.tradeValue,
            history    = hist,
        }
    end
    return snap
end

local function broadcast()
    if not Remotes then return end
    local snap = GemMarketManager.GetPrices()
    for _, pl in ipairs(Players:GetPlayers()) do
        Remotes.UpdateGemMarket:FireClient(pl, snap)
    end
end

-- `quiet` skips the market broadcast + client updates (used by SellAll to batch)
function GemMarketManager.Sell(player, gemType, qty, quiet)
    local data = DataManager.Get(player)
    if not data then return false, "No data" end
    if not GemTypes[gemType] then return false, "Unknown gem" end

    qty = math.floor(tonumber(qty) or 0)
    if qty < 1 then return false, "Invalid quantity" end
    local held = data.gems[gemType] or 0
    if held < 1 then return false, "You have none to sell" end
    if qty > held then qty = held end

    -- Workshop "Market Value" sell multiplier
    local sellMult = 1
    for _, cfg in ipairs(GameConfig.WORKSHOP_UPGRADES) do
        if cfg.kind == "market" then
            sellMult += ((data.coreUpgrades and data.coreUpgrades[cfg.key]) or 0) * cfg.perLevel
        end
    end

    local tradeValue = GemTypes[gemType].tradeValue
    local p = pct[gemType]
    local payout = 0
    for _ = 1, qty do
        payout += tradeValue * p / 100
        p = math.max(LOWER_PCT, p - SELL_IMPACT)   -- selling pushes the price down
    end
    payout = math.floor(payout * sellMult)
    pct[gemType] = p

    data.gems[gemType] = held - qty
    if data.gems[gemType] <= 0 then data.gems[gemType] = nil end
    data.credits             += payout
    data.totalEarned         += payout
    data.stats.creditsEarned += payout
    data.stats.tradesCompleted = (data.stats.tradesCompleted or 0) + 1

    pushHistory(gemType)
    if not quiet then
        broadcast()
        if Remotes then
            Remotes.UpdateInventory:FireClient(player, data.gems)
            Remotes.UpdateHUD:FireClient(player, {
                credits     = data.credits,
                totalEarned = data.totalEarned,
            })
        end
    end

    return true, { payout = payout, qty = qty, pct = math.floor(pct[gemType]), credits = data.credits }
end

-- Sell every gem the player holds, each at its current price
function GemMarketManager.SellAll(player)
    local data = DataManager.Get(player)
    if not data then return false, "No data" end

    local toSell = {}
    for gt, cnt in pairs(data.gems) do
        if cnt and cnt > 0 and GemTypes[gt] then toSell[gt] = cnt end
    end
    if next(toSell) == nil then return false, "No gems to sell" end

    local total = 0
    for gt, cnt in pairs(toSell) do
        local ok, res = GemMarketManager.Sell(player, gt, cnt, true)   -- quiet
        if ok then total += res.payout end
    end

    -- one batched update instead of one per gem type
    broadcast()
    if Remotes then
        Remotes.UpdateInventory:FireClient(player, data.gems)
        Remotes.UpdateHUD:FireClient(player, {
            credits     = data.credits,
            totalEarned = data.totalEarned,
        })
    end
    return true, { payout = total, credits = data.credits }
end

function GemMarketManager.StartLoop()
    task.spawn(function()
        while true do
            task.wait(TICK)
            for gt, p in pairs(pct) do
                local noise  = (math.random() * 2 - 1) * VOLATILITY
                local revert = (BASE_PCT - p) * REVERT_RATE
                pct[gt] = math.clamp(p + noise + revert, LOWER_PCT, upperPct(gt))
                pushHistory(gt)
            end
            broadcast()
        end
    end)
end

return GemMarketManager
