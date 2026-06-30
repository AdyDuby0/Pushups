-- Shop panel: Game Passes, 💎 Premium Boosts, 💱 Convert.
-- Toggle button at the right end of the button row (x=422, y=64).

local MarketplaceService = game:GetService("MarketplaceService")
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("GameConfig"))
local Panels     = require(script.Parent:WaitForChild("Panels"))

local ShopUI = {}
local RF_ref
local gemCurrLabel  -- updated by UpdateGemCurrency
local gemCurr = 0
local shopPanel
local shopOpen = false

local function corner(inst, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = inst
end

local function fmt(n)
    n = math.floor(n)
    local a = math.abs(n)
    if a >= 1e15 then return string.format("%.1fQ", n/1e15)
    elseif a >= 1e12 then return string.format("%.1fT", n/1e12)
    elseif a >= 1e9  then return string.format("%.1fB", n/1e9)
    elseif a >= 1e6  then return string.format("%.1fM", n/1e6)
    elseif a >= 1e3  then return string.format("%.1fK", n/1e3)
    else return tostring(n) end
end

local function sectionHdr(parent, text, color)
    local hdr = Instance.new("Frame")
    hdr.Size = UDim2.new(1, 0, 0, 28)
    hdr.BackgroundColor3 = Color3.fromRGB(10, 10, 28)
    hdr.BackgroundTransparency = 0.2
    hdr.BorderSizePixel = 0
    hdr.Parent = parent
    corner(hdr, 4)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -10, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = color
    lbl.Font = Enum.Font.GothamBold
    lbl.TextScaled = true
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = hdr
end

-- Generic shop row frame with a right-side action button.
-- Returns (row, btn)
local function makeRow(parent, h)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, h or 70)
    row.BackgroundColor3 = Color3.fromRGB(18, 18, 40)
    row.BackgroundTransparency = 0.3
    row.BorderSizePixel = 0
    row.Parent = parent
    corner(row, 6)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 100, 0, h and (h - 18) or 52)
    btn.Position = UDim2.new(1, -108, 0.5, 0)
    btn.AnchorPoint = Vector2.new(0, 0.5)
    btn.BorderSizePixel = 0
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextScaled = true
    btn.Parent = row
    corner(btn, 5)

    return row, btn
end

local function lbl(parent, text, size, pos, color, font, xAlign)
    local l = Instance.new("TextLabel")
    l.Size = size
    l.Position = pos
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color or Color3.fromRGB(220, 220, 255)
    l.Font = font or Enum.Font.Gotham
    l.TextScaled = true
    l.TextXAlignment = xAlign or Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

