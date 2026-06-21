local TweenService = game:GetService("TweenService")
local Players      = game:GetService("Players")

local HUD = {}
local creditsLabel, incomeLabel, leaderboardList, notifLabel

local function fmt(n)
    n = math.floor(n)
    if n >= 1e12 then return string.format("%.2fT", n/1e12)
    elseif n >= 1e9  then return string.format("%.2fB", n/1e9)
    elseif n >= 1e6  then return string.format("%.2fM", n/1e6)
    elseif n >= 1e3  then return string.format("%.1fK", n/1e3)
    else return tostring(n) end
end

local function makeFrame(parent, props)
    local f = Instance.new("Frame")
    for k, v in pairs(props) do f[k] = v end
    f.Parent = parent
    return f
end

local function makeLabel(parent, props)
    local l = Instance.new("TextLabel")
    for k, v in pairs(props) do l[k] = v end
    l.Parent = parent
    return l
end

local function corner(inst, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = inst
end

function HUD.Init(playerGui, initData)
    local gui = Instance.new("ScreenGui")
    gui.Name           = "HUD"
    gui.ResetOnSpawn   = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent         = playerGui

    -- Top bar
    local topBar = makeFrame(gui, {
        Size                  = UDim2.new(1, 0, 0, 56),
        BackgroundColor3      = Color3.fromRGB(8, 8, 18),
        BackgroundTransparency = 0.25,
        BorderSizePixel       = 0,
    })

    -- Credits container
    local creditBox = makeFrame(topBar, {
        Size             = UDim2.new(0, 210, 1, -10),
        Position         = UDim2.new(0, 8, 0, 5),
        BackgroundColor3 = Color3.fromRGB(18, 18, 36),
        BorderSizePixel  = 0,
    })
    corner(creditBox, 6)

    makeLabel(creditBox, {
        Size                 = UDim2.new(0, 28, 1, 0),
        Position             = UDim2.new(0, 4, 0, 0),
        BackgroundTransparency = 1,
        Text                 = "💎",
        TextScaled           = true,
    })

    creditsLabel = makeLabel(creditBox, {
        Name                 = "CreditsLabel",
        Size                 = UDim2.new(1, -38, 0.58, 0),
        Position             = UDim2.new(0, 34, 0, 2),
        BackgroundTransparency = 1,
        Text                 = fmt(initData.credits),
        TextColor3           = Color3.fromRGB(255, 220, 50),
        Font                 = Enum.Font.GothamBold,
        TextScaled           = true,
        TextXAlignment       = Enum.TextXAlignment.Left,
    })

    incomeLabel = makeLabel(creditBox, {
        Name                 = "IncomeLabel",
        Size                 = UDim2.new(1, -38, 0.38, 0),
        Position             = UDim2.new(0, 34, 0.58, 0),
        BackgroundTransparency = 1,
        Text                 = "+" .. fmt(initData.incomeRate) .. "/s",
        TextColor3           = Color3.fromRGB(80, 255, 80),
        Font                 = Enum.Font.Gotham,
        TextScaled           = true,
        TextXAlignment       = Enum.TextXAlignment.Left,
    })

    -- Leaderboard panel (right side)
    local lbPanel = makeFrame(gui, {
        Name             = "Leaderboard",
        Size             = UDim2.new(0, 230, 0, 290),
        Position         = UDim2.new(1, -238, 0, 64),
        BackgroundColor3 = Color3.fromRGB(8, 8, 18),
        BackgroundTransparency = 0.15,
        BorderSizePixel  = 0,
    })
    corner(lbPanel, 10)

    local lbTitle = makeLabel(lbPanel, {
        Size             = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = Color3.fromRGB(30, 10, 60),
        BackgroundTransparency = 0,
        BorderSizePixel  = 0,
        Text             = "⚡  POWER RANKINGS",
        TextColor3       = Color3.fromRGB(200, 150, 255),
        Font             = Enum.Font.GothamBold,
        TextScaled       = true,
    })
    corner(lbTitle, 10)

    local lbScroll = Instance.new("ScrollingFrame")
    lbScroll.Size              = UDim2.new(1, -8, 1, -46)
    lbScroll.Position          = UDim2.new(0, 4, 0, 42)
    lbScroll.BackgroundTransparency = 1
    lbScroll.BorderSizePixel   = 0
    lbScroll.ScrollBarThickness = 0
    lbScroll.CanvasSize        = UDim2.new(0, 0, 0, 0)
    lbScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    lbScroll.Parent            = lbPanel
    leaderboardList = lbScroll

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding   = UDim.new(0, 3)
    listLayout.Parent    = lbScroll

    -- Notification bar
    notifLabel = makeLabel(gui, {
        Name             = "Notification",
        Size             = UDim2.new(0, 420, 0, 44),
        Position         = UDim2.new(0.5, -210, 0, 64),
        BackgroundColor3 = Color3.fromRGB(18, 18, 40),
        BackgroundTransparency = 0.1,
        BorderSizePixel  = 0,
        Text             = "",
        TextColor3       = Color3.fromRGB(200, 200, 255),
        Font             = Enum.Font.Gotham,
        TextScaled       = true,
        Visible          = false,
        ZIndex           = 20,
    })
    corner(notifLabel, 8)
end

function HUD.Update(hudData)
    if hudData.credits and creditsLabel then
        creditsLabel.Text = fmt(hudData.credits)
    end
    if hudData.incomeRate and incomeLabel then
        incomeLabel.Text = "+" .. fmt(hudData.incomeRate) .. "/s"
    end
end

function HUD.UpdateLeaderboard(board)
    if not leaderboardList then return end
    for _, c in ipairs(leaderboardList:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

    local localId = Players.LocalPlayer.UserId

    for rank, entry in ipairs(board) do
        if rank > 6 then break end

        local isMe = entry.userId == localId
        local row  = makeFrame(leaderboardList, {
            Size             = UDim2.new(1, 0, 0, 40),
            LayoutOrder      = rank,
            BackgroundColor3 = isMe and Color3.fromRGB(45, 25, 90) or Color3.fromRGB(18, 18, 32),
            BackgroundTransparency = isMe and 0.3 or 0.6,
            BorderSizePixel  = 0,
        })
        corner(row, 5)

        makeLabel(row, {
            Size                 = UDim2.new(0, 26, 1, 0),
            Position             = UDim2.new(0, 4, 0, 0),
            BackgroundTransparency = 1,
            Text                 = rank == 1 and "👑" or tostring(rank),
            TextColor3           = rank == 1 and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(160, 160, 160),
            Font                 = Enum.Font.GothamBold,
            TextScaled           = true,
        })
        makeLabel(row, {
            Size                 = UDim2.new(0.5, -30, 0.55, 0),
            Position             = UDim2.new(0, 30, 0, 2),
            BackgroundTransparency = 1,
            Text                 = entry.name,
            TextColor3           = Color3.fromRGB(220, 220, 255),
            Font                 = Enum.Font.Gotham,
            TextScaled           = true,
            TextXAlignment       = Enum.TextXAlignment.Left,
        })
        makeLabel(row, {
            Size                 = UDim2.new(0.48, 0, 0.55, 0),
            Position             = UDim2.new(0.52, 0, 0, 2),
            BackgroundTransparency = 1,
            Text                 = fmt(entry.totalEarned) .. " 💳",
            TextColor3           = Color3.fromRGB(255, 220, 50),
            Font                 = Enum.Font.GothamBold,
            TextScaled           = true,
            TextXAlignment       = Enum.TextXAlignment.Right,
        })
        makeLabel(row, {
            Size                 = UDim2.new(1, -34, 0.42, 0),
            Position             = UDim2.new(0, 30, 0.55, 0),
            BackgroundTransparency = 1,
            Text                 = "Lv." .. entry.coreLevel .. "  +" .. fmt(entry.incomeRate) .. "/s",
            TextColor3           = Color3.fromRGB(130, 130, 180),
            Font                 = Enum.Font.Gotham,
            TextScaled           = true,
            TextXAlignment       = Enum.TextXAlignment.Left,
        })
    end
end

function HUD.ShowNotification(msg)
    if not notifLabel then return end
    notifLabel.Text    = msg
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
    bb.Size         = UDim2.new(0, 100, 0, 34)
    bb.StudsOffset  = Vector3.new(0, 4, 0)
    bb.AlwaysOnTop  = true
    bb.Adornee      = hrp
    bb.Parent       = workspace

    local lbl = Instance.new("TextLabel")
    lbl.Size                 = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text                 = text
    lbl.TextColor3           = color or Color3.fromRGB(80, 255, 80)
    lbl.Font                 = Enum.Font.GothamBold
    lbl.TextScaled           = true
    lbl.Parent               = bb

    TweenService:Create(bb, TweenInfo.new(1.5), { StudsOffset = Vector3.new(0, 9, 0) }):Play()
    task.delay(1.5, function() bb:Destroy() end)
end

return HUD
