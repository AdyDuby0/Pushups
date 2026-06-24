local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GemTypes   = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("GemTypes"))
local CoreTypes  = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("PowerCoreTypes"))
local Panels     = require(script.Parent:WaitForChild("Panels"))

local PlotUI = {}
local RF_ref
local callbacks_ref
local data = { coreLevel = 1, coreSlots = {}, gems = {}, credits = 0 }
local slotsGrid, gemsScroll, coreTitle, coreMult, upgradeBtn
local upgradesFrame
local upgradeInfo = {}   -- array of { key, name, icon, level, bonusPerLevel, nextCost }
local upgradeRows = {}   -- key -> { buyBtn, entry }

-- Forward declarations so functions can reference each other
local refreshSlots, refreshGems, refreshUpgrades, updateUpgradeAffordability

local function fmt(n)
    n = math.floor(n)
    if n >= 1e6 then return string.format("%.2fM", n/1e6)
    elseif n >= 1e3 then return string.format("%.1fK", n/1e3)
    else return tostring(n) end
end

local function corner(inst, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = inst
end

function refreshSlots()
    if not slotsGrid then return end
    for _, c in ipairs(slotsGrid:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end
    end

    local coreData = CoreTypes[data.coreLevel]
    if coreTitle then coreTitle.Text = "⚡ " .. coreData.name .. "  (Lv." .. data.coreLevel .. ")" end
    if coreMult  then coreMult.Text  = "Base multiplier  ×" .. coreData.baseMultiplier end
    if upgradeBtn then
        if coreData.upgradeCost then
            upgradeBtn.Text = "Upgrade → " .. fmt(coreData.upgradeCost) .. " CR"
        else
            upgradeBtn.Text = "MAX LEVEL"
            upgradeBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 160)
        end
    end

    for i = 1, coreData.maxSlots do
        local slotted = data.coreSlots[i]
        local gemData = slotted and GemTypes[slotted]

        local slot = Instance.new("Frame")
        slot.Size            = UDim2.new(0, 78, 0, 78)
        slot.BackgroundColor3 = gemData and gemData.color or Color3.fromRGB(28, 28, 50)
        slot.BackgroundTransparency = gemData and 0.3 or 0.55
        slot.BorderSizePixel = 0
        slot.Parent          = slotsGrid
        corner(slot, 8)

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size                 = UDim2.new(1, -4, 0.55, 0)
        nameLbl.Position             = UDim2.new(0, 2, 0, 2)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text                 = gemData and gemData.displayName or "EMPTY"
        nameLbl.TextColor3           = Color3.fromRGB(255, 255, 255)
        nameLbl.Font                 = Enum.Font.GothamBold
        nameLbl.TextScaled           = true
        nameLbl.TextWrapped          = true
        nameLbl.Parent               = slot

        if slotted then
            local removeBtn = Instance.new("TextButton")
            removeBtn.Size            = UDim2.new(1, -6, 0.35, 0)
            removeBtn.Position        = UDim2.new(0, 3, 0.62, 0)
            removeBtn.BackgroundColor3 = Color3.fromRGB(170, 45, 45)
            removeBtn.BorderSizePixel = 0
            removeBtn.Text            = "Remove"
            removeBtn.TextColor3      = Color3.fromRGB(255, 255, 255)
            removeBtn.TextScaled      = true
            removeBtn.Font            = Enum.Font.Gotham
            removeBtn.Parent          = slot
            corner(removeBtn, 4)

            local captI = i
            local captG = slotted
            removeBtn.MouseButton1Click:Connect(function()
                local ok = RF_ref.UnslotGem:InvokeServer(captI)
                if ok then
                    data.coreSlots[captI] = nil
                    data.gems[captG] = (data.gems[captG] or 0) + 1
                    refreshSlots()
                    refreshGems()
                end
            end)
        end
    end
end

function refreshGems()
    if not gemsScroll then return end
    for _, c in ipairs(gemsScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

    for gemType, count in pairs(data.gems) do
        if count > 0 and GemTypes[gemType] then
            local gd = GemTypes[gemType]
            local row = Instance.new("Frame")
            row.Size             = UDim2.new(1, -6, 0, 50)
            row.BackgroundColor3 = gd.color
            row.BackgroundTransparency = 0.5
            row.BorderSizePixel  = 0
            row.Parent           = gemsScroll
            corner(row, 6)

            local stripe = Instance.new("Frame")
            stripe.Size             = UDim2.new(0, 5, 1, 0)
            stripe.BackgroundColor3 = gd.color
            stripe.BorderSizePixel  = 0
            stripe.Parent           = row
            corner(stripe, 4)

            local nameLbl = Instance.new("TextLabel")
            nameLbl.Size                 = UDim2.new(0.5, -12, 0.55, 0)
            nameLbl.Position             = UDim2.new(0, 12, 0, 2)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Text                 = gd.displayName
            nameLbl.TextColor3           = Color3.fromRGB(255, 255, 255)
            nameLbl.Font                 = Enum.Font.GothamBold
            nameLbl.TextScaled           = true
            nameLbl.TextXAlignment       = Enum.TextXAlignment.Left
            nameLbl.Parent               = row

            local cntLbl = Instance.new("TextLabel")
            cntLbl.Size                 = UDim2.new(0.25, 0, 0.42, 0)
            cntLbl.Position             = UDim2.new(0, 12, 0.55, 0)
            cntLbl.BackgroundTransparency = 1
            cntLbl.Text                 = "×" .. count
            cntLbl.TextColor3           = Color3.fromRGB(255, 255, 180)
            cntLbl.Font                 = Enum.Font.Gotham
            cntLbl.TextScaled           = true
            cntLbl.TextXAlignment       = Enum.TextXAlignment.Left
            cntLbl.Parent               = row

            local slotBtn = Instance.new("TextButton")
            slotBtn.Size             = UDim2.new(0.35, -4, 0.75, 0)
            slotBtn.Position         = UDim2.new(0.65, 2, 0.125, 0)
            slotBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 40)
            slotBtn.BorderSizePixel  = 0
            slotBtn.Text             = "Slot"
            slotBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
            slotBtn.Font             = Enum.Font.Gotham
            slotBtn.TextScaled       = true
            slotBtn.Parent           = row
            corner(slotBtn, 4)

            local captG = gemType
            slotBtn.MouseButton1Click:Connect(function()
                local coreData = CoreTypes[data.coreLevel]
                local emptySlot
                for s = 1, coreData.maxSlots do
                    if not data.coreSlots[s] then emptySlot = s; break end
                end
                if not emptySlot then return end

                local ok = RF_ref.SlotGem:InvokeServer(captG, emptySlot)
                if ok then
                    data.coreSlots[emptySlot] = captG
                    data.gems[captG] = (data.gems[captG] or 0) - 1
                    if data.gems[captG] <= 0 then data.gems[captG] = nil end
                    refreshSlots()
                    refreshGems()
                    if callbacks_ref and callbacks_ref.onFirstSlot then callbacks_ref.onFirstSlot() end
                end
            end)
        end
    end
end

function updateUpgradeAffordability()
    for _, r in pairs(upgradeRows) do
        local afford = data.credits >= r.entry.nextCost
        r.buyBtn.BackgroundColor3 = afford and Color3.fromRGB(40, 140, 70) or Color3.fromRGB(55, 55, 75)
        r.buyBtn.AutoButtonColor  = afford
    end
end

function refreshUpgrades()
    if not upgradesFrame then return end
    for _, c in ipairs(upgradesFrame:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    upgradeRows = {}

    for _, entry in ipairs(upgradeInfo) do
        local row = Instance.new("Frame")
        row.Size                 = UDim2.new(1, -8, 0, 46)
        row.BackgroundColor3     = Color3.fromRGB(16, 22, 44)
        row.BackgroundTransparency = 0.2
        row.BorderSizePixel      = 0
        row.Parent               = upgradesFrame
        corner(row, 6)

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size                 = UDim2.new(0.58, -6, 0.55, 0)
        nameLbl.Position             = UDim2.new(0, 8, 0, 2)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text                 = entry.icon .. " " .. entry.name .. "  Lv." .. entry.level
        nameLbl.TextColor3           = Color3.fromRGB(180, 220, 255)
        nameLbl.Font                 = Enum.Font.GothamBold
        nameLbl.TextScaled           = true
        nameLbl.TextXAlignment       = Enum.TextXAlignment.Left
        nameLbl.Parent               = row

        local bonusLbl = Instance.new("TextLabel")
        bonusLbl.Size                 = UDim2.new(0.58, -6, 0.42, 0)
        bonusLbl.Position             = UDim2.new(0, 8, 0.55, 0)
        bonusLbl.BackgroundTransparency = 1
        bonusLbl.Text                 = string.format("+%d%% per lvl  •  now +%d%%",
            math.floor(entry.bonusPerLevel * 100 + 0.5),
            math.floor(entry.level * entry.bonusPerLevel * 100 + 0.5))
        bonusLbl.TextColor3           = Color3.fromRGB(120, 210, 130)
        bonusLbl.Font                 = Enum.Font.Gotham
        bonusLbl.TextScaled           = true
        bonusLbl.TextXAlignment       = Enum.TextXAlignment.Left
        bonusLbl.Parent               = row

        local buyBtn = Instance.new("TextButton")
        buyBtn.Size              = UDim2.new(0.4, -8, 0.78, 0)
        buyBtn.Position          = UDim2.new(0.6, 0, 0.11, 0)
        buyBtn.BorderSizePixel   = 0
        buyBtn.Text              = fmt(entry.nextCost) .. " CR"
        buyBtn.TextColor3        = Color3.fromRGB(255, 255, 255)
        buyBtn.Font              = Enum.Font.GothamBold
        buyBtn.TextScaled        = true
        buyBtn.Parent            = row
        corner(buyBtn, 4)

        local capKey = entry.key
        buyBtn.MouseButton1Click:Connect(function()
            local ok, result = RF_ref.BuyCoreUpgrade:InvokeServer(capKey)
            if ok and type(result) == "table" then
                entry.level    = result.level
                entry.nextCost = result.nextCost
                data.credits   = result.credits
                refreshUpgrades()
            end
        end)

        upgradeRows[entry.key] = { buyBtn = buyBtn, entry = entry }
    end

    updateUpgradeAffordability()
end

function PlotUI.Init(playerGui, initData, RF, callbacks)
    RF_ref = RF
    callbacks_ref = callbacks
    data.coreLevel = initData.coreLevel
    data.coreSlots = initData.coreSlots
    data.gems      = initData.gems
    data.credits   = initData.credits
    upgradeInfo    = initData.coreUpgrades or {}

    local gui = Instance.new("ScreenGui")
    gui.Name           = "PlotUI"
    gui.ResetOnSpawn   = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent         = playerGui

    -- Toggle button
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size            = UDim2.new(0, 130, 0, 38)
    toggleBtn.Position        = UDim2.new(0, 8, 0, 64)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(35, 15, 75)
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Text            = "⚡ Power Core"
    toggleBtn.TextColor3      = Color3.fromRGB(200, 150, 255)
    toggleBtn.Font            = Enum.Font.GothamBold
    toggleBtn.TextScaled      = true
    toggleBtn.Parent          = gui
    corner(toggleBtn, 6)

    -- Panel
    local panel = Instance.new("Frame")
    panel.Name            = "CorePanel"
    panel.Size            = UDim2.new(0, 360, 0, 660)
    panel.Position        = UDim2.new(0, 8, 0, 110)
    panel.BackgroundColor3 = Color3.fromRGB(8, 8, 22)
    panel.BackgroundTransparency = 0.08
    panel.BorderSizePixel = 0
    panel.Visible         = false
    panel.Parent          = gui
    corner(panel, 10)

    -- Header
    local header = Instance.new("Frame")
    header.Size            = UDim2.new(1, 0, 0, 42)
    header.BackgroundColor3 = Color3.fromRGB(35, 10, 75)
    header.BorderSizePixel = 0
    header.Parent          = panel
    corner(header, 10)

    coreTitle = Instance.new("TextLabel")
    coreTitle.Size                 = UDim2.new(1, -8, 1, 0)
    coreTitle.Position             = UDim2.new(0, 8, 0, 0)
    coreTitle.BackgroundTransparency = 1
    coreTitle.TextColor3           = Color3.fromRGB(200, 150, 255)
    coreTitle.Font                 = Enum.Font.GothamBold
    coreTitle.TextScaled           = true
    coreTitle.TextXAlignment       = Enum.TextXAlignment.Left
    coreTitle.Parent               = header

    coreMult = Instance.new("TextLabel")
    coreMult.Size                 = UDim2.new(1, -16, 0, 22)
    coreMult.Position             = UDim2.new(0, 8, 0, 44)
    coreMult.BackgroundTransparency = 1
    coreMult.TextColor3           = Color3.fromRGB(130, 190, 255)
    coreMult.Font                 = Enum.Font.Gotham
    coreMult.TextScaled           = true
    coreMult.TextXAlignment       = Enum.TextXAlignment.Left
    coreMult.Parent               = panel

    -- Slots label
    local slotsLbl = Instance.new("TextLabel")
    slotsLbl.Size                 = UDim2.new(1, -8, 0, 20)
    slotsLbl.Position             = UDim2.new(0, 8, 0, 68)
    slotsLbl.BackgroundTransparency = 1
    slotsLbl.Text                 = "GEM SLOTS"
    slotsLbl.TextColor3           = Color3.fromRGB(160, 160, 160)
    slotsLbl.Font                 = Enum.Font.GothamBold
    slotsLbl.TextScaled           = true
    slotsLbl.TextXAlignment       = Enum.TextXAlignment.Left
    slotsLbl.Parent               = panel

    -- Slots grid frame
    slotsGrid = Instance.new("Frame")
    slotsGrid.Name            = "SlotsGrid"
    slotsGrid.Size            = UDim2.new(1, -8, 0, 176)
    slotsGrid.Position        = UDim2.new(0, 4, 0, 90)
    slotsGrid.BackgroundTransparency = 1
    slotsGrid.Parent          = panel

    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize    = UDim2.new(0, 78, 0, 78)
    gridLayout.CellPadding = UDim2.new(0, 5, 0, 5)
    gridLayout.Parent      = slotsGrid

    -- Inventory label
    local invLbl = Instance.new("TextLabel")
    invLbl.Size                 = UDim2.new(1, -8, 0, 20)
    invLbl.Position             = UDim2.new(0, 8, 0, 272)
    invLbl.BackgroundTransparency = 1
    invLbl.Text                 = "INVENTORY"
    invLbl.TextColor3           = Color3.fromRGB(160, 160, 160)
    invLbl.Font                 = Enum.Font.GothamBold
    invLbl.TextScaled           = true
    invLbl.TextXAlignment       = Enum.TextXAlignment.Left
    invLbl.Parent               = panel

    -- Gems scrolling frame
    gemsScroll = Instance.new("ScrollingFrame")
    gemsScroll.Size              = UDim2.new(1, -8, 0, 108)
    gemsScroll.Position          = UDim2.new(0, 4, 0, 294)
    gemsScroll.BackgroundTransparency = 1
    gemsScroll.BorderSizePixel   = 0
    gemsScroll.ScrollBarThickness = 4
    gemsScroll.CanvasSize        = UDim2.new(0, 0, 0, 0)
    gemsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    gemsScroll.Parent            = panel

    local gemsList = Instance.new("UIListLayout")
    gemsList.Padding   = UDim.new(0, 4)
    gemsList.Parent    = gemsScroll

    -- Core upgrades label
    local upgLbl = Instance.new("TextLabel")
    upgLbl.Size                 = UDim2.new(1, -8, 0, 20)
    upgLbl.Position             = UDim2.new(0, 8, 0, 408)
    upgLbl.BackgroundTransparency = 1
    upgLbl.Text                 = "⚡ CORE UPGRADES"
    upgLbl.TextColor3           = Color3.fromRGB(255, 210, 90)
    upgLbl.Font                 = Enum.Font.GothamBold
    upgLbl.TextScaled           = true
    upgLbl.TextXAlignment       = Enum.TextXAlignment.Left
    upgLbl.Parent               = panel

    -- Core upgrades container (rows stacked vertically)
    upgradesFrame = Instance.new("Frame")
    upgradesFrame.Name            = "UpgradesFrame"
    upgradesFrame.Size            = UDim2.new(1, -8, 0, 156)
    upgradesFrame.Position        = UDim2.new(0, 4, 0, 430)
    upgradesFrame.BackgroundTransparency = 1
    upgradesFrame.BorderSizePixel = 0
    upgradesFrame.Parent          = panel

    local upgLayout = Instance.new("UIListLayout")
    upgLayout.Padding   = UDim.new(0, 4)
    upgLayout.Parent    = upgradesFrame

    -- Upgrade button
    upgradeBtn = Instance.new("TextButton")
    upgradeBtn.Name            = "UpgradeBtn"
    upgradeBtn.Size            = UDim2.new(1, -16, 0, 36)
    upgradeBtn.Position        = UDim2.new(0, 8, 1, -44)
    upgradeBtn.BackgroundColor3 = Color3.fromRGB(40, 90, 200)
    upgradeBtn.BorderSizePixel = 0
    upgradeBtn.TextColor3      = Color3.fromRGB(255, 255, 255)
    upgradeBtn.Font            = Enum.Font.GothamBold
    upgradeBtn.TextScaled      = true
    upgradeBtn.Parent          = panel
    corner(upgradeBtn, 6)

    upgradeBtn.MouseButton1Click:Connect(function()
        local ok, err = RF.UpgradeCore:InvokeServer()
        if ok then
            local prevCoreData = CoreTypes[data.coreLevel]
            data.credits -= prevCoreData.upgradeCost
            data.coreLevel += 1
            refreshSlots()
        end
    end)

    -- Toggle
    local open = false
    Panels.Register("PowerCore", function()
        open = false
        panel.Visible = false
    end)
    toggleBtn.MouseButton1Click:Connect(function()
        open = not open
        panel.Visible = open
        if open then
            Panels.CloseOthers("PowerCore")
            refreshSlots()
            refreshGems()
            refreshUpgrades()
            if callbacks_ref and callbacks_ref.onCoreOpened then callbacks_ref.onCoreOpened() end
        end
    end)

    refreshSlots()
    refreshUpgrades()
end

function PlotUI.UpdateGems(gems)
    data.gems = gems
    refreshGems()
end

function PlotUI.UpdateCredits(credits)
    data.credits = credits
    updateUpgradeAffordability()
end

return PlotUI
