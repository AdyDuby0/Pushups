-- Builds and places a physical Power Core object on each player's plot.
-- The model is purely cosmetic + a proximity anchor: the client watches the
-- distance to the core tagged with its own UserId and opens the Power Core
-- menu when the player walks up to it.
--
-- Cores live in workspace.PowerCores. Each core part carries an
-- "OwnerUserId" attribute so the client only reacts to its own core.

local RunService = game:GetService("RunService")

local PowerCoreModel = {}
local cores = {}   -- userId -> Model

local function ensureFolder()
    local folder = workspace:FindFirstChild("PowerCores")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "PowerCores"
        folder.Parent = workspace
    end
    return folder
end

-- Where to drop the core: a few studs in front of the plot's Spawn pad so the
-- player lands next to it rather than inside it.
local function coreCFrame(plot)
    local spawn = plot:FindFirstChild("Spawn")
    if spawn and spawn:IsA("BasePart") then
        return spawn.CFrame * CFrame.new(0, 0, -8)
    end
    -- Fallback: pivot of the plot model, lifted up a little
    local cf = plot:GetPivot()
    return cf + Vector3.new(0, 3, 0)
end

function PowerCoreModel.Spawn(player, plot)
    if not plot then return end
    PowerCoreModel.Despawn(player)

    local folder = ensureFolder()
    local baseCF = coreCFrame(plot)

    local model = Instance.new("Model")
    model.Name = "Core_" .. player.UserId

    -- Pedestal
    local pedestal = Instance.new("Part")
    pedestal.Name         = "Pedestal"
    pedestal.Shape        = Enum.PartType.Cylinder
    pedestal.Size         = Vector3.new(1.6, 6, 6)
    pedestal.CFrame       = baseCF * CFrame.new(0, 0.8, 0) * CFrame.Angles(0, 0, math.rad(90))
    pedestal.Anchored     = true
    pedestal.Material     = Enum.Material.Metal
    pedestal.Color        = Color3.fromRGB(40, 40, 60)
    pedestal.TopSurface   = Enum.SurfaceType.Smooth
    pedestal.BottomSurface = Enum.SurfaceType.Smooth
    pedestal.Parent       = model

    -- Floating energy crystal — this is the proximity anchor
    local crystal = Instance.new("Part")
    crystal.Name         = "PowerCore"
    crystal.Shape        = Enum.PartType.Ball
    crystal.Size         = Vector3.new(4, 4, 4)
    crystal.CFrame       = baseCF * CFrame.new(0, 5, 0)
    crystal.Anchored     = true
    crystal.CanCollide   = false
    crystal.Material     = Enum.Material.Neon
    crystal.Color        = Color3.fromRGB(150, 90, 255)
    crystal:SetAttribute("OwnerUserId", player.UserId)
    crystal.Parent       = model

    local light = Instance.new("PointLight")
    light.Color     = Color3.fromRGB(170, 110, 255)
    light.Range     = 18
    light.Brightness = 4
    light.Parent    = crystal

    -- Floating name tag with a hint
    local billboard = Instance.new("BillboardGui")
    billboard.Name          = "CoreLabel"
    billboard.Size          = UDim2.new(0, 220, 0, 56)
    billboard.StudsOffset   = Vector3.new(0, 4, 0)
    billboard.AlwaysOnTop   = true
    billboard.MaxDistance   = 60
    billboard.Parent        = crystal

    local title = Instance.new("TextLabel")
    title.Size                 = UDim2.new(1, 0, 0.6, 0)
    title.BackgroundTransparency = 1
    title.Text                 = "⚡ POWER CORE"
    title.TextColor3           = Color3.fromRGB(200, 150, 255)
    title.TextStrokeTransparency = 0.4
    title.Font                 = Enum.Font.GothamBold
    title.TextScaled           = true
    title.Parent               = billboard

    local hint = Instance.new("TextLabel")
    hint.Size                 = UDim2.new(1, 0, 0.4, 0)
    hint.Position             = UDim2.new(0, 0, 0.6, 0)
    hint.BackgroundTransparency = 1
    hint.Text                 = "walk up to open"
    hint.TextColor3           = Color3.fromRGB(180, 180, 210)
    hint.TextStrokeTransparency = 0.5
    hint.Font                 = Enum.Font.Gotham
    hint.TextScaled           = true
    hint.Parent               = billboard

    model.PrimaryPart = crystal
    model.Parent = folder
    cores[player.UserId] = { model = model, crystal = crystal, baseCF = baseCF }
end

function PowerCoreModel.Despawn(player)
    local entry = cores[player.UserId]
    if entry then
        if entry.model then entry.model:Destroy() end
        cores[player.UserId] = nil
    end
end

-- Gentle floating + spin animation for all live cores.
local started = false
function PowerCoreModel.StartAnimation()
    if started then return end
    started = true
    task.spawn(function()
        while true do
            RunService.Heartbeat:Wait()
            local t = os.clock()
            for _, entry in pairs(cores) do
                local crystal = entry.crystal
                if crystal and crystal.Parent then
                    local bob = math.sin(t * 1.5) * 0.6
                    crystal.CFrame = entry.baseCF
                        * CFrame.new(0, 5 + bob, 0)
                        * CFrame.Angles(0, t * 0.8, 0)
                end
            end
        end
    end)
end

return PowerCoreModel
