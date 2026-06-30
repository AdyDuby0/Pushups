-- Procedurally builds the playable world so everything syncs through Rojo
-- (no hand-placed parts needed in Studio).
--
-- For each of the 6 plots it creates:
--   • a green, blocky checkerboard base plate
--   • a fence around the perimeter with a front entrance gap
--   • a "Spawn" pad (PlotManager teleports players here; PowerCoreModel drops
--     the core just in front of it)
--   • three physical station pedestals (Market / Crafting / Shop) — clickable
--     buttons tagged with a StationType attribute that the client wires to UIs
--   • a row of gem-node crystals to mine (Crystite, Voidstone, Neutronium,
--     Singularity Core)
--   • a plot sign
-- Plus a ground baseplate and some sci-fi lighting polish.

local Lighting          = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GemTypes = require(ReplicatedStorage.Config.GemTypes)

local WorldBuilder = {}

-- ── Layout constants ────────────────────────────────────────────────────────
local PLOT_SIZE   = 56          -- square footprint (studs)
local HALF        = PLOT_SIZE / 2
local TILE        = 14          -- checkerboard tile size (4×4 grid)
local COL_SPACING = 80
local ROW_SPACING = 92
local GROUND_Y    = 0           -- top of base plates

local GRASS_A = Color3.fromRGB(74, 160, 64)
local GRASS_B = Color3.fromRGB(92, 184, 80)
local FENCE_C = Color3.fromRGB(40, 44, 60)
local FENCE_T = Color3.fromRGB(120, 200, 255)

-- Plot center for index 1..6 (3 columns × 2 rows)
local function plotOrigin(i)
    local col = (i - 1) % 3            -- 0,1,2
    local row = math.floor((i - 1) / 3) -- 0,1
    local x = (col - 1) * COL_SPACING
    local z = (row == 0) and -ROW_SPACING / 2 or ROW_SPACING / 2
    return Vector3.new(x, GROUND_Y, z)
end

-- ── Part helpers ────────────────────────────────────────────────────────────
local function part(parent, props)
    local p = Instance.new("Part")
    p.Anchored      = true
    p.CanCollide    = true
    p.TopSurface    = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    for k, v in pairs(props) do p[k] = v end
    p.Parent = parent
    return p
end

local function corner(inst, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 6); c.Parent = inst
end

