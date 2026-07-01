-- Admin (dev) menu. Only created for admins (place owner / Studio / ADMIN_IDS).
-- Lets you set your own credits, premium currency and gems. Temporary dev tool.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GemTypes = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("GemTypes"))
local Panels   = require(script.Parent:WaitForChild("Panels"))
local Responsive = require(script.Parent:WaitForChild("Responsive"))

local AdminUI = {}
local RF_ref
local adminPanel
local adminOpen = false
local gemPick   -- currently selected gem type for the gem setter

local gemOrder = {}
do
    for gt, gd in pairs(GemTypes) do
        table.insert(gemOrder, { t = gt, tier = gd.rarityTier or 0 })
    end
    table.sort(gemOrder, function(a, b) return a.tier < b.tier end)
    gemPick = gemOrder[1] and gemOrder[1].t or "Crystite"
end

local function corner(inst, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 6); c.Parent = inst
end

local function label(parent, text, pos, size, color, align)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Position = pos; l.Size = size
    l.Text = text; l.TextColor3 = color or Color3.fromRGB(225, 225, 235)
    l.Font = Enum.Font.GothamBold; l.TextScaled = true
    l.TextXAlignment = align or Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

local function box(parent, pos, size, placeholder)
    local b = Instance.new("TextBox")
    b.Position = pos; b.Size = size
    b.BackgroundColor3 = Color3.fromRGB(20, 20, 44); b.BorderSizePixel = 0
    b.PlaceholderText = placeholder; b.Text = ""
    b.TextColor3 = Color3.fromRGB(230, 230, 245); b.PlaceholderColor3 = Color3.fromRGB(110, 110, 140)
    b.Font = Enum.Font.GothamBold; b.TextScaled = true; b.ClearTextOnFocus = false
    b.Parent = parent
    corner(b, 5)
    return b
end

local function button(parent, text, pos, size, color, fn)
    local btn = Instance.new("TextButton")
    btn.Position = pos; btn.Size = size
    btn.BackgroundColor3 = color; btn.BorderSizePixel = 0
    btn.Text = text; btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold; btn.TextScaled = true; btn.Parent = parent
    corner(btn, 5)
    btn.MouseButton1Click:Connect(fn)
    return btn
end

