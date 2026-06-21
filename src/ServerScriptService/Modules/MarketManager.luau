local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local GemTypes   = require(ReplicatedStorage.Config.GemTypes)

local MarketManager = {}
local DataManager
local Remotes

-- In-memory listing table (resets on server restart — add DataStore persistence later if needed)
local listings = {}
local nextId   = 1

function MarketManager.Init(dm, remotes)
    DataManager = dm
    Remotes     = remotes
end

function MarketManager.GetAll()
    return listings
end

function MarketManager.Create(player, gemType, quantity, priceEach)
    if not GemTypes[gemType]    then return false, "Unknown gem type" end
    if quantity  < 1            then return false, "Invalid quantity" end
    if priceEach < 1            then return false, "Invalid price" end

    local data = DataManager.Get(player)
    if not data then return false, "No data" end

    -- Count existing listings by this player
    local count = 0
    for _, l in ipairs(listings) do
        if l.sellerUserId == player.UserId then count += 1 end
    end
    if count >= GameConfig.MAX_MARKET_LISTINGS then
        return false, "Listing limit reached"
    end

    local owned = data.gems[gemType] or 0
    if owned < quantity then return false, "Not enough gems" end

    -- Deduct gems from inventory
    data.gems[gemType] = owned - quantity
    if data.gems[gemType] <= 0 then data.gems[gemType] = nil end

    local listing = {
        id           = nextId,
        sellerUserId = player.UserId,
        sellerName   = player.Name,
        gemType      = gemType,
        quantity     = quantity,
        priceEach    = priceEach,
        listedAt     = os.time(),
    }
    nextId += 1
    table.insert(listings, listing)

    MarketManager.Broadcast()
    return true, listing.id
end

function MarketManager.Cancel(player, listingId)
    for i, l in ipairs(listings) do
        if l.id == listingId and l.sellerUserId == player.UserId then
            local data = DataManager.Get(player)
            if data then
                data.gems[l.gemType] = (data.gems[l.gemType] or 0) + l.quantity
            end
            table.remove(listings, i)
            MarketManager.Broadcast()
            return true
        end
    end
    return false, "Listing not found"
end

function MarketManager.Buy(buyer, listingId, quantity)
    local listingIdx, listing
    for i, l in ipairs(listings) do
        if l.id == listingId then listingIdx, listing = i, l; break end
    end
    if not listing then return false, "Listing not found" end
    if listing.sellerUserId == buyer.UserId then return false, "Cannot buy own listing" end

    quantity = math.min(quantity, listing.quantity)
    local total = quantity * listing.priceEach

    local buyerData = DataManager.Get(buyer)
    if not buyerData then return false, "No data" end
    if buyerData.credits < total then return false, "Not enough credits" end

    local fee       = math.floor(total * GameConfig.MARKET_FEE_PERCENT / 100)
    local sellerGets = total - fee

    buyerData.credits -= total
    buyerData.gems[listing.gemType] = (buyerData.gems[listing.gemType] or 0) + quantity
    buyerData.stats.tradesCompleted += 1

    -- Credit the seller if online
    local seller = Players:GetPlayerByUserId(listing.sellerUserId)
    if seller then
        local sellerData = DataManager.Get(seller)
        if sellerData then
            sellerData.credits += sellerGets
            if Remotes then
                Remotes.UpdateHUD:FireClient(seller, { credits = sellerData.credits })
            end
        end
    end

    listing.quantity -= quantity
    if listing.quantity <= 0 then
        table.remove(listings, listingIdx)
    end

    if Remotes then
        Remotes.UpdateInventory:FireClient(buyer, buyerData.gems)
    end
    MarketManager.Broadcast()
    return true
end

function MarketManager.Broadcast()
    for _, player in ipairs(Players:GetPlayers()) do
        if Remotes then
            Remotes.UpdateMarket:FireClient(player, listings)
        end
    end
end

return MarketManager
