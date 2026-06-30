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

local Lighting = game:GetService("Lighting")

local WorldBuilder = {}

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

-- ── Drill (front-right corner of the plot) ──────────────────────────────────
local function buildDrill(plot, plotCF)
    local lx, lz = 13, 6
    local ORANGE = Color3.fromRGB(255, 170, 80)

    local housing = place(plot, plotCF, CFrame.new(lx, 1.5, lz), {
        Name = "Drill", Size = Vector3.new(5.5, 3, 5.5),
        Color = Color3.fromRGB(46, 46, 60), Material = Enum.Material.Metal,
    })
    housing:SetAttribute("StationType", "Drill")
    addPrompt(housing, "Open", "Drill")

    for _, dx in ipairs({ -2, 2 }) do
        place(plot, plotCF, CFrame.new(lx + dx, 5, lz), {
            Name = "DrillLeg", Size = Vector3.new(0.5, 7, 0.5),
            Color = Color3.fromRGB(70, 70, 88), Material = Enum.Material.Metal, CanCollide = false,
        })
    end
    place(plot, plotCF, CFrame.new(lx, 8.6, lz), {
        Name = "DrillTop", Size = Vector3.new(5, 0.8, 1.4),
        Color = Color3.fromRGB(70, 70, 88), Material = Enum.Material.Metal, CanCollide = false,
    })
    place(plot, plotCF, CFrame.new(lx, 4.2, lz) * CFrame.Angles(0, 0, math.rad(90)), {
        Name = "DrillBit", Shape = Enum.PartType.Cylinder, Size = Vector3.new(5.5, 1.3, 1.3),
        Color = Color3.fromRGB(120, 120, 140), Material = Enum.Material.Metal, CanCollide = false,
    })
    place(plot, plotCF, CFrame.new(lx, 3.2, lz), {
        Name = "DrillGlow", Shape = Enum.PartType.Ball, Size = Vector3.new(1.6, 1.6, 1.6),
        Color = ORANGE, Material = Enum.Material.Neon, CanCollide = false,
    })

    labelBillboard(housing, 6, "⛏ DRILL", "hold [E]", ORANGE)
end

-- ── Crafting machine (front-left corner) ─────────────────────────────────────
local function buildCraftingStation(plot, plotCF)
    local lx, lz = -13, 6
    local CYAN = Color3.fromRGB(100, 220, 255)

    -- workbench base (the station body)
    local bench = place(plot, plotCF, CFrame.new(lx, 1.5, lz), {
        Name = "Station_Crafting", Size = Vector3.new(5.5, 3, 4),
        Color = Color3.fromRGB(26, 32, 44), Material = Enum.Material.DiamondPlate,
    })
    bench:SetAttribute("StationType", "Crafting")
    addPrompt(bench, "Open", "Crafting")

    -- back panel + glowing fabricator core
    place(plot, plotCF, CFrame.new(lx, 4.2, lz - 1.6), {
        Name = "FabPanel", Size = Vector3.new(5.5, 4.6, 0.5),
        Color = Color3.fromRGB(38, 44, 58), Material = Enum.Material.Metal, CanCollide = false,
    })
    place(plot, plotCF, CFrame.new(lx, 4.4, lz - 1.1), {
        Name = "FabCore", Shape = Enum.PartType.Ball, Size = Vector3.new(1.8, 1.8, 1.8),
        Color = CYAN, Material = Enum.Material.Neon, CanCollide = false,
    })
    -- gantry arm over the bench
    place(plot, plotCF, CFrame.new(lx, 6.2, lz - 0.4), {
        Name = "FabArm", Size = Vector3.new(0.5, 0.5, 2.6),
        Color = Color3.fromRGB(70, 80, 96), Material = Enum.Material.Metal, CanCollide = false,
    })
    place(plot, plotCF, CFrame.new(lx, 5.4, lz + 0.7), {
        Name = "FabHead", Size = Vector3.new(1.2, 1, 1),
        Color = Color3.fromRGB(90, 100, 120), Material = Enum.Material.Metal, CanCollide = false,
    })
    -- two gear cogs on the bench top
    for _, dx in ipairs({ -1.7, 1.7 }) do
        place(plot, plotCF, CFrame.new(lx + dx, 3.3, lz + 0.9) * CFrame.Angles(math.rad(90), 0, 0), {
            Name = "FabGear", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.5, 1.6, 1.6),
            Color = Color3.fromRGB(120, 130, 150), Material = Enum.Material.Metal, CanCollide = false,
        })
    end

    labelBillboard(bench, 6, "🔧 CRAFTING", "hold [E]", CYAN)
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

local function buildStationPillar(model, pos, stationType, title, subtitle, color)
    local base = part(model, {
        Name = "Station_" .. stationType, Size = Vector3.new(5, 4, 5),
        Position = pos + Vector3.new(0, 2, 0),
        Color = Color3.fromRGB(24, 26, 40), Material = Enum.Material.Metal,
    })
    base:SetAttribute("StationType", stationType)
    part(model, {
        Name = "StationTop", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 5.2, 5.2),
        CFrame = CFrame.new(pos + Vector3.new(0, 4.3, 0)) * CFrame.Angles(0, 0, math.rad(90)),
        Color = color, Material = Enum.Material.Neon, CanCollide = false,
    })
    addPrompt(base, "Open", stationType)
    labelBillboard(base, 4.6, title, subtitle, color)
end

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

    -- Gem Exchange robot vendor at the center (on the pad)
    local PURPLE = Color3.fromRGB(255, 170, 90)
    local torso = part(model, {
        Name = "VendorTorso", Size = Vector3.new(3.4, 4, 2),
        Position = CENTER + Vector3.new(0, HUB_TOP + 2, 0),
        Color = Color3.fromRGB(60, 60, 85), Material = Enum.Material.Metal,
    })
    torso:SetAttribute("StationType", "GemMarket")
    addPrompt(torso, "Sell Gems", "Gem Exchange")
    part(model, {
        Name = "VendorHead", Size = Vector3.new(2.4, 2, 2.2),
        Position = CENTER + Vector3.new(0, HUB_TOP + 5, 0),
        Color = Color3.fromRGB(75, 75, 105), Material = Enum.Material.Metal,
    })
    part(model, {
        Name = "VendorVisor", Size = Vector3.new(2.0, 0.7, 0.4),
        Position = CENTER + Vector3.new(0, HUB_TOP + 5.1, -1.05),
        Color = PURPLE, Material = Enum.Material.Neon, CanCollide = false,
    })
    local light = Instance.new("PointLight")
    light.Color = PURPLE; light.Range = 18; light.Brightness = 1.6; light.Parent = torso
    labelBillboard(torso, 7, "💹 GEM EXCHANGE", "hold [E]", PURPLE)

    -- Market + Shop pillars flanking the vendor
    buildStationPillar(model, CENTER + Vector3.new(-13, HUB_TOP, 8), "Market", "💱 MARKET", "hold [E]", Color3.fromRGB(130, 255, 130))
    buildStationPillar(model, CENTER + Vector3.new(13, HUB_TOP, 8),  "Shop",   "🛒 SHOP",   "hold [E]", Color3.fromRGB(200, 130, 255))

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
        buildDrill(plot, cf)
        buildCraftingStation(plot, cf)
        signLabels[i] = buildSign(plot, cf, i)

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

return WorldBuilder
