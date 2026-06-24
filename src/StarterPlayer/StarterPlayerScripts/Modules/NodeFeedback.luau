-- Attaches a world-space BillboardGui to the active mining node.
-- Shows a progress bar filling over mineTime seconds + a live time countdown.
-- Designed for the single-shot model: each round = one full bar = one shard.

local TweenService = game:GetService("TweenService")
local GemTypes     = require(game.ReplicatedStorage:WaitForChild("Config"):WaitForChild("GemTypes"))

local NodeFeedback = {}

local billboard    = nil
local progressBar  = nil
local timeLbl      = nil
local activeTween  = nil
local countThread  = nil

local function killAll()
    if activeTween then activeTween:Cancel(); activeTween = nil end
    if countThread then task.cancel(countThread); countThread = nil end
end

local function fmtTime(s)
    s = math.ceil(s)
    if s >= 3600 then
        return string.format("%dh %02dm", math.floor(s/3600), math.floor(s%3600/60))
    elseif s >= 60 then
        return string.format("%dm %02ds", math.floor(s/60), s % 60)
    else
        return s .. "s"
    end
end

function NodeFeedback.Attach(node, gemType, mineTime)
    NodeFeedback.Detach()

    local gd = GemTypes[gemType]

    local bb = Instance.new("BillboardGui")
    bb.Name        = "NodeFeedbackGui"
    bb.Size        = UDim2.new(0, 180, 0, 68)
    bb.StudsOffset = Vector3.new(0, 5, 0)
    bb.AlwaysOnTop = true
    bb.Adornee     = node
    bb.Parent      = workspace
    billboard      = bb

    local bg = Instance.new("Frame")
    bg.Size                 = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3     = Color3.fromRGB(8, 8, 20)
    bg.BackgroundTransparency = 0.25
    bg.BorderSizePixel      = 0
    bg.Parent               = bb
    local bgCorner = Instance.new("UICorner"); bgCorner.CornerRadius = UDim.new(0, 10); bgCorner.Parent = bg

    -- Gem name
    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size                 = UDim2.new(1, -8, 0, 22)
    nameLbl.Position             = UDim2.new(0, 4, 0, 3)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text                 = gd and gd.displayName or gemType
    nameLbl.TextColor3           = gd and gd.color or Color3.fromRGB(255, 255, 255)
    nameLbl.Font                 = Enum.Font.GothamBold
    nameLbl.TextScaled           = true
    nameLbl.TextXAlignment       = Enum.TextXAlignment.Left
    nameLbl.Parent               = bg

    -- "⛏ mining"
    local miningLbl = Instance.new("TextLabel")
    miningLbl.Size                 = UDim2.new(0.5, -4, 0, 16)
    miningLbl.Position             = UDim2.new(0, 4, 0, 28)
    miningLbl.BackgroundTransparency = 1
    miningLbl.Text                 = "⛏ mining"
    miningLbl.TextColor3           = Color3.fromRGB(100, 210, 130)
    miningLbl.Font                 = Enum.Font.Gotham
    miningLbl.TextScaled           = true
    miningLbl.TextXAlignment       = Enum.TextXAlignment.Left
    miningLbl.Parent               = bg

    -- Live time-remaining
    timeLbl = Instance.new("TextLabel")
    timeLbl.Size                 = UDim2.new(0.5, -4, 0, 16)
    timeLbl.Position             = UDim2.new(0.5, 0, 0, 28)
    timeLbl.BackgroundTransparency = 1
    timeLbl.Text                 = fmtTime(mineTime)
    timeLbl.TextColor3           = Color3.fromRGB(200, 200, 200)
    timeLbl.Font                 = Enum.Font.Gotham
    timeLbl.TextScaled           = true
    timeLbl.TextXAlignment       = Enum.TextXAlignment.Right
    timeLbl.Parent               = bg

    -- Progress track
    local track = Instance.new("Frame")
    track.Size                 = UDim2.new(1, -8, 0, 12)
    track.Position             = UDim2.new(0, 4, 0, 48)
    track.BackgroundColor3     = Color3.fromRGB(25, 25, 50)
    track.BackgroundTransparency = 0.2
    track.BorderSizePixel      = 0
    track.Parent               = bg
    local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(0, 4); tc.Parent = track

    progressBar = Instance.new("Frame")
    progressBar.Size             = UDim2.new(0, 0, 1, 0)
    progressBar.BackgroundColor3 = gd and gd.color or Color3.fromRGB(80, 255, 80)
    progressBar.BackgroundTransparency = 0.05
    progressBar.BorderSizePixel  = 0
    progressBar.Parent           = track
    local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(0, 4); fc.Parent = progressBar

    NodeFeedback._startRound(mineTime)
end

function NodeFeedback._startRound(mineTime)
    if not progressBar or not progressBar.Parent then return end
    killAll()
    progressBar.Size = UDim2.new(0, 0, 1, 0)

    -- Bar tween
    local t = TweenService:Create(
        progressBar,
        TweenInfo.new(math.max(mineTime, 0.5), Enum.EasingStyle.Linear),
        { Size = UDim2.new(1, 0, 1, 0) }
    )
    t:Play()
    activeTween = t

    -- Live countdown
    local elapsed = 0
    countThread = task.spawn(function()
        while elapsed < mineTime do
            task.wait(1)
            elapsed += 1
            local left = mineTime - elapsed
            if timeLbl and timeLbl.Parent then
                timeLbl.Text = fmtTime(math.max(left, 0))
            end
        end
    end)
end

-- Called by GemExtracted handler each time a round completes, to restart the bar.
function NodeFeedback.OnRoundComplete(nextMineTime)
    NodeFeedback._startRound(nextMineTime)
end

function NodeFeedback.Detach()
    killAll()
    if billboard and billboard.Parent then billboard:Destroy() end
    billboard   = nil
    progressBar = nil
    timeLbl     = nil
end

return NodeFeedback
