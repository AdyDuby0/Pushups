-- Drill configuration menu (opened by clicking the plot drill).
-- Pick which gem the drill mines (from the tiers your depth has unlocked),
-- start/stop drilling, upgrade depth to reach rarer gems, and buy the
-- drill-speed upgrades (moved here from the Power Core).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GemTypes          = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("GemTypes"))
local Panels            = require(script.Parent:WaitForChild("Panels"))

local DrillUI = {}
local RF_ref
local myGems   = {}
local drill    = {}      -- { gemType, depth, maxDepth, unlocked, atMaxDepth, nextGem, depthCost, upgrades }
local credits  = 0
local listFrame, statusBar, statusLbl, startBtn
local drillPanel
local drillOpen = false

local mining       = false
local roundEnd     = 0   -- os.clock() time the current round finishes
local roundLen     = 1

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

local function fmtTime(s)
    s = math.max(0, math.floor(s))
    if s >= 3600 then return string.format("%dh %dm", s//3600, (s%3600)//60)
    elseif s >= 60 then return string.format("%dm %ds", s//60, s%60)
    else return s .. "s" end
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
    l.TextColor3 = Color3.fromRGB(225, 225, 235)
    for k, v in pairs(props) do l[k] = v end
    l.Parent = parent
    return l
end

local function sectionHdr(text, color)
    local hdr = Instance.new("Frame")
    hdr.Size = UDim2.new(1, 0, 0, 24)
    hdr.BackgroundColor3 = Color3.fromRGB(12, 12, 26)
    hdr.BackgroundTransparency = 0.25
    hdr.BorderSizePixel = 0
    hdr.Parent = listFrame
    corner(hdr, 4)
    lbl(hdr, {
        Text = text, Font = Enum.Font.GothamBold, TextColor3 = color or Color3.fromRGB(255, 210, 120),
        Size = UDim2.new(1, -10, 1, 0), Position = UDim2.new(0, 10, 0, 0),
    })
end

local refresh   -- forward decl

local function refetch()
    local info = RF_ref.GetDrillInfo:InvokeServer()
    if info then drill = info end
    refresh()
end

function refresh()
    if not listFrame then return end
    for _, c in ipairs(listFrame:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

    local selGd = GemTypes[drill.gemType]
    if statusLbl then
        local held = myGems[drill.gemType] or 0
        statusLbl.Text = (mining and "⛏ Drilling " or "Idle — set to ")
            .. (selGd and selGd.displayName or "?") .. "   (you have ×" .. held .. ")"
    end
    if startBtn then
        startBtn.Text = mining and "■ Stop Drilling" or "▶ Start Drilling"
        startBtn.BackgroundColor3 = mining and Color3.fromRGB(150, 50, 50) or Color3.fromRGB(40, 140, 70)
    end

    -- TARGET GEM
    sectionHdr("⛏ TARGET GEM", Color3.fromRGB(255, 210, 120))
    for _, u in ipairs(drill.unlocked or {}) do
        local gd = GemTypes[u.gemType]
        local selected = (u.gemType == drill.gemType)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 44)
        row.BackgroundColor3 = selected and Color3.fromRGB(40, 60, 30) or Color3.fromRGB(18, 18, 36)
        row.BackgroundTransparency = 0.2
        row.BorderSizePixel = 0
        row.Parent = listFrame
        corner(row, 5)

        local stripe = Instance.new("Frame")
        stripe.Size = UDim2.new(0, 5, 1, 0); stripe.BorderSizePixel = 0
        stripe.BackgroundColor3 = gd.color; stripe.Parent = row; corner(stripe, 4)

        lbl(row, {
            Text = (selected and "✔ " or "") .. gd.displayName,
            Font = Enum.Font.GothamBold,
            TextColor3 = selected and Color3.fromRGB(140, 255, 140) or Color3.fromRGB(230, 230, 245),
            Size = UDim2.new(0.55, -10, 0.55, 0), Position = UDim2.new(0, 12, 0, 3),
        })
        lbl(row, {
            Text = "base " .. fmtTime(u.mineTime) .. "  •  ×" .. (myGems[u.gemType] or 0),
            TextColor3 = Color3.fromRGB(170, 170, 195),
            Size = UDim2.new(0.55, -10, 0.4, 0), Position = UDim2.new(0, 12, 0.55, 0),
        })

        if not selected then
            local pick = Instance.new("TextButton")
            pick.Size = UDim2.new(0, 78, 0, 30); pick.Position = UDim2.new(1, -86, 0.5, -15)
            pick.BackgroundColor3 = Color3.fromRGB(50, 90, 160); pick.BorderSizePixel = 0
            pick.Text = "Select"; pick.TextColor3 = Color3.fromRGB(255, 255, 255)
            pick.Font = Enum.Font.GothamBold; pick.TextScaled = true; pick.Parent = row
            corner(pick, 4)
            local capGem = u.gemType
            pick.MouseButton1Click:Connect(function()
                local ok, result = RF_ref.SetDrillGem:InvokeServer(capGem)
                if ok then
                    drill.gemType = capGem
                    if type(result) == "table" and result.mining then
                        mining = true
                        roundLen = result.mineTime or roundLen
                        roundEnd = os.clock() + roundLen
                    end
                    refresh()
                end
            end)
        end
    end

    -- DEPTH
    sectionHdr("🛢 DRILL DEPTH", Color3.fromRGB(255, 180, 90))
    local depthRow = Instance.new("Frame")
    depthRow.Size = UDim2.new(1, 0, 0, 50)
    depthRow.BackgroundColor3 = Color3.fromRGB(18, 18, 36); depthRow.BackgroundTransparency = 0.2
    depthRow.BorderSizePixel = 0; depthRow.Parent = listFrame; corner(depthRow, 5)
    lbl(depthRow, {
        Text = "Depth " .. (drill.depth or 1) .. " / " .. (drill.maxDepth or 6),
        Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(255, 200, 120),
        Size = UDim2.new(0.55, -10, 0.55, 0), Position = UDim2.new(0, 12, 0, 3),
    })
    lbl(depthRow, {
        Text = drill.atMaxDepth and "Deepest layer reached" or ("Next: " .. (drill.nextGem or "?")),
        TextColor3 = Color3.fromRGB(170, 170, 195),
        Size = UDim2.new(0.55, -10, 0.4, 0), Position = UDim2.new(0, 12, 0.55, 0),
    })
    if not drill.atMaxDepth then
        local dig = Instance.new("TextButton")
        dig.Size = UDim2.new(0, 120, 0, 34); dig.Position = UDim2.new(1, -128, 0.5, -17)
        dig.BackgroundColor3 = (credits >= (drill.depthCost or 0)) and Color3.fromRGB(150, 100, 30) or Color3.fromRGB(60, 60, 78)
        dig.BorderSizePixel = 0; dig.Text = "Dig ▾ " .. fmt(drill.depthCost or 0)
        dig.TextColor3 = Color3.fromRGB(255, 255, 255); dig.Font = Enum.Font.GothamBold
        dig.TextScaled = true; dig.Parent = depthRow; corner(dig, 4)
        dig.MouseButton1Click:Connect(function()
            local ok = RF_ref.UpgradeDrillDepth:InvokeServer()
            if ok then refetch() end
        end)
    end

    -- DRILL SPEED upgrades
    sectionHdr("⚙ DRILL SPEED", Color3.fromRGB(120, 200, 255))
    for _, up in ipairs(drill.upgrades or {}) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 48)
        row.BackgroundColor3 = Color3.fromRGB(16, 22, 44); row.BackgroundTransparency = 0.2
        row.BorderSizePixel = 0; row.Parent = listFrame; corner(row, 5)
        lbl(row, {
            Text = up.icon .. " " .. up.name .. "  Lv." .. up.level .. (up.maxLevel and ("/" .. up.maxLevel) or ""),
            Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(150, 215, 255),
            Size = UDim2.new(0.58, -8, 0.55, 0), Position = UDim2.new(0, 10, 0, 2),
        })
        lbl(row, {
            Text = string.format("-%d%% mine time/lvl  •  now -%d%%",
                math.floor(up.reductionPerLevel * 100 + 0.5),
                math.floor(up.level * up.reductionPerLevel * 100 + 0.5)),
            TextColor3 = Color3.fromRGB(120, 200, 255),
            Size = UDim2.new(0.58, -8, 0.42, 0), Position = UDim2.new(0, 10, 0.55, 0),
        })
        local buy = Instance.new("TextButton")
        buy.Size = UDim2.new(0.4, -10, 0.75, 0); buy.Position = UDim2.new(0.6, 0, 0.12, 0)
        buy.BorderSizePixel = 0; buy.TextColor3 = Color3.fromRGB(255, 255, 255)
        buy.Font = Enum.Font.GothamBold; buy.TextScaled = true; buy.Parent = row; corner(buy, 4)
        if up.atMax then
            buy.Text = "MAX"; buy.BackgroundColor3 = Color3.fromRGB(80, 60, 130); buy.AutoButtonColor = false
        else
            buy.Text = fmt(up.nextCost) .. " CR"
            buy.BackgroundColor3 = (credits >= up.nextCost) and Color3.fromRGB(40, 110, 150) or Color3.fromRGB(55, 55, 75)
            local capKey = up.key
            buy.MouseButton1Click:Connect(function()
                local ok = RF_ref.BuyCoreUpgrade:InvokeServer(capKey)
                if ok then refetch() end
            end)
        end
    end
end

function DrillUI.Init(playerGui, initData, RF)
    RF_ref  = RF
    myGems  = initData.gems or {}
    drill   = initData.drill or {}
    credits = initData.credits or 0

    local gui = Instance.new("ScreenGui")
    gui.Name = "DrillUI"; gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = playerGui

    local panel = Instance.new("Frame")
    panel.Name = "DrillPanel"
    panel.Size = UDim2.new(0, 500, 0, 640)
    panel.Position = UDim2.new(0.5, 0, 0.5, 0)
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.BackgroundColor3 = Color3.fromRGB(8, 8, 20)
    panel.BackgroundTransparency = 0.06
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Parent = gui
    corner(panel, 10)

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 42); header.BorderSizePixel = 0
    header.BackgroundColor3 = Color3.fromRGB(50, 34, 10); header.Parent = panel
    corner(header, 10)
    lbl(header, {
        Text = "⛏  DRILL", Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(255, 200, 120),
        TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 1, 0),
    })

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 34, 0, 34); closeBtn.Position = UDim2.new(1, -38, 0, 4)
    closeBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 40); closeBtn.BorderSizePixel = 0
    closeBtn.Text = "✕"; closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextScaled = true; closeBtn.Parent = header
    corner(closeBtn, 6)
    closeBtn.MouseButton1Click:Connect(function() drillOpen = false; panel.Visible = false end)

    statusLbl = lbl(panel, {
        Text = "", TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = Color3.fromRGB(255, 225, 160),
        Size = UDim2.new(1, -16, 0, 20), Position = UDim2.new(0, 8, 0, 46),
    })

    -- Progress bar for the current round
    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(1, -16, 0, 14); barBg.Position = UDim2.new(0, 8, 0, 68)
    barBg.BackgroundColor3 = Color3.fromRGB(20, 20, 40); barBg.BorderSizePixel = 0
    barBg.Parent = panel; corner(barBg, 6)
    statusBar = Instance.new("Frame")
    statusBar.Size = UDim2.new(0, 0, 1, 0); statusBar.BorderSizePixel = 0
    statusBar.BackgroundColor3 = Color3.fromRGB(255, 190, 80); statusBar.Parent = barBg
    corner(statusBar, 6)
    local barLbl = Instance.new("TextLabel")
    barLbl.Name = "BarLbl"; barLbl.Size = UDim2.new(1, 0, 1, 0); barLbl.BackgroundTransparency = 1
    barLbl.Text = ""; barLbl.Font = Enum.Font.GothamBold; barLbl.TextScaled = true
    barLbl.TextColor3 = Color3.fromRGB(255, 255, 255); barLbl.Parent = barBg

    startBtn = Instance.new("TextButton")
    startBtn.Size = UDim2.new(1, -16, 0, 38); startBtn.Position = UDim2.new(0, 8, 0, 88)
    startBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 70); startBtn.BorderSizePixel = 0
    startBtn.Text = "▶ Start Drilling"; startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    startBtn.Font = Enum.Font.GothamBold; startBtn.TextScaled = true; startBtn.Parent = panel
    corner(startBtn, 6)
    startBtn.MouseButton1Click:Connect(function()
        if mining then
            RF_ref.StopDrill:InvokeServer()
            mining = false
            refresh()
        else
            local ok, mineTime = RF_ref.StartDrill:InvokeServer()
            if ok then
                mining = true
                roundLen = mineTime or 1
                roundEnd = os.clock() + roundLen
                refresh()
            end
        end
    end)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -8, 1, -138); scroll.Position = UDim2.new(0, 4, 0, 132)
    scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4; scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; scroll.Parent = panel
    listFrame = scroll
    local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0, 5); layout.Parent = scroll

    drillPanel = panel
    Panels.Register("Drill", function()
        drillOpen = false
        panel.Visible = false
    end)

    -- Countdown updater
    task.spawn(function()
        while true do
            task.wait(0.2)
            if mining and barBg then
                local remain = roundEnd - os.clock()
                local frac = roundLen > 0 and math.clamp(1 - remain / roundLen, 0, 1) or 0
                statusBar.Size = UDim2.new(frac, 0, 1, 0)
                barLbl.Text = fmtTime(remain) .. " left"
            elseif barBg then
                statusBar.Size = UDim2.new(0, 0, 1, 0)
                barLbl.Text = ""
            end
        end
    end)

    refresh()
end

function DrillUI.Toggle()
    if not drillPanel then return end
    drillOpen = not drillOpen
    drillPanel.Visible = drillOpen
    if drillOpen then
        Panels.CloseOthers("Drill")
        refetch()
    end
end

function DrillUI.Open()
    if not drillPanel then return end
    if not drillOpen then DrillUI.Toggle() end
end

-- Called each time a mining round completes (next round auto-starts server-side)
function DrillUI.OnRound(gemType, waitTime)
    mining = true
    roundLen = waitTime or roundLen
    roundEnd = os.clock() + roundLen
    if drillOpen then refresh() end
end

function DrillUI.UpdateGems(gems)
    myGems = gems
    if drillOpen then refresh() end
end

function DrillUI.UpdateCredits(c)
    credits = c
    if drillOpen then refresh() end
end

return DrillUI
