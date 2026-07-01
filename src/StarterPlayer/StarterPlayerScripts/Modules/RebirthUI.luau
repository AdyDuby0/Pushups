-- Rebirth / prestige panel. Shows current prestige & multiplier and lets you
-- rebirth for permanent income points (resets the run).

local Panels     = require(script.Parent:WaitForChild("Panels"))
local Responsive = require(script.Parent:WaitForChild("Responsive"))
local Effects    = require(script.Parent:WaitForChild("Effects"))
local Sounds     = require(script.Parent:WaitForChild("Sounds"))

local RebirthUI = {}
local RF_ref
local rebirthPanel
local rebirthOpen = false
local bodyRefs = {}

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

local function lbl(parent, props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1; l.Font = Enum.Font.Gotham; l.TextScaled = true
    l.TextXAlignment = Enum.TextXAlignment.Center; l.TextColor3 = Color3.fromRGB(230, 230, 245)
    for k, v in pairs(props) do l[k] = v end
    l.Parent = parent
    return l
end

local function refresh()
    local info = RF_ref.GetRebirthInfo:InvokeServer() or {}
    bodyRefs.prestige.Text  = "🌟 Prestige: " .. (info.prestige or 0)
    bodyRefs.mult.Text      = string.format("Current income bonus:  ×%.2f", info.multiplier or 1)
    bodyRefs.pending.Text   = "Rebirth now for  +" .. (info.pending or 0) .. " prestige"
    bodyRefs.next.Text      = string.format("→ new bonus  ×%.2f", info.nextMult or (info.multiplier or 1))
    local canR = info.canRebirth
    bodyRefs.btn.Text = canR and ("🌟 REBIRTH  (+" .. (info.pending or 0) .. ")") or "Earn more to rebirth"
    bodyRefs.btn.BackgroundColor3 = canR and Color3.fromRGB(120, 60, 180) or Color3.fromRGB(55, 50, 70)
    bodyRefs.btn.AutoButtonColor = canR
    bodyRefs.canRebirth = canR
end

function RebirthUI.Init(playerGui, initData, RF)
    RF_ref = RF

    local gui = Instance.new("ScreenGui")
    gui.Name = "RebirthUI"; gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = playerGui

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 120, 0, 34); toggleBtn.Position = UDim2.new(0, 8, 0, 144)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(70, 40, 100); toggleBtn.BorderSizePixel = 0
    toggleBtn.Text = "🌟 Rebirth"; toggleBtn.TextColor3 = Color3.fromRGB(230, 200, 255)
    toggleBtn.Font = Enum.Font.GothamBold; toggleBtn.TextScaled = true; toggleBtn.Parent = gui
    corner(toggleBtn, 6)

    local panel = Instance.new("Frame")
    panel.Name = "RebirthPanel"
    panel.Size = UDim2.new(0, 420, 0, 380)
    panel.Position = UDim2.new(0.5, 0, 0.5, 0); panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.BackgroundColor3 = Color3.fromRGB(14, 10, 20); panel.BackgroundTransparency = 0.05
    panel.BorderSizePixel = 0; panel.Visible = false; panel.Parent = gui
    corner(panel, 10)
    Responsive.Fit(panel, 420, 380)

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 42); header.BorderSizePixel = 0
    header.BackgroundColor3 = Color3.fromRGB(55, 30, 80); header.Parent = panel
    corner(header, 10)
    lbl(header, {
        Text = "🌟  REBIRTH", Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(230, 200, 255),
        Size = UDim2.new(1, -50, 1, 0), Position = UDim2.new(0, 12, 0, 0), TextXAlignment = Enum.TextXAlignment.Left,
    })
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 34, 0, 34); closeBtn.Position = UDim2.new(1, -38, 0, 4)
    closeBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 40); closeBtn.BorderSizePixel = 0
    closeBtn.Text = "✕"; closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextScaled = true; closeBtn.Parent = header
    corner(closeBtn, 6)
    closeBtn.MouseButton1Click:Connect(function() rebirthOpen = false; panel.Visible = false end)

    bodyRefs.prestige = lbl(panel, { Text = "", Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(255, 220, 120),
        Size = UDim2.new(1, -20, 0, 30), Position = UDim2.new(0, 10, 0, 54) })
    bodyRefs.mult = lbl(panel, { Text = "", TextColor3 = Color3.fromRGB(120, 230, 150),
        Size = UDim2.new(1, -20, 0, 24), Position = UDim2.new(0, 10, 0, 90) })
    bodyRefs.pending = lbl(panel, { Text = "", Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(230, 200, 255),
        Size = UDim2.new(1, -20, 0, 28), Position = UDim2.new(0, 10, 0, 130) })
    bodyRefs.next = lbl(panel, { Text = "", TextColor3 = Color3.fromRGB(180, 210, 255),
        Size = UDim2.new(1, -20, 0, 22), Position = UDim2.new(0, 10, 0, 162) })

    lbl(panel, {
        Text = "Resets credits, core level, upgrades, slots, gems and drill depth.\nKeeps gear, 💎, gamepasses, goals and codes.",
        TextColor3 = Color3.fromRGB(170, 160, 190), TextWrapped = true, TextScaled = false, TextSize = 15,
        Size = UDim2.new(1, -30, 0, 50), Position = UDim2.new(0, 15, 0, 192),
    })

    bodyRefs.btn = Instance.new("TextButton")
    bodyRefs.btn.Size = UDim2.new(1, -30, 0, 52); bodyRefs.btn.Position = UDim2.new(0, 15, 1, -66)
    bodyRefs.btn.BorderSizePixel = 0; bodyRefs.btn.Text = ""
    bodyRefs.btn.TextColor3 = Color3.fromRGB(255, 255, 255); bodyRefs.btn.Font = Enum.Font.GothamBold
    bodyRefs.btn.TextScaled = true; bodyRefs.btn.Parent = panel
    corner(bodyRefs.btn, 8)
    bodyRefs.btn.MouseButton1Click:Connect(function()
        if not bodyRefs.canRebirth then return end
        local ok, result = RF_ref.Rebirth:InvokeServer()
        if ok then
            Effects.Flash(Color3.fromRGB(150, 90, 230), 0.5)
            if type(result) == "table" then
                Effects.Popup("🌟 REBIRTH! +" .. (result.gained or 0) .. " prestige", Color3.fromRGB(220, 180, 255))
            end
            Sounds.Play("rebirth", 0.7)
            refresh()
        end
    end)

    rebirthPanel = panel
    Panels.Register("Rebirth", function() rebirthOpen = false; panel.Visible = false end)
    toggleBtn.MouseButton1Click:Connect(function() RebirthUI.Toggle() end)
end

function RebirthUI.Toggle()
    if not rebirthPanel then return end
    rebirthOpen = not rebirthOpen
    rebirthPanel.Visible = rebirthOpen
    if rebirthOpen then Panels.CloseOthers("Rebirth"); refresh() end
end

return RebirthUI
