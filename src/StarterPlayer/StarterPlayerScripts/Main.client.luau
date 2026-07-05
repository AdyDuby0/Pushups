local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player.PlayerGui

local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes", 30)
assert(RemotesFolder, "[GemPowerCore] Remotes folder not found")

local R = {
    UpdateHUD         = RemotesFolder:WaitForChild("UpdateHUD"),
    UpdateInventory   = RemotesFolder:WaitForChild("UpdateInventory"),
    UpdateMarket      = RemotesFolder:WaitForChild("UpdateMarket"),
    GemExtracted      = RemotesFolder:WaitForChild("GemExtracted"),
    Notification      = RemotesFolder:WaitForChild("Notification"),
    UpdateLeaderboard = RemotesFolder:WaitForChild("UpdateLeaderboard"),
    UpdatePotions     = RemotesFolder:WaitForChild("UpdatePotions"),
    UpdateGemMarket   = RemotesFolder:WaitForChild("UpdateGemMarket"),
    Teleport          = RemotesFolder:WaitForChild("Teleport"),
    Resync            = RemotesFolder:WaitForChild("Resync"),
}

local RF = {
    GetInitialData  = RemotesFolder:WaitForChild("GetInitialData"),
    SlotGem         = RemotesFolder:WaitForChild("SlotGem"),
    UnslotGem       = RemotesFolder:WaitForChild("UnslotGem"),
    ClearSlots      = RemotesFolder:WaitForChild("ClearSlots"),
    AutoFillBest    = RemotesFolder:WaitForChild("AutoFillBest"),
    UpgradeCore     = RemotesFolder:WaitForChild("UpgradeCore"),
    CreateListing   = RemotesFolder:WaitForChild("CreateListing"),
    CancelListing   = RemotesFolder:WaitForChild("CancelListing"),
    BuyListing      = RemotesFolder:WaitForChild("BuyListing"),
    SellAllGems     = RemotesFolder:WaitForChild("SellAllGems"),
    StartDrill        = RemotesFolder:WaitForChild("StartDrill"),
    StopDrill         = RemotesFolder:WaitForChild("StopDrill"),
    SetDrillGem       = RemotesFolder:WaitForChild("SetDrillGem"),
    UpgradeDrillDepth = RemotesFolder:WaitForChild("UpgradeDrillDepth"),
    GetDrillInfo      = RemotesFolder:WaitForChild("GetDrillInfo"),
    GetWorkshopInfo   = RemotesFolder:WaitForChild("GetWorkshopInfo"),
    AdminAction       = RemotesFolder:WaitForChild("AdminAction"),
    RedeemCode        = RemotesFolder:WaitForChild("RedeemCode"),
    GetGoals          = RemotesFolder:WaitForChild("GetGoals"),
    ClaimGoal         = RemotesFolder:WaitForChild("ClaimGoal"),
    GetRebirthInfo    = RemotesFolder:WaitForChild("GetRebirthInfo"),
    Rebirth           = RemotesFolder:WaitForChild("Rebirth"),
    GetDailyInfo      = RemotesFolder:WaitForChild("GetDailyInfo"),
    ClaimDaily        = RemotesFolder:WaitForChild("ClaimDaily"),
    GetChargeInfo     = RemotesFolder:WaitForChild("GetChargeInfo"),
    ClaimCharge       = RemotesFolder:WaitForChild("ClaimCharge"),
    BuyCoreUpgrade  = RemotesFolder:WaitForChild("BuyCoreUpgrade"),
    CraftGear       = RemotesFolder:WaitForChild("CraftGear"),
    EquipGear       = RemotesFolder:WaitForChild("EquipGear"),
    UnequipGear     = RemotesFolder:WaitForChild("UnequipGear"),
    BrewPotion          = RemotesFolder:WaitForChild("BrewPotion"),
    UsePotion           = RemotesFolder:WaitForChild("UsePotion"),
    ConvertGems         = RemotesFolder:WaitForChild("ConvertGems"),
    BuyPremiumBoost     = RemotesFolder:WaitForChild("BuyPremiumBoost"),
    SellToNPC           = RemotesFolder:WaitForChild("SellToNPC"),
}

