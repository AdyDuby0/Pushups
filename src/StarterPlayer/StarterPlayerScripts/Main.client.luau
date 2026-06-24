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
}

local RF = {
    GetInitialData  = RemotesFolder:WaitForChild("GetInitialData"),
    SlotGem         = RemotesFolder:WaitForChild("SlotGem"),
    UnslotGem       = RemotesFolder:WaitForChild("UnslotGem"),
    UpgradeCore     = RemotesFolder:WaitForChild("UpgradeCore"),
    CreateListing   = RemotesFolder:WaitForChild("CreateListing"),
    CancelListing   = RemotesFolder:WaitForChild("CancelListing"),
    BuyListing      = RemotesFolder:WaitForChild("BuyListing"),
    StartExtraction = RemotesFolder:WaitForChild("StartExtraction"),
    StopExtraction  = RemotesFolder:WaitForChild("StopExtraction"),
    BuyCoreUpgrade  = RemotesFolder:WaitForChild("BuyCoreUpgrade"),
    CraftGear       = RemotesFolder:WaitForChild("CraftGear"),
    EquipGear       = RemotesFolder:WaitForChild("EquipGear"),
    UnequipGear     = RemotesFolder:WaitForChild("UnequipGear"),
    BrewPotion      = RemotesFolder:WaitForChild("BrewPotion"),
    UsePotion       = RemotesFolder:WaitForChild("UsePotion"),
}

local Modules          = script.Parent:WaitForChild("Modules")
local HUD              = require(Modules:WaitForChild("HUD"))
local PlotUI           = require(Modules:WaitForChild("PlotUI"))
local MarketUI         = require(Modules:WaitForChild("MarketUI"))
local CraftingUI       = require(Modules:WaitForChild("CraftingUI"))
local TutorialManager  = require(Modules:WaitForChild("TutorialManager"))
local NodeFeedback     = require(Modules:WaitForChild("NodeFeedback"))

if not player.Character then player.CharacterAdded:Wait() end
task.wait(2)

local initData = RF.GetInitialData:InvokeServer()
assert(initData, "[GemPowerCore] Failed to load initial data")

HUD.Init(playerGui, initData)
PlotUI.Init(playerGui, initData, RF, {
    onCoreOpened = function() TutorialManager.OnCoreOpened() end,
    onFirstSlot  = function() TutorialManager.OnFirstSlot() end,
})
MarketUI.Init(playerGui, initData, RF)
CraftingUI.Init(playerGui, initData, RF)
TutorialManager.Start(playerGui, initData)

-- ── Server event hooks ────────────────────────────────────────────────────────

R.UpdateHUD.OnClientEvent:Connect(function(hudData)
    HUD.Update(hudData)
    if hudData.credits then
        CraftingUI.UpdateCredits(hudData.credits)
        PlotUI.UpdateCredits(hudData.credits)
    end
end)

R.UpdateInventory.OnClientEvent:Connect(function(gems)
    PlotUI.UpdateGems(gems)
    MarketUI.UpdateGems(gems)
    CraftingUI.UpdateGems(gems)
end)

R.UpdateMarket.OnClientEvent:Connect(function(newListings)
    MarketUI.UpdateListings(newListings)
end)

R.UpdateLeaderboard.OnClientEvent:Connect(function(board)
    HUD.UpdateLeaderboard(board)
end)

local firstMine = true
-- GemExtracted now fires once per completed mine round: (gemType, heldCount, nextMineTime)
R.GemExtracted.OnClientEvent:Connect(function(gemType, heldCount, nextMineTime)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local GemTypes = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("GemTypes"))
    local gd = GemTypes[gemType]
    local displayName = gd and gd.displayName or gemType
    HUD.ShowFloatingText("+1 " .. displayName, gd and gd.color or Color3.fromRGB(80, 255, 80))

    if firstMine then
        firstMine = false
        TutorialManager.OnFirstExtraction()
    end

    -- Restart the progress bar for the next round
    NodeFeedback.OnRoundComplete(nextMineTime or 120)
