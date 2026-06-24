-- Crafting panel: two tabs — Gear and Potions.
-- Shows what's available to craft, what the player owns/has equipped, and lets them equip/use.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GearTypes    = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("GearTypes"))
local PotionTypes  = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("PotionTypes"))
local Panels       = require(script.Parent:WaitForChild("Panels"))

local CraftingUI = {}
local RF_ref
local playerData = { gems = {}, credits = 0, craftedGear = {}, gear = {}, potionInventory = {} }

local gearPanel, potionPanel
local gearListFrame, potionListFrame

local GEAR_CATEGORIES = { "Conductor", "Amplifier", "Capacitor", "Drill" }
local GEAR_DESCS = {
    Conductor = "Boosts total income by a %.",
    Amplifier = "Boosts base fuel of all gems by a %.",
    Capacitor = "Adds extra gem slots to your core.",
    Drill     = "Reduces extraction time per gem.",
}

local function fmt(n)
    n = math.floor(n)
    if n >= 1e9 then return string.format("%.2fB", n/1e9)
    elseif n >= 1e6 then return string.format("%.2fM", n/1e6)
    elseif n >= 1e3 then return string.format("%.1fK", n/1e3)
    else return tostring(n) end
end

local function corner(inst, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = inst
end

local function owned(category, tier)
    for _, g in ipairs(playerData.craftedGear) do
        if g.category == category and g.tier == tier then return true end
    end
    return false
end

local function equipped(category, tier)
    local key = string.lower(category)
    return playerData.gear[key] and playerData.gear[key].tier == tier
end

local function canAfford(cost)
    if playerData.credits < cost.credits then return false end
    for gemType, qty in pairs(cost) do
        if gemType ~= "credits" and (playerData.gems[gemType] or 0) < qty then
            return false
        end
    end
    return true
end

local function costText(cost)
    local parts = { fmt(cost.credits) .. " CR" }
    for gemType, qty in pairs(cost) do
        if gemType ~= "credits" then
            table.insert(parts, qty .. "× " .. gemType)
        end
    end
    return table.concat(parts, "  +  ")
end

local rebuildGear  -- forward declaration (row buttons call it)

-- Lower number = higher on the list. Craftable rises to the top.
local function gearPriority(category, tier)
    if canAfford(GearTypes[category][tier].craftCost) and not owned(category, tier) then
        return 0  -- craftable right now
    end
    if equipped(category, tier) then return 1 end
    if owned(category, tier)    then return 2 end
    return 3  -- locked
end

local function makeGearRow(category, tier)
    local gd = GearTypes[category][tier]
    local isOwned    = owned(category, tier)
    local isEquipped = equipped(category, tier)
    local affordable = canAfford(gd.craftCost)
    local craftable  = affordable and not isOwned

    local statusIcon = isEquipped and "✔ "
        or (isOwned and "📦 ")
        or (craftable and "🔨 " or "🔒 ")

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -4, 0, 52)
    row.BackgroundColor3 = isEquipped and Color3.fromRGB(40, 60, 20)
        or (craftable and Color3.fromRGB(22, 34, 58) or Color3.fromRGB(18, 18, 35))
    row.BackgroundTransparency = 0.25
    row.BorderSizePixel = 0
    row.Parent = gearListFrame
    corner(row, 5)

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(0.55, -8, 0.55, 0)
    nameLbl.Position = UDim2.new(0, 8, 0, 2)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = statusIcon .. gd.name
    nameLbl.TextColor3 = isEquipped and Color3.fromRGB(100, 255, 100)
        or (craftable and Color3.fromRGB(150, 220, 255) or Color3.fromRGB(220, 220, 255))
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextScaled = true
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.Parent = row

    local costLbl = Instance.new("TextLabel")
    costLbl.Size = UDim2.new(0.55, -8, 0.42, 0)
    costLbl.Position = UDim2.new(0, 8, 0.55, 0)
    costLbl.BackgroundTransparency = 1
    costLbl.Text = isOwned and GEAR_DESCS[category] or costText(gd.craftCost)
    costLbl.TextColor3 = isOwned and Color3.fromRGB(150, 200, 150)
        or (affordable and Color3.fromRGB(255, 220, 80) or Color3.fromRGB(180, 100, 100))
    costLbl.Font = Enum.Font.Gotham
    costLbl.TextScaled = true
    costLbl.TextXAlignment = Enum.TextXAlignment.Left
    costLbl.Parent = row

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.4, -6, 0.75, 0)
    btn.Position = UDim2.new(0.6, 3, 0.125, 0)
    btn.BorderSizePixel = 0
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextScaled = true
    btn.Parent = row
    corner(btn, 4)

    if isEquipped then
        btn.BackgroundColor3 = Color3.fromRGB(100, 60, 20)
        btn.Text = "Unequip"
        local capCat = category
        btn.MouseButton1Click:Connect(function()
            RF_ref.UnequipGear:InvokeServer(capCat)
            local key = string.lower(capCat)
            if playerData.gear[key] then
                table.insert(playerData.craftedGear, { category = capCat, tier = playerData.gear[key].tier })
                playerData.gear[key] = nil
            end
            rebuildGear()
        end)
    elseif isOwned then
        btn.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
        btn.Text = "Equip"
        local capCat, capTier = category, tier
        btn.MouseButton1Click:Connect(function()
            local ok = RF_ref.EquipGear:InvokeServer(capCat, capTier)
            if ok then
                local key = string.lower(capCat)
                local oldTier = playerData.gear[key] and playerData.gear[key].tier
                if oldTier then
                    table.insert(playerData.craftedGear, { category = capCat, tier = oldTier })
                end
                for i, g in ipairs(playerData.craftedGear) do
                    if g.category == capCat and g.tier == capTier then
                        table.remove(playerData.craftedGear, i); break
                    end
                end
                playerData.gear[key] = { tier = capTier }
                rebuildGear()
            end
        end)
    else
        btn.BackgroundColor3 = affordable and Color3.fromRGB(50, 80, 180) or Color3.fromRGB(60, 60, 80)
        btn.Text = affordable and "Craft" or "Locked"
        if affordable then
            local capCat, capTier = category, tier
            btn.MouseButton1Click:Connect(function()
                local ok = RF_ref.CraftGear:InvokeServer(capCat, capTier)
                if ok then
                    table.insert(playerData.craftedGear, { category = capCat, tier = capTier })
                    playerData.credits -= GearTypes[capCat][capTier].craftCost.credits
                    rebuildGear()
                end
            end)
        end
    end
