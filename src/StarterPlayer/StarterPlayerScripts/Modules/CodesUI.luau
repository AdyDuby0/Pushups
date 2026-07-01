-- Promo code redemption. A small 🎁 Codes button opens a centered panel with
-- a text field and a Redeem button.

local Panels     = require(script.Parent:WaitForChild("Panels"))
local Responsive = require(script.Parent:WaitForChild("Responsive"))

local CodesUI = {}
local RF_ref
local codesPanel
local codesOpen = false

local function corner(inst, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 6); c.Parent = inst
end

function CodesUI.Init(playerGui, initData, RF)
    RF_ref = RF

    local gui = Instance.new("ScreenGui")
    gui.Name = "CodesUI"; gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = playerGui

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 120, 0, 34)
    toggleBtn.Position = UDim2.new(0, 8, 0, 64)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Text = "🎁 Codes"
    toggleBtn.TextColor3 = Color3.fromRGB(190, 255, 190)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextScaled = true
    toggleBtn.Parent = gui
    corner(toggleBtn, 6)

    local panel = Instance.new("Frame")
    panel.Name = "CodesPanel"
    panel.Size = UDim2.new(0, 420, 0, 260)
    panel.Position = UDim2.new(0.5, 0, 0.5, 0)
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.BackgroundColor3 = Color3.fromRGB(10, 14, 12)
    panel.BackgroundTransparency = 0.05
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Parent = gui
    corner(panel, 10)
    Responsive.Fit(panel, 420, 260)

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 42); header.BorderSizePixel = 0
    header.BackgroundColor3 = Color3.fromRGB(25, 60, 30); header.Parent = panel
    corner(header, 10)
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -50, 1, 0); title.Position = UDim2.new(0, 12, 0, 0)
    title.BackgroundTransparency = 1; title.Text = "🎁  REDEEM CODE"
    title.TextColor3 = Color3.fromRGB(190, 255, 190); title.Font = Enum.Font.GothamBold
    title.TextScaled = true; title.TextXAlignment = Enum.TextXAlignment.Left; title.Parent = header

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 34, 0, 34); closeBtn.Position = UDim2.new(1, -38, 0, 4)
    closeBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 40); closeBtn.BorderSizePixel = 0
    closeBtn.Text = "✕"; closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextScaled = true; closeBtn.Parent = header
    corner(closeBtn, 6)
    closeBtn.MouseButton1Click:Connect(function() codesOpen = false; panel.Visible = false end)

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, -24, 0, 46); input.Position = UDim2.new(0, 12, 0, 64)
    input.BackgroundColor3 = Color3.fromRGB(22, 26, 24); input.BorderSizePixel = 0
    input.PlaceholderText = "Enter code…"; input.Text = ""
    input.TextColor3 = Color3.fromRGB(235, 245, 235); input.PlaceholderColor3 = Color3.fromRGB(110, 130, 110)
    input.Font = Enum.Font.GothamBold; input.TextScaled = true; input.ClearTextOnFocus = false
    input.Parent = panel
    corner(input, 6)

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -24, 0, 30); status.Position = UDim2.new(0, 12, 0, 170)
    status.BackgroundTransparency = 1; status.Text = ""
    status.TextColor3 = Color3.fromRGB(150, 230, 160); status.Font = Enum.Font.Gotham
    status.TextScaled = true; status.Parent = panel

    local redeem = Instance.new("TextButton")
    redeem.Size = UDim2.new(1, -24, 0, 46); redeem.Position = UDim2.new(0, 12, 0, 118)
    redeem.BackgroundColor3 = Color3.fromRGB(40, 130, 70); redeem.BorderSizePixel = 0
    redeem.Text = "Redeem"; redeem.TextColor3 = Color3.fromRGB(255, 255, 255)
    redeem.Font = Enum.Font.GothamBold; redeem.TextScaled = true; redeem.Parent = panel
    corner(redeem, 6)
    redeem.MouseButton1Click:Connect(function()
        local code = input.Text
        if #code == 0 then return end
        local ok, result = RF_ref.RedeemCode:InvokeServer(code)
        if ok then
            status.Text = "✓ " .. ((type(result) == "table" and result.msg) or "Reward granted!")
            status.TextColor3 = Color3.fromRGB(150, 230, 160)
            input.Text = ""
        else
            status.Text = "✗ " .. tostring(result)
            status.TextColor3 = Color3.fromRGB(255, 130, 130)
        end
    end)

    codesPanel = panel
    Panels.Register("Codes", function() codesOpen = false; panel.Visible = false end)
    toggleBtn.MouseButton1Click:Connect(function() CodesUI.Toggle() end)
end

function CodesUI.Toggle()
    if not codesPanel then return end
    codesOpen = not codesOpen
    codesPanel.Visible = codesOpen
    if codesOpen then Panels.CloseOthers("Codes") end
end

return CodesUI
