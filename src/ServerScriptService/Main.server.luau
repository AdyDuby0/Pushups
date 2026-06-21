-- Server entry point: wires all managers together and handles player events

local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Mods = ServerScriptService:WaitForChild("Modules")

local DataManager         = require(Mods:WaitForChild("DataManager"))
local PlotManager         = require(Mods:WaitForChild("PlotManager"))
local GemManager          = require(Mods:WaitForChild("GemManager"))
local PowerCoreManager    = require(Mods:WaitForChild("PowerCoreManager"))
local MarketManager       = require(Mods:WaitForChild("MarketManager"))
local MonetizationManager = require(Mods:WaitForChild("MonetizationManager"))
local GameConfig          = require(ReplicatedStorage.Config.GameConfig)

-- ── Remotes ──────────────────────────────────────────────────────────────────

local RemotesFolder = Instance.new("Folder")
RemotesFolder.Name   = "Remotes"
RemotesFolder.Parent = ReplicatedStorage

local function makeEvent(name)
    local e = Instance.new("RemoteEvent")
    e.Name   = name
    e.Parent = RemotesFolder
    return e
end

local function makeFunction(name)
    local f = Instance.new("RemoteFunction")
    f.Name   = name
    f.Parent = RemotesFolder
    return f
end

-- Server → Client events
local R = {
    UpdateHUD         = makeEvent("UpdateHUD"),
    UpdateInventory   = makeEvent("UpdateInventory"),
    UpdateMarket      = makeEvent("UpdateMarket"),
    GemExtracted      = makeEvent("GemExtracted"),
    Notification      = makeEvent("Notification"),
    UpdateLeaderboard = makeEvent("UpdateLeaderboard"),
}

-- Client → Server calls (with return value)
local RF = {
    GetInitialData  = makeFunction("GetInitialData"),
    SlotGem         = makeFunction("SlotGem"),
    UnslotGem       = makeFunction("UnslotGem"),
    UpgradeCore     = makeFunction("UpgradeCore"),
    CreateListing   = makeFunction("CreateListing"),
    CancelListing   = makeFunction("CancelListing"),
    BuyListing      = makeFunction("BuyListing"),
    StartExtraction = makeFunction("StartExtraction"),
    StopExtraction  = makeFunction("StopExtraction"),
}

-- ── Manager init ─────────────────────────────────────────────────────────────

PlotManager.Init()
GemManager.Init(DataManager, R)
PowerCoreManager.Init(DataManager, R)
PowerCoreManager.SetMonetization(MonetizationManager)
MarketManager.Init(DataManager, R)
MonetizationManager.Init(DataManager)

-- ── Remote handlers ───────────────────────────────────────────────────────────

RF.GetInitialData.OnServerInvoke = function(player)
    local data = DataManager.Get(player)
    if not data then return nil end
    return {
        credits     = data.credits,
        totalEarned = data.totalEarned,
        gems        = data.gems,
        coreLevel   = data.coreLevel,
        coreSlots   = data.coreSlots,
        stats       = data.stats,
        incomeRate  = PowerCoreManager.GetIncomeRate(player),
        listings    = MarketManager.GetAll(),
    }
end

RF.SlotGem.OnServerInvoke = function(player, gemType, slotIndex)
    return PowerCoreManager.SlotGem(player, gemType, slotIndex)
end

RF.UnslotGem.OnServerInvoke = function(player, slotIndex)
    return PowerCoreManager.UnslotGem(player, slotIndex)
end

RF.UpgradeCore.OnServerInvoke = function(player)
    local ok, err = PowerCoreManager.UpgradeCore(player)
    if ok then DataManager.Save(player) end
    return ok, err
end

RF.CreateListing.OnServerInvoke = function(player, gemType, quantity, priceEach)
    return MarketManager.Create(player, gemType, quantity, priceEach)
end

RF.CancelListing.OnServerInvoke = function(player, listingId)
    return MarketManager.Cancel(player, listingId)
end

RF.BuyListing.OnServerInvoke = function(player, listingId, quantity)
    return MarketManager.Buy(player, listingId, quantity)
end

RF.StartExtraction.OnServerInvoke = function(player, node)
    return GemManager.StartExtraction(player, node)
end

RF.StopExtraction.OnServerInvoke = function(player)
    GemManager.StopExtraction(player)
    return true
end

-- ── Player lifecycle ──────────────────────────────────────────────────────────

Players.PlayerAdded:Connect(function(player)
    DataManager.Load(player)

    player.CharacterAdded:Connect(function(character)
        task.wait(1)
        local plot, idx = PlotManager.Assign(player)
        if plot then
            R.Notification:FireClient(player, "You have been assigned Plot " .. tostring(idx) .. ". Build your empire.")
        else
            R.Notification:FireClient(player, "All plots are taken. Wait for a spot to open.")
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    GemManager.StopExtraction(player)
    PlotManager.Release(player)
    DataManager.Unload(player)
end)

-- Gamepass purchased mid-session: invalidate pass cache
game:GetService("MarketplaceService").PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
    if purchased then
        MonetizationManager.OnPassPurchased(player, passId)
    end
end)

-- ── Game loops ────────────────────────────────────────────────────────────────

PowerCoreManager.StartIncomeLoop()

-- Leaderboard loop
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

print("[GemPowerCore] Server ready.")
