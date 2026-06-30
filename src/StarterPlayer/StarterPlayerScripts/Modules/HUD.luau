local TweenService  = game:GetService("TweenService")
local Players       = game:GetService("Players")
local PotionTypes   = require(game.ReplicatedStorage:WaitForChild("Config"):WaitForChild("PotionTypes"))
local GameConfig    = require(game.ReplicatedStorage:WaitForChild("Config"):WaitForChild("GameConfig"))

-- Premium 💎 boosts live in activePotions too but aren't in PotionTypes;
-- build a lookup so the active-bar can render them like potions.
local PREMIUM_BY_KEY = {}
for _, item in ipairs(GameConfig.PREMIUM_ITEMS) do
    PREMIUM_BY_KEY[item.key] = {
        icon        = item.icon,
        displayName = item.name,
        color       = Color3.fromRGB(150, 90, 230),
    }
end

local HUD = {}
local creditsLabel, incomeLabel, gemCurrLabel, notifLabel, potionBar

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
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = inst
end

local function makeLabel(parent, props)
    local l = Instance.new("TextLabel")
    for k, v in pairs(props) do l[k] = v end
    l.Parent = parent; return l
end

local function makeFrame(parent, props)
    local f = Instance.new("Frame")
    for k, v in pairs(props) do f[k] = v end
    f.Parent = parent; return f
end

function HUD.Init(playerGui, initData, hooks)
    hooks = hooks or {}
    local gui = Instance.new("ScreenGui")
    gui.Name = "HUD"; gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = playerGui

    local BOX_W = 236

    -- ── Credits box (💰) — bottom-right ──────────────────────────────────────
    local creditBox = makeFrame(gui, {
        Size = UDim2.new(0, BOX_W, 0, 52),
        Position = UDim2.new(1, -8, 1, -48), AnchorPoint = Vector2.new(1, 1),
        BackgroundColor3 = Color3.fromRGB(18, 18, 36), BackgroundTransparency = 0.1, BorderSizePixel = 0,
    })
    corner(creditBox, 6)

    makeLabel(creditBox, {
        Size = UDim2.new(0, 28, 1, 0), Position = UDim2.new(0, 6, 0, 0),
        BackgroundTransparency = 1, Text = "💰", TextScaled = true,
    })
    creditsLabel = makeLabel(creditBox, {
        Name = "CreditsLabel",
        Size = UDim2.new(1, -40, 0.58, 0), Position = UDim2.new(0, 36, 0, 2),
        BackgroundTransparency = 1, Text = fmt(initData.credits),
        TextColor3 = Color3.fromRGB(255, 220, 50), Font = Enum.Font.GothamBold,
        TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left,
    })
    incomeLabel = makeLabel(creditBox, {
        Name = "IncomeLabel",
        Size = UDim2.new(1, -40, 0.38, 0), Position = UDim2.new(0, 36, 0.58, 0),
        BackgroundTransparency = 1, Text = "+" .. fmt(initData.incomeRate) .. "/s",
        TextColor3 = Color3.fromRGB(80, 255, 80), Font = Enum.Font.Gotham,
        TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left,
    })

    -- ── Premium currency box (💎) — above credits ────────────────────────────
    local gemBox = makeFrame(gui, {
        Size = UDim2.new(0, BOX_W, 0, 42),
        Position = UDim2.new(1, -8, 1, -106), AnchorPoint = Vector2.new(1, 1),
        BackgroundColor3 = Color3.fromRGB(20, 10, 40), BackgroundTransparency = 0.1, BorderSizePixel = 0,
    })
    corner(gemBox, 6)
    makeLabel(gemBox, {
        Size = UDim2.new(0, 28, 1, 0), Position = UDim2.new(0, 6, 0, 0),
        BackgroundTransparency = 1, Text = "💎", TextScaled = true,
    })
    gemCurrLabel = makeLabel(gemBox, {
        Name = "GemCurrLabel",
        Size = UDim2.new(1, -38, 1, 0), Position = UDim2.new(0, 36, 0, 0),
        BackgroundTransparency = 1, Text = fmt(initData.gemCurrency or 0),
        TextColor3 = Color3.fromRGB(200, 150, 255), Font = Enum.Font.GothamBold,
        TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left,
    })

    -- ── Teleport buttons — above the money ───────────────────────────────────
    local tpRow = makeFrame(gui, {
        Size = UDim2.new(0, BOX_W, 0, 40),
        Position = UDim2.new(1, -8, 1, -154), AnchorPoint = Vector2.new(1, 1),
        BackgroundTransparency = 1, BorderSizePixel = 0,
    })
    local function tpButton(text, xScale, color, fn)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0.49, 0, 1, 0); b.Position = UDim2.new(xScale, 0, 0, 0)
        b.BackgroundColor3 = color; b.BorderSizePixel = 0
        b.Text = text; b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.Font = Enum.Font.GothamBold; b.TextScaled = true; b.Parent = tpRow
        corner(b, 6)
        b.MouseButton1Click:Connect(function() if fn then fn() end end)
        return b
    end
    tpButton("🏠 My Plot", 0,    Color3.fromRGB(35, 70, 120), hooks.teleportPlot)
    tpButton("🛒 Shop",    0.51, Color3.fromRGB(90, 50, 130), hooks.teleportCenter)

    -- description above the teleport buttons
    makeLabel(gui, {
        Size = UDim2.new(0, BOX_W, 0, 18),
        Position = UDim2.new(1, -8, 1, -198), AnchorPoint = Vector2.new(1, 1),
        BackgroundTransparency = 1, Text = "TELEPORT TO",
        TextColor3 = Color3.fromRGB(170, 170, 200), Font = Enum.Font.GothamBold,
        TextScaled = true, TextXAlignment = Enum.TextXAlignment.Right,
    })

    -- (Rankings now use the classic Roblox player list via leaderstats.)

    -- ── Notification (center, just below top bar) ─────────────────────────
    notifLabel = makeLabel(gui, {
        Size = UDim2.new(0, 440, 0, 44),
        Position = UDim2.new(0.5, -220, 0, 64),
        BackgroundColor3 = Color3.fromRGB(18, 18, 40),
        BackgroundTransparency = 0.1, BorderSizePixel = 0,
        Text = "", TextColor3 = Color3.fromRGB(200, 200, 255),
        Font = Enum.Font.Gotham, TextScaled = true,
        Visible = false, ZIndex = 20,
    })
    corner(notifLabel, 8)

    -- ── Active potions bar (center-bottom, always visible) ───────────────
    -- Place above the very bottom so it's never behind side-panel buttons.
    potionBar = makeFrame(gui, {
        Name = "PotionBar",
        Size = UDim2.new(0, 0, 0, 40),
        Position = UDim2.new(0.5, 0, 1, -56),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1, BorderSizePixel = 0,
    })
    local potionLayout = Instance.new("UIListLayout")
    potionLayout.FillDirection = Enum.FillDirection.Horizontal
    potionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    potionLayout.Padding = UDim.new(0, 6)
    potionLayout.Parent = potionBar

    if initData.activePotions then
        HUD.UpdatePotions(initData.activePotions)
    end