local function billboard(adornee, offsetY, h)
    local bb = Instance.new("BillboardGui")
    bb.Size        = UDim2.new(0, 200, 0, h or 56)
    bb.StudsOffset = Vector3.new(0, offsetY, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 60
    bb.Adornee     = adornee
    bb.Parent      = adornee
    return bb
end

-- ── Base plate (green, blocky checkerboard) ─────────────────────────────────
local function buildBase(plot, origin)
    local n = math.floor(PLOT_SIZE / TILE)  -- 4
    for tx = 0, n - 1 do
        for tz = 0, n - 1 do
            local cx = origin.x + (tx - (n - 1) / 2) * TILE
            local cz = origin.z + (tz - (n - 1) / 2) * TILE
            part(plot, {
                Name     = "Tile",
                Size     = Vector3.new(TILE, 1, TILE),
                Position = Vector3.new(cx, GROUND_Y - 0.5, cz),
                Color    = ((tx + tz) % 2 == 0) and GRASS_A or GRASS_B,
                Material = Enum.Material.Grass,
            })
        end
    end
    -- Thin dark rim so the plot reads as a defined platform
    part(plot, {
        Name      = "Rim",
        Size      = Vector3.new(PLOT_SIZE + 2, 1.4, PLOT_SIZE + 2),
        Position  = Vector3.new(origin.x, GROUND_Y - 1.0, origin.z),
        Color     = Color3.fromRGB(28, 30, 42),
        Material   = Enum.Material.Slate,
        CanCollide = false,
    })
end

-- ── Fence around the perimeter with a front entrance gap (+Z side) ───────────
local function buildFence(plot, origin)
    local POST_H = 5
    local step   = TILE
    local function post(x, z)
        part(plot, {
            Name = "FencePost", Shape = Enum.PartType.Block,
            Size = Vector3.new(0.6, POST_H, 0.6),
            Position = Vector3.new(x, GROUND_Y + POST_H / 2, z),
            Color = FENCE_C, Material = Enum.Material.Metal,
        })
    end
    local function rail(x, z, len, horizontal)
        part(plot, {
            Name = "FenceRail",
            Size = horizontal and Vector3.new(len, 0.35, 0.35) or Vector3.new(0.35, 0.35, len),
            Position = Vector3.new(x, GROUND_Y + POST_H - 1.2, z),
            Color = FENCE_T, Material = Enum.Material.Neon,
            CanCollide = false,
        })
    end

    local minX, maxX = origin.x - HALF, origin.x + HALF
    local minZ, maxZ = origin.z - HALF, origin.z + HALF

    -- Posts along all four edges
    for x = minX, maxX, step do
        post(x, minZ)             -- back edge
        -- front edge: skip the center post to leave an entrance doorway
        if math.abs(x - origin.x) > 1 then post(x, maxZ) end
    end
    for z = minZ, maxZ, step do
        post(minX, z)
        post(maxX, z)
    end

    -- Glowing rails
    rail(origin.x, minZ, PLOT_SIZE, true)              -- back
    rail(minX, origin.z, PLOT_SIZE, false)             -- left
    rail(maxX, origin.z, PLOT_SIZE, false)             -- right
    -- Front rails on either side of the entrance gap
    local segLen = HALF - step
    rail(origin.x - (HALF - segLen / 2), maxZ, segLen, true)
    rail(origin.x + (HALF - segLen / 2), maxZ, segLen, true)
end

-- ── Spawn pad ───────────────────────────────────────────────────────────────
local function buildSpawn(plot, origin)
    local spawn = part(plot, {
        Name      = "Spawn",
        Size      = Vector3.new(10, 1, 10),
        Position  = Vector3.new(origin.x, GROUND_Y + 0.6, origin.z + 16),
        Color     = Color3.fromRGB(60, 70, 110),
        Material  = Enum.Material.SmoothPlastic,
        Transparency = 0.1,
    })
    -- glowing ring on the pad
    part(plot, {
        Name = "SpawnGlow", Shape = Enum.PartType.Cylinder,
        Size = Vector3.new(0.3, 9, 9),
        CFrame = CFrame.new(spawn.Position + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, 0, math.rad(90)),
        Color = FENCE_T, Material = Enum.Material.Neon, CanCollide = false,
    })
    return spawn
end

-- ── Station pedestal (clickable button → opens a UI panel on the client) ─────
local function buildStation(plot, pos, stationType, label, icon, themeColor)
    local base = part(plot, {
        Name      = "Station_" .. stationType,
        Size      = Vector3.new(5, 4, 5),
        Position  = pos + Vector3.new(0, 2, 0),
        Color     = Color3.fromRGB(24, 26, 40),
        Material  = Enum.Material.Metal,
    })
    base:SetAttribute("StationType", stationType)

    -- glowing top
    part(plot, {
        Name = "StationTop", Shape = Enum.PartType.Cylinder,
        Size = Vector3.new(0.6, 5.2, 5.2),
        CFrame = CFrame.new(pos + Vector3.new(0, 4.3, 0)) * CFrame.Angles(0, 0, math.rad(90)),
        Color = themeColor, Material = Enum.Material.Neon, CanCollide = false,
    })

    local light = Instance.new("PointLight")
    light.Color = themeColor; light.Range = 14; light.Brightness = 3
    light.Parent = base

    local cd = Instance.new("ClickDetector")
    cd.MaxActivationDistance = 16
    cd.Parent = base

    local bb = billboard(base, 4.6, 60)
    local t1 = Instance.new("TextLabel")
    t1.Size = UDim2.new(1, 0, 0.55, 0); t1.BackgroundTransparency = 1
    t1.Text = icon .. " " .. label; t1.Font = Enum.Font.GothamBold; t1.TextScaled = true
    t1.TextColor3 = themeColor; t1.TextStrokeTransparency = 0.3; t1.Parent = bb
    local t2 = Instance.new("TextLabel")
    t2.Size = UDim2.new(1, 0, 0.4, 0); t2.Position = UDim2.new(0, 0, 0.58, 0)
    t2.BackgroundTransparency = 1; t2.Text = "click to open"
    t2.Font = Enum.Font.Gotham; t2.TextScaled = true
    t2.TextColor3 = Color3.fromRGB(200, 200, 220); t2.TextStrokeTransparency = 0.4; t2.Parent = bb

    return base
end

local function buildStations(plot, origin)
    local backZ = origin.z - 20
    buildStation(plot, Vector3.new(origin.x - 15, GROUND_Y, backZ), "Market",   "Market",   "💱", Color3.fromRGB(130, 255, 130))
    buildStation(plot, Vector3.new(origin.x,      GROUND_Y, backZ), "Crafting", "Crafting", "🔧", Color3.fromRGB(100, 220, 255))
    buildStation(plot, Vector3.new(origin.x + 15, GROUND_Y, backZ), "Shop",     "Shop",     "🛒", Color3.fromRGB(200, 130, 255))
end

-- ── Gem nodes ───────────────────────────────────────────────────────────────
local function buildNode(folder, pos, gemType)
    local gd = GemTypes[gemType]
    if not gd then return end

    -- rocky base (decorative, no GemType so the client ignores it)
    part(folder, {
        Name = "NodeRock",
        Size = Vector3.new(4.2, 2, 4.2),
        Position = pos + Vector3.new(0, 1, 0),
        Color = Color3.fromRGB(40, 40, 52), Material = Enum.Material.Slate,
    })

    -- the mineable crystal (BasePart child of GemNodes with GemType attribute).
    -- Built from reliable primitives so it never depends on a remote mesh asset:
    -- a tall faceted shard + a smaller cross shard for a clustered crystal look.
    local crystal = part(folder, {
        Name = "Node_" .. gemType,
        Size = Vector3.new(2.4, 5.5, 2.4),
        CFrame = CFrame.new(pos + Vector3.new(0, 4, 0)) * CFrame.Angles(math.rad(8), math.rad(45), math.rad(6)),
        Color = gd.color, Material = Enum.Material.Neon, Transparency = 0.08,
    })
    crystal:SetAttribute("GemType", gemType)

    -- secondary shards (decorative, no GemType)
    part(folder, {
        Name = "NodeShard",
        Size = Vector3.new(1.6, 3.6, 1.6),
        CFrame = CFrame.new(pos + Vector3.new(1.3, 2.6, 0.4)) * CFrame.Angles(0, math.rad(30), math.rad(22)),
        Color = gd.color, Material = Enum.Material.Neon, Transparency = 0.12, CanCollide = false,
    })
    part(folder, {
        Name = "NodeShard",
        Size = Vector3.new(1.3, 2.8, 1.3),
        CFrame = CFrame.new(pos + Vector3.new(-1.2, 2.2, -0.5)) * CFrame.Angles(0, math.rad(15), math.rad(-20)),
        Color = gd.color, Material = Enum.Material.Neon, Transparency = 0.12, CanCollide = false,
    })

    local light = Instance.new("PointLight")
    light.Color = gd.color; light.Range = 12; light.Brightness = 2
    light.Parent = crystal

    local bb = billboard(crystal, 4, 52)
    local t1 = Instance.new("TextLabel")
    t1.Size = UDim2.new(1, 0, 0.6, 0); t1.BackgroundTransparency = 1
    t1.Text = gd.displayName; t1.Font = Enum.Font.GothamBold; t1.TextScaled = true
    t1.TextColor3 = gd.color; t1.TextStrokeTransparency = 0.35; t1.Parent = bb
    local t2 = Instance.new("TextLabel")
    t2.Size = UDim2.new(1, 0, 0.38, 0); t2.Position = UDim2.new(0, 0, 0.62, 0)
    t2.BackgroundTransparency = 1; t2.Text = "⛏ click to mine"
    t2.Font = Enum.Font.Gotham; t2.TextScaled = true
    t2.TextColor3 = Color3.fromRGB(210, 210, 230); t2.TextStrokeTransparency = 0.4; t2.Parent = bb
end

local function buildNodes(folder, origin)
    -- starter nodes along the left edge + one aspirational on the right
    local leftX = origin.x - 20
    buildNode(folder, Vector3.new(leftX, GROUND_Y, origin.z - 14), "Crystite")
    buildNode(folder, Vector3.new(leftX, GROUND_Y, origin.z),      "Voidstone")
    buildNode(folder, Vector3.new(leftX, GROUND_Y, origin.z + 14), "Neutronium")
    buildNode(folder, Vector3.new(origin.x + 20, GROUND_Y, origin.z), "SingularityCore")
end

-- ── Plot sign ───────────────────────────────────────────────────────────────
local function buildSign(plot, origin, index)
    local pole = part(plot, {
        Name = "SignPole", Shape = Enum.PartType.Cylinder,
        Size = Vector3.new(6, 0.4, 0.4),
        CFrame = CFrame.new(origin.x, GROUND_Y + 3, origin.z + HALF + 1) * CFrame.Angles(0, 0, math.rad(90)),
        Color = FENCE_C, Material = Enum.Material.Metal, CanCollide = false,
    })
    local board = part(plot, {
        Name = "SignBoard",
        Size = Vector3.new(10, 2.4, 0.4),
        Position = Vector3.new(origin.x, GROUND_Y + 6.4, origin.z + HALF + 1),
        Color = Color3.fromRGB(16, 18, 30), Material = Enum.Material.SmoothPlastic, CanCollide = false,
    })
    local sg = Instance.new("SurfaceGui")
    sg.Face = Enum.NormalId.Front; sg.CanvasSize = Vector2.new(400, 100)
    sg.Parent = board
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0); lbl.BackgroundTransparency = 1
    lbl.Text = "⚡ PLOT " .. index; lbl.Font = Enum.Font.GothamBold
    lbl.TextColor3 = FENCE_T; lbl.TextScaled = true
    lbl.Name = "PlotLabel"; lbl.Parent = sg
    return lbl
