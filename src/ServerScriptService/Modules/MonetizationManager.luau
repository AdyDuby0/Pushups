local MarketplaceService = game:GetService("MarketplaceService")
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local GemTypes   = require(ReplicatedStorage.Config.GemTypes)

local MonetizationManager = {}
local DataManager
local passCache = {}  -- userId -> { passId -> bool }

local PRODUCTS  = GameConfig.PRODUCTS
local GAMEPASSES = GameConfig.GAMEPASSES

-- What each developer product grants on purchase
local PRODUCT_HANDLERS = {
    [PRODUCTS.CREDITS_SMALL]  = function(data) data.credits += 10000 end,
    [PRODUCTS.CREDITS_MEDIUM] = function(data) data.credits += 100000 end,
    [PRODUCTS.CREDITS_LARGE]  = function(data) data.credits += 1000000 end,
    [PRODUCTS.RARE_GEM_PACK]  = function(data)
        data.gems["Neutronium"]  = (data.gems["Neutronium"]  or 0) + 5
        data.gems["Voidstone"]   = (data.gems["Voidstone"]   or 0) + 10
    end,
}

function MonetizationManager.Init(dm)
    DataManager = dm

    MarketplaceService.ProcessReceipt = function(info)
        local player = Players:GetPlayerByUserId(info.PlayerId)
        if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end

        local data = DataManager.Get(player)
        if not data then return Enum.ProductPurchaseDecision.NotProcessedYet end

        local handler = PRODUCT_HANDLERS[info.ProductId]
        if handler then
            handler(data)
            DataManager.Save(player)
            return Enum.ProductPurchaseDecision.PurchaseGranted
        end

        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
end

local function checkPass(player, passId)
    if passId == 0 then return false end  -- not configured yet
    local uid = player.UserId
    if not passCache[uid] then passCache[uid] = {} end
    if passCache[uid][passId] ~= nil then return passCache[uid][passId] end

    local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, uid, passId)
    local result = ok and owns or false
    passCache[uid][passId] = result
    return result
end

function MonetizationManager.HasDoubleIncome(player)
    return checkPass(player, GAMEPASSES.DOUBLE_INCOME)
end

function MonetizationManager.HasAutoExtract(player)
    return checkPass(player, GAMEPASSES.AUTO_EXTRACT)
end

function MonetizationManager.HasExtraSlots(player)
    return checkPass(player, GAMEPASSES.EXTRA_SLOTS)
end

function MonetizationManager.HasVIP(player)
    return checkPass(player, GAMEPASSES.VIP)
end

function MonetizationManager.PromptProduct(player, productId)
    MarketplaceService:PromptProductPurchase(player, productId)
end

function MonetizationManager.PromptPass(player, passId)
    MarketplaceService:PromptGamePassPurchase(player, passId)
end

function MonetizationManager.OnPassPurchased(player, passId)
    -- Clear cache so next check re-reads from Roblox
    if passCache[player.UserId] then
        passCache[player.UserId][passId] = nil
    end
end

return MonetizationManager
