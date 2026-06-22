local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")

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
    CraftGear       = RemotesFolder:WaitForChild("CraftGear"),
    EquipGear       = RemotesFolder:WaitForChild("EquipGear"),
    UnequipGear     = RemotesFolder:WaitForChild("UnequipGear"),
    BrewPotion      = RemotesFolder:WaitForChild("BrewPotion"),
    UsePotion       = RemotesFolder:WaitForChild("UsePotion"),
}

local Modules     = script.Parent:WaitForChild("Modules")
local HUD         = require(Modules:WaitForChild("HUD"))
local PlotUI      = require(Modules:WaitForChild("PlotUI"))
local MarketUI    = require(Modules:WaitForChild("MarketUI"))
local CraftingUI  = require(Modules:WaitForChild("CraftingUI"))

if not player.Character then player.CharacterAdded:Wait() end
task.wait(2)

local initData = RF.GetInitialData:InvokeServer()
assert(initData, "[GemPowerCore] Failed to load initial data")

HUD.Init(playerGui, initData)
PlotUI.Init(playerGui, initData, RF)
MarketUI.Init(playerGui, initData, RF)
CraftingUI.Init(playerGui, initData, RF)

-- ── Server event hooks ────────────────────────────────────────────────────────

R.UpdateHUD:Connect(function(hudData)
    HUD.Update(hudData)
    if hudData.credits then
        CraftingUI.UpdateCredits(hudData.credits)
    end
end)

R.UpdateInventory:Connect(function(gems)
    PlotUI.UpdateGems(gems)
    MarketUI.UpdateGems(gems)
    CraftingUI.UpdateGems(gems)
end)

R.UpdateMarket:Connect(function(newListings)
    MarketUI.UpdateListings(newListings)
end)

R.UpdateLeaderboard:Connect(function(board)
    HUD.UpdateLeaderboard(board)
end)

R.GemExtracted:Connect(function(gemType, remaining, yield)
    local text = yield > 1 and ("+" .. yield .. "× " .. gemType) or ("+" .. gemType)
    HUD.ShowFloatingText(text, Color3.fromRGB(80, 255, 80))
end)

R.Notification:Connect(function(msg)
    HUD.ShowNotification(msg)
end)

R.UpdatePotions:Connect(function(activePotions)
    HUD.UpdatePotions(activePotions)
end)

-- ── Gem node click to extract ─────────────────────────────────────────────────

local extracting = false

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
    and input.UserInputType ~= Enum.UserInputType.Touch then return end

    local camera  = workspace.CurrentCamera
    local ray     = camera:ScreenPointToRay(input.Position.X, input.Position.Y)
    local result  = workspace:Raycast(ray.Origin, ray.Direction * 60)

    if result and result.Instance and result.Instance:GetAttribute("GemType") then
        local node = result.Instance
        if not extracting then
            extracting = true
            local gemType = node:GetAttribute("GemType")
            RF.StartExtraction:InvokeServer(node)
            HUD.ShowNotification("Extracting " .. gemType .. "… click again to stop.")
        else
            extracting = false
            RF.StopExtraction:InvokeServer()
            HUD.ShowNotification("Extraction stopped.")
        end
    end
end)

print("[GemPowerCore] Client ready — v2.")
