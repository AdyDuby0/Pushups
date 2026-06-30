-- NPC Gem Exchange UI: sell-only, with live stock-chart prices.
-- Prices drop as the server registers sells and recover over time; this panel
-- shows the current price, a trend arrow, a sparkline of recent history, and
-- Sell 1 / Sell All buttons per gem type.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GemTypes          = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("GemTypes"))
local Panels            = require(script.Parent:WaitForChild("Panels"))

local GemMarketUI = {}
local RF_ref
local myGems      = {}
local marketData  = {}   -- gemType -> { price, base, floor, history }
local prevPrices  = {}   -- gemType -> last seen price (for trend arrows)
local listFrame
local statusLbl
local exchangePanel
local exchangeOpen = false

-- Gem types ordered by rarity (common first)
local gemOrder = {}
do
    for gemType, gd in pairs(GemTypes) do
        table.insert(gemOrder, { t = gemType, tier = gd.rarityTier or 0 })
    end
    table.sort(gemOrder, function(a, b) return a.tier < b.tier end)
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

local function corner(inst, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 6); c.Parent = inst
end

local function lbl(parent, props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Font = Enum.Font.Gotham
    l.TextScaled = true
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextColor3 = Color3.fromRGB(220, 220, 235)
    for k, v in pairs(props) do l[k] = v end
    l.Parent = parent
    return l
end

-- Build a sparkline of recent prices into `container`
local function buildSpark(container, entry, gemColor)
    for _, c in ipairs(container:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    local hist = entry.history or {}
    local len  = #hist
    if len == 0 then return end
    local span = math.max(entry.base - entry.floor, 1)
    for i, price in ipairs(hist) do
        local norm = math.clamp((price - entry.floor) / span, 0.03, 1)
        local bar = Instance.new("Frame")
        bar.AnchorPoint = Vector2.new(0, 1)
        bar.Position = UDim2.new((i - 1) / len, 0, 1, 0)
        bar.Size = UDim2.new(1 / len - 0.004, 0, norm, 0)
        bar.BorderSizePixel = 0
        bar.BackgroundColor3 = gemColor
        bar.BackgroundTransparency = (i == len) and 0 or 0.45
        bar.Parent = container
    end
end

local function makeRow(gemType, entry)
    local gd = GemTypes[gemType]
    local held = myGems[gemType] or 0

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -4, 0, 86)
    row.BackgroundColor3 = Color3.fromRGB(16, 16, 32)
    row.BackgroundTransparency = 0.2
    row.BorderSizePixel = 0
    row.Parent = listFrame
    corner(row, 6)

    local stripe = Instance.new("Frame")
    stripe.Size = UDim2.new(0, 5, 1, 0)
    stripe.BackgroundColor3 = gd.color
    stripe.BorderSizePixel = 0
    stripe.Parent = row
    corner(stripe, 4)

    -- Name + holdings (left)
    lbl(row, {
        Text = gd.displayName, Font = Enum.Font.GothamBold,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Size = UDim2.new(0.5, -12, 0, 22), Position = UDim2.new(0, 12, 0, 4),
    })
    lbl(row, {
        Text = "You have ×" .. held,
        TextColor3 = held > 0 and Color3.fromRGB(255, 235, 160) or Color3.fromRGB(140, 140, 160),
        Size = UDim2.new(0.5, -12, 0, 18), Position = UDim2.new(0, 12, 0, 28),
    })

    -- Price + trend (right)
    local prev   = prevPrices[gemType]
    local trend  = "—"
    local trendC = Color3.fromRGB(170, 170, 190)
    if prev then
        if entry.price > prev + 0.5 then trend = "▲"; trendC = Color3.fromRGB(90, 230, 120)
        elseif entry.price < prev - 0.5 then trend = "▼"; trendC = Color3.fromRGB(255, 100, 100) end
    end
    lbl(row, {
        Text = "💰 " .. fmt(entry.price) .. " ea",
        Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(255, 220, 90),
        TextXAlignment = Enum.TextXAlignment.Right,
        Size = UDim2.new(0.46, -32, 0, 22), Position = UDim2.new(0.5, 0, 0, 4),
    })
    lbl(row, {
        Text = trend, Font = Enum.Font.GothamBold, TextColor3 = trendC,
        TextXAlignment = Enum.TextXAlignment.Center,
        Size = UDim2.new(0, 28, 0, 22), Position = UDim2.new(1, -30, 0, 4),
    })

    -- Sparkline (right, below price)
    local spark = Instance.new("Frame")
    spark.Size = UDim2.new(0.46, -8, 0, 30)
    spark.Position = UDim2.new(0.5, 0, 0, 30)
    spark.BackgroundColor3 = Color3.fromRGB(10, 10, 22)
    spark.BackgroundTransparency = 0.3
    spark.BorderSizePixel = 0
    spark.ClipsDescendants = true
    spark.Parent = row
    corner(spark, 4)
    buildSpark(spark, entry, gd.color)

    -- Sell buttons (left, bottom)
    local function sellBtn(text, xPos, w, color, qtyFn)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(w, -4, 0, 26)
        btn.Position = UDim2.new(xPos, 6, 1, -30)
        btn.BackgroundColor3 = held > 0 and color or Color3.fromRGB(55, 55, 72)
        btn.BorderSizePixel = 0
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextScaled = true
        btn.Parent = row
        corner(btn, 4)
        if held > 0 then
            btn.MouseButton1Click:Connect(function()
                local q = qtyFn()
                if q < 1 then return end
                local ok, result = RF_ref.SellToNPC:InvokeServer(gemType, q)
                if ok and type(result) == "table" then
                    if statusLbl then
                        statusLbl.Text = "Sold " .. result.qty .. " " .. gd.displayName
                            .. " for 💰 " .. fmt(result.payout)
                        statusLbl.TextColor3 = Color3.fromRGB(120, 230, 150)
                    end
                end
            end)
        end
        return btn
    end

    sellBtn("Sell 1",   0,    0.25, Color3.fromRGB(40, 130, 60),  function() return 1 end)
    sellBtn("Sell All", 0.26, 0.24, Color3.fromRGB(150, 90, 30),  function() return held end)
end

local function refresh()
    if not listFrame then return end
    for _, c in ipairs(listFrame:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    for _, g in ipairs(gemOrder) do
        local entry = marketData[g.t]
        if entry then makeRow(g.t, entry) end
    end
end

function GemMarketUI.Init(playerGui, initData, RF)
    RF_ref     = RF
    myGems     = initData.gems or {}
    marketData = initData.gemMarket or {}

    local gui = Instance.new("ScreenGui")
    gui.Name = "GemMarketUI"; gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = playerGui

    -- Toggle button (right of the Shop button)
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 130, 0, 38)
    toggleBtn.Position = UDim2.new(0, 560, 0, 64)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 30, 12)
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Text = "💹 Exchange"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 200, 120)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextScaled = true
    toggleBtn.Parent = gui
    corner(toggleBtn, 6)

    local panel = Instance.new("Frame")
    panel.Name = "ExchangePanel"
    panel.Size = UDim2.new(0, 440, 0, 560)
    panel.Position = UDim2.new(0, 8, 0, 110)
    panel.BackgroundColor3 = Color3.fromRGB(8, 8, 20)
    panel.BackgroundTransparency = 0.06
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Parent = gui
    corner(panel, 10)

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 42)
    header.BackgroundColor3 = Color3.fromRGB(48, 28, 10)
    header.BorderSizePixel = 0
    header.Parent = panel
    corner(header, 10)
    lbl(header, {
        Text = "💹  GEM EXCHANGE", Font = Enum.Font.GothamBold,
        TextColor3 = Color3.fromRGB(255, 200, 120),
        TextXAlignment = Enum.TextXAlignment.Center,
        Size = UDim2.new(1, 0, 1, 0),
    })

    lbl(panel, {
        Text = "Sell gems for credits — prices fall as you sell, recover over time.",
        TextColor3 = Color3.fromRGB(170, 170, 195),
        TextXAlignment = Enum.TextXAlignment.Center,
        Size = UDim2.new(1, -16, 0, 18), Position = UDim2.new(0, 8, 0, 46),
    })

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -8, 1, -100)
    scroll.Position = UDim2.new(0, 4, 0, 68)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = panel
    listFrame = scroll

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.Parent = listFrame

    statusLbl = lbl(panel, {
        Text = "", TextXAlignment = Enum.TextXAlignment.Center,
        Size = UDim2.new(1, -16, 0, 22), Position = UDim2.new(0, 8, 1, -28),
        TextColor3 = Color3.fromRGB(120, 230, 150),
    })

    exchangePanel = panel
    Panels.Register("GemMarket", function()
        exchangeOpen = false
        panel.Visible = false
    end)
    toggleBtn.MouseButton1Click:Connect(function()
        GemMarketUI.Toggle()
    end)

    refresh()
end

function GemMarketUI.Toggle()
    if not exchangePanel then return end
    exchangeOpen = not exchangeOpen
    exchangePanel.Visible = exchangeOpen
    if exchangeOpen then
        Panels.CloseOthers("GemMarket")
        refresh()
    end
end

function GemMarketUI.Open()
    if not exchangePanel then return end
    if not exchangeOpen then GemMarketUI.Toggle() end
end

function GemMarketUI.UpdatePrices(snap)
    -- remember the prices we're replacing so we can show trend arrows
    prevPrices = {}
    for gemType, entry in pairs(marketData) do
        prevPrices[gemType] = entry.price
    end
    marketData = snap or {}
    if exchangeOpen then refresh() end
end

function GemMarketUI.UpdateGems(gems)
    myGems = gems
    if exchangeOpen then refresh() end
end

return GemMarketUI
