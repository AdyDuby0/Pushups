-- Keeps a fixed-size panel fitting on any screen (esp. mobile). Adds a UIScale
-- that shrinks the panel (and its children) so it never exceeds ~92% of the
-- viewport, while never scaling up past 1× on desktop.

local Responsive = {}

local camera = workspace.CurrentCamera

function Responsive.Fit(panel, baseW, baseH)
    local scale = panel:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
    scale.Parent = panel

    local function update()
        local cam = workspace.CurrentCamera
        if not cam then return end
        local vp = cam.ViewportSize
        if vp.X < 1 or vp.Y < 1 then return end
        scale.Scale = math.min(1, (vp.X * 0.94) / baseW, (vp.Y * 0.92) / baseH)
    end

    if camera then
        camera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
    end
    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        camera = workspace.CurrentCamera
        if camera then camera:GetPropertyChangedSignal("ViewportSize"):Connect(update) end
        update()
    end)
    update()
    return scale
end

return Responsive
