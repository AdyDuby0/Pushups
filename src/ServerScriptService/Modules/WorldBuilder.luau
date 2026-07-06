-- Procedurally builds the playable world so everything syncs through Rojo.
--
-- Layout: 6 plots arranged in a ring, each rotated so its entrance faces the
-- middle. The middle holds a central hub with the Market, Shop and Gem Exchange.
--
-- Each plot has:
--   • a single creamy-grey base block (lifted slightly to avoid z-fighting)
--   • a fence with a doorway facing the center
--   • a Spawn pad (PlotManager landing; PowerCoreModel drops the core in front)
--   • a DRILL (replaces the old gem nodes) — clickable, opens the Drill menu
--   • a CRAFTING station next to the drill
--   • a plot sign
-- Lighting keeps the dark floor mist but uses ShadowMap so it doesn't flicker.

local Lighting   = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local StationModels = require(script.Parent.StationModels)

local WorldBuilder = {}

local drillBits = {}   -- plotIndex -> { parts = { { part, rest }, ... } }
local drillSpin = {}   -- plotIndex -> bool (spin while the owner is mining)

-- ── Layout constants ────────────────────────────────────────────────────────
local GROUND_Y     = 0
local PLOT_SIZE    = 52
local HALF         = PLOT_SIZE / 2
local TILE_F       = 13          -- fence post spacing
local RING_RADIUS  = 112         -- distance from world center to each plot center
local CENTER       = Vector3.new(0, GROUND_Y, 0)

local CREAM    = Color3.fromRGB(206, 201, 190)   -- creamy-grey base block
local FENCE_C  = Color3.fromRGB(40, 44, 60)
local FENCE_T  = Color3.fromRGB(120, 200, 255)

-- Plot CFrame for index 1..6: positioned on the ring, local +Z faces the center
local function plotCFrame(i)
    local angle = math.rad((i - 1) * 60)
    local pc = Vector3.new(math.cos(angle) * RING_RADIUS, GROUND_Y, math.sin(angle) * RING_RADIUS)
    -- lookAt makes -Z point toward `target`; aim it outward so +Z faces center
    return CFrame.lookAt(pc, pc + (pc - CENTER))
end

-- ── Part helpers ────────────────────────────────────────────────────────────
-- World-space part
local function part(parent, props)
    local p = Instance.new("Part")
    p.Anchored = true; p.CanCollide = true
    p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
    p.CastShadow = false
    for k, v in pairs(props) do p[k] = v end
    p.Parent = parent
    return p
end

-- Part placed in a plot's local frame: CFrame = plotCF * lcf
local function place(parent, plotCF, lcf, props)
    local p = Instance.new("Part")
    p.Anchored = true; p.CanCollide = true
    p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
    p.CastShadow = false
    for k, v in pairs(props) do p[k] = v end
    p.CFrame = plotCF * lcf
    p.Parent = parent
    return p
end