local Modules          = script.Parent:WaitForChild("Modules")
local HUD              = require(Modules:WaitForChild("HUD"))
local PlotUI           = require(Modules:WaitForChild("PlotUI"))
local MarketUI         = require(Modules:WaitForChild("MarketUI"))
local CraftingUI       = require(Modules:WaitForChild("CraftingUI"))
local ShopUI           = require(Modules:WaitForChild("ShopUI"))
local GemMarketUI      = require(Modules:WaitForChild("GemMarketUI"))
local DrillUI          = require(Modules:WaitForChild("DrillUI"))
local WorkshopUI       = require(Modules:WaitForChild("WorkshopUI"))
local AdminUI          = require(Modules:WaitForChild("AdminUI"))
local CodesUI          = require(Modules:WaitForChild("CodesUI"))
local QuestsUI         = require(Modules:WaitForChild("QuestsUI"))
local RebirthUI        = require(Modules:WaitForChild("RebirthUI"))
local RewardsUI        = require(Modules:WaitForChild("RewardsUI"))
local Effects          = require(Modules:WaitForChild("Effects"))
local Sounds           = require(Modules:WaitForChild("Sounds"))
local TutorialManager  = require(Modules:WaitForChild("TutorialManager"))

if not player.Character then player.CharacterAdded:Wait() end
task.wait(2)

local initData = RF.GetInitialData:InvokeServer()
assert(initData, "[GemPowerCore] Failed to load initial data")

HUD.Init(playerGui, initData, {
    teleportPlot   = function() R.Teleport:FireServer("plot") end,
    teleportCenter = function() R.Teleport:FireServer("center") end,
})
Effects.Init(playerGui)
PlotUI.Init(playerGui, initData, RF, {
    onCoreOpened = function() TutorialManager.OnCoreOpened() end,
    onFirstSlot  = function() TutorialManager.OnFirstSlot() end,
})
MarketUI.Init(playerGui, initData, RF)
CraftingUI.Init(playerGui, initData, RF)
ShopUI.Init(playerGui, initData, RF)
GemMarketUI.Init(playerGui, initData, RF)
DrillUI.Init(playerGui, initData, RF)
WorkshopUI.Init(playerGui, initData, RF)
CodesUI.Init(playerGui, initData, RF)
QuestsUI.Init(playerGui, initData, RF)
RebirthUI.Init(playerGui, initData, RF)
RewardsUI.Init(playerGui, initData, RF)
if initData.isAdmin then
    AdminUI.Init(playerGui, initData, RF)
end
TutorialManager.Start(playerGui, initData)

-- Welcome back: show offline earnings once
if initData.offlineEarnings and initData.offlineEarnings.amount and initData.offlineEarnings.amount > 0 then
    local off = initData.offlineEarnings
    local hrs = math.floor(off.seconds / 3600)
    local mins = math.floor((off.seconds % 3600) / 60)
    local awayText = hrs > 0 and (hrs .. "h " .. mins .. "m") or (mins .. "m")
    task.delay(1.5, function()
        local fmtAmount
        local a = off.amount
        if a >= 1e9 then fmtAmount = string.format("%.1fB", a/1e9)
        elseif a >= 1e6 then fmtAmount = string.format("%.1fM", a/1e6)
        elseif a >= 1e3 then fmtAmount = string.format("%.1fK", a/1e3)
        else fmtAmount = tostring(a) end
        Effects.Popup("⏰ Welcome back! +💰 " .. fmtAmount, Color3.fromRGB(120, 220, 160))
        HUD.ShowNotification("Your core earned 💰 " .. fmtAmount .. " while you were away (" .. awayText .. ")")
        Sounds.Play("claim", 0.5)
    end)
end

-- ── Server event hooks ────────────────────────────────────────────────────────

R.UpdateHUD.OnClientEvent:Connect(function(hudData)
    HUD.Update(hudData)
    if hudData.credits then
        CraftingUI.UpdateCredits(hudData.credits)
        PlotUI.UpdateCredits(hudData.credits)
        DrillUI.UpdateCredits(hudData.credits)
        WorkshopUI.UpdateCredits(hudData.credits)
    end
    if hudData.gemCurrency then
        ShopUI.UpdateGemCurrency(hudData.gemCurrency)
    end
end)

R.UpdateInventory.OnClientEvent:Connect(function(gems)
    PlotUI.UpdateGems(gems)
    MarketUI.UpdateGems(gems)
    CraftingUI.UpdateGems(gems)
    GemMarketUI.UpdateGems(gems)
    DrillUI.UpdateGems(gems)
end)

R.UpdateGemMarket.OnClientEvent:Connect(function(snap)
    GemMarketUI.UpdatePrices(snap)
end)

R.Resync.OnClientEvent:Connect(function(d)
    PlotUI.Resync(d)
    if d.gems then
        MarketUI.UpdateGems(d.gems)
        CraftingUI.UpdateGems(d.gems)
        GemMarketUI.UpdateGems(d.gems)
        DrillUI.UpdateGems(d.gems)
    end
end)

