local Players             = game:GetService("Players")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Mods = ServerScriptService:WaitForChild("Modules")

local DataManager         = require(Mods:WaitForChild("DataManager"))
local PlotManager         = require(Mods:WaitForChild("PlotManager"))
local GemManager          = require(Mods:WaitForChild("GemManager"))
local PowerCoreManager    = require(Mods:WaitForChild("PowerCoreManager"))
local MarketManager       = require(Mods:WaitForChild("MarketManager"))
local GearManager         = require(Mods:WaitForChild("GearManager"))
local PotionManager       = require(Mods:WaitForChild("PotionManager"))
local MonetizationManager = require(Mods:WaitForChild("MonetizationManager"))
local PowerCoreModel      = require(Mods:WaitForChild("PowerCoreModel"))
local GameConfig          = require(ReplicatedStorage.Config.GameConfig)

-- ── Remotes ───────────────────────────────────────────────────────────────────

local RF = Instance.new("Folder")
RF.Name = "Remotes"; RF.Parent = ReplicatedStorage

local function ev(name)
    local e = Instance.new("RemoteEvent"); e.Name = name; e.Parent = RF; return e
end
local function fn(name)
    local f = Instance.new("RemoteFunction"); f.Name = name; f.Parent = RF; return f
end

local R = {
    UpdateHUD         = ev("UpdateHUD"),
    UpdateInventory   = ev("UpdateInventory"),
    UpdateMarket      = ev("UpdateMarket"),
    GemExtracted      = ev("GemExtracted"),
    Notification      = ev("Notification"),
    UpdateLeaderboard = ev("UpdateLeaderboard"),
    UpdatePotions     = ev("UpdatePotions"),
}

local RFn = {
    GetInitialData  = fn("GetInitialData"),
    SlotGem         = fn("SlotGem"),
    UnslotGem       = fn("UnslotGem"),
    UpgradeCore     = fn("UpgradeCore"),
    CreateListing   = fn("CreateListing"),
    CancelListing   = fn("CancelListing"),
    BuyListing      = fn("BuyListing"),
    StartExtraction = fn("StartExtraction"),
    StopExtraction  = fn("StopExtraction"),
    BuyCoreUpgrade  = fn("BuyCoreUpgrade"),
    CraftGear       = fn("CraftGear"),
    EquipGear       = fn("EquipGear"),
    UnequipGear     = fn("UnequipGear"),
    BrewPotion          = fn("BrewPotion"),
    UsePotion           = fn("UsePotion"),
    ConvertGems         = fn("ConvertGems"),
    BuyPremiumBoost     = fn("BuyPremiumBoost"),
}

-- ── Init ──────────────────────────────────────────────────────────────────────

PlotManager.Init()
GemManager.Init(DataManager, R)
PowerCoreManager.Init(DataManager, R)
PowerCoreManager.SetMonetization(MonetizationManager)
MarketManager.Init(DataManager, R)
GearManager.Init(DataManager)
PotionManager.Init(DataManager)
MonetizationManager.Init(DataManager)
PowerCoreModel.StartAnimation()

-- ── Remote handlers ───────────────────────────────────────────────────────────

RFn.GetInitialData.OnServerInvoke = function(player)
    local data = DataManager.Get(player)
    if not data then return nil end
    return {
        credits         = data.credits,
        gemCurrency     = data.gemCurrency or 0,
        totalEarned     = data.totalEarned,
        gems            = data.gems,
        coreLevel       = data.coreLevel,
        coreSlots       = data.coreSlots,
        gear            = data.gear,
        craftedGear     = data.craftedGear,
        potionInventory = data.potionInventory,
        activePotions   = PotionManager.GetActive(player),
        stats           = data.stats,
        incomeRate      = PowerCoreManager.GetIncomeRate(player),
        maxSlots        = PowerCoreManager.GetMaxSlots(player),
        coreUpgrades    = PowerCoreManager.GetCoreUpgradeInfo(player),
        listings        = MarketManager.GetAll(),
    }
end

RFn.SlotGem.OnServerInvoke = function(p, gemType, slot)
    return PowerCoreManager.SlotGem(p, gemType, slot)
end

RFn.UnslotGem.OnServerInvoke = function(p, slot)
    return PowerCoreManager.UnslotGem(p, slot)
end

RFn.UpgradeCore.OnServerInvoke = function(p)
    local ok, err = PowerCoreManager.UpgradeCore(p)
    if ok then DataManager.Save(p) end
    return ok, err
end

RFn.CreateListing.OnServerInvoke = function(p, gemType, qty, price)
    return MarketManager.Create(p, gemType, qty, price)
end

RFn.CancelListing.OnServerInvoke = function(p, id)
    return MarketManager.Cancel(p, id)
end

RFn.BuyListing.OnServerInvoke = function(p, id, qty)
    return MarketManager.Buy(p, id, qty)
end

RFn.StartExtraction.OnServerInvoke = function(p, node)
    return GemManager.StartExtraction(p, node)
end

RFn.StopExtraction.OnServerInvoke = function(p)
    GemManager.StopExtraction(p); return true
end