local function billboard(adornee, offsetY, h)
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 200, 0, h or 56)
    bb.StudsOffset = Vector3.new(0, offsetY, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 70
    bb.Adornee = adornee
    bb.Parent = adornee
    return bb
end

local function labelBillboard(adornee, offsetY, title, subtitle, color)
    local bb = billboard(adornee, offsetY, 58)
    local t1 = Instance.new("TextLabel")
    t1.Size = UDim2.new(1, 0, 0.55, 0); t1.BackgroundTransparency = 1
    t1.Text = title; t1.Font = Enum.Font.GothamBold; t1.TextScaled = true
    t1.TextColor3 = color; t1.TextStrokeTransparency = 0.3; t1.Parent = bb
    local t2 = Instance.new("TextLabel")
    t2.Size = UDim2.new(1, 0, 0.4, 0); t2.Position = UDim2.new(0, 0, 0.58, 0)
    t2.BackgroundTransparency = 1; t2.Text = subtitle
    t2.Font = Enum.Font.Gotham; t2.TextScaled = true
    t2.TextColor3 = Color3.fromRGB(205, 205, 222); t2.TextStrokeTransparency = 0.4; t2.Parent = bb
    return bb
end

-- Hold-E ProximityPrompt (replaces ClickDetectors)
local function addPrompt(parentPart, actionText, objectText)
    local pp = Instance.new("ProximityPrompt")
    pp.ActionText           = actionText
    pp.ObjectText           = objectText
    pp.KeyboardKeyCode      = Enum.KeyCode.E
    pp.HoldDuration         = 0.3
    pp.MaxActivationDistance = 12
    pp.RequiresLineOfSight  = false
    pp.Parent               = parentPart
    return pp
end

-- Steps rising toward a platform. `baseCF` sits at the platform's front edge on
-- the ground; steps extend out in +Z and get taller as they approach (−Z side).
local function buildSteps(parent, baseCF, topY, count, width, color)
    for i = 1, count do
        local h = (i / count) * topY
        local p = Instance.new("Part")
        p.Anchored = true; p.TopSurface = Enum.SurfaceType.Smooth
        p.BottomSurface = Enum.SurfaceType.Smooth; p.CastShadow = false
        p.Size = Vector3.new(width, h, 1.2)
        p.Color = color; p.Material = Enum.Material.SmoothPlastic
        p.CFrame = baseCF * CFrame.new(0, h / 2, (count - i) * 1.2)
        p.Parent = parent
    end
end

-- ── Base plate (single creamy-grey block) ───────────────────────────────────
local function buildBase(plot, plotCF)
    -- top at GROUND_Y + 0.05 (lifted a hair so it never z-fights the ground)
    place(plot, plotCF, CFrame.new(0, -0.95, 0), {
        Name = "Base",
        Size = Vector3.new(PLOT_SIZE, 2, PLOT_SIZE),
        Color = CREAM,
        Material = Enum.Material.SmoothPlastic,
    })
end

-- ── Fence (doorway on the inward +Z side) ───────────────────────────────────
local function buildFence(plot, plotCF)
    local POST_H = 5
    local function post(x, z)
        place(plot, plotCF, CFrame.new(x, POST_H / 2, z), {
            Name = "FencePost", Size = Vector3.new(0.6, POST_H, 0.6),
            Color = FENCE_C, Material = Enum.Material.Metal,
        })
    end
    local function rail(lx, lz, sx, sz)
        place(plot, plotCF, CFrame.new(lx, POST_H - 1.2, lz), {
            Name = "FenceRail", Size = Vector3.new(sx, 0.3, sz),
            Color = FENCE_T, Material = Enum.Material.Neon, CanCollide = false,
        })
    end

    for x = -HALF, HALF, TILE_F do
        post(x, -HALF)                       -- outward (back) edge
        if math.abs(x) > 1 then post(x, HALF) end  -- inward edge: skip center for the doorway
    end
    for z = -HALF, HALF, TILE_F do
        post(-HALF, z)
        post(HALF, z)
    end

    rail(0, -HALF, PLOT_SIZE, 0.3)           -- back
    rail(-HALF, 0, 0.3, PLOT_SIZE)           -- left
    rail(HALF, 0, 0.3, PLOT_SIZE)            -- right
    local seg = HALF - TILE_F
    rail(-(HALF - seg / 2), HALF, seg, 0.3)  -- front, left of doorway
    rail(HALF - seg / 2, HALF, seg, 0.3)     -- front, right of doorway
end

-- ── Spawn pad ───────────────────────────────────────────────────────────────
local function buildSpawn(plot, plotCF)
    local spawn = place(plot, plotCF, CFrame.new(0, 0.6, HALF - 6), {
        Name = "Spawn", Size = Vector3.new(10, 1, 10),
        Color = Color3.fromRGB(60, 70, 110), Material = Enum.Material.SmoothPlastic, Transparency = 0.1,
    })
    place(plot, plotCF, CFrame.new(0, 1.1, HALF - 6) * CFrame.Angles(0, 0, math.rad(90)), {
        Name = "SpawnGlow", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 9, 9),
        Color = FENCE_T, Material = Enum.Material.Neon, CanCollide = false,
    })
    return spawn
end

-- ── Drill (front-right corner; detailed rig lives in StationModels) ──────────
local function buildDrill(plot, plotCF)
    -- faces the plot doorway (+Z)
    local cf = plotCF * CFrame.new(13, 0, 6) * CFrame.Angles(0, math.rad(180), 0)
    return StationModels.BuildDrill(plot, cf)
end

-- ── Crafting fabricator (front-left corner; model in StationModels) ──────────
local function buildCraftingStation(plot, plotCF)
    local cf = plotCF * CFrame.new(-13, 0, 6) * CFrame.Angles(0, math.rad(180), 0)
    StationModels.BuildCrafting(plot, cf)
end