end)

R.Notification.OnClientEvent:Connect(function(msg)
    HUD.ShowNotification(msg)
end)

R.UpdatePotions.OnClientEvent:Connect(function(activePotions)
    HUD.UpdatePotions(activePotions)
end)

-- ── Gem node click to extract ─────────────────────────────────────────────────
-- Every part inside Workspace.GemNodes gets a ClickDetector so it shows a hover
-- cursor and is obviously clickable. Clicking toggles extraction on that node.

local mining     = false
local currentNode = nil

local function onNodeClicked(node)
    if not node:GetAttribute("GemType") then return end

    if not mining then
        mining      = true
        currentNode = node
        local gemType = node:GetAttribute("GemType")
        local ok, mineTime = RF.StartExtraction:InvokeServer(node)
        if ok then
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local GemTypes = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("GemTypes"))
            local gd = GemTypes[gemType]
            NodeFeedback.Attach(node, gemType, mineTime or 120)
            HUD.ShowNotification("Mining " .. (gd and gd.displayName or gemType) .. "… click again to stop.")
        else
            mining      = false
            currentNode = nil
            HUD.ShowNotification("Could not start: " .. tostring(mineTime))
        end
    else
        mining      = false
        currentNode = nil
        RF.StopExtraction:InvokeServer()
        NodeFeedback.Detach()
        HUD.ShowNotification("Mining stopped.")
    end
end

local wiredNodes = {}  -- part -> true, so we wire each node's click exactly once

local function setupNode(part)
    if not part:IsA("BasePart") then return end
    if not part:GetAttribute("GemType") then return end
    if wiredNodes[part] then return end
    wiredNodes[part] = true

    -- Reuse a ClickDetector if one already exists (e.g. added by hand); else create it
    local cd = part:FindFirstChildOfClass("ClickDetector")
    if not cd then
        cd = Instance.new("ClickDetector")
        cd.MaxActivationDistance = 40
        cd.Parent = part
    end
    cd.MouseClick:Connect(function()
        onNodeClicked(part)
    end)
end

local wiredCount = 0
local nodesFolder = workspace:WaitForChild("GemNodes", 30)
if nodesFolder then
    for _, part in ipairs(nodesFolder:GetChildren()) do
        setupNode(part)
        if wiredNodes[part] then wiredCount += 1 end
    end
    -- Wire newly added nodes (e.g. placed by level scripts)
    nodesFolder.ChildAdded:Connect(function(part)
        task.wait()
        setupNode(part)
    end)
else
    warn("[GemPowerCore] Workspace.GemNodes folder not found — gem nodes won't be clickable.")
end

-- ── Physical Power Core proximity ─────────────────────────────────────────────
-- The server places a glowing core on your plot (workspace.PowerCores). When you
-- walk up to YOUR core the Power Core menu opens; it closes when you walk away.
-- The toggle button still works as a fallback.

task.spawn(function()
    local myCore
    local wasInRange = false
    local OPEN_DIST, CLOSE_DIST = 14, 20

    while true do
        task.wait(0.2)
        local char = player.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            -- (re)locate the core tagged with our UserId
            if not (myCore and myCore.Parent) then
                myCore = nil
                local folder = workspace:FindFirstChild("PowerCores")
                if folder then
                    for _, m in ipairs(folder:GetChildren()) do
                        local c = m:FindFirstChild("PowerCore")
                        if c and c:GetAttribute("OwnerUserId") == player.UserId then
                            myCore = c
                            break
                        end
                    end
                end
            end

            if myCore then
                local dist = (hrp.Position - myCore.Position).Magnitude
                if not wasInRange and dist < OPEN_DIST then
                    wasInRange = true
                    PlotUI.Open()
                elseif wasInRange and dist > CLOSE_DIST then
                    wasInRange = false
                    PlotUI.Close()
                end
            else
                wasInRange = false
            end
        end
    end
end)

print("[GemPowerCore] Client ready. Wired " .. wiredCount .. " gem node(s).")