RFn.BuyCoreUpgrade.OnServerInvoke = function(p, key)
    local ok, result = PowerCoreManager.BuyCoreUpgrade(p, key)
    if ok then
        R.UpdateHUD:FireClient(p, {
            credits    = result.credits,
            incomeRate = result.incomeRate,
        })
    end
    return ok, result
end

RFn.CraftGear.OnServerInvoke = function(p, category, tier)
    local ok, err = GearManager.Craft(p, category, tier)
    if ok then
        local data = DataManager.Get(p)
        R.UpdateInventory:FireClient(p, data.gems)
    end
    return ok, err
end

RFn.EquipGear.OnServerInvoke = function(p, category, tier)
    local ok, err = GearManager.Equip(p, category, tier)
    if ok then
        local data = DataManager.Get(p)
        -- Recalculate income after gear change and push new rate
        R.UpdateHUD:FireClient(p, {
            credits    = data.credits,
            incomeRate = PowerCoreManager.GetIncomeRate(p),
            maxSlots   = PowerCoreManager.GetMaxSlots(p),
        })
    end
    return ok, err
end

RFn.UnequipGear.OnServerInvoke = function(p, category)
    return GearManager.Unequip(p, category)
end

RFn.BrewPotion.OnServerInvoke = function(p, potionType)
    local ok, err = PotionManager.Brew(p, potionType)
    if ok then
        local data = DataManager.Get(p)
        R.UpdateInventory:FireClient(p, data.gems)
    end
    return ok, err
end

RFn.UsePotion.OnServerInvoke = function(p, potionType)
    local ok, expiresAt = PotionManager.Use(p, potionType)
    if ok then
        R.UpdatePotions:FireClient(p, PotionManager.GetActive(p))
        local data = DataManager.Get(p)
        R.UpdateHUD:FireClient(p, {
            credits    = data.credits,
            incomeRate = PowerCoreManager.GetIncomeRate(p),
        })
    end
    return ok, expiresAt
end

RFn.ConvertGems.OnServerInvoke = function(p, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false, "Invalid amount" end
    local data = DataManager.Get(p)
    if not data then return false, "No data" end
    if (data.gemCurrency or 0) < amount then return false, "Not enough 💎" end
    data.gemCurrency -= amount
    data.credits     += amount * GameConfig.GEM_TO_CREDITS_RATE
    DataManager.Save(p)
    R.UpdateHUD:FireClient(p, {
        credits     = data.credits,
        gemCurrency = data.gemCurrency,
    })
    return true, { credits = data.credits, gemCurrency = data.gemCurrency }
end

RFn.BuyPremiumBoost.OnServerInvoke = function(p, itemKey)
    local data = DataManager.Get(p)
    if not data then return false, "No data" end

    local item
    for _, cfg in ipairs(GameConfig.PREMIUM_ITEMS) do
        if cfg.key == itemKey then item = cfg break end
    end
    if not item then return false, "Unknown item" end

    if (data.gemCurrency or 0) < item.gemCost then return false, "Not enough 💎" end
    data.gemCurrency -= item.gemCost

    -- Stack onto existing timer if still active
    local now = os.time()
    local existing = data.activePotions[item.key]
    local base = (existing and existing > now) and existing or now
    data.activePotions[item.key] = base + item.duration

    DataManager.Save(p)
    R.UpdatePotions:FireClient(p, PotionManager.GetActive(p))
    R.UpdateHUD:FireClient(p, {
        gemCurrency = data.gemCurrency,
        credits     = data.credits,
        incomeRate  = PowerCoreManager.GetIncomeRate(p),
    })
    return true, { gemCurrency = data.gemCurrency, expiresAt = data.activePotions[item.key] }
end

-- ── Player lifecycle ──────────────────────────────────────────────────────────

Players.PlayerAdded:Connect(function(player)
    DataManager.Load(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        local plot, idx = PlotManager.Assign(player)
        if plot then
            PowerCoreModel.Spawn(player, plot)
        end
        local msg = plot
            and "Assigned to Plot " .. idx .. ". Head to a gem node and click to extract."
            or  "All plots taken. Wait for a player to leave."
        R.Notification:FireClient(player, msg)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    GemManager.StopExtraction(player)
    PowerCoreModel.Despawn(player)
    PlotManager.Release(player)
    DataManager.Unload(player)
end)

game:GetService("MarketplaceService").PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
    if purchased then MonetizationManager.OnPassPurchased(player, passId) end
end)

-- ── Game loops ────────────────────────────────────────────────────────────────

PowerCoreManager.StartIncomeLoop()

task.spawn(function()
    while true do
        task.wait(GameConfig.LEADERBOARD_RATE)
        local board = {}
        for _, player in ipairs(Players:GetPlayers()) do
            local data = DataManager.Get(player)
            if data then
                table.insert(board, {
                    name        = player.Name,
                    userId      = player.UserId,
                    totalEarned = data.totalEarned,
                    coreLevel   = data.coreLevel,
                    incomeRate  = PowerCoreManager.GetIncomeRate(player),
                })
            end
        end
        table.sort(board, function(a, b) return a.totalEarned > b.totalEarned end)
        for _, player in ipairs(Players:GetPlayers()) do
            R.UpdateLeaderboard:FireClient(player, board)
        end
    end
end)

print("[GemPowerCore] Server ready — v2 (gear + potions + resonance).")
