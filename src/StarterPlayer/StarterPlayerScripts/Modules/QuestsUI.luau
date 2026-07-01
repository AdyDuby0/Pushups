-- Goals / quests panel. Lists goals with a progress bar and a Claim button.

local Panels     = require(script.Parent:WaitForChild("Panels"))
local Responsive = require(script.Parent:WaitForChild("Responsive"))

local QuestsUI = {}
local RF_ref
local listFrame
local questsPanel
local questsOpen = false
local objectiveBanner

local function fmt(n)
    n = math.floor(n)
    local a = math.abs(n)
    if a >= 1e12 then return string.format("%.1fT", n/1e12)
    elseif a >= 1e9 then return string.format("%.1fB", n/1e9)
    elseif a >= 1e6 then return string.format("%.1fM", n/1e6)
    elseif a >= 1e3 then return string.format("%.1fK", n/1e3)
    else return tostring(n) end
end

local function corner(inst, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 6); c.Parent = inst
end

local function rewardText(reward)
    local parts = {}
    if reward.credits then table.insert(parts, "💰" .. fmt(reward.credits)) end
    if reward.gemCurrency then table.insert(parts, "💎" .. reward.gemCurrency) end
    if reward.gems then for gt, n in pairs(reward.gems) do table.insert(parts, n .. "× " .. gt) end end
    return table.concat(parts, "  ")
end

local refresh

local function makeRow(goal)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -4, 0, 64)
    row.BackgroundColor3 = goal.claimed and Color3.fromRGB(20, 30, 22)
        or (goal.claimable and Color3.fromRGB(30, 44, 24) or Color3.fromRGB(18, 18, 34))
    row.BackgroundTransparency = 0.15; row.BorderSizePixel = 0; row.Parent = listFrame
    corner(row, 6)

    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(0.62, -8, 0, 22); name.Position = UDim2.new(0, 10, 0, 4)
    name.BackgroundTransparency = 1; name.Text = goal.name
    name.TextColor3 = Color3.fromRGB(235, 235, 245); name.Font = Enum.Font.GothamBold
    name.TextScaled = true; name.TextXAlignment = Enum.TextXAlignment.Left; name.Parent = row

    local rew = Instance.new("TextLabel")
    rew.Size = UDim2.new(0.62, -8, 0, 18); rew.Position = UDim2.new(0, 10, 0, 40)
    rew.BackgroundTransparency = 1; rew.Text = rewardText(goal.reward)
    rew.TextColor3 = Color3.fromRGB(255, 220, 120); rew.Font = Enum.Font.Gotham
    rew.TextScaled = true; rew.TextXAlignment = Enum.TextXAlignment.Left; rew.Parent = row

    -- progress bar
    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(0.62, -8, 0, 10); barBg.Position = UDim2.new(0, 10, 0, 26)
    barBg.BackgroundColor3 = Color3.fromRGB(20, 20, 40); barBg.BorderSizePixel = 0; barBg.Parent = row
    corner(barBg, 5)
    local frac = goal.target > 0 and math.clamp(goal.progress / goal.target, 0, 1) or 1
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(frac, 0, 1, 0); fill.BorderSizePixel = 0
    fill.BackgroundColor3 = goal.claimable and Color3.fromRGB(90, 230, 120) or Color3.fromRGB(90, 150, 230)
    fill.Parent = barBg
    corner(fill, 5)
    local pText = Instance.new("TextLabel")
    pText.Size = UDim2.new(1, 0, 1, 0); pText.BackgroundTransparency = 1
    pText.Text = fmt(goal.progress) .. " / " .. fmt(goal.target)
    pText.TextColor3 = Color3.fromRGB(230, 230, 245); pText.Font = Enum.Font.Gotham
    pText.TextScaled = true; pText.Parent = barBg

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.36, -8, 0, 48); btn.Position = UDim2.new(0.64, 0, 0, 8)
    btn.BorderSizePixel = 0; btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold; btn.TextScaled = true; btn.Parent = row
    corner(btn, 6)
    if goal.claimed then
        btn.Text = "✓ Claimed"; btn.BackgroundColor3 = Color3.fromRGB(50, 60, 52); btn.AutoButtonColor = false
    elseif goal.claimable then
        btn.Text = "Claim!"; btn.BackgroundColor3 = Color3.fromRGB(45, 150, 80)
        local capId = goal.id
        btn.MouseButton1Click:Connect(function()
            local ok = RF_ref.ClaimGoal:InvokeServer(capId)
            if ok then refresh() end
        end)
    else
        btn.Text = "In progress"; btn.BackgroundColor3 = Color3.fromRGB(45, 45, 62); btn.AutoButtonColor = false
    end
end