-- ── Power Core platform (back-center, raised, with steps) ────────────────────
local function buildCorePlatform(plot, plotCF)
    local lz, topY, radius = -8, 2.0, 4.6
    place(plot, plotCF, CFrame.new(0, topY / 2, lz) * CFrame.Angles(0, 0, math.rad(90)), {
        Name = "CorePad", Shape = Enum.PartType.Cylinder, Size = Vector3.new(topY, radius * 2, radius * 2),
        Color = Color3.fromRGB(34, 30, 50), Material = Enum.Material.SmoothPlastic,
    })
    place(plot, plotCF, CFrame.new(0, topY + 0.06, lz) * CFrame.Angles(0, 0, math.rad(90)), {
        Name = "CoreRing", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, radius * 2 + 0.7, radius * 2 + 0.7),
        Color = Color3.fromRGB(170, 90, 255), Material = Enum.Material.Neon, CanCollide = false,
    })
    -- steps up to the platform from the front (+Z)
    buildSteps(plot, plotCF * CFrame.new(0, 0, lz + radius), topY, 3, 8, Color3.fromRGB(40, 36, 56))

    -- invisible anchor PowerCoreModel uses to position the core
    place(plot, plotCF, CFrame.new(0, topY, lz), {
        Name = "CoreSpot", Size = Vector3.new(1, 1, 1), Transparency = 1, CanCollide = false,
    })
end

-- ── Workshop console (back-right; model in StationModels) ────────────────────
local function buildWorkshop(plot, plotCF)
    -- faces toward the middle of the plot
    local cf = plotCF * CFrame.lookAt(Vector3.new(13, 0, -6), Vector3.new(0, 0, 4))
    StationModels.BuildWorkshop(plot, cf)
end

-- ── Plot sign ───────────────────────────────────────────────────────────────
local function buildSign(plot, plotCF, index)
    place(plot, plotCF, CFrame.new(0, 3, -(HALF + 1)) * CFrame.Angles(0, 0, math.rad(90)), {
        Name = "SignPole", Shape = Enum.PartType.Cylinder, Size = Vector3.new(6, 0.4, 0.4),
        Color = FENCE_C, Material = Enum.Material.Metal, CanCollide = false,
    })
    local board = place(plot, plotCF, CFrame.new(0, 6.4, -(HALF + 1)), {
        Name = "SignBoard", Size = Vector3.new(10, 2.4, 0.4),
        Color = Color3.fromRGB(16, 18, 30), Material = Enum.Material.SmoothPlastic, CanCollide = false,
    })
    local sg = Instance.new("SurfaceGui")
    sg.Face = Enum.NormalId.Back; sg.CanvasSize = Vector2.new(400, 100); sg.Parent = board
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0); lbl.BackgroundTransparency = 1
    lbl.Text = "⚡ PLOT " .. index; lbl.Font = Enum.Font.GothamBold
    lbl.TextColor3 = FENCE_T; lbl.TextScaled = true; lbl.Name = "PlotLabel"; lbl.Parent = sg
    return lbl
end

-- ── Central hub: Market + Shop + Gem Exchange (NPC) on a raised, stepped pad ──
local HUB_TOP    = 2.5
local HUB_RADIUS = 26

