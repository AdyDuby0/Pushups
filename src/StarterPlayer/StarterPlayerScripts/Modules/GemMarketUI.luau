-- NPC Gem Exchange UI (simulated stock market).
-- Top: a list of gems with their live price % and trend. Select one to see its
-- price chart below, along with the current per-unit price and sell buttons.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GemTypes          = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("GemTypes"))
local Panels            = require(script.Parent:WaitForChild("Panels"))
local Responsive        = require(script.Parent:WaitForChild("Responsive"))
local Effects           = require(script.Parent:WaitForChild("Effects"))
local Sounds            = require(script.Parent:WaitForChild("Sounds"))

local GemMarketUI = {}
local RF_ref
local myGems      = {}
local marketData  = {}   -- gemType -> { pct, lower, upper, base, unit, tradeValue, history }
local prevPct     = {}   -- gemType -> last pct (for trend arrows)
local selected            -- currently selected gemType
local listFrame, detailFrame, statusLbl
local exchangePanel
local exchangeOpen = false

local gemOrder = {}
do
    for gemType, gd in pairs(GemTypes) do
        table.insert(gemOrder, { t = gemType, tier = gd.rarityTier or 0 })
    end
    table.sort(gemOrder, function(a, b) return a.tier < b.tier end)
    selected = gemOrder[1] and gemOrder[1].t or "Crystite"
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
    l.BackgroundTransparency = 1; l.Font = Enum.Font.Gotham; l.TextScaled = true
    l.TextXAlignment = Enum.TextXAlignment.Left; l.TextColor3 = Color3.fromRGB(225, 225, 235)
    for k, v in pairs(props) do l[k] = v end
    l.Parent = parent
    return l
end

local function trendArrow(gemType, cur)
    local prev = prevPct[gemType]
    if prev then
        if cur > prev + 0.5 then return "▲", Color3.fromRGB(90, 230, 120)
        elseif cur < prev - 0.5 then return "▼", Color3.fromRGB(255, 100, 100) end
    end
    return "—", Color3.fromRGB(170, 170, 190)
end

local refresh   -- forward decl

