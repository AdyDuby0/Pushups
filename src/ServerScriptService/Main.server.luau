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
local GemMarketManager    = require(Mods:WaitForChild("GemMarketManager"))
local DrillManager        = require(Mods:WaitForChild("DrillManager"))
local WorldBuilder        = require(Mods:WaitForChild("WorldBuilder"))
local GameConfig          = require(ReplicatedStorage.Config.GameConfig)

-- Build the playable world (plots, fences, stations, gem nodes, lighting)
-- before anything tries to find them.
WorldBuilder.Build()

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
    UpdateGemMarket   = ev("UpdateGemMarket"),
    Teleport          = ev("Teleport"),
}

local RFn = {
    GetInitialData  = fn("GetInitialData"),
    SlotGem         = fn("SlotGem"),
    UnslotGem       = fn("UnslotGem"),
    UpgradeCore     = fn("UpgradeCore"),
    CreateListing   = fn("CreateListing"),
    CancelListing   = fn("CancelListing"),
    BuyListing      = fn("BuyListing"),
    StartDrill      = fn("StartDrill"),
    StopDrill       = fn("StopDrill"),
    SetDrillGem     = fn("SetDrillGem"),
    UpgradeDrillDepth = fn("UpgradeDrillDepth"),
    GetDrillInfo    = fn("GetDrillInfo"),
    BuyCoreUpgrade  = fn("BuyCoreUpgrade"),
    CraftGear       = fn("CraftGear"),
    EquipGear       = fn("EquipGear"),
    UnequipGear     = fn("UnequipGear"),
    BrewPotion          = fn("BrewPotion"),
    UsePotion           = fn("UsePotion"),
    ConvertGems         = fn("ConvertGems"),
    BuyPremiumBoost     = fn("BuyPremiumBoost"),
    SellToNPC           = fn("SellToNPC"),
}

-- ── Init ──────────────────────────────────────────────────────────────────────

PlotManager.Init()
GemManager.Init(DataManager, R)
PowerCoreManager.Init(DataManager, R)
PowerCoreManager.SetMonetization(MonetizationManager)
MarketManager.Init(DataManager, R)
GearManager.Init(DataManager)
PotionManager.Init(DataManager)
MonetizationManager.Init(DataManager, R)
GemMarketManager.Init(DataManager, R)
DrillManager.Init(DataManager)
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
        gemMarket       = GemMarketManager.GetPrices(),
        drill           = DrillManager.GetInfo(player),
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

RFn.SellToNPC.OnServerInvoke = function(p, gemType, qty)
    return GemMarketManager.Sell(p, gemType, qty)
end

RFn.StartDrill.OnServerInvoke = function(p)
    local gemType = DrillManager.CurrentGem(p)
    if not gemType then return false, "Drill not set" end
    local ok, mineTime = GemManager.StartMining(p, gemType)
    if ok then
        local _, idx = PlotManager.GetPlot(p)
        if idx then WorldBuilder.SetDrillSpinning(idx, true) end
    end
    return ok, mineTime
end

RFn.StopDrill.OnServerInvoke = function(p)
    GemManager.StopMining(p)
    local _, idx = PlotManager.GetPlot(p)
    if idx then WorldBuilder.SetDrillSpinning(idx, false) end
    return true
end

RFn.SetDrillGem.OnServerInvoke = function(p, gemType)
    local ok, err = DrillManager.SetGem(p, gemType)
    if ok and GemManager.IsMining(p) then
        -- restart the drill on the newly selected gem
        GemManager.StopMining(p)
        local restartOk, mineTime = GemManager.StartMining(p, gemType)
        return true, { gemType = gemType, mining = restartOk, mineTime = mineTime }
    end
    return ok, ok and { gemType = gemType, mining = false } or err
end

RFn.UpgradeDrillDepth.OnServerInvoke = function(p)
    local ok, result = DrillManager.UpgradeDepth(p)
    if ok then
        R.UpdateHUD:FireClient(p, { credits = result.credits })
    end
    return ok, result
end

RFn.GetDrillInfo.OnServerInvoke = function(p)
    return DrillManager.GetInfo(p)
end

R.Teleport.OnServerEvent:Connect(function(player, target)
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if target == "plot" then
        local plot = PlotManager.GetPlot(player)
        local spawn = plot and plot:FindFirstChild("Spawn")
        if spawn then hrp.CFrame = spawn.CFrame + Vector3.new(0, 5, 0) end
    elseif target == "center" then
        hrp.CFrame = CFrame.new(0, 8, 20)   -- shop district hub
    end
end)

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

-- Classic Roblox leaderboard (top-right player list) via leaderstats
local function fmtCredits(n)
    n = math.floor(n)
    if n >= 1e15 then return string.format("%.1fQ", n/1e15)
    elseif n >= 1e12 then return string.format("%.1fT", n/1e12)
    elseif n >= 1e9  then return string.format("%.1fB", n/1e9)
    elseif n >= 1e6  then return string.format("%.1fM", n/1e6)
    elseif n >= 1e3  then return string.format("%.1fK", n/1e3)
    else return tostring(n) end
end

local function ensureLeaderstats(player)
    local ls = player:FindFirstChild("leaderstats")
    if not ls then
        ls = Instance.new("Folder"); ls.Name = "leaderstats"; ls.Parent = player
        local lvl = Instance.new("IntValue"); lvl.Name = "Core Lv"; lvl.Value = 1; lvl.Parent = ls
        local cr  = Instance.new("StringValue"); cr.Name = "Credits"; cr.Value = "0"; cr.Parent = ls
    end
    return ls
end

Players.PlayerAdded:Connect(function(player)
    DataManager.Load(player)
    ensureLeaderstats(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        local plot, idx = PlotManager.Assign(player)
        if plot then
            PowerCoreModel.Spawn(player, plot)
            WorldBuilder.SetPlotOwner(idx, player.DisplayName)
        end
        local msg = plot
            and "Assigned to Plot " .. idx .. ". Hold E on your ⛏ Drill to start mining."
            or  "All plots taken. Wait for a player to leave."
        R.Notification:FireClient(player, msg)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    GemManager.StopExtraction(player)
    PowerCoreModel.Despawn(player)
    local _, idx = PlotManager.GetPlot(player)
    if idx then
        WorldBuilder.SetPlotOwner(idx, nil)
        WorldBuilder.SetDrillSpinning(idx, false)
    end
    PlotManager.Release(player)
    DataManager.Unload(player)
end)

game:GetService("MarketplaceService").PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
    if purchased then MonetizationManager.OnPassPurchased(player, passId) end
end)

-- ── Game loops ────────────────────────────────────────────────────────────────

PowerCoreManager.StartIncomeLoop()
GemMarketManager.StartLoop()

-- Keep the classic leaderstats up to date
task.spawn(function()
    while true do
        task.wait(GameConfig.LEADERBOARD_RATE)
        for _, player in ipairs(Players:GetPlayers()) do
            local data = DataManager.Get(player)
            local ls   = player:FindFirstChild("leaderstats")
            if data and ls then
                local lvl = ls:FindFirstChild("Core Lv")
                local cr  = ls:FindFirstChild("Credits")
                if lvl then lvl.Value = data.coreLevel end
                if cr  then cr.Value  = fmtCredits(data.credits) end
            end
        end
    end
end)

print("[GemPowerCore] Server ready — v2 (gear + potions + resonance).")