end

-- ── NPC Gem Exchange kiosk (central, sell-only market) ──────────────────────
local function buildGemExchange()
    local model = Instance.new("Model"); model.Name = "GemExchange"
    local pos = Vector3.new(0, GROUND_Y, 0)
    local PURPLE = Color3.fromRGB(255, 170, 90)

    -- raised circular platform
    part(model, {
        Name = "ExchangePad", Shape = Enum.PartType.Cylinder,
        Size = Vector3.new(1, 18, 18),
        CFrame = CFrame.new(pos + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, 0, math.rad(90)),
        Color = Color3.fromRGB(30, 26, 40), Material = Enum.Material.SmoothPlastic,
    })
    part(model, {
        Name = "ExchangeRing", Shape = Enum.PartType.Cylinder,
        Size = Vector3.new(0.4, 18.6, 18.6),
        CFrame = CFrame.new(pos + Vector3.new(0, 1.0, 0)) * CFrame.Angles(0, 0, math.rad(90)),
        Color = PURPLE, Material = Enum.Material.Neon, CanCollide = false,
    })

    -- counter / console (the clickable station)
    local desk = part(model, {
        Name = "ExchangeDesk",
        Size = Vector3.new(9, 4, 2.6),
        Position = pos + Vector3.new(0, 2.4, 4),
        Color = Color3.fromRGB(26, 24, 38), Material = Enum.Material.Metal,
    })
    desk:SetAttribute("StationType", "GemMarket")
    part(model, {
        Name = "DeskGlow",
        Size = Vector3.new(9.2, 0.4, 2.8),
        Position = pos + Vector3.new(0, 4.5, 4),
        Color = PURPLE, Material = Enum.Material.Neon, CanCollide = false,
    })
    local cdDesk = Instance.new("ClickDetector"); cdDesk.MaxActivationDistance = 18; cdDesk.Parent = desk

    -- simple robot vendor behind the counter
    local torso = part(model, {
        Name = "VendorTorso",
        Size = Vector3.new(3.4, 4, 2),
        Position = pos + Vector3.new(0, 4, 0),
        Color = Color3.fromRGB(60, 60, 85), Material = Enum.Material.Metal,
    })
    torso:SetAttribute("StationType", "GemMarket")
    local cdBot = Instance.new("ClickDetector"); cdBot.MaxActivationDistance = 18; cdBot.Parent = torso

    part(model, {
        Name = "VendorHead",
        Size = Vector3.new(2.4, 2, 2.2),
        Position = pos + Vector3.new(0, 7, 0),
        Color = Color3.fromRGB(75, 75, 105), Material = Enum.Material.Metal,
    })
    -- glowing visor
    part(model, {
        Name = "VendorVisor",
        Size = Vector3.new(2.0, 0.7, 0.4),
        Position = pos + Vector3.new(0, 7.1, -1.05),
        Color = PURPLE, Material = Enum.Material.Neon, CanCollide = false,
    })
    -- shoulders/arms
    for _, sx in ipairs({ -2.3, 2.3 }) do
        part(model, {
            Name = "VendorArm",
            Size = Vector3.new(0.9, 3.4, 0.9),
            Position = pos + Vector3.new(sx, 4, 0),
            Color = Color3.fromRGB(55, 55, 80), Material = Enum.Material.Metal,
        })
    end

    local light = Instance.new("PointLight")
    light.Color = PURPLE; light.Range = 26; light.Brightness = 4
    light.Parent = torso

    -- floating holographic sign
    local sign = part(model, {
        Name = "ExchangeSign",
        Size = Vector3.new(0.5, 0.5, 0.5),
        Position = pos + Vector3.new(0, 11, 0),
        Transparency = 1, CanCollide = false,
    })
    local bb = billboard(sign, 0, 72)
    bb.MaxDistance = 120
    local t1 = Instance.new("TextLabel")
    t1.Size = UDim2.new(1, 0, 0.55, 0); t1.BackgroundTransparency = 1
    t1.Text = "💹 GEM EXCHANGE"; t1.Font = Enum.Font.GothamBold; t1.TextScaled = true
    t1.TextColor3 = PURPLE; t1.TextStrokeTransparency = 0.3; t1.Parent = bb
    local t2 = Instance.new("TextLabel")
    t2.Size = UDim2.new(1, 0, 0.4, 0); t2.Position = UDim2.new(0, 0, 0.58, 0)
    t2.BackgroundTransparency = 1; t2.Text = "click to sell gems"
    t2.Font = Enum.Font.Gotham; t2.TextScaled = true
    t2.TextColor3 = Color3.fromRGB(210, 200, 225); t2.TextStrokeTransparency = 0.4; t2.Parent = bb

    model.PrimaryPart = desk
    model.Parent = workspace
    return model