-- draw the selected gem's chart into `container`
local function drawChart(container, entry, gemColor)
    for _, c in ipairs(container:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    local hist = entry.history or {}
    local len  = #hist
    local span = math.max(entry.upper - entry.lower, 1)

    -- baseline at 100%
    local baseNorm = math.clamp((entry.base - entry.lower) / span, 0, 1)
    local base = Instance.new("Frame")
    base.BackgroundColor3 = Color3.fromRGB(90, 90, 110); base.BackgroundTransparency = 0.4
    base.BorderSizePixel = 0; base.Size = UDim2.new(1, 0, 0, 1)
    base.Position = UDim2.new(0, 0, 1 - baseNorm, 0); base.Parent = container

    for i, v in ipairs(hist) do
        local norm = math.clamp((v - entry.lower) / span, 0.02, 1)
        local bar = Instance.new("Frame")
        bar.AnchorPoint = Vector2.new(0, 1)
        bar.Position = UDim2.new((i - 1) / len, 0, 1, 0)
        bar.Size = UDim2.new(1 / len - 0.004, 0, norm, 0)
        bar.BorderSizePixel = 0
        bar.BackgroundColor3 = gemColor
        bar.BackgroundTransparency = (i == len) and 0 or 0.5
        bar.Parent = container
    end
end

function refresh()
    if not listFrame then return end
    for _, c in ipairs(listFrame:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end

    -- ── gem list ──────────────────────────────────────────────────────────────
    for _, g in ipairs(gemOrder) do
        local entry = marketData[g.t]
        if entry then
            local gd = GemTypes[g.t]
            local isSel = (g.t == selected)
            local row = Instance.new("TextButton")
            row.Size = UDim2.new(1, -4, 0, 32)
            row.BackgroundColor3 = isSel and Color3.fromRGB(48, 34, 12) or Color3.fromRGB(18, 18, 34)
            row.BackgroundTransparency = 0.15; row.BorderSizePixel = 0
            row.Text = ""; row.AutoButtonColor = not isSel; row.Parent = listFrame
            corner(row, 5)

            local stripe = Instance.new("Frame")
            stripe.Size = UDim2.new(0, 4, 1, 0); stripe.BorderSizePixel = 0
            stripe.BackgroundColor3 = gd.color; stripe.Parent = row

            lbl(row, {
                Text = (isSel and "▶ " or "") .. gd.displayName, Font = Enum.Font.GothamBold,
                TextColor3 = isSel and Color3.fromRGB(255, 220, 150) or Color3.fromRGB(230, 230, 245),
                Size = UDim2.new(0.5, -10, 1, 0), Position = UDim2.new(0, 12, 0, 0),
            })
            local arrow, aColor = trendArrow(g.t, entry.pct)
            lbl(row, {
                Text = entry.pct .. "%  " .. arrow, Font = Enum.Font.GothamBold, TextColor3 = aColor,
                TextXAlignment = Enum.TextXAlignment.Right,
                Size = UDim2.new(0.28, 0, 1, 0), Position = UDim2.new(0.5, 0, 0, 0),
            })
            lbl(row, {
                Text = "💰" .. fmt(entry.unit), TextColor3 = Color3.fromRGB(255, 220, 90),
                TextXAlignment = Enum.TextXAlignment.Right,
                Size = UDim2.new(0.22, -8, 1, 0), Position = UDim2.new(0.78, 0, 0, 0),
            })

            local capT = g.t
            row.MouseButton1Click:Connect(function() selected = capT; refresh() end)
        end
    end

    -- ── detail for the selected gem ───────────────────────────────────────────
    for _, c in ipairs(detailFrame:GetChildren()) do
        if not c:IsA("UICorner") then c:Destroy() end
    end
    local entry = marketData[selected]
    local gd = GemTypes[selected]
    if not entry or not gd then return end

    lbl(detailFrame, {
        Text = gd.displayName, Font = Enum.Font.GothamBold, TextColor3 = gd.color,
        Size = UDim2.new(0.6, -8, 0, 24), Position = UDim2.new(0, 10, 0, 6),
    })
    local arrow, aColor = trendArrow(selected, entry.pct)
    lbl(detailFrame, {
        Text = entry.pct .. "% " .. arrow .. "   (50–" .. entry.upper .. "%)",
        Font = Enum.Font.GothamBold, TextColor3 = aColor, TextXAlignment = Enum.TextXAlignment.Right,
        Size = UDim2.new(0.4, -10, 0, 24), Position = UDim2.new(0.6, 0, 0, 6),
    })

    local chart = Instance.new("Frame")
    chart.Size = UDim2.new(1, -20, 0, 168); chart.Position = UDim2.new(0, 10, 0, 34)
    chart.BackgroundColor3 = Color3.fromRGB(10, 10, 20); chart.BackgroundTransparency = 0.25
    chart.BorderSizePixel = 0; chart.ClipsDescendants = true; chart.Parent = detailFrame
    corner(chart, 6)
    drawChart(chart, entry, gd.color)

    local held = myGems[selected] or 0
    lbl(detailFrame, {
        Text = "💰 " .. fmt(entry.unit) .. " each        You have ×" .. held,
        TextColor3 = Color3.fromRGB(230, 230, 245), TextXAlignment = Enum.TextXAlignment.Center,
        Size = UDim2.new(1, -20, 0, 24), Position = UDim2.new(0, 10, 0, 210),
    })

    local function sellBtn(text, xScale, color, qtyFn)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0.49, -10, 0, 42); b.Position = UDim2.new(xScale, xScale == 0 and 10 or 0, 0, 242)
        b.BackgroundColor3 = held > 0 and color or Color3.fromRGB(55, 55, 72); b.BorderSizePixel = 0
        b.Text = text; b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.Font = Enum.Font.GothamBold; b.TextScaled = true; b.Parent = detailFrame
        corner(b, 6)
        if held > 0 then
            b.MouseButton1Click:Connect(function()
                local q = qtyFn()
                if q < 1 then return end
                local ok, result = RF_ref.SellToNPC:InvokeServer(selected, q)
                if ok and type(result) == "table" then
                    if statusLbl then
                        statusLbl.Text = "Sold " .. result.qty .. " " .. gd.displayName .. " for 💰 " .. fmt(result.payout)
                        statusLbl.TextColor3 = Color3.fromRGB(120, 230, 150)
                    end
                    Effects.Popup("+💰 " .. fmt(result.payout), Color3.fromRGB(255, 220, 90))
                    Sounds.Play("sell", 0.5)
                end
            end)
        end
        return b
    end
    sellBtn("Sell 1", 0, Color3.fromRGB(40, 130, 60), function() return 1 end)
    sellBtn("Sell All", 0.51, Color3.fromRGB(150, 90, 30), function() return held end)
end

function GemMarketUI.Init(playerGui, initData, RF)
    RF_ref     = RF
    myGems     = initData.gems or {}
    marketData = initData.gemMarket or {}

    local gui = Instance.new("ScreenGui")
    gui.Name = "GemMarketUI"; gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = playerGui

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 130, 0, 38); toggleBtn.Position = UDim2.new(0, 560, 0, 64)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 30, 12); toggleBtn.BorderSizePixel = 0
    toggleBtn.Text = "💹 Exchange"; toggleBtn.TextColor3 = Color3.fromRGB(255, 200, 120)
    toggleBtn.Font = Enum.Font.GothamBold; toggleBtn.TextScaled = true
    toggleBtn.Visible = false  -- physical-only: opened from the center Exchange NPC
    toggleBtn.Parent = gui
    corner(toggleBtn, 6)

    local panel = Instance.new("Frame")
    panel.Name = "ExchangePanel"
    panel.Size = UDim2.new(0, 520, 0, 640)
    panel.Position = UDim2.new(0.5, 0, 0.5, 0); panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.BackgroundColor3 = Color3.fromRGB(8, 8, 20); panel.BackgroundTransparency = 0.06
    panel.BorderSizePixel = 0; panel.Visible = false; panel.Parent = gui
    corner(panel, 10)
    Responsive.Fit(panel, 520, 640)

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 42); header.BorderSizePixel = 0
    header.BackgroundColor3 = Color3.fromRGB(48, 28, 10); header.Parent = panel
    corner(header, 10)
    lbl(header, {
        Text = "💹  GEM EXCHANGE", Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(255, 200, 120),
        TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 1, 0),
    })
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 34, 0, 34); closeBtn.Position = UDim2.new(1, -38, 0, 4)
    closeBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 40); closeBtn.BorderSizePixel = 0
    closeBtn.Text = "✕"; closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextScaled = true; closeBtn.Parent = header
    corner(closeBtn, 6)
    closeBtn.MouseButton1Click:Connect(function() exchangeOpen = false; panel.Visible = false end)

    lbl(panel, {
        Text = "Select a gem to view its market chart, then sell.",
        TextColor3 = Color3.fromRGB(170, 170, 195), TextXAlignment = Enum.TextXAlignment.Center,
        Size = UDim2.new(1, -16, 0, 16), Position = UDim2.new(0, 8, 0, 46),
    })

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -8, 0, 174); scroll.Position = UDim2.new(0, 4, 0, 66)
    scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4; scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; scroll.Parent = panel
    listFrame = scroll
    local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0, 4); layout.Parent = scroll

    local sellAllBtn = Instance.new("TextButton")
    sellAllBtn.Size = UDim2.new(1, -8, 0, 30); sellAllBtn.Position = UDim2.new(0, 4, 0, 244)
    sellAllBtn.BackgroundColor3 = Color3.fromRGB(150, 100, 30); sellAllBtn.BorderSizePixel = 0
    sellAllBtn.Text = "💰 Sell Everything (best prices)"; sellAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    sellAllBtn.Font = Enum.Font.GothamBold; sellAllBtn.TextScaled = true; sellAllBtn.Parent = panel
    corner(sellAllBtn, 6)
    sellAllBtn.MouseButton1Click:Connect(function()
        local ok, result = RF_ref.SellAllGems:InvokeServer()
        if ok and type(result) == "table" then
            if statusLbl then
                statusLbl.Text = "Sold everything for 💰 " .. fmt(result.payout)
                statusLbl.TextColor3 = Color3.fromRGB(120, 230, 150)
            end
            Effects.Popup("+💰 " .. fmt(result.payout), Color3.fromRGB(255, 220, 90))
            Effects.Flash(Color3.fromRGB(255, 210, 90), 0.25)
            Sounds.Play("sell", 0.6)
        end
    end)

    detailFrame = Instance.new("Frame")
    detailFrame.Size = UDim2.new(1, -8, 1, -300); detailFrame.Position = UDim2.new(0, 4, 0, 274)
    detailFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 24); detailFrame.BackgroundTransparency = 0.3
    detailFrame.BorderSizePixel = 0; detailFrame.Parent = panel
    corner(detailFrame, 8)

    statusLbl = lbl(panel, {
        Text = "", TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = Color3.fromRGB(120, 230, 150),
        Size = UDim2.new(1, -16, 0, 18), Position = UDim2.new(0, 8, 1, -22),
    })

    exchangePanel = panel
    Panels.Register("GemMarket", function() exchangeOpen = false; panel.Visible = false end)
    toggleBtn.MouseButton1Click:Connect(function() GemMarketUI.Toggle() end)
    refresh()
end

function GemMarketUI.Toggle()
    if not exchangePanel then return end
    exchangeOpen = not exchangeOpen
    exchangePanel.Visible = exchangeOpen
    if exchangeOpen then Panels.CloseOthers("GemMarket"); refresh() end
end

function GemMarketUI.Open()
    if not exchangePanel then return end
    if not exchangeOpen then GemMarketUI.Toggle() end
end

function GemMarketUI.UpdatePrices(snap)
    prevPct = {}
    for gt, entry in pairs(marketData) do prevPct[gt] = entry.pct end
    marketData = snap or {}
    if exchangeOpen then refresh() end
end

function GemMarketUI.UpdateGems(gems)
    myGems = gems
    if exchangeOpen then refresh() end
end

return GemMarketUI
