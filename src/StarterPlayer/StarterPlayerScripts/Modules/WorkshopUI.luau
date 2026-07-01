-- Workshop panel: deep, uncapped credit-sink upgrades (Core Power / Drill Power
-- / Market Value). Opened by holding E on the plot Workshop station.

local Panels     = require(script.Parent:WaitForChild("Panels"))
local Responsive = require(script.Parent:WaitForChild("Responsive"))

local WorkshopUI = {}
local RF_ref
local credits = 0
local listFrame
local shopPanel
local shopOpen = false

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

local function effectText(u)
    local per = math.floor(u.perLevel * 100 + 0.5)
    local now = math.floor(u.level * u.perLevel * 100 + 0.5)
    if u.kind == "income" then return string.format("+%d%% income/lvl  •  now +%d%%", per, now)
    elseif u.kind == "mining" then return string.format("-%d%% mine time/lvl  •  now -%d%%", per, now)
    else return string.format("+%d%% sell value/lvl  •  now +%d%%", per, now) end
end

local refresh
local function refetch()
    local info = RF_ref.GetWorkshopInfo:InvokeServer() or {}
    refresh(info)
end

function refresh(info)
    if not listFrame then return end
    for _, c in ipairs(listFrame:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    for _, u in ipairs(info or {}) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -4, 0, 66)
        row.BackgroundColor3 = Color3.fromRGB(20, 18, 30); row.BackgroundTransparency = 0.15
        row.BorderSizePixel = 0; row.Parent = listFrame
        corner(row, 6)
        lbl(row, { Text = u.icon .. "  " .. u.name .. "   Lv." .. u.level, Font = Enum.Font.GothamBold,
            TextColor3 = Color3.fromRGB(255, 220, 150), Size = UDim2.new(0.6, -8, 0.5, 0), Position = UDim2.new(0, 10, 0, 4) })
        lbl(row, { Text = effectText(u), TextColor3 = Color3.fromRGB(150, 220, 255),
            Size = UDim2.new(0.6, -8, 0.42, 0), Position = UDim2.new(0, 10, 0.52, 0) })

        local buy = Instance.new("TextButton")
        buy.Size = UDim2.new(0.38, -10, 0.72, 0); buy.Position = UDim2.new(0.62, 0, 0.14, 0)
        buy.BorderSizePixel = 0; buy.Text = fmt(u.nextCost) .. " CR"
        buy.TextColor3 = Color3.fromRGB(255, 255, 255); buy.Font = Enum.Font.GothamBold
        buy.TextScaled = true; buy.Parent = row; corner(buy, 5)
        buy.BackgroundColor3 = (credits >= u.nextCost) and Color3.fromRGB(150, 110, 30) or Color3.fromRGB(55, 52, 66)
        local capKey = u.key
        buy.MouseButton1Click:Connect(function()
            local ok, result = RF_ref.BuyCoreUpgrade:InvokeServer(capKey)
            if ok then
                if type(result) == "table" and result.credits then credits = result.credits end
                refetch()
            end
        end)
    end
end

function WorkshopUI.Init(playerGui, initData, RF)
    RF_ref  = RF
    credits = initData.credits or 0

    local gui = Instance.new("ScreenGui")
    gui.Name = "WorkshopUI"; gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = playerGui

    local panel = Instance.new("Frame")
    panel.Name = "WorkshopPanel"
    panel.Size = UDim2.new(0, 480, 0, 420)
    panel.Position = UDim2.new(0.5, 0, 0.5, 0); panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.BackgroundColor3 = Color3.fromRGB(12, 10, 16); panel.BackgroundTransparency = 0.05
    panel.BorderSizePixel = 0; panel.Visible = false; panel.Parent = gui
    corner(panel, 10)
    Responsive.Fit(panel, 480, 420)

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 42); header.BorderSizePixel = 0
    header.BackgroundColor3 = Color3.fromRGB(58, 44, 14); header.Parent = panel
    corner(header, 10)
    lbl(header, { Text = "⚙️  WORKSHOP", Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(255, 210, 120),
        Size = UDim2.new(1, -50, 1, 0), Position = UDim2.new(0, 12, 0, 0) })
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 34, 0, 34); closeBtn.Position = UDim2.new(1, -38, 0, 4)
    closeBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 40); closeBtn.BorderSizePixel = 0
    closeBtn.Text = "✕"; closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextScaled = true; closeBtn.Parent = header
    corner(closeBtn, 6)
    closeBtn.MouseButton1Click:Connect(function() shopOpen = false; panel.Visible = false end)

    lbl(panel, { Text = "Sink your credits into permanent, uncapped upgrades.",
        TextColor3 = Color3.fromRGB(170, 170, 195), TextXAlignment = Enum.TextXAlignment.Center,
        Size = UDim2.new(1, -16, 0, 16), Position = UDim2.new(0, 8, 0, 46) })

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -8, 1, -70); scroll.Position = UDim2.new(0, 4, 0, 66)
    scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4; scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; scroll.Parent = panel
    listFrame = scroll
    local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0, 5); layout.Parent = scroll

    shopPanel = panel
    Panels.Register("Workshop", function() shopOpen = false; panel.Visible = false end)
end

function WorkshopUI.Toggle()
    if not shopPanel then return end
    shopOpen = not shopOpen
    shopPanel.Visible = shopOpen
    if shopOpen then Panels.CloseOthers("Workshop"); refetch() end
end

function WorkshopUI.UpdateCredits(c)
    credits = c
    if shopOpen then refetch() end
end

return WorkshopUI
