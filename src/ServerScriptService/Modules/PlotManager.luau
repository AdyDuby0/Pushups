-- Assigns each joining player to one of the 6 plot pads in workspace.
-- Plots must be named Plot1..Plot6 inside a folder called "Plots" in workspace.
-- Each Plot model needs a Part named "Spawn" that marks the teleport landing point.

local PlotManager = {}
local assignments = {}  -- userId -> plotIndex
local plots = {}        -- plotIndex -> Model

function PlotManager.Init()
    local folder = workspace:WaitForChild("Plots", 15)
    if not folder then
        warn("[PlotManager] 'Plots' folder not found in workspace")
        return
    end
    for i = 1, 6 do
        local plot = folder:WaitForChild("Plot" .. i, 5)
        if plot then
            plots[i] = plot
        else
            warn("[PlotManager] Plot" .. i .. " missing")
        end
    end
end

function PlotManager.Assign(player)
    for i = 1, 6 do
        local taken = false
        for _, idx in pairs(assignments) do
            if idx == i then taken = true; break end
        end
        if not taken and plots[i] then
            assignments[player.UserId] = i
            local spawn = plots[i]:FindFirstChild("Spawn")
            if spawn and player.Character then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
                end
            end
            return plots[i], i
        end
    end
    return nil, nil
end

function PlotManager.GetPlot(player)
    local idx = assignments[player.UserId]
    return plots[idx], idx
end

function PlotManager.Release(player)
    assignments[player.UserId] = nil
end

return PlotManager
