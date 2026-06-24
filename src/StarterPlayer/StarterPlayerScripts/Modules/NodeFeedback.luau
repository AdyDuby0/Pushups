-- Attaches a world-space BillboardGui to the active extraction node.
-- Shows a progress bar that fills over extractTime seconds + a remaining counter.
-- Reset the bar each tick by calling UpdateRemaining().

local TweenService = game:GetService("TweenService")
local GemTypes     = require(game.ReplicatedStorage:WaitForChild("Config"):WaitForChild("GemTypes"))

local NodeFeedback = {}

local billboard   = nil
local progressBar = nil
local remainLbl   = nil
local activeTween = nil

local function killTween()
    if activeTween then activeTween:Cancel(); activeTween = nil end
end

function NodeFeedback.Attach(node, gemType, remaining, extractTime)
    NodeFeedback.Detach()

    local gd = GemTypes[gemType]

    local bb = Instance.new("BillboardGui")
    bb.Name        = "NodeFeedbackGui"
    bb.Size        = UDim2.new(0, 160, 0, 52)
    bb.StudsOffset = Vector3.new(0, 4.5, 0)
    bb.AlwaysOnTop = true
    bb.Adornee     = node
    bb.Parent      = workspace
    billboard      = bb

    -- Background
    local bg = Instance.new("Frame")
    bg.Size                 = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3     = Color3.fromRGB(10, 10, 20)
    bg.BackgroundTransparency = 0.3
    bg.BorderSizePixel      = 0
    bg.Parent               = bb
    local bgCorner = Instance.new("UICorner"); bgCorner.CornerRadius = UDim.new(0, 8); bgCorner.Parent = bg

    -- Gem name label
    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size                 = UDim2.new(1, -8, 0, 18)
    nameLbl.Position             = UDim2.new(0, 4, 0, 2)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text                 = gd and gd.displayName or gemType
    nameLbl.TextColor3           = gd and gd.color or Color3.fromRGB(255, 255, 255)
    nameLbl.Font                 = Enum.Font.GothamBold
    nameLbl.TextScaled           = true
    nameLbl.TextXAlignment       = Enum.TextXAlignment.Left
    nameLbl.Parent               = bg

    -- Remaining counter
    remainLbl = Instance.new("TextLabel")
    remainLbl.Size                 = UDim2.new(0.5, -4, 0, 14)
    remainLbl.Position             = UDim2.new(0.5, 0, 0, 22)
    remainLbl.BackgroundTransparency = 1
    remainLbl.Text                 = remaining .. " left"
    remainLbl.TextColor3           = Color3.fromRGB(180, 180, 180)
    remainLbl.Font                 = Enum.Font.Gotham
    remainLbl.TextScaled           = true
    remainLbl.TextXAlignment       = Enum.TextXAlignment.Right
    remainLbl.Parent               = bg

    -- Progress bar track
    local track = Instance.new("Frame")
    track.Size                 = UDim2.new(1, -8, 0, 10)
    track.Position             = UDim2.new(0, 4, 0, 38)
    track.BackgroundColor3     = Color3.fromRGB(30, 30, 50)
    track.BackgroundTransparency = 0.2
    track.BorderSizePixel      = 0
    track.Parent               = bg
    local trackCorner = Instance.new("UICorner"); trackCorner.CornerRadius = UDim.new(0, 4); trackCorner.Parent = track

    -- Progress bar fill
    progressBar = Instance.new("Frame")
    progressBar.Size             = UDim2.new(0, 0, 1, 0)
    progressBar.BackgroundColor3 = gd and gd.color or Color3.fromRGB(80, 255, 80)
    progressBar.BackgroundTransparency = 0.1
    progressBar.BorderSizePixel  = 0
    progressBar.Parent           = track
    local fillCorner = Instance.new("UICorner"); fillCorner.CornerRadius = UDim.new(0, 4); fillCorner.Parent = progressBar

    -- "⛏ extracting" label on left of bar area
    local extractLbl = Instance.new("TextLabel")
    extractLbl.Size                 = UDim2.new(0.5, -4, 0, 14)
    extractLbl.Position             = UDim2.new(0, 0, 0, 22)
    extractLbl.BackgroundTransparency = 1
    extractLbl.Text                 = "⛏ extracting"
    extractLbl.TextColor3           = Color3.fromRGB(100, 200, 100)
    extractLbl.Font                 = Enum.Font.Gotham
    extractLbl.TextScaled           = true
    extractLbl.TextXAlignment       = Enum.TextXAlignment.Left
    extractLbl.Parent               = bg

    -- Start first fill animation
    NodeFeedback._animateBar(extractTime)
end

function NodeFeedback._animateBar(extractTime)
    if not progressBar or not progressBar.Parent then return end
    killTween()
    progressBar.Size = UDim2.new(0, 0, 1, 0)
    local t = TweenService:Create(
        progressBar,
        TweenInfo.new(math.max(extractTime, 0.1), Enum.EasingStyle.Linear),
        { Size = UDim2.new(1, 0, 1, 0) }
    )
    t:Play()
    activeTween = t
end

function NodeFeedback.UpdateRemaining(remaining, extractTime)
    if remainLbl and remainLbl.Parent then
        remainLbl.Text = remaining .. " left"
    end
    NodeFeedback._animateBar(extractTime)
end

function NodeFeedback.Detach()
    killTween()
    if billboard and billboard.Parent then billboard:Destroy() end
    billboard   = nil
    progressBar = nil
    remainLbl   = nil
end

return NodeFeedback
