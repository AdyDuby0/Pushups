local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local GemTypes          = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("GemTypes"))
local Panels            = require(script.Parent:WaitForChild("Panels"))

local MarketUI = {}
local RF_ref
local myGems    = {}
local listings  = {}
local listingsFrame
local selectedGem
local marketPanel
local marketOpen = false

-- Filter state for the listings view
local filterGem  = nil        -- nil = show all gem types
local priceSort  = "none"     -- "none" | "asc" | "desc"
local filterBtn, sortBtn      -- buttons whose labels reflect current filter

-- Ordered list of gem types (rarest last) used to cycle the type filter
local gemOrder = {}
do
    for gemType, gd in pairs(GemTypes) do
        table.insert(gemOrder, { t = gemType, tier = gd.rarityTier or 0 })
    end
    table.sort(gemOrder, function(a, b) return a.tier < b.tier end)
end

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
    return c
end

local function refreshListings()
    if not listingsFrame then return end
    for _, c in ipairs(listingsFrame:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

    local localId = Players.LocalPlayer.UserId

    -- Apply gem-type filter, then optional price sort, to a working copy
    local view = {}
    for _, l in ipairs(listings) do
        if not filterGem or l.gemType == filterGem then
            table.insert(view, l)
        end
    end
    if priceSort == "asc" then
        table.sort(view, function(a, b) return a.priceEach < b.priceEach end)
    elseif priceSort == "desc" then
        table.sort(view, function(a, b) return a.priceEach > b.priceEach end)
    end

    if #view == 0 then
        local empty = Instance.new("Frame")
        empty.Size             = UDim2.new(1, -4, 0, 44)
        empty.BackgroundTransparency = 1
        empty.BorderSizePixel  = 0
        empty.Parent           = listingsFrame
        local lbl = Instance.new("TextLabel")
        lbl.Size                 = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text                 = filterGem and "No listings for that gem." or "No active listings."
        lbl.TextColor3           = Color3.fromRGB(130, 130, 160)
        lbl.Font                 = Enum.Font.Gotham
        lbl.TextScaled           = true
        lbl.Parent               = empty
    end

    for _, l in ipairs(view) do
        local gd = GemTypes[l.gemType]
        if not gd then continue end

        local row = Instance.new("Frame")
        row.Size             = UDim2.new(1, -4, 0, 54)
        row.BackgroundColor3 = Color3.fromRGB(18, 18, 38)
        row.BackgroundTransparency = 0.3
        row.BorderSizePixel  = 0
        row.Parent           = listingsFrame
        corner(row, 6)

        -- Color stripe
        local stripe = Instance.new("Frame")
        stripe.Size             = UDim2.new(0, 5, 1, 0)
        stripe.BackgroundColor3 = gd.color
        stripe.BorderSizePixel  = 0
        stripe.Parent           = row
        corner(stripe, 4)

        local gemLbl = Instance.new("TextLabel")
        gemLbl.Size                 = UDim2.new(0.38, -12, 0.55, 0)
        gemLbl.Position             = UDim2.new(0, 12, 0, 2)
        gemLbl.BackgroundTransparency = 1
        gemLbl.Text                 = gd.displayName
        gemLbl.TextColor3           = Color3.fromRGB(220, 220, 255)
        gemLbl.Font                 = Enum.Font.GothamBold
        gemLbl.TextScaled           = true
        gemLbl.TextXAlignment       = Enum.TextXAlignment.Left
        gemLbl.Parent               = row

        local sellerLbl = Instance.new("TextLabel")
        sellerLbl.Size                 = UDim2.new(0.38, -12, 0.42, 0)
        sellerLbl.Position             = UDim2.new(0, 12, 0.55, 0)
        sellerLbl.BackgroundTransparency = 1
        sellerLbl.Text                 = l.sellerName .. "  ×" .. l.quantity
        sellerLbl.TextColor3           = Color3.fromRGB(140, 140, 170)
        sellerLbl.Font                 = Enum.Font.Gotham
        sellerLbl.TextScaled           = true
        sellerLbl.TextXAlignment       = Enum.TextXAlignment.Left
        sellerLbl.Parent               = row

        local priceLbl = Instance.new("TextLabel")
        priceLbl.Size                 = UDim2.new(0.26, 0, 1, 0)
        priceLbl.Position             = UDim2.new(0.38, 0, 0, 0)
        priceLbl.BackgroundTransparency = 1
        priceLbl.Text                 = fmt(l.priceEach) .. "/ea"
        priceLbl.TextColor3           = Color3.fromRGB(255, 220, 50)
        priceLbl.Font                 = Enum.Font.GothamBold
        priceLbl.TextScaled           = true
        priceLbl.Parent               = row

        local actionBtn = Instance.new("TextButton")
        actionBtn.Size             = UDim2.new(0.32, -6, 0.7, 0)
        actionBtn.Position         = UDim2.new(0.68, 3, 0.15, 0)
        actionBtn.BorderSizePixel  = 0
        actionBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
        actionBtn.Font             = Enum.Font.Gotham
        actionBtn.TextScaled       = true
        actionBtn.Parent           = row
        corner(actionBtn, 4)

        if l.sellerUserId == localId then
            actionBtn.BackgroundColor3 = Color3.fromRGB(170, 45, 45)
            actionBtn.Text             = "Cancel"
            local captId = l.id
            actionBtn.MouseButton1Click:Connect(function()
                RF_ref.CancelListing:InvokeServer(captId)
            end)
        else
            actionBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 40)
            actionBtn.Text             = "Buy 1"
            local captId = l.id
            actionBtn.MouseButton1Click:Connect(function()
                RF_ref.BuyListing:InvokeServer(captId, 1)
            end)
        end
    end