end

function rebuildGear()
    if not gearListFrame then return end
    for _, c in ipairs(gearListFrame:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

    -- Flatten every gear piece, then sort so the items you can act on come first
    local entries = {}
    for ci, category in ipairs(GEAR_CATEGORIES) do
        for tier = 1, 4 do
            table.insert(entries, { category = category, tier = tier, ci = ci })
        end
    end
    table.sort(entries, function(a, b)
        local pa = gearPriority(a.category, a.tier)
        local pb = gearPriority(b.category, b.tier)
        if pa ~= pb then return pa < pb end
        if a.ci ~= b.ci then return a.ci < b.ci end
        return a.tier < b.tier
    end)

    for _, e in ipairs(entries) do
        makeGearRow(e.category, e.tier)
    end
end

local function rebuildPotions()
    if not potionListFrame then return end
    for _, c in ipairs(potionListFrame:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

    -- Sort: brewable potions first, then by name (stable, unlike pairs())
    local potionEntries = {}
    for potionType, pd in pairs(PotionTypes) do
        table.insert(potionEntries, { t = potionType, pd = pd })
    end
    table.sort(potionEntries, function(a, b)
        local aa, ba = canAfford(a.pd.craftCost), canAfford(b.pd.craftCost)
        if aa ~= ba then return aa end
        return a.pd.displayName < b.pd.displayName
    end)

    for _, entry in ipairs(potionEntries) do
        local potionType, pd = entry.t, entry.pd
        local count     = playerData.potionInventory[potionType] or 0
        local affordable = canAfford(pd.craftCost)

        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -4, 0, 64)
        row.BackgroundColor3 = pd.color
        row.BackgroundTransparency = 0.6
        row.BorderSizePixel = 0
        row.Parent = potionListFrame
        corner(row, 6)

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(0.55, -8, 0.48, 0)
        nameLbl.Position = UDim2.new(0, 8, 0, 2)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = pd.icon .. " " .. pd.displayName .. (count > 0 and "  ×" .. count or "")
        nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextScaled = true
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.Parent = row

        local descLbl = Instance.new("TextLabel")
        descLbl.Size = UDim2.new(0.55, -8, 0.38, 0)
        descLbl.Position = UDim2.new(0, 8, 0.48, 0)
        descLbl.BackgroundTransparency = 1
        descLbl.Text = pd.description
        descLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
        descLbl.Font = Enum.Font.Gotham
        descLbl.TextScaled = true
        descLbl.TextXAlignment = Enum.TextXAlignment.Left
        descLbl.Parent = row

        local costLbl = Instance.new("TextLabel")
        costLbl.Size = UDim2.new(0.55, -8, 0.18, 0)
        costLbl.Position = UDim2.new(0, 8, 0.82, 0)
        costLbl.BackgroundTransparency = 1
        costLbl.Text = "Brew: " .. costText(pd.craftCost)
        costLbl.TextColor3 = affordable
            and Color3.fromRGB(255, 220, 80)
            or  Color3.fromRGB(200, 130, 130)
        costLbl.Font = Enum.Font.Gotham
        costLbl.TextScaled = true
        costLbl.TextXAlignment = Enum.TextXAlignment.Left
        costLbl.Parent = row

        -- Brew button
        local brewBtn = Instance.new("TextButton")
        brewBtn.Size = UDim2.new(0.2, -4, 0.75, 0)
        brewBtn.Position = UDim2.new(0.58, 2, 0.125, 0)
        brewBtn.BackgroundColor3 = affordable
            and Color3.fromRGB(40, 100, 160)
            or  Color3.fromRGB(60, 60, 80)
        brewBtn.BorderSizePixel = 0
        brewBtn.Text = "Brew"
        brewBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        brewBtn.Font = Enum.Font.Gotham
        brewBtn.TextScaled = true
        brewBtn.Parent = row
        corner(brewBtn, 4)

        if affordable then
            local capType = potionType
            brewBtn.MouseButton1Click:Connect(function()
                local ok = RF_ref.BrewPotion:InvokeServer(capType)
                if ok then
                    playerData.potionInventory[capType] = (playerData.potionInventory[capType] or 0) + 1
                    playerData.credits -= pd.craftCost.credits
                    rebuildPotions()
                end
            end)
        end

        -- Use button
        local useBtn = Instance.new("TextButton")
        useBtn.Size = UDim2.new(0.2, -4, 0.75, 0)
        useBtn.Position = UDim2.new(0.79, 2, 0.125, 0)
        useBtn.BackgroundColor3 = count > 0
            and Color3.fromRGB(140, 40, 160)
            or  Color3.fromRGB(60, 60, 80)
        useBtn.BorderSizePixel = 0
        useBtn.Text = count > 0 and "Use" or "—"
        useBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        useBtn.Font = Enum.Font.GothamBold
        useBtn.TextScaled = true
        useBtn.Parent = row
        corner(useBtn, 4)

        if count > 0 then
            local capType = potionType
            useBtn.MouseButton1Click:Connect(function()
                RF_ref.UsePotion:InvokeServer(capType)
                playerData.potionInventory[capType] = math.max((playerData.potionInventory[capType] or 1) - 1, 0)
                rebuildPotions()
            end)
        end
    end
end

function CraftingUI.Init(playerGui, initData, RF)
    RF_ref = RF
    playerData.gems            = initData.gems or {}
    playerData.credits         = initData.credits or 0
    playerData.craftedGear     = initData.craftedGear or {}
    playerData.gear            = initData.gear or {}
    playerData.potionInventory = initData.potionInventory or {}

    local gui = Instance.new("ScreenGui")
    gui.Name = "CraftingUI"; gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = playerGui

    -- Toggle button
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 130, 0, 38)
    toggleBtn.Position = UDim2.new(0, 284, 0, 64)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(20, 50, 60)
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Text = "🔧 Crafting"
    toggleBtn.TextColor3 = Color3.fromRGB(100, 220, 255)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextScaled = true
    toggleBtn.Parent = gui
    corner(toggleBtn, 6)

    -- Panel
    local panel = Instance.new("Frame")
    panel.Name = "CraftingPanel"
    panel.Size = UDim2.new(0, 480, 0, 580)
    panel.Position = UDim2.new(0, 8, 0, 110)
    panel.BackgroundColor3 = Color3.fromRGB(8, 8, 22)
    panel.BackgroundTransparency = 0.08
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Parent = gui
    corner(panel, 10)

    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 42)
    header.BackgroundColor3 = Color3.fromRGB(10, 45, 55)
    header.BorderSizePixel = 0
    header.Parent = panel
    corner(header, 10)

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, 0, 1, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = "🔧  CRAFTING"
    titleLbl.TextColor3 = Color3.fromRGB(100, 220, 255)
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextScaled = true
    titleLbl.Parent = header

    -- Tabs
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, -8, 0, 32)
    tabBar.Position = UDim2.new(0, 4, 0, 46)
    tabBar.BackgroundTransparency = 1
    tabBar.BorderSizePixel = 0
    tabBar.Parent = panel

    local function makeTab(label, xPos)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.48, 0, 1, 0)
        btn.Position = UDim2.new(xPos, 0, 0, 0)
        btn.BackgroundColor3 = Color3.fromRGB(25, 25, 50)
        btn.BorderSizePixel = 0
        btn.Text = label
        btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        btn.Font = Enum.Font.GothamBold
        btn.TextScaled = true
        btn.Parent = tabBar
        corner(btn, 4)
        return btn
    end

    local gearTab   = makeTab("⚙ Gear",    0)
    local potionTab = makeTab("🧪 Potions", 0.52)

    -- Content area
    local contentArea = Instance.new("Frame")
    contentArea.Size = UDim2.new(1, -8, 1, -86)
    contentArea.Position = UDim2.new(0, 4, 0, 82)
    contentArea.BackgroundTransparency = 1
    contentArea.BorderSizePixel = 0
    contentArea.Parent = panel

    -- Gear scroll
    local gearScroll = Instance.new("ScrollingFrame")
    gearScroll.Size = UDim2.new(1, 0, 1, 0)
    gearScroll.BackgroundTransparency = 1
    gearScroll.BorderSizePixel = 0
    gearScroll.ScrollBarThickness = 4
    gearScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    gearScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    gearScroll.Parent = contentArea
    gearListFrame = gearScroll

    local gearLayout = Instance.new("UIListLayout")
    gearLayout.Padding = UDim.new(0, 4)
    gearLayout.Parent = gearListFrame

    -- Potion scroll
    local potionScroll = Instance.new("ScrollingFrame")
    potionScroll.Size = UDim2.new(1, 0, 1, 0)
    potionScroll.BackgroundTransparency = 1
    potionScroll.BorderSizePixel = 0
    potionScroll.ScrollBarThickness = 4
    potionScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    potionScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    potionScroll.Visible = false
    potionScroll.Parent = contentArea
    potionListFrame = potionScroll

    local potionLayout = Instance.new("UIListLayout")
    potionLayout.Padding = UDim.new(0, 4)
    potionLayout.Parent = potionListFrame

    gearPanel   = gearScroll
    potionPanel = potionScroll

    gearTab.MouseButton1Click:Connect(function()
        gearScroll.Visible   = true
        potionScroll.Visible = false
        gearTab.BackgroundColor3   = Color3.fromRGB(40, 40, 80)
        potionTab.BackgroundColor3 = Color3.fromRGB(25, 25, 50)
        rebuildGear()
    end)

    potionTab.MouseButton1Click:Connect(function()
        gearScroll.Visible   = false
        potionScroll.Visible = true
        gearTab.BackgroundColor3   = Color3.fromRGB(25, 25, 50)
        potionTab.BackgroundColor3 = Color3.fromRGB(40, 40, 80)
        rebuildPotions()
    end)

    -- Default active tab
    gearTab.BackgroundColor3 = Color3.fromRGB(40, 40, 80)
    rebuildGear()

    local open = false
    Panels.Register("Crafting", function()
        open = false
        panel.Visible = false
    end)
    toggleBtn.MouseButton1Click:Connect(function()
        open = not open
        panel.Visible = open
        if open then
            Panels.CloseOthers("Crafting")
            rebuildGear()
        end
    end)
end

function CraftingUI.UpdateCredits(credits)
    playerData.credits = credits
end

function CraftingUI.UpdateGems(gems)
    playerData.gems = gems
end

return CraftingUI
