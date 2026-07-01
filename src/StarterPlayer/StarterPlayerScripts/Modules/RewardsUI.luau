-- ⚡ Core Charge (playtime bar, bottom-center) + 🌌 Cosmic Cache (daily streak).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GemTypes = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("GemTypes"))
local Panels     = require(script.Parent:WaitForChild("Panels"))
local Responsive = require(script.Parent:WaitForChild("Responsive"))
local Effects    = require(script.Parent:WaitForChild("Effects"))
local Sounds     = require(script.Parent:WaitForChild("Sounds"))

local RewardsUI = {}
local RF_ref

-- charge state (client-side countdown; server is authority on claim)
local chargeInterval = 300
local chargeReadyAt   = 0
local chargeBtn, chargeFill, chargeLbl

-- daily
local dailyPanel, dailyOpen, dailyBody

local function corner(inst, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 6); c.Parent = inst
end

local function fmt(n)
    n = math.floor(n)
    local a = math.abs(n)
    if a >= 1e12 then return string.format("%.1fT", n/1e12)
    elseif a >= 1e9 then return string.format("%.1fB", n/1e9)
    elseif a >= 1e6 then return string.format("%.1fM", n/1e6)
    elseif a >= 1e3 then return string.format("%.1fK", n/1e3)
    else return tostring(n) end
end