R.UpdateMarket.OnClientEvent:Connect(function(newListings)
    MarketUI.UpdateListings(newListings)
end)

local firstMine = true
-- GemExtracted fires once per completed drill round:
-- (gemType, heldCount, nextMineTime, inventoryFull)
R.GemExtracted.OnClientEvent:Connect(function(gemType, heldCount, nextMineTime, full)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local GemTypes = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("GemTypes"))
    local gd = GemTypes[gemType]
    local displayName = gd and gd.displayName or gemType
    if full then
        HUD.ShowFloatingText("Inventory full — sell at the Exchange!", Color3.fromRGB(255, 110, 110))
    else
        HUD.ShowFloatingText("+1 " .. displayName, gd and gd.color or Color3.fromRGB(80, 255, 80))
        Sounds.Play("mine", 0.35, 0.9 + math.random() * 0.2)
    end

    if firstMine then
        firstMine = false
        TutorialManager.OnFirstExtraction()
    end

    -- Reset the drill's progress bar for the next round
    DrillUI.OnRound(gemType, nextMineTime or 120)
end)

R.Notification.OnClientEvent:Connect(function(msg)
    HUD.ShowNotification(msg)
end)

R.UpdatePotions.OnClientEvent:Connect(function(activePotions)
    HUD.UpdatePotions(activePotions)
end)

-- ── Physical stations (Drill / Crafting / Market / Shop / Exchange) ───────────
-- WorldBuilder tags each station with a StationType attribute and a
-- ProximityPrompt. Holding E toggles the matching UI panel.

local stationOpeners = {
    Market    = function() MarketUI.Toggle() end,
    Crafting  = function() CraftingUI.Toggle() end,
    Shop      = function() ShopUI.Toggle() end,
    GemMarket = function() GemMarketUI.Toggle() end,
    Drill     = function() DrillUI.Toggle() end,
    Workshop  = function() WorkshopUI.Toggle() end,
}

local wiredStations = {}
local function setupStation(inst)
    if not inst:IsA("BasePart") then return end
    local st = inst:GetAttribute("StationType")
    if not st or not stationOpeners[st] then return end
    if wiredStations[inst] then return end
    wiredStations[inst] = true

    local pp = inst:FindFirstChildOfClass("ProximityPrompt")
    if not pp then
        pp = Instance.new("ProximityPrompt")
        pp.ActionText = "Open"; pp.KeyboardKeyCode = Enum.KeyCode.E
        pp.HoldDuration = 0.3; pp.MaxActivationDistance = 12; pp.RequiresLineOfSight = false
        pp.Parent = inst
    end
    pp.Triggered:Connect(function()
        stationOpeners[st]()
    end)
end

do
    local plotsFolder = workspace:WaitForChild("Plots", 30)
    if plotsFolder then
        for _, d in ipairs(plotsFolder:GetDescendants()) do
            setupStation(d)
        end
        plotsFolder.DescendantAdded:Connect(setupStation)
    end

    -- Central NPC kiosk (Gem Exchange) lives in its own model
    local exchange = workspace:WaitForChild("GemExchange", 30)
    if exchange then
        for _, d in ipairs(exchange:GetDescendants()) do
            setupStation(d)
        end
        exchange.DescendantAdded:Connect(setupStation)
    end
end

-- ── Physical Power Core (hold E) ──────────────────────────────────────────────
-- The server places a glowing core on each plot (workspace.PowerCores), each with
-- a ProximityPrompt. We connect our own core's prompt to open the panel and
-- disable the prompt on other players' cores so they don't clutter our screen.

local wiredCores = {}
local function setupCore(crystal)
    if not crystal:IsA("BasePart") then return end
    if crystal.Name ~= "PowerCore" then return end
    local pp = crystal:FindFirstChildOfClass("ProximityPrompt")
    if not pp then return end
    if crystal:GetAttribute("OwnerUserId") == player.UserId then
        if not wiredCores[crystal] then
            wiredCores[crystal] = true
            pp.Enabled = true
            pp.Triggered:Connect(function() PlotUI.Toggle() end)
        end
    else
        pp.Enabled = false
    end
end

task.spawn(function()
    while true do
        local folder = workspace:FindFirstChild("PowerCores")
        if folder then
            for _, m in ipairs(folder:GetChildren()) do
                local c = m:FindFirstChild("PowerCore")
                if c then setupCore(c) end
            end
        end
        task.wait(1)
    end
end)

print("[GemPowerCore] Client ready.")
