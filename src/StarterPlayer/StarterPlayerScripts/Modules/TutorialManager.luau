-- Guides first-time players through 4 steps: find node → extract → open core → slot gem
-- Skipped automatically for returning players (gemsCollected > 0)

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local TutorialManager = {}

local STEPS = {
    "Walk to your ⛏ DRILL, click it, then press Start Drilling to mine gems.",
    "Nice! Now walk up to your ⚡ Power Core to open its panel.",
    "Click SLOT next to your gem to start generating income.",
    "Your core is running! Click the 🔧 Crafting station to build gear that boosts output.",
}

local step       = 0
local active     = false
local nodeArrow  = nil   -- BillboardGui on the target node
local hintGui    = nil   -- ScreenGui with hint bar
local playerGui_ref = nil

local function corner(inst, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = inst
end

local function destroyHint()
    if hintGui and hintGui.Parent then hintGui:Destroy() end
    hintGui = nil
end

local function destroyArrow()
    if nodeArrow and nodeArrow.Parent then nodeArrow:Destroy() end
    nodeArrow = nil
end

local function showHint(text)
    destroyHint()
    if not playerGui_ref then return end

    local gui = Instance.new("ScreenGui")
    gui.Name = "TutorialHint"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = playerGui_ref
    hintGui = gui

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 500, 0, 58)
    bar.Position = UDim2.new(0.5, -250, 1, -82)
    bar.BackgroundColor3 = Color3.fromRGB(20, 50, 15)
    bar.BackgroundTransparency = 0.08
    bar.BorderSizePixel = 0
    bar.Parent = gui
    corner(bar, 10)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(80, 255, 80)
    stroke.Thickness = 2
    stroke.Parent = bar

    -- Pulse the border
    task.spawn(function()
        while gui.Parent do
            TweenService:Create(stroke, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                { Transparency = 0.85 }):Play()
            task.wait(0.9)
            TweenService:Create(stroke, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                { Transparency = 0.0 }):Play()
            task.wait(0.9)
        end
    end)

    local stepLbl = Instance.new("TextLabel")
    stepLbl.Size = UDim2.new(0, 60, 1, 0)
    stepLbl.BackgroundTransparency = 1
    stepLbl.Text = "STEP " .. step .. "/4"
    stepLbl.TextColor3 = Color3.fromRGB(80, 200, 80)
    stepLbl.Font = Enum.Font.GothamBold
    stepLbl.TextScaled = true
    stepLbl.Parent = bar

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -110, 1, 0)
    lbl.Position = UDim2.new(0, 62, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(210, 255, 210)
    lbl.Font = Enum.Font.Gotham
    lbl.TextScaled = true
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = bar

    local skipBtn = Instance.new("TextButton")
    skipBtn.Size = UDim2.new(0, 38, 0, 38)
    skipBtn.Position = UDim2.new(1, -44, 0.5, -19)
    skipBtn.BackgroundColor3 = Color3.fromRGB(70, 30, 30)
    skipBtn.BorderSizePixel = 0
    skipBtn.Text = "✕"
    skipBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
    skipBtn.Font = Enum.Font.GothamBold
    skipBtn.TextScaled = true
    skipBtn.Parent = bar
    corner(skipBtn, 6)

    skipBtn.MouseButton1Click:Connect(function()
        TutorialManager.Complete()
    end)
end

local function attachNodeArrow(node)
    destroyArrow()

    local bb = Instance.new("BillboardGui")
    bb.Name = "TutorialNodeArrow"
    bb.Size = UDim2.new(0, 130, 0, 44)
    bb.StudsOffset = Vector3.new(0, 6, 0)
    bb.AlwaysOnTop = true
    bb.Adornee = node
    bb.Parent = workspace
    nodeArrow = bb

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "▼  HOLD [E]"
    lbl.TextColor3 = Color3.fromRGB(80, 255, 80)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextScaled = true
    lbl.Parent = bb

    -- Bob up and down
    task.spawn(function()
        while bb.Parent do
            TweenService:Create(bb, TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                { StudsOffset = Vector3.new(0, 7.5, 0) }):Play()
            task.wait(0.55)
            TweenService:Create(bb, TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                { StudsOffset = Vector3.new(0, 6, 0) }):Play()
            task.wait(0.55)
        end
    end)
end

-- Point the arrow at the nearest plot Drill (the old GemNodes folder is gone)
local function findNearestNode()
    local char = Players.LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end

    local best, bestDist = nil, math.huge
    for _, d in ipairs(plots:GetDescendants()) do
        if d:IsA("BasePart") and d.Name == "Drill" then
            local dist = (d.Position - hrp.Position).Magnitude
            if dist < bestDist then best, bestDist = d, dist end
        end
    end
    return best
end

-- ── Public API ────────────────────────────────────────────────────────────────

function TutorialManager.Start(playerGui, initData)
    -- Skip for returning players
    if initData.stats and initData.stats.gemsCollected > 0 then return end

    active        = true
    step          = 1
    playerGui_ref = playerGui

    task.delay(3, function()
        if not active then return end
        local node = findNearestNode()
        if node then attachNodeArrow(node) end
        showHint(STEPS[1])
    end)
end

-- Called from Main.client when GemExtracted fires for the first time
function TutorialManager.OnFirstExtraction()
    if not active or step ~= 1 then return end
    step = 2
    destroyArrow()
    showHint(STEPS[2])
end

-- Called from PlotUI when the panel opens
function TutorialManager.OnCoreOpened()
    if not active or step ~= 2 then return end
    step = 3
    showHint(STEPS[3])
end

-- Called from PlotUI when a gem is successfully slotted
function TutorialManager.OnFirstSlot()
    if not active or step ~= 3 then return end
    step = 4
    showHint(STEPS[4])
    task.delay(6, function() TutorialManager.Complete() end)
end

function TutorialManager.Complete()
    active = false
    destroyArrow()
    destroyHint()
end

function TutorialManager.IsActive() return active end

return TutorialManager