local function fmtTime(s)
    s = math.max(0, math.floor(s))
    if s >= 3600 then return string.format("%dh %dm", s//3600, (s%3600)//60) end
    return string.format("%dm %02ds", s//60, s%60)
end

local function rewardText(r)
    local parts = {}
    if r.credits then table.insert(parts, "💰" .. fmt(r.credits)) end
    if r.gemCurrency then table.insert(parts, "💎" .. r.gemCurrency) end
    if r.gems then
        for gt, n in pairs(r.gems) do
            local gd = GemTypes[gt]
            table.insert(parts, n .. "× " .. (gd and gd.displayName or gt))
        end
    end
    return table.concat(parts, "  ")
end

local function lbl(parent, props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1; l.Font = Enum.Font.Gotham; l.TextScaled = true
    l.TextXAlignment = Enum.TextXAlignment.Center; l.TextColor3 = Color3.fromRGB(230, 230, 245)
    for k, v in pairs(props) do l[k] = v end
    l.Parent = parent
    return l
end

-- ── Cosmic Cache (daily) ────────────────────────────────────────────────────
local function refreshDaily()
    local info = RF_ref.GetDailyInfo:InvokeServer() or {}
    for _, c in ipairs(dailyBody.cells:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    local rewards = info.rewards or {}
    for i, r in ipairs(rewards) do
        local isNext = (i == info.nextDay)
        local cell = Instance.new("Frame")
        cell.Size = UDim2.new(1 / #rewards, -4, 1, 0)
        cell.Position = UDim2.new((i - 1) / #rewards, 2, 0, 0)
        cell.BackgroundColor3 = isNext and Color3.fromRGB(60, 45, 90) or Color3.fromRGB(22, 20, 34)
        cell.BorderSizePixel = 0; cell.Parent = dailyBody.cells
        corner(cell, 6)
        lbl(cell, { Text = "Day " .. i, Font = Enum.Font.GothamBold,
            TextColor3 = isNext and Color3.fromRGB(255, 220, 150) or Color3.fromRGB(180, 180, 200),
            Size = UDim2.new(1, -4, 0, 18), Position = UDim2.new(0, 2, 0, 4) })
        lbl(cell, { Text = rewardText(r), TextColor3 = Color3.fromRGB(210, 210, 230), TextWrapped = true,
            TextScaled = false, TextSize = 12,
            Size = UDim2.new(1, -6, 1, -26), Position = UDim2.new(0, 3, 0, 22) })
        if i == 7 then
            local star = lbl(cell, { Text = "★", TextColor3 = Color3.fromRGB(255, 210, 90),
                Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(1, -18, 0, 2) })
            star.TextScaled = true
        end
    end

    dailyBody.streak.Text = "🔥 Streak: " .. (info.streak or 0) .. " days"
    if info.canClaim then
        dailyBody.claim.Text = "🌌 Claim Day " .. (info.nextDay or 1)
        dailyBody.claim.BackgroundColor3 = Color3.fromRGB(90, 60, 160)
        dailyBody.claim.AutoButtonColor = true
        dailyBody.canClaim = true
    else
        dailyBody.claim.Text = "Next cache in " .. fmtTime(info.nextIn or 0)
        dailyBody.claim.BackgroundColor3 = Color3.fromRGB(50, 45, 66)
        dailyBody.claim.AutoButtonColor = false
        dailyBody.canClaim = false
    end
end

-- ── Core Charge visuals ─────────────────────────────────────────────────────
local function updateCharge()
    if not chargeBtn then return end
    local remain = chargeReadyAt - os.clock()
    if remain <= 0 then
        chargeFill.Size = UDim2.new(1, 0, 1, 0)
        chargeFill.BackgroundColor3 = Color3.fromRGB(255, 200, 70)
        chargeLbl.Text = "⚡ CLAIM CORE SURGE!"
        chargeBtn.AutoButtonColor = true
    else
        local frac = math.clamp(1 - remain / chargeInterval, 0, 1)
        chargeFill.Size = UDim2.new(frac, 0, 1, 0)
        chargeFill.BackgroundColor3 = Color3.fromRGB(90, 130, 220)
        chargeLbl.Text = "⚡ Core charging…  " .. fmtTime(remain)
        chargeBtn.AutoButtonColor = false
    end
end

function RewardsUI.Init(playerGui, initData, RF)
    RF_ref = RF

    local gui = Instance.new("ScreenGui")
    gui.Name = "RewardsUI"; gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = playerGui

    -- ── Core Charge bar (bottom-center, above the potion bar) ─────────────────
    local ci = initData.charge or {}
    chargeInterval = ci.interval or 300
    chargeReadyAt  = os.clock() + (ci.ready and 0 or (ci.secondsLeft or chargeInterval))

    chargeBtn = Instance.new("TextButton")
    chargeBtn.Size = UDim2.new(0, 340, 0, 28)
    chargeBtn.Position = UDim2.new(0.5, 0, 1, -104); chargeBtn.AnchorPoint = Vector2.new(0.5, 1)
    chargeBtn.BackgroundColor3 = Color3.fromRGB(16, 16, 34); chargeBtn.BorderSizePixel = 0
    chargeBtn.Text = ""; chargeBtn.Parent = gui
    corner(chargeBtn, 8)
    chargeFill = Instance.new("Frame")
    chargeFill.Size = UDim2.new(0, 0, 1, 0); chargeFill.BorderSizePixel = 0
    chargeFill.BackgroundColor3 = Color3.fromRGB(90, 130, 220); chargeFill.Parent = chargeBtn
    corner(chargeFill, 8)
    chargeLbl = lbl(chargeBtn, { Text = "", Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(255, 255, 255),
        Size = UDim2.new(1, -10, 1, 0), Position = UDim2.new(0, 5, 0, 0), ZIndex = 2 })
    chargeLbl.ZIndex = 2

    chargeBtn.MouseButton1Click:Connect(function()
        if (chargeReadyAt - os.clock()) > 0 then return end
        local ok, result = RF_ref.ClaimCharge:InvokeServer()
        if ok and type(result) == "table" then
            chargeReadyAt = os.clock() + chargeInterval
            chargeLbl.Text = "⚡ +💰 " .. fmt(result.reward) .. "  (Core Surge!)"
            Effects.Popup("⚡ +💰 " .. fmt(result.reward), Color3.fromRGB(255, 210, 90))
            Effects.Flash(Color3.fromRGB(255, 210, 90), 0.3)
            Sounds.Play("claim", 0.6)
        end
    end)

    task.spawn(function()
        while true do updateCharge(); task.wait(0.3) end
    end)

    -- ── Daily button + panel ──────────────────────────────────────────────────
    local dailyToggle = Instance.new("TextButton")
    dailyToggle.Size = UDim2.new(0, 120, 0, 34); dailyToggle.Position = UDim2.new(0, 8, 0, 184)
    dailyToggle.BackgroundColor3 = Color3.fromRGB(30, 40, 80); dailyToggle.BorderSizePixel = 0
    dailyToggle.Text = "🌌 Daily"; dailyToggle.TextColor3 = Color3.fromRGB(180, 200, 255)
    dailyToggle.Font = Enum.Font.GothamBold; dailyToggle.TextScaled = true; dailyToggle.Parent = gui
    corner(dailyToggle, 6)

    local panel = Instance.new("Frame")
    panel.Name = "DailyPanel"
    panel.Size = UDim2.new(0, 500, 0, 320)
    panel.Position = UDim2.new(0.5, 0, 0.5, 0); panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.BackgroundColor3 = Color3.fromRGB(10, 10, 22); panel.BackgroundTransparency = 0.05
    panel.BorderSizePixel = 0; panel.Visible = false; panel.Parent = gui
    corner(panel, 10)
    Responsive.Fit(panel, 500, 320)

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 42); header.BorderSizePixel = 0
    header.BackgroundColor3 = Color3.fromRGB(30, 30, 70); header.Parent = panel
    corner(header, 10)
    lbl(header, { Text = "🌌  COSMIC CACHE", Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(180, 200, 255),
        Size = UDim2.new(1, -50, 1, 0), Position = UDim2.new(0, 12, 0, 0), TextXAlignment = Enum.TextXAlignment.Left })
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 34, 0, 34); closeBtn.Position = UDim2.new(1, -38, 0, 4)
    closeBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 40); closeBtn.BorderSizePixel = 0
    closeBtn.Text = "✕"; closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextScaled = true; closeBtn.Parent = header
    corner(closeBtn, 6)
    closeBtn.MouseButton1Click:Connect(function() dailyOpen = false; panel.Visible = false end)

    dailyBody = {}
    dailyBody.streak = lbl(panel, { Text = "", Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(255, 180, 90),
        Size = UDim2.new(1, -20, 0, 24), Position = UDim2.new(0, 10, 0, 50) })

    dailyBody.cells = Instance.new("Frame")
    dailyBody.cells.Size = UDim2.new(1, -20, 0, 150); dailyBody.cells.Position = UDim2.new(0, 10, 0, 80)
    dailyBody.cells.BackgroundTransparency = 1; dailyBody.cells.Parent = panel

    dailyBody.claim = Instance.new("TextButton")
    dailyBody.claim.Size = UDim2.new(1, -30, 0, 46); dailyBody.claim.Position = UDim2.new(0, 15, 1, -58)
    dailyBody.claim.BorderSizePixel = 0; dailyBody.claim.Text = ""
    dailyBody.claim.TextColor3 = Color3.fromRGB(255, 255, 255); dailyBody.claim.Font = Enum.Font.GothamBold
    dailyBody.claim.TextScaled = true; dailyBody.claim.Parent = panel
    corner(dailyBody.claim, 8)
    dailyBody.claim.MouseButton1Click:Connect(function()
        if not dailyBody.canClaim then return end
        local ok, result = RF_ref.ClaimDaily:InvokeServer()
        if ok then
            if type(result) == "table" and result.reward then
                Effects.Popup("🌌 " .. rewardText(result.reward), Color3.fromRGB(180, 200, 255))
                Effects.Flash(Color3.fromRGB(120, 140, 255), 0.3)
            end
            Sounds.Play("claim", 0.6)
            refreshDaily()
        end
    end)

    dailyPanel = panel
    Panels.Register("Daily", function() dailyOpen = false; panel.Visible = false end)
    dailyToggle.MouseButton1Click:Connect(function() RewardsUI.ToggleDaily() end)
end

function RewardsUI.ToggleDaily()
    if not dailyPanel then return end
    dailyOpen = not dailyOpen
    dailyPanel.Visible = dailyOpen
    if dailyOpen then Panels.CloseOthers("Daily"); refreshDaily() end
end

return RewardsUI