end

-- ── Lighting polish ─────────────────────────────────────────────────────────
local function polishLighting()
    Lighting.ClockTime         = 18.5            -- dusk so neon pops
    Lighting.Brightness        = 2
    Lighting.EnvironmentDiffuseScale = 0.4
    Lighting.OutdoorAmbient    = Color3.fromRGB(70, 70, 95)
    Lighting.Ambient           = Color3.fromRGB(40, 40, 60)
    pcall(function() Lighting.Technology = Enum.Technology.Future end)

    if not Lighting:FindFirstChild("WorldAtmosphere") then
        local atmo = Instance.new("Atmosphere")
        atmo.Name = "WorldAtmosphere"
        atmo.Density = 0.32
        atmo.Haze    = 1.6
        atmo.Color   = Color3.fromRGB(190, 200, 230)
        atmo.Decay   = Color3.fromRGB(90, 100, 150)
        atmo.Parent  = Lighting
    end
    if not Lighting:FindFirstChild("WorldBloom") then
        local bloom = Instance.new("BloomEffect")
        bloom.Name = "WorldBloom"; bloom.Intensity = 0.7; bloom.Size = 24; bloom.Threshold = 1.1
        bloom.Parent = Lighting
    end
end

-- ── Public build ────────────────────────────────────────────────────────────
local signLabels = {}  -- plotIndex -> SurfaceGui TextLabel