function AdminUI.Init(playerGui, initData, RF)
    RF_ref = RF

    local gui = Instance.new("ScreenGui")
    gui.Name = "AdminUI"; gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = playerGui

    -- toggle button (top-left)
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 120, 0, 34)
    toggleBtn.Position = UDim2.new(0, 8, 0, 144)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(110, 30, 30)
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Text = "🛠 Admin"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 220, 220)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextScaled = true
    toggleBtn.Parent = gui
    corner(toggleBtn, 6)

    -- centered panel
    local panel = Instance.new("Frame")
    panel.Name = "AdminPanel"
    panel.Size = UDim2.new(0, 440, 0, 440)
    panel.Position = UDim2.new(0.5, 0, 0.5, 0)
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.BackgroundColor3 = Color3.fromRGB(14, 10, 16)
    panel.BackgroundTransparency = 0.05
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Parent = gui
    corner(panel, 10)
    Responsive.Fit(panel, 440, 440)

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 42); header.BorderSizePixel = 0
    header.BackgroundColor3 = Color3.fromRGB(90, 25, 25); header.Parent = panel
    corner(header, 10)
    label(header, "🛠  ADMIN — CLAIM", UDim2.new(0, 12, 0, 0), UDim2.new(1, -56, 1, 0),
        Color3.fromRGB(255, 210, 210))

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 34, 0, 34); closeBtn.Position = UDim2.new(1, -38, 0, 4)
    closeBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50); closeBtn.BorderSizePixel = 0
    closeBtn.Text = "✕"; closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextScaled = true; closeBtn.Parent = header
    corner(closeBtn, 6)
    closeBtn.MouseButton1Click:Connect(function() adminOpen = false; panel.Visible = false end)

    local statusLbl = label(panel, "", UDim2.new(0, 12, 1, -28), UDim2.new(1, -24, 0, 22),
        Color3.fromRGB(140, 230, 160), Enum.TextXAlignment.Center)

    local function admin(action, a, b)
        local ok, result = RF_ref.AdminAction:InvokeServer(action, a, b)
        if ok then
            statusLbl.Text = "✓ Done"
            statusLbl.TextColor3 = Color3.fromRGB(140, 230, 160)
        else
            statusLbl.Text = "✗ " .. tostring(result)
            statusLbl.TextColor3 = Color3.fromRGB(255, 120, 120)
        end
    end

    -- ── Credits row ──────────────────────────────────────────────────────────
    label(panel, "💰 Credits", UDim2.new(0, 12, 0, 54), UDim2.new(0, 120, 0, 22),
        Color3.fromRGB(255, 220, 90))
    local creditBox = box(panel, UDim2.new(0, 12, 0, 78), UDim2.new(0, 200, 0, 36), "amount")
    button(panel, "Set", UDim2.new(0, 222, 0, 78), UDim2.new(0, 90, 0, 36), Color3.fromRGB(40, 110, 60),
        function() admin("setCredits", creditBox.Text) end)
    button(panel, "+1B", UDim2.new(0, 320, 0, 78), UDim2.new(0, 100, 0, 36), Color3.fromRGB(40, 80, 140),
        function() admin("addCredits", 1e9) end)

    -- ── Premium currency row ─────────────────────────────────────────────────
    label(panel, "💎 Premium", UDim2.new(0, 12, 0, 124), UDim2.new(0, 120, 0, 22),
        Color3.fromRGB(200, 150, 255))
    local gemCurrBox = box(panel, UDim2.new(0, 12, 0, 148), UDim2.new(0, 200, 0, 36), "amount")
    button(panel, "Set", UDim2.new(0, 222, 0, 148), UDim2.new(0, 90, 0, 36), Color3.fromRGB(40, 110, 60),
        function() admin("setGemCurrency", gemCurrBox.Text) end)
    button(panel, "+1000", UDim2.new(0, 320, 0, 148), UDim2.new(0, 100, 0, 36), Color3.fromRGB(80, 50, 140),
        function() admin("addGemCurrency", 1000) end)

    -- ── Gems row ─────────────────────────────────────────────────────────────
    label(panel, "🔷 Gems", UDim2.new(0, 12, 0, 194), UDim2.new(0, 120, 0, 22),
        Color3.fromRGB(120, 210, 255))
    local gemBtn = button(panel, GemTypes[gemPick].displayName, UDim2.new(0, 12, 0, 218),
        UDim2.new(0, 200, 0, 36), Color3.fromRGB(40, 60, 110), function() end)
    -- cycle the gem type
    gemBtn.MouseButton1Click:Connect(function()
        local idx = 1
        for i, g in ipairs(gemOrder) do if g.t == gemPick then idx = i break end end
        idx = (idx % #gemOrder) + 1
        gemPick = gemOrder[idx].t
        gemBtn.Text = GemTypes[gemPick].displayName
    end)
    local gemAmtBox = box(panel, UDim2.new(0, 222, 0, 218), UDim2.new(0, 90, 0, 36), "qty")
    button(panel, "Set", UDim2.new(0, 320, 0, 218), UDim2.new(0, 100, 0, 36), Color3.fromRGB(40, 110, 60),
        function() admin("setGem", gemPick, gemAmtBox.Text) end)

    -- ── Quick claims ─────────────────────────────────────────────────────────
    button(panel, "Max All Gems", UDim2.new(0, 12, 0, 270), UDim2.new(0, 200, 0, 40),
        Color3.fromRGB(60, 120, 90), function() admin("maxGems") end)
    button(panel, "Max Drill Depth", UDim2.new(0, 222, 0, 270), UDim2.new(0, 198, 0, 40),
        Color3.fromRGB(120, 90, 40), function() admin("maxDrill") end)

    label(panel, "Dev tool — restricted to admins. Will be removed later.",
        UDim2.new(0, 12, 0, 322), UDim2.new(1, -24, 0, 20),
        Color3.fromRGB(150, 150, 170), Enum.TextXAlignment.Center)

    adminPanel = panel
    Panels.Register("Admin", function() adminOpen = false; panel.Visible = false end)
    toggleBtn.MouseButton1Click:Connect(function() AdminUI.Toggle() end)
end

function AdminUI.Toggle()
    if not adminPanel then return end
    adminOpen = not adminOpen
    adminPanel.Visible = adminOpen
    if adminOpen then Panels.CloseOthers("Admin") end
end

return AdminUI