function ShopUI.Init(playerGui, initData, RF)
    RF_ref   = RF
    gemCurr  = initData.gemCurrency or 0

    local player = Players.LocalPlayer

    local gui = Instance.new("ScreenGui")
    gui.Name = "ShopUI"; gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = playerGui

    -- Toggle button
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 120, 0, 38)
    toggleBtn.Position = UDim2.new(0, 422, 0, 64)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 20, 60)
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Text = "🛒 Shop"
    toggleBtn.TextColor3 = Color3.fromRGB(200, 130, 255)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextScaled = true
    toggleBtn.Visible = false  -- physical-only: opened from the center Shop station
    toggleBtn.Parent = gui
    corner(toggleBtn, 6)

    -- Panel (centered on screen)
    local panel = Instance.new("Frame")
    panel.Name = "ShopPanel"
    panel.Size = UDim2.new(0, 540, 0, 640)
    panel.Position = UDim2.new(0.5, 0, 0.5, 0)
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.BackgroundColor3 = Color3.fromRGB(8, 6, 20)
    panel.BackgroundTransparency = 0.06
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Parent = gui
    corner(panel, 10)

    -- Header bar
    local headerBar = Instance.new("Frame")
    headerBar.Size = UDim2.new(1, 0, 0, 42)
    headerBar.BackgroundColor3 = Color3.fromRGB(28, 10, 50)
    headerBar.BorderSizePixel = 0
    headerBar.Parent = panel
    corner(headerBar, 10)

    lbl(headerBar, "🛒  SHOP", UDim2.new(0.5, 0, 1, 0), UDim2.new(0, 8, 0, 0),
        Color3.fromRGB(200, 130, 255), Enum.Font.GothamBold, Enum.TextXAlignment.Left)

    -- 💎 balance in header
    gemCurrLabel = lbl(headerBar, "💎 " .. fmt(gemCurr),
        UDim2.new(0.4, -52, 1, 0), UDim2.new(0.6, 4, 0, 0),
        Color3.fromRGB(160, 100, 255), Enum.Font.GothamBold, Enum.TextXAlignment.Right)

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 34, 0, 34); closeBtn.Position = UDim2.new(1, -38, 0, 4)
    closeBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 40); closeBtn.BorderSizePixel = 0
    closeBtn.Text = "✕"; closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextScaled = true; closeBtn.Parent = headerBar
    corner(closeBtn, 6)
    closeBtn.MouseButton1Click:Connect(function() shopOpen = false; panel.Visible = false end)

    -- Scroll area
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -8, 1, -50)
    scroll.Position = UDim2.new(0, 4, 0, 46)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = panel

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.Parent = scroll

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 4)
    pad.Parent = scroll

    -- ── GAME PASSES ──────────────────────────────────────────────────────────

    sectionHdr(scroll, "🎟  GAME PASSES", Color3.fromRGB(255, 200, 80))

    local passInfo = {
        {
            name  = "Double Income",
            desc  = "Permanently 2× all credit income",
            price = GameConfig.GAMEPASSES_ROBUX.DOUBLE_INCOME,
            id    = GameConfig.GAMEPASSES.DOUBLE_INCOME,
        },
        {
            name  = "Extra Slots",
            desc  = "+2 permanent gem slots in your core",
            price = GameConfig.GAMEPASSES_ROBUX.EXTRA_SLOTS,
            id    = GameConfig.GAMEPASSES.EXTRA_SLOTS,
        },
        {
            name  = "VIP",
            desc  = "1.5× income + exclusive effects",
            price = GameConfig.GAMEPASSES_ROBUX.VIP,
            id    = GameConfig.GAMEPASSES.VIP,
        },
    }

    for _, info in ipairs(passInfo) do
        local row, btn = makeRow(scroll, 70)
        lbl(row, info.name,
            UDim2.new(0.6, -16, 0.45, 0), UDim2.new(0, 10, 0, 4),
            Color3.fromRGB(255, 230, 100), Enum.Font.GothamBold)
        lbl(row, info.desc,
            UDim2.new(0.6, -16, 0.38, 0), UDim2.new(0, 10, 0.48, 0),
            Color3.fromRGB(180, 180, 220))

        btn.BackgroundColor3 = Color3.fromRGB(180, 120, 10)
        btn.Text = "R$" .. info.price
        local capId = info.id
        btn.MouseButton1Click:Connect(function()
            MarketplaceService:PromptGamePassPurchase(player, capId)
        end)
    end

    -- ── BUY GEMS (💎 with Robux) ──────────────────────────────────────────────

    sectionHdr(scroll, "💎  BUY GEMS", Color3.fromRGB(160, 110, 255))

    for _, pack in ipairs(GameConfig.GEM_PACKS) do
        local row, btn = makeRow(scroll, 70)
        lbl(row, "💎 " .. fmt(pack.amount) .. " Gems",
            UDim2.new(0.6, -16, 0.45, 0), UDim2.new(0, 10, 0, 4),
            Color3.fromRGB(210, 170, 255), Enum.Font.GothamBold)
        lbl(row, pack.bonus or "Premium currency",
            UDim2.new(0.6, -16, 0.38, 0), UDim2.new(0, 10, 0.48, 0),
            Color3.fromRGB(170, 160, 210))

        btn.BackgroundColor3 = Color3.fromRGB(110, 60, 170)
        btn.Text = "R$" .. pack.robux
        local capProductId = GameConfig.PRODUCTS[pack.productKey]
        btn.MouseButton1Click:Connect(function()
            MarketplaceService:PromptProductPurchase(player, capProductId)
        end)
    end

    -- ── PREMIUM BOOSTS ───────────────────────────────────────────────────────

    sectionHdr(scroll, "⚡  PREMIUM BOOSTS", Color3.fromRGB(180, 100, 255))

    -- Keep references so we can re-tint affordability after gemCurr updates
    local boostBtns = {}

    local function canAffordBoost(cost) return gemCurr >= cost end

    local function updateBoostAffordability()
        for _, entry in ipairs(boostBtns) do
            local affordable = canAffordBoost(entry.cost)
            entry.btn.BackgroundColor3 = affordable
                and Color3.fromRGB(80, 30, 130)
                or  Color3.fromRGB(50, 50, 70)
            entry.btn.Text = "💎 " .. entry.cost
        end
    end

    for _, item in ipairs(GameConfig.PREMIUM_ITEMS) do
        local row, btn = makeRow(scroll, 72)

        lbl(row, item.icon .. "  " .. item.name,
            UDim2.new(0.6, -16, 0.44, 0), UDim2.new(0, 10, 0, 4),
            Color3.fromRGB(220, 170, 255), Enum.Font.GothamBold)
        lbl(row, item.description,
            UDim2.new(0.6, -16, 0.38, 0), UDim2.new(0, 10, 0.46, 0),
            Color3.fromRGB(160, 160, 210))

        btn.BackgroundColor3 = canAffordBoost(item.gemCost)
            and Color3.fromRGB(80, 30, 130)
            or  Color3.fromRGB(50, 50, 70)
        btn.Text = "💎 " .. item.gemCost

        local capKey  = item.key
        local capCost = item.gemCost
        btn.MouseButton1Click:Connect(function()
            if not canAffordBoost(capCost) then return end
            local ok, result = RF_ref.BuyPremiumBoost:InvokeServer(capKey)
            if ok then
                gemCurr = result.gemCurrency
                gemCurrLabel.Text = "💎 " .. fmt(gemCurr)
                updateBoostAffordability()
            end
        end)

        table.insert(boostBtns, { btn = btn, cost = item.gemCost })
    end

    -- ── 💱 CONVERT ───────────────────────────────────────────────────────────

    sectionHdr(scroll, "💱  CONVERT  💎 → 💰", Color3.fromRGB(80, 220, 180))

    -- Rate display
    local rateRow = Instance.new("Frame")
    rateRow.Size = UDim2.new(1, 0, 0, 32)
    rateRow.BackgroundTransparency = 1
    rateRow.BorderSizePixel = 0
    rateRow.Parent = scroll
    lbl(rateRow, "Rate:  1 💎  =  " .. fmt(GameConfig.GEM_TO_CREDITS_RATE) .. " 💰",
        UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0),
        Color3.fromRGB(100, 220, 180), Enum.Font.GothamBold, Enum.TextXAlignment.Center)

    -- Amount input row
    local inputRow = Instance.new("Frame")
    inputRow.Size = UDim2.new(1, 0, 0, 52)
    inputRow.BackgroundTransparency = 1
    inputRow.BorderSizePixel = 0
    inputRow.Parent = scroll

    local amtBox = Instance.new("TextBox")
    amtBox.Size = UDim2.new(0, 160, 0, 40)
    amtBox.Position = UDim2.new(0.5, -170, 0.5, 0)
    amtBox.AnchorPoint = Vector2.new(0, 0.5)
    amtBox.BackgroundColor3 = Color3.fromRGB(20, 20, 50)
    amtBox.BorderSizePixel = 0
    amtBox.PlaceholderText = "Amount (💎)"
    amtBox.Text = ""
    amtBox.TextColor3 = Color3.fromRGB(220, 220, 255)
    amtBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 140)
    amtBox.Font = Enum.Font.GothamBold
    amtBox.TextScaled = true
    amtBox.ClearTextOnFocus = false
    amtBox.Parent = inputRow
    corner(amtBox, 6)

    local convertBtn = Instance.new("TextButton")
    convertBtn.Size = UDim2.new(0, 110, 0, 40)
    convertBtn.Position = UDim2.new(0.5, -4, 0.5, 0)
    convertBtn.AnchorPoint = Vector2.new(0, 0.5)
    convertBtn.BackgroundColor3 = Color3.fromRGB(20, 120, 100)
    convertBtn.BorderSizePixel = 0
    convertBtn.Text = "Convert"
    convertBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    convertBtn.Font = Enum.Font.GothamBold
    convertBtn.TextScaled = true
    convertBtn.Parent = inputRow
    corner(convertBtn, 6)

    local convertMsg = lbl(scroll, "",
        UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 0, 0),
        Color3.fromRGB(120, 220, 180), Enum.Font.Gotham, Enum.TextXAlignment.Center)
    convertMsg.Size = UDim2.new(1, 0, 0, 24)

    convertBtn.MouseButton1Click:Connect(function()
        local amount = math.floor(tonumber(amtBox.Text) or 0)
        if amount <= 0 then
            convertMsg.Text = "Enter a valid amount."
            convertMsg.TextColor3 = Color3.fromRGB(255, 100, 100)
            return
        end
        local ok, result = RF_ref.ConvertGems:InvokeServer(amount)
        if ok then
            gemCurr = result.gemCurrency
            gemCurrLabel.Text = "💎 " .. fmt(gemCurr)
            updateBoostAffordability()
            amtBox.Text = ""
            convertMsg.Text = "Converted! You received 💰 " .. fmt(amount * GameConfig.GEM_TO_CREDITS_RATE)
            convertMsg.TextColor3 = Color3.fromRGB(100, 220, 150)
        else
            convertMsg.Text = tostring(result)
            convertMsg.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end)

    -- ── Panel toggle ─────────────────────────────────────────────────────────

    shopPanel = panel
    Panels.Register("Shop", function()
        shopOpen = false
        panel.Visible = false
    end)
    toggleBtn.MouseButton1Click:Connect(function()
        ShopUI.Toggle()
    end)
end

function ShopUI.Toggle()
    if not shopPanel then return end
    shopOpen = not shopOpen
    shopPanel.Visible = shopOpen
    if shopOpen then Panels.CloseOthers("Shop") end
end

function ShopUI.Open()
    if not shopPanel then return end
    if not shopOpen then ShopUI.Toggle() end
end

function ShopUI.UpdateGemCurrency(amount)
    if amount == nil then return end
    gemCurr = amount
    if gemCurrLabel then
        gemCurrLabel.Text = "💎 " .. math.floor(amount)
    end
end

return ShopUI