function WorldBuilder.Build()
    -- Idempotent: clear anything we built before
    for _, name in ipairs({ "Plots", "GemNodes", "WorldGround", "GemExchange" }) do
        local existing = workspace:FindFirstChild(name)
        if existing then existing:Destroy() end
    end

    -- Ground baseplate so nobody falls into the void
    local ground = part(workspace, {
        Name = "WorldGround",
        Size = Vector3.new(420, 4, 320),
        Position = Vector3.new(0, GROUND_Y - 3, 0),
        Color = Color3.fromRGB(22, 24, 34),
        Material = Enum.Material.Slate,
    })
    ground.Parent = workspace

    local plotsFolder = Instance.new("Folder"); plotsFolder.Name = "Plots"; plotsFolder.Parent = workspace
    local nodesFolder = Instance.new("Folder"); nodesFolder.Name = "GemNodes"; nodesFolder.Parent = workspace

    for i = 1, 6 do
        local origin = plotOrigin(i)
        local plot = Instance.new("Model"); plot.Name = "Plot" .. i; plot.Parent = plotsFolder

        buildBase(plot, origin)
        buildFence(plot, origin)
        local spawn = buildSpawn(plot, origin)
        buildStations(plot, origin)
        buildNodes(nodesFolder, origin)
        signLabels[i] = buildSign(plot, origin, i)

        plot.PrimaryPart = spawn
    end

    buildGemExchange()
    polishLighting()
    return plotsFolder
end

-- Update a plot's sign with the owner's name (called when a plot is assigned)
function WorldBuilder.SetPlotOwner(index, name)
    local lbl = signLabels[index]
    if lbl then
        lbl.Text = name and ("⚡ " .. name .. "'s Plot") or ("⚡ PLOT " .. index)
    end
end

return WorldBuilder