end

function HUD.Update(hudData)
    if hudData.credits     and creditsLabel  then creditsLabel.Text  = fmt(hudData.credits) end
    if hudData.incomeRate  and incomeLabel   then incomeLabel.Text   = "+" .. fmt(hudData.incomeRate) .. "/s" end
    if hudData.gemCurrency and gemCurrLabel  then gemCurrLabel.Text  = fmt(hudData.gemCurrency) end
end

function HUD.UpdatePotions(activePotions)
    if not potionBar then return end
    for _, c in ipairs(potionBar:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

    for potionType, secondsLeft in pairs(activePotions) do
        local pd = PotionTypes[potionType] or PREMIUM_BY_KEY[potionType]
        if not pd then continue end

        local pill = Instance.new("Frame")
        pill.Size = UDim2.new(0, 144, 1, 0)
        pill.BackgroundColor3 = pd.color
        pill.BackgroundTransparency = 0.2
        pill.BorderSizePixel = 0
        pill.Parent = potionBar
        corner(pill, 8)

        local lbl = makeLabel(pill, {
            Size = UDim2.new(1, -6, 1, 0), Position = UDim2.new(0, 3, 0, 0),
            BackgroundTransparency = 1,
            Text = pd.icon .. " " .. pd.displayName,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Font = Enum.Font.GothamBold, TextScaled = true,
        })

        -- Countdown ticker below the name
        local timeLbl = makeLabel(pill, {
            Size = UDim2.new(1, 0, 0.42, 0), Position = UDim2.new(0, 0, 0.58, 0),
            BackgroundTransparency = 1,
            Text = math.ceil(secondsLeft) .. "s",
            TextColor3 = Color3.fromRGB(255, 255, 200),
            Font = Enum.Font.Gotham, TextScaled = true,
        })
        lbl.Size = UDim2.new(1, -6, 0.55, 0)

        local remaining = secondsLeft
        task.spawn(function()
            while remaining > 0 do
                task.wait(1)
                remaining -= 1
                if timeLbl and timeLbl.Parent then
                    local mins = math.floor(remaining / 60)
                    timeLbl.Text = mins > 0
                        and (mins .. "m " .. (remaining % 60) .. "s")
                        or  (math.ceil(remaining) .. "s")
                    if remaining <= 0 then pill:Destroy() end
                end
            end
        end)
    end
end

function HUD.ShowNotification(msg)
    if not notifLabel then return end
    notifLabel.Text = msg
    notifLabel.Visible = true
    task.delay(3.5, function()
        if notifLabel then notifLabel.Visible = false end
    end)
end

function HUD.ShowFloatingText(text, color)
    local character = Players.LocalPlayer.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 140, 0, 38)
    bb.StudsOffset = Vector3.new(0, 4, 0)
    bb.AlwaysOnTop = true
    bb.Adornee = hrp
    bb.Parent = workspace

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = color or Color3.fromRGB(80, 255, 80)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextScaled = true
    lbl.TextStrokeTransparency = 0.3
    lbl.Parent = bb

    TweenService:Create(bb, TweenInfo.new(1.5), { StudsOffset = Vector3.new(0, 9, 0) }):Play()
    task.delay(1.5, function() bb:Destroy() end)
end

return HUD