end

function MarketUI.Init(playerGui, initData, RF)
    RF_ref   = RF
    myGems   = initData.gems or {}
    listings = initData.listings or {}

    local gui = Instance.new("ScreenGui")
    gui.Name           = "MarketUI"
    gui.ResetOnSpawn   = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent         = playerGui

    -- Toggle button
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size            = UDim2.new(0, 130, 0, 38)
    toggleBtn.Position        = UDim2.new(0, 146, 0, 64)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(10, 55, 10)
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Text            = "💱 Market"
    toggleBtn.TextColor3      = Color3.fromRGB(130, 255, 130)
    toggleBtn.Font            = Enum.Font.GothamBold
    toggleBtn.TextScaled      = true
    toggleBtn.Parent          = gui
    corner(toggleBtn, 6)

    -- Panel
    local panel = Instance.new("Frame")
    panel.Name            = "MarketPanel"
    panel.Size            = UDim2.new(0, 420, 0, 560)
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
    header.BackgroundColor3 = Color3.fromRGB(10, 50, 10)
    header.BorderSizePixel = 0
    header.Parent          = panel
    corner(header, 10)

    local title = Instance.new("TextLabel")
    title.Size                 = UDim2.new(1, 0, 1, 0)
    title.BackgroundTransparency = 1
    title.Text                 = "💱  GEM MARKET"
    title.TextColor3           = Color3.fromRGB(130, 255, 130)
    title.Font                 = Enum.Font.GothamBold
    title.TextScaled           = true
    title.Parent               = header

    -- Sell panel
    local sellPanel = Instance.new("Frame")
    sellPanel.Size            = UDim2.new(1, -8, 0, 152)
    sellPanel.Position        = UDim2.new(0, 4, 0, 46)
    sellPanel.BackgroundColor3 = Color3.fromRGB(14, 14, 28)
    sellPanel.BackgroundTransparency = 0.2
    sellPanel.BorderSizePixel = 0
    sellPanel.Parent          = panel
    corner(sellPanel, 8)

    local sellTitle = Instance.new("TextLabel")
    sellTitle.Size                 = UDim2.new(1, 0, 0, 26)
    sellTitle.BackgroundTransparency = 1
    sellTitle.Text                 = "LIST A GEM FOR SALE"
    sellTitle.TextColor3           = Color3.fromRGB(170, 170, 220)
    sellTitle.Font                 = Enum.Font.GothamBold
    sellTitle.TextScaled           = true
    sellTitle.Parent               = sellPanel

    -- Gem selector button
    local gemPickBtn = Instance.new("TextButton")
    gemPickBtn.Size            = UDim2.new(0.44, -4, 0, 32)
    gemPickBtn.Position        = UDim2.new(0, 4, 0, 28)
    gemPickBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 58)
    gemPickBtn.BorderSizePixel = 0
    gemPickBtn.Text            = "Pick Gem ▾"
    gemPickBtn.TextColor3      = Color3.fromRGB(200, 200, 255)
    gemPickBtn.Font            = Enum.Font.Gotham
    gemPickBtn.TextScaled      = true
    gemPickBtn.Parent          = sellPanel
    corner(gemPickBtn, 4)

    local qtyBox = Instance.new("TextBox")
    qtyBox.Size            = UDim2.new(0.24, -4, 0, 32)
    qtyBox.Position        = UDim2.new(0.44, 2, 0, 28)
    qtyBox.BackgroundColor3 = Color3.fromRGB(28, 28, 58)
    qtyBox.BorderSizePixel = 0
    qtyBox.Text            = "1"
    qtyBox.PlaceholderText = "Qty"
    qtyBox.TextColor3      = Color3.fromRGB(255, 255, 255)
    qtyBox.Font            = Enum.Font.Gotham
    qtyBox.TextScaled      = true
    qtyBox.Parent          = sellPanel
    corner(qtyBox, 4)

    local priceBox = Instance.new("TextBox")
    priceBox.Size            = UDim2.new(0.32, -4, 0, 32)
    priceBox.Position        = UDim2.new(0.68, 2, 0, 28)
    priceBox.BackgroundColor3 = Color3.fromRGB(28, 28, 58)
    priceBox.BorderSizePixel = 0
    priceBox.Text            = ""
    priceBox.PlaceholderText = "Price each"
    priceBox.TextColor3      = Color3.fromRGB(255, 255, 255)
    priceBox.Font            = Enum.Font.Gotham
    priceBox.TextScaled      = true
    priceBox.Parent          = sellPanel
    corner(priceBox, 4)

    -- Cycle through owned gems on click
    gemPickBtn.MouseButton1Click:Connect(function()
        local available = {}
        for gt, cnt in pairs(myGems) do
            if cnt > 0 then table.insert(available, gt) end
        end
        if #available == 0 then return end
        table.sort(available)
        local idx = 1
        for i, g in ipairs(available) do
            if g == selectedGem then idx = i; break end
        end
        idx = (idx % #available) + 1
        selectedGem = available[idx]
        local gd = GemTypes[selectedGem]
        gemPickBtn.Text = gd and gd.displayName or selectedGem
    end)

    local listBtn = Instance.new("TextButton")
    listBtn.Size            = UDim2.new(1, -8, 0, 36)
    listBtn.Position        = UDim2.new(0, 4, 0, 66)
    listBtn.BackgroundColor3 = Color3.fromRGB(70, 45, 190)
    listBtn.BorderSizePixel = 0
    listBtn.Text            = "List for Sale"
    listBtn.TextColor3      = Color3.fromRGB(255, 255, 255)
    listBtn.Font            = Enum.Font.GothamBold
    listBtn.TextScaled      = true
    listBtn.Parent          = sellPanel
    corner(listBtn, 6)

    listBtn.MouseButton1Click:Connect(function()
        if not selectedGem then return end
        local qty   = tonumber(qtyBox.Text)   or 0
        local price = tonumber(priceBox.Text) or 0
        if qty < 1 or price < 1 then return end

        local ok = RF.CreateListing:InvokeServer(selectedGem, qty, price)
        if ok then
            qtyBox.Text   = "1"
            priceBox.Text = ""
            selectedGem   = nil
            gemPickBtn.Text = "Pick Gem ▾"
        end
    end)

    -- Info text
    local infoLbl = Instance.new("TextLabel")
    infoLbl.Size                 = UDim2.new(1, -8, 0, 18)
    infoLbl.Position             = UDim2.new(0, 4, 0, 108)
    infoLbl.BackgroundTransparency = 1
    infoLbl.Text                 = "5% market fee on all sales"
    infoLbl.TextColor3           = Color3.fromRGB(120, 120, 150)
    infoLbl.Font                 = Enum.Font.Gotham
    infoLbl.TextScaled           = true
    infoLbl.Parent               = sellPanel

    -- Listings label
    local listLbl = Instance.new("TextLabel")
    listLbl.Size                 = UDim2.new(1, -8, 0, 20)
    listLbl.Position             = UDim2.new(0, 4, 0, 202)
    listLbl.BackgroundTransparency = 1
    listLbl.Text                 = "ACTIVE LISTINGS"
    listLbl.TextColor3           = Color3.fromRGB(160, 160, 160)
    listLbl.Font                 = Enum.Font.GothamBold
    listLbl.TextScaled           = true
    listLbl.TextXAlignment       = Enum.TextXAlignment.Left
    listLbl.Parent               = panel

    -- ── Filter bar: gem-type filter + price sort ─────────────────────────────
    local function gemDisplay(gemType)
        local gd = GemTypes[gemType]
        return gd and gd.displayName or gemType
    end

    filterBtn = Instance.new("TextButton")
    filterBtn.Size            = UDim2.new(0.58, -2, 0, 30)
    filterBtn.Position        = UDim2.new(0, 4, 0, 224)
    filterBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 58)
    filterBtn.BorderSizePixel = 0
    filterBtn.Text            = "Filter: All ▾"
    filterBtn.TextColor3      = Color3.fromRGB(200, 220, 255)
    filterBtn.Font            = Enum.Font.Gotham
    filterBtn.TextScaled      = true
    filterBtn.Parent          = panel
    corner(filterBtn, 5)

    sortBtn = Instance.new("TextButton")
    sortBtn.Size            = UDim2.new(0.42, -6, 0, 30)
    sortBtn.Position        = UDim2.new(0.58, 2, 0, 224)
    sortBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 58)
    sortBtn.BorderSizePixel = 0
    sortBtn.Text            = "Price: —"
    sortBtn.TextColor3      = Color3.fromRGB(255, 220, 120)
    sortBtn.Font            = Enum.Font.Gotham
    sortBtn.TextScaled      = true
    sortBtn.Parent          = panel
    corner(sortBtn, 5)

    -- Cycle the gem-type filter: All → each gem (rarest last) → All
    filterBtn.MouseButton1Click:Connect(function()
        local idx = 0  -- 0 means "All"
        if filterGem then
            for i, g in ipairs(gemOrder) do
                if g.t == filterGem then idx = i; break end
            end
        end
        idx += 1
        if idx > #gemOrder then
            filterGem = nil
            filterBtn.Text = "Filter: All ▾"
        else
            filterGem = gemOrder[idx].t
            filterBtn.Text = "Filter: " .. gemDisplay(filterGem) .. " ▾"
        end
        refreshListings()
    end)

    -- Cycle price sort: none → low→high → high→low → none
    sortBtn.MouseButton1Click:Connect(function()
        if priceSort == "none" then
            priceSort = "asc";  sortBtn.Text = "Price: ↑"
        elseif priceSort == "asc" then
            priceSort = "desc"; sortBtn.Text = "Price: ↓"
        else
            priceSort = "none"; sortBtn.Text = "Price: —"
        end
        refreshListings()
    end)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size              = UDim2.new(1, -8, 1, -262)
    scroll.Position          = UDim2.new(0, 4, 0, 260)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel   = 0
    scroll.ScrollBarThickness = 4
    scroll.CanvasSize        = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent            = panel

    listingsFrame = scroll

    local layout = Instance.new("UIListLayout")
    layout.Padding   = UDim.new(0, 4)
    layout.Parent    = scroll

    refreshListings()

    marketPanel = panel
    Panels.Register("Market", function()
        marketOpen = false
        panel.Visible = false
    end)
    toggleBtn.MouseButton1Click:Connect(function()
        MarketUI.Toggle()
    end)
end

function MarketUI.Toggle()
    if not marketPanel then return end
    marketOpen = not marketOpen
    marketPanel.Visible = marketOpen
    if marketOpen then
        Panels.CloseOthers("Market")
        refreshListings()
    end
end

function MarketUI.Open()
    if not marketPanel then return end
    if not marketOpen then MarketUI.Toggle() end
end

function MarketUI.UpdateListings(newListings)
    listings = newListings
    refreshListings()
end

function MarketUI.UpdateGems(gems)
    myGems = gems
end

return MarketUI