local function buildCenterHub()
    local model = Instance.new("Model"); model.Name = "GemExchange"

    -- raised platform
    part(model, {
        Name = "HubPad", Shape = Enum.PartType.Cylinder, Size = Vector3.new(HUB_TOP, HUB_RADIUS * 2, HUB_RADIUS * 2),
        CFrame = CFrame.new(CENTER + Vector3.new(0, HUB_TOP / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
        Color = Color3.fromRGB(34, 32, 46), Material = Enum.Material.SmoothPlastic,
    })
    part(model, {
        Name = "HubRing", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.5, HUB_RADIUS * 2 + 1, HUB_RADIUS * 2 + 1),
        CFrame = CFrame.new(CENTER + Vector3.new(0, HUB_TOP + 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90)),
        Color = Color3.fromRGB(255, 170, 90), Material = Enum.Material.Neon, CanCollide = false,
    })
    -- steps up to the pad on four sides
    for _, ang in ipairs({ 0, 90, 180, 270 }) do
        local baseCF = CFrame.new(CENTER) * CFrame.Angles(0, math.rad(ang), 0) * CFrame.new(0, 0, HUB_RADIUS)
        buildSteps(model, baseCF, HUB_TOP, 3, 10, Color3.fromRGB(40, 38, 54))
    end

    -- Exchange booth at the center, Market stall and Shop vending machine
    -- flanking it — all facing outward toward the steps (models in StationModels)
    StationModels.BuildExchange(model,
        CFrame.new(CENTER + Vector3.new(0, HUB_TOP, 0)) * CFrame.Angles(0, math.rad(180), 0))

    local marketPos = CENTER + Vector3.new(-14, HUB_TOP, 7)
    StationModels.BuildMarket(model,
        CFrame.lookAt(marketPos, marketPos + Vector3.new(-14, 0, 7)))

    local shopPos = CENTER + Vector3.new(14, HUB_TOP, 7)
    StationModels.BuildShop(model,
        CFrame.lookAt(shopPos, shopPos + Vector3.new(14, 0, 7)))

    model.Parent = workspace
    return model
end

-- ── Lighting (keep the dark floor mist, but no flicker) ─────────────────────
local function polishLighting()
    pcall(function() Lighting.Technology = Enum.Technology.ShadowMap end)
    Lighting.ClockTime          = 17.6           -- low sun for the moody look
    Lighting.GeographicLatitude  = 30
    Lighting.Brightness          = 2
    Lighting.EnvironmentDiffuseScale  = 0.4
    Lighting.EnvironmentSpecularScale = 0.4
    Lighting.OutdoorAmbient     = Color3.fromRGB(95, 98, 120)
    Lighting.Ambient            = Color3.fromRGB(55, 56, 72)

    local bloom = Lighting:FindFirstChild("WorldBloom")
    if not bloom then bloom = Instance.new("BloomEffect"); bloom.Name = "WorldBloom"; bloom.Parent = Lighting end
    bloom.Intensity = 0.3; bloom.Size = 18; bloom.Threshold = 1.5

    -- the dark mist that hangs on the floor
    local atmo = Lighting:FindFirstChild("WorldAtmosphere")
    if not atmo then atmo = Instance.new("Atmosphere"); atmo.Name = "WorldAtmosphere"; atmo.Parent = Lighting end
    atmo.Density = 0.36
    atmo.Offset  = 0.1
    atmo.Haze    = 1.8
    atmo.Color   = Color3.fromRGB(170, 178, 205)
    atmo.Decay   = Color3.fromRGB(70, 78, 110)
end

-- ── Public build ────────────────────────────────────────────────────────────
local signLabels = {}

function WorldBuilder.Build()
    for _, name in ipairs({ "Plots", "GemNodes", "WorldGround", "GemExchange" }) do
        local existing = workspace:FindFirstChild(name)
        if existing then existing:Destroy() end
    end

    -- ground baseplate (big enough for the ring)
    part(workspace, {
        Name = "WorldGround", Size = Vector3.new(420, 4, 420),
        Position = Vector3.new(0, GROUND_Y - 3, 0),
        Color = Color3.fromRGB(22, 24, 34), Material = Enum.Material.Slate,
    })

    local plotsFolder = Instance.new("Folder"); plotsFolder.Name = "Plots"; plotsFolder.Parent = workspace

    for i = 1, 6 do
        local cf = plotCFrame(i)
        local plot = Instance.new("Model"); plot.Name = "Plot" .. i; plot.Parent = plotsFolder

        buildBase(plot, cf)
        buildFence(plot, cf)
        local spawn = buildSpawn(plot, cf)
        buildCorePlatform(plot, cf)
        local _, auger = buildDrill(plot, cf)
        buildCraftingStation(plot, cf)
        buildWorkshop(plot, cf)
        signLabels[i] = buildSign(plot, cf, i)

        drillBits[i] = { parts = auger }
        drillSpin[i] = false

        plot.PrimaryPart = spawn
    end

    buildCenterHub()
    polishLighting()
    return plotsFolder
end

function WorldBuilder.SetPlotOwner(index, name)
    local lbl = signLabels[index]
    if lbl then
        lbl.Text = name and ("⚡ " .. name .. "'s Plot") or ("⚡ PLOT " .. index)
    end
end

-- Spin the plot's drill bit while its owner is mining
function WorldBuilder.SetDrillSpinning(index, on)
    if drillSpin[index] ~= nil then drillSpin[index] = on and true or false end
end

-- Drives the auger spin every frame for plots flagged as mining. Each flight
-- blade is centered on the shaft axis, so spinning each about its own Y axis
-- rotates the whole helix coherently.
RunService.Heartbeat:Connect(function()
    local a = os.clock() * 9   -- spin speed
    for idx, on in pairs(drillSpin) do
        local d = drillBits[idx]
        if on and d and d.parts then
            for _, e in ipairs(d.parts) do
                if e.part.Parent then
                    e.part.CFrame = e.rest * CFrame.Angles(0, a, 0)
                end
            end
        end
    end
end)

return WorldBuilder
