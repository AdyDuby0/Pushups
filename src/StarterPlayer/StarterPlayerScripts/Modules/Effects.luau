-- Screen juice: floating number pop-ups and full-screen flashes.

local TweenService = game:GetService("TweenService")

local Effects = {}
local container

function Effects.Init(playerGui)
    container = Instance.new("ScreenGui")
    container.Name = "Effects"
    container.ResetOnSpawn = false
    container.IgnoreGuiInset = true
    container.DisplayOrder = 50
    container.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    container.Parent = playerGui
end

-- Rising, fading text near the center of the screen
function Effects.Popup(text, color, atScale)
    if not container then return end
    local lbl = Instance.new("TextLabel")
    lbl.AnchorPoint = Vector2.new(0.5, 0.5)
    lbl.Position = UDim2.new(0.5, 0, atScale or 0.42, 0)
    lbl.Size = UDim2.new(0, 340, 0, 54)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = color or Color3.fromRGB(255, 230, 120)
    lbl.Font = Enum.Font.GothamBlack
    lbl.TextScaled = true
    lbl.TextStrokeTransparency = 0.3
    lbl.Parent = container

    local up = TweenService:Create(lbl, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = lbl.Position - UDim2.new(0, 0, 0.09, 0),
        TextTransparency = 1,
        TextStrokeTransparency = 1,
    })
    up:Play()
    up.Completed:Connect(function() lbl:Destroy() end)
end

-- Brief full-screen colour flash
function Effects.Flash(color, strength)
    if not container then return end
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 1, 0)
    f.BackgroundColor3 = color or Color3.fromRGB(255, 255, 255)
    f.BackgroundTransparency = 1 - (strength or 0.35)
    f.BorderSizePixel = 0
    f.ZIndex = 0
    f.Parent = container
    local t = TweenService:Create(f, TweenInfo.new(0.5), { BackgroundTransparency = 1 })
    t:Play()
    t.Completed:Connect(function() f:Destroy() end)
end

return Effects
