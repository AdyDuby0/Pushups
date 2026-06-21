-- Client entry point: loads all UI modules and connects server events

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")

local player    = Players.LocalPlayer
local playerGui = player.PlayerGui

-- Wait for remotes (server creates them at startup)
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes", 30)
assert(RemotesFolder, "[GemPowerCore] Remotes folder not found")

local R = {
    UpdateHUD         = RemotesFolder:WaitForChild("UpdateHUD"),
    UpdateInventory   = RemotesFolder:WaitForChild("UpdateInventory"),
    UpdateMarket      = RemotesFolder:WaitForChild("UpdateMarket"),
    GemExtracted      = RemotesFolder:WaitForChild("GemExtracted"),
    Notification      = RemotesFolder:WaitForChild("Notification"),
    UpdateLeaderboard = RemotesFolder:WaitForChild("UpdateLeaderboard"),
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
}

-- Load UI modules
local Modules = script.Parent:WaitForChild("Modules")
local HUD      = require(Modules:WaitForChild("HUD"))
local PlotUI   = require(Modules:WaitForChild("PlotUI"))
local MarketUI = require(Modules:WaitForChild("MarketUI"))

-- Wait for character to exist before fetching data
if not player.Character then
    player.CharacterAdded:Wait()
end
task.wait(2)  -- let server assign plot and load data first

local initData = RF.GetInitialData:InvokeServer()
assert(initData, "[GemPowerCore] Failed to get initial data from server")

-- Init all UIs
HUD.Init(playerGui, initData)
PlotUI.Init(playerGui, initData, RF)
MarketUI.Init(playerGui, initData, RF)

-- ── Server event hooks ────────────────────────────────────────────────────────

R.UpdateHUD:Connect(function(hudData)
    HUD.Update(hudData)
end)

R.UpdateInventory:Connect(function(gems)
    PlotUI.UpdateGems(gems)
    MarketUI.UpdateGems(gems)
end)

R.UpdateMarket:Connect(function(newListings)
    MarketUI.UpdateListings(newListings)
end)

R.UpdateLeaderboard:Connect(function(board)
    HUD.UpdateLeaderboard(board)
end)

R.GemExtracted:Connect(function(gemType, remaining)
    HUD.ShowFloatingText("+" .. gemType, Color3.fromRGB(80, 255, 80))
end)

R.Notification:Connect(function(msg)
    HUD.ShowNotification(msg)
end)

-- ── Gem node interaction ──────────────────────────────────────────────────────
-- Player clicks a gem node to start/stop extraction

local extracting = false

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
    and input.UserInputType ~= Enum.UserInputType.Touch then return end

    local camera    = workspace.CurrentCamera
    local unitRay   = camera:ScreenPointToRay(input.Position.X, input.Position.Y)
    local rayResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * 50)

    if rayResult and rayResult.Instance then
        local hit = rayResult.Instance
        -- Check if it's a gem node (has GemType attribute)
        if hit:GetAttribute("GemType") then
            if not extracting then
                extracting = true
                RF.StartExtraction:InvokeServer(hit)
                HUD.ShowNotification("Extracting " .. (hit:GetAttribute("GemType") or "gem") .. "...")
            else
                extracting = false
                RF.StopExtraction:InvokeServer()
                HUD.ShowNotification("Extraction stopped.")
            end
        end
    end
end)

print("[GemPowerCore] Client ready.")