-- Persistent "do this next" beacon
local function updateObjective()
    if not (objectiveBanner and RF_ref) then return end
    local goals = RF_ref.GetGoals:InvokeServer() or {}
    local claimable, nextInc
    for _, g in ipairs(goals) do
        if g.claimable and not claimable then claimable = g end
        if not g.claimed and g.progress < g.target and not nextInc then nextInc = g end
    end
    if claimable then
        objectiveBanner.Text = "🎯 Claim reward: " .. claimable.name .. "!"
        objectiveBanner.BackgroundColor3 = Color3.fromRGB(45, 120, 60)
        objectiveBanner.Visible = true
    elseif nextInc then
        objectiveBanner.Text = "🎯 " .. nextInc.name .. "  (" .. fmt(nextInc.progress) .. "/" .. fmt(nextInc.target) .. ")"
        objectiveBanner.BackgroundColor3 = Color3.fromRGB(38, 38, 66)
        objectiveBanner.Visible = true
    else
        objectiveBanner.Visible = false
    end
end

function refresh()
    if not listFrame then return end
    for _, c in ipairs(listFrame:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    local goals = RF_ref.GetGoals:InvokeServer() or {}
    for _, g in ipairs(goals) do makeRow(g) end
    updateObjective()
end

function QuestsUI.Init(playerGui, initData, RF)
    RF_ref = RF

    local gui = Instance.new("ScreenGui")
    gui.Name = "QuestsUI"; gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = playerGui

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 120, 0, 34); toggleBtn.Position = UDim2.new(0, 8, 0, 104)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(70, 55, 20); toggleBtn.BorderSizePixel = 0
    toggleBtn.Text = "🎯 Goals"; toggleBtn.TextColor3 = Color3.fromRGB(255, 230, 160)
    toggleBtn.Font = Enum.Font.GothamBold; toggleBtn.TextScaled = true; toggleBtn.Parent = gui
    corner(toggleBtn, 6)

    local panel = Instance.new("Frame")
    panel.Name = "QuestsPanel"
    panel.Size = UDim2.new(0, 500, 0, 560)
    panel.Position = UDim2.new(0.5, 0, 0.5, 0); panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.BackgroundColor3 = Color3.fromRGB(10, 12, 18); panel.BackgroundTransparency = 0.05
    panel.BorderSizePixel = 0; panel.Visible = false; panel.Parent = gui
    corner(panel, 10)
    Responsive.Fit(panel, 500, 560)

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 42); header.BorderSizePixel = 0
    header.BackgroundColor3 = Color3.fromRGB(60, 48, 16); header.Parent = panel
    corner(header, 10)
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -50, 1, 0); title.Position = UDim2.new(0, 12, 0, 0)
    title.BackgroundTransparency = 1; title.Text = "🎯  GOALS"
    title.TextColor3 = Color3.fromRGB(255, 230, 160); title.Font = Enum.Font.GothamBold
    title.TextScaled = true; title.TextXAlignment = Enum.TextXAlignment.Left; title.Parent = header

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 34, 0, 34); closeBtn.Position = UDim2.new(1, -38, 0, 4)
    closeBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 40); closeBtn.BorderSizePixel = 0
    closeBtn.Text = "✕"; closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextScaled = true; closeBtn.Parent = header
    corner(closeBtn, 6)
    closeBtn.MouseButton1Click:Connect(function() questsOpen = false; panel.Visible = false end)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -8, 1, -50); scroll.Position = UDim2.new(0, 4, 0, 46)
    scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4; scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; scroll.Parent = panel
    listFrame = scroll
    local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0, 5); layout.Parent = scroll

    -- persistent objective beacon (top-center), click to open Goals
    objectiveBanner = Instance.new("TextButton")
    objectiveBanner.Size = UDim2.new(0, 380, 0, 32)
    objectiveBanner.Position = UDim2.new(0.5, 0, 0, 8); objectiveBanner.AnchorPoint = Vector2.new(0.5, 0)
    objectiveBanner.BackgroundColor3 = Color3.fromRGB(38, 38, 66); objectiveBanner.BackgroundTransparency = 0.1
    objectiveBanner.BorderSizePixel = 0; objectiveBanner.Text = ""
    objectiveBanner.TextColor3 = Color3.fromRGB(255, 230, 160); objectiveBanner.Font = Enum.Font.GothamBold
    objectiveBanner.TextScaled = true; objectiveBanner.Visible = false; objectiveBanner.Parent = gui
    corner(objectiveBanner, 8)
    objectiveBanner.MouseButton1Click:Connect(function() QuestsUI.Open() end)

    questsPanel = panel
    Panels.Register("Quests", function() questsOpen = false; panel.Visible = false end)
    toggleBtn.MouseButton1Click:Connect(function() QuestsUI.Toggle() end)

    task.spawn(function()
        while true do updateObjective(); task.wait(12) end
    end)
end

function QuestsUI.Open()
    if questsPanel and not questsOpen then QuestsUI.Toggle() end
end

function QuestsUI.Toggle()
    if not questsPanel then return end
    questsOpen = not questsOpen
    questsPanel.Visible = questsOpen
    if questsOpen then Panels.CloseOthers("Quests"); refresh() end
end

return QuestsUI
