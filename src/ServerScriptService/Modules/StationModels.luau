-- Station models rebuilt from the reference renders: grey metal frames, glass,
-- neon accents in each station's theme color, and RGB cables sprawling at the
-- base. Every builder takes (parent, cf) where cf sits on the floor and its
-- LookVector is the station's facing direction (front components live at
-- negative local Z). Each handles its own StationType attribute, hold-E prompt
-- and billboard, and returns the interactive part.

local StationModels = {}

local GREY  = Color3.fromRGB(140, 143, 152)
local DARK  = Color3.fromRGB(58, 60, 72)
local GLASS = Color3.fromRGB(208, 226, 236)

local CABLE_COLORS = {
    Color3.fromRGB(230, 70, 60),
    Color3.fromRGB(240, 200, 60),
    Color3.fromRGB(70, 120, 230),
}

local function part(parent, props)
    local p = Instance.new("Part")
    p.Anchored = true; p.CanCollide = true
    p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
    p.CastShadow = false
    for k, v in pairs(props) do p[k] = v end
    p.Parent = parent
    return p
end

local function addPrompt(parentPart, actionText, objectText)
    local pp = Instance.new("ProximityPrompt")
    pp.ActionText = actionText
    pp.ObjectText = objectText
    pp.KeyboardKeyCode = Enum.KeyCode.E
    pp.HoldDuration = 0.3
    pp.MaxActivationDistance = 14
    pp.RequiresLineOfSight = false
    pp.Parent = parentPart
    return pp
end

local function labelBillboard(adornee, offsetY, title, subtitle, color)
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 200, 0, 58)
    bb.StudsOffset = Vector3.new(0, offsetY, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 70
    bb.Adornee = adornee
    bb.Parent = adornee
    local t1 = Instance.new("TextLabel")
    t1.Size = UDim2.new(1, 0, 0.55, 0); t1.BackgroundTransparency = 1
    t1.Text = title; t1.Font = Enum.Font.GothamBold; t1.TextScaled = true
    t1.TextColor3 = color; t1.TextStrokeTransparency = 0.3; t1.Parent = bb
    local t2 = Instance.new("TextLabel")
    t2.Size = UDim2.new(1, 0, 0.4, 0); t2.Position = UDim2.new(0, 0, 0.58, 0)
    t2.BackgroundTransparency = 1; t2.Text = subtitle
    t2.Font = Enum.Font.Gotham; t2.TextScaled = true
    t2.TextColor3 = Color3.fromRGB(205, 205, 222); t2.TextStrokeTransparency = 0.4; t2.Parent = bb
end

-- RGB cables sprawling on the floor around the base (2 segments each)
local function cables(parent, cf, spread)
    for i, color in ipairs(CABLE_COLORS) do
        local ang = math.rad(-150 + i * 55)
        local baseCF = cf * CFrame.new(math.sin(ang) * spread, 0.12, math.cos(ang) * spread)
        part(parent, {
            Name = "Cable", Shape = Enum.PartType.Cylinder,
            Size = Vector3.new(2.2, 0.22, 0.22),
            CFrame = baseCF * CFrame.Angles(0, ang, 0),
            Color = color, Material = Enum.Material.SmoothPlastic, CanCollide = false,
        })
        part(parent, {
            Name = "Cable", Shape = Enum.PartType.Cylinder,
            Size = Vector3.new(1.4, 0.22, 0.22),
            CFrame = baseCF * CFrame.new(0.8, 0, 0.5) * CFrame.Angles(0, ang + math.rad(60), 0),
            Color = color, Material = Enum.Material.SmoothPlastic, CanCollide = false,
        })
    end
end

-- ── 🔧 Crafting fabricator (cyan) ───────────────────────────────────────────
function StationModels.BuildCrafting(parent, cf)
    local CYAN = Color3.fromRGB(100, 220, 255)

    -- legs + tool shelf + tabletop
    for _, dx in ipairs({ -2.6, 2.6 }) do
        for _, dz in ipairs({ -1.6, 1.6 }) do
            part(parent, { Size = Vector3.new(0.5, 2.6, 0.5), CFrame = cf * CFrame.new(dx, 1.3, dz),
                Color = GREY, Material = Enum.Material.Metal })
        end
    end
    part(parent, { Size = Vector3.new(5, 0.3, 3), CFrame = cf * CFrame.new(0, 0.9, 0),
        Color = DARK, Material = Enum.Material.Metal, CanCollide = false })
    local top = part(parent, { Name = "Station_Crafting",
        Size = Vector3.new(6, 0.5, 4), CFrame = cf * CFrame.new(0, 2.85, 0),
        Color = GREY, Material = Enum.Material.Metal })

    -- cyan edge strips around the tabletop
    for _, dz in ipairs({ -2.0, 2.0 }) do
        part(parent, { Size = Vector3.new(6.1, 0.15, 0.15), CFrame = cf * CFrame.new(0, 3.12, dz),
            Color = CYAN, Material = Enum.Material.Neon, CanCollide = false })
    end
    for _, dx in ipairs({ -3.02, 3.02 }) do
        part(parent, { Size = Vector3.new(0.15, 0.15, 4.1), CFrame = cf * CFrame.new(dx, 3.12, 0),
            Color = CYAN, Material = Enum.Material.Neon, CanCollide = false })
    end

    -- glass side rails
    for _, dx in ipairs({ -2.95, 2.95 }) do
        part(parent, { Size = Vector3.new(0.12, 1.2, 3.6), CFrame = cf * CFrame.new(dx, 3.75, 0),
            Color = GLASS, Material = Enum.Material.Glass, Transparency = 0.55, CanCollide = false })
    end

    -- back panel with the glowing fabricator core
    part(parent, { Size = Vector3.new(6, 3.4, 0.4), CFrame = cf * CFrame.new(0, 4.6, 1.9),
        Color = GREY, Material = Enum.Material.Metal })
    part(parent, { Shape = Enum.PartType.Ball, Size = Vector3.new(1.7, 1.7, 1.7),
        CFrame = cf * CFrame.new(0, 5.1, 1.6),
        Color = CYAN, Material = Enum.Material.Neon, CanCollide = false })
    part(parent, { Size = Vector3.new(1.9, 0.2, 0.2), CFrame = cf * CFrame.new(0, 5.1, 1.45),
        Color = GREY, Material = Enum.Material.Metal, CanCollide = false })
    part(parent, { Size = Vector3.new(0.2, 1.9, 0.2), CFrame = cf * CFrame.new(0, 5.1, 1.45),
        Color = GREY, Material = Enum.Material.Metal, CanCollide = false })

    -- overhead gantry with printer head + red nozzle
    for _, dx in ipairs({ -2.4, 2.4 }) do
        part(parent, { Size = Vector3.new(0.4, 3.2, 0.4), CFrame = cf * CFrame.new(dx, 4.7, 0.6),
            Color = GREY, Material = Enum.Material.Metal, CanCollide = false })
    end
    part(parent, { Size = Vector3.new(5.2, 0.45, 0.45), CFrame = cf * CFrame.new(0, 6.4, 0.6),
        Color = GREY, Material = Enum.Material.Metal, CanCollide = false })
    part(parent, { Size = Vector3.new(0.9, 0.7, 0.9), CFrame = cf * CFrame.new(0, 6.0, 0.6),
        Color = DARK, Material = Enum.Material.Metal, CanCollide = false })
    part(parent, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.8, 0.35, 0.35),
        CFrame = cf * CFrame.new(0, 5.5, 0.6) * CFrame.Angles(0, 0, math.rad(90)),
        Color = GREY, Material = Enum.Material.Metal, CanCollide = false })
    part(parent, { Shape = Enum.PartType.Ball, Size = Vector3.new(0.3, 0.3, 0.3),
        CFrame = cf * CFrame.new(0, 5.05, 0.6),
        Color = Color3.fromRGB(230, 70, 60), Material = Enum.Material.Neon, CanCollide = false })

    -- half-fabricated glowing part + gear cogs on the table
    part(parent, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.8, 0.55, 0.55),
        CFrame = cf * CFrame.new(-0.6, 3.35, 0.2) * CFrame.Angles(0, math.rad(20), 0),
        Color = CYAN, Material = Enum.Material.Neon, CanCollide = false })
    for _, pos in ipairs({ Vector3.new(1.6, 3.2, -0.6), Vector3.new(2.2, 3.2, 0.4) }) do
        part(parent, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.18, 1.3, 1.3),
            CFrame = cf * CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)),
            Color = GREY, Material = Enum.Material.Metal, CanCollide = false })
    end

    cables(parent, cf, 3.4)
    top:SetAttribute("StationType", "Crafting")
    addPrompt(top, "Open", "Crafting")
    labelBillboard(top, 5.6, "🔧 CRAFTING", "hold [E]", CYAN)
    return top
end

-- ── ⚙️ Workshop console (gold) ───────────────────────────────────────────────
function StationModels.BuildWorkshop(parent, cf)
    local GOLD = Color3.fromRGB(255, 200, 90)
    local TRIM = Color3.fromRGB(210, 170, 80)

    local body = part(parent, { Name = "Station_Workshop",
        Size = Vector3.new(5.4, 2.2, 3.4), CFrame = cf * CFrame.new(0, 1.1, 0),
        Color = DARK, Material = Enum.Material.DiamondPlate })

    -- work surface with little tools
    part(parent, { Size = Vector3.new(4.6, 0.3, 2.0), CFrame = cf * CFrame.new(0, 2.35, -0.55),
        Color = Color3.fromRGB(96, 90, 80), Material = Enum.Material.Metal })
    part(parent, { Size = Vector3.new(1.0, 0.12, 0.3), CFrame = cf * CFrame.new(-0.7, 2.56, -0.6) * CFrame.Angles(0, math.rad(25), 0),
        Color = GREY, Material = Enum.Material.Metal, CanCollide = false })
    part(parent, { Size = Vector3.new(0.7, 0.12, 0.16), CFrame = cf * CFrame.new(0.8, 2.56, -0.4) * CFrame.Angles(0, math.rad(-40), 0),
        Color = Color3.fromRGB(220, 120, 50), Material = Enum.Material.SmoothPlastic, CanCollide = false })

    -- sloped golden holo screen (tilts back)
    part(parent, { Size = Vector3.new(4.8, 3.2, 0.5),
        CFrame = cf * CFrame.new(0, 3.9, 1.05) * CFrame.Angles(math.rad(22), 0, 0),
        Color = DARK, Material = Enum.Material.Metal })
    part(parent, { Size = Vector3.new(4.0, 2.4, 0.12),
        CFrame = cf * CFrame.new(0, 3.9, 0.78) * CFrame.Angles(math.rad(22), 0, 0),
        Color = GOLD, Material = Enum.Material.Neon, CanCollide = false })

    -- gold trim along the body's top edges
    for _, dz in ipairs({ -1.72, 1.72 }) do
        part(parent, { Size = Vector3.new(5.5, 0.12, 0.12), CFrame = cf * CFrame.new(0, 2.25, dz),
            Color = TRIM, Material = Enum.Material.Neon, CanCollide = false })
    end

    -- gear cogs on the left flank
    part(parent, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.35, 1.7, 1.7),
        CFrame = cf * CFrame.new(-2.85, 3.0, 0.2),
        Color = TRIM, Material = Enum.Material.Metal, CanCollide = false })
    part(parent, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.35, 1.2, 1.2),
        CFrame = cf * CFrame.new(-2.85, 1.9, -0.6),
        Color = TRIM, Material = Enum.Material.Metal, CanCollide = false })

    -- little robotic arm on the right
    part(parent, { Size = Vector3.new(0.35, 1.6, 0.35),
        CFrame = cf * CFrame.new(2.5, 3.1, -0.2) * CFrame.Angles(0, 0, math.rad(-18)),
        Color = GREY, Material = Enum.Material.Metal, CanCollide = false })
    part(parent, { Size = Vector3.new(0.32, 1.3, 0.32),
        CFrame = cf * CFrame.new(2.85, 4.0, -0.45) * CFrame.Angles(math.rad(20), 0, math.rad(-40)),
        Color = GREY, Material = Enum.Material.Metal, CanCollide = false })
    part(parent, { Size = Vector3.new(0.5, 0.4, 0.5), CFrame = cf * CFrame.new(3.15, 4.55, -0.65),
        Color = DARK, Material = Enum.Material.Metal, CanCollide = false })

    -- orange accents on the front
    for _, dx in ipairs({ -1.6, 1.6 }) do
        part(parent, { Size = Vector3.new(0.9, 0.16, 0.06), CFrame = cf * CFrame.new(dx, 1.5, -1.74),
            Color = Color3.fromRGB(255, 140, 60), Material = Enum.Material.Neon, CanCollide = false })
    end

    cables(parent, cf, 3.2)
    body:SetAttribute("StationType", "Workshop")
    addPrompt(body, "Open", "Workshop")
    labelBillboard(body, 6.2, "⚙️ WORKSHOP", "hold [E]", GOLD)
    return body
end

-- ── 💱 Market stall (green) ─────────────────────────────────────────────────
function StationModels.BuildMarket(parent, cf)
    local GREEN = Color3.fromRGB(130, 255, 130)
    local gemColors = {
        Color3.fromRGB(100, 200, 255), Color3.fromRGB(150, 50, 255), Color3.fromRGB(80, 120, 255),
        Color3.fromRGB(255, 150, 0), Color3.fromRGB(255, 60, 60),
    }

    local counter = part(parent, { Name = "Station_Market",
        Size = Vector3.new(7, 2, 4.6), CFrame = cf * CFrame.new(0, 1, 0),
        Color = DARK, Material = Enum.Material.Metal })
    part(parent, { Size = Vector3.new(7.2, 0.3, 4.8), CFrame = cf * CFrame.new(0, 2.15, 0),
        Color = GREY, Material = Enum.Material.Metal })

    -- green neon strip around the counter
    part(parent, { Size = Vector3.new(7.1, 0.14, 0.14), CFrame = cf * CFrame.new(0, 1.85, -2.32),
        Color = GREEN, Material = Enum.Material.Neon, CanCollide = false })
    for _, dx in ipairs({ -3.55, 3.55 }) do
        part(parent, { Size = Vector3.new(0.14, 0.14, 4.7), CFrame = cf * CFrame.new(dx, 1.85, 0),
            Color = GREEN, Material = Enum.Material.Neon, CanCollide = false })
    end

    -- glass display case with gem clusters (grouped by color)
    part(parent, { Size = Vector3.new(6.6, 1.1, 4.2), CFrame = cf * CFrame.new(0, 2.9, 0),
        Color = GLASS, Material = Enum.Material.Glass, Transparency = 0.55, CanCollide = false })
    for i, color in ipairs(gemColors) do
        local gx = -2.4 + (i - 1) * 1.2
        for j = 1, 2 do
            local gz = (j == 1) and -0.8 or 0.7
            local s = (j == 1) and 0.6 or 0.45
            part(parent, { Size = Vector3.new(s, s * 1.4, s),
                CFrame = cf * CFrame.new(gx, 2.7, gz) * CFrame.Angles(math.rad(12), math.rad(i * 40 + j * 25), math.rad(8)),
                Color = color, Material = Enum.Material.Neon, CanCollide = false })
        end
    end

    -- corner posts + canopy roof
    for _, dx in ipairs({ -3.4, 3.4 }) do
        for _, dz in ipairs({ -2.2, 2.2 }) do
            part(parent, { Size = Vector3.new(0.5, 6.2, 0.5), CFrame = cf * CFrame.new(dx, 3.1, dz),
                Color = GREY, Material = Enum.Material.Metal })
        end
    end
    part(parent, { Size = Vector3.new(8, 0.4, 6),
        CFrame = cf * CFrame.new(0, 6.45, 0) * CFrame.Angles(math.rad(4), 0, 0),
        Color = GREY, Material = Enum.Material.Metal, CanCollide = false })

    -- floating price hologram with a down arrow
    part(parent, { Size = Vector3.new(1.5, 0.9, 0.12), CFrame = cf * CFrame.new(0, 4.7, -0.4),
        Color = GREEN, Material = Enum.Material.Neon, CanCollide = false })
    part(parent, { Size = Vector3.new(0.5, 0.5, 0.12),
        CFrame = cf * CFrame.new(0, 4.0, -0.4) * CFrame.Angles(0, 0, math.rad(45)),
        Color = GREEN, Material = Enum.Material.Neon, CanCollide = false })

    -- blank hanging sign on one corner
    part(parent, { Size = Vector3.new(1.6, 0.15, 0.15), CFrame = cf * CFrame.new(4.1, 5.7, -2.2),
        Color = GREY, Material = Enum.Material.Metal, CanCollide = false })
    part(parent, { Size = Vector3.new(1.3, 0.9, 0.15), CFrame = cf * CFrame.new(4.7, 5.1, -2.2),
        Color = DARK, Material = Enum.Material.SmoothPlastic, CanCollide = false })

    cables(parent, cf, 4.0)
    counter:SetAttribute("StationType", "Market")
    addPrompt(counter, "Open", "Market")
    labelBillboard(counter, 7.4, "💱 MARKET", "hold [E]", GREEN)
    return counter
end

-- ── 🛒 Shop vending machine (purple) ─────────────────────────────────────────
function StationModels.BuildShop(parent, cf)
    local PURPLE  = Color3.fromRGB(200, 130, 255)
    local PANEL   = Color3.fromRGB(130, 80, 200)

    local body = part(parent, { Name = "Station_Shop",
        Size = Vector3.new(4.2, 7, 2.6), CFrame = cf * CFrame.new(0, 3.5, 0),
        Color = GREY, Material = Enum.Material.Metal })

    -- purple front face + neon outline
    part(parent, { Size = Vector3.new(3.6, 6.4, 0.25), CFrame = cf * CFrame.new(0, 3.6, -1.35),
        Color = PANEL, Material = Enum.Material.SmoothPlastic, CanCollide = false })
    for _, y in ipairs({ 6.75, 0.45 }) do
        part(parent, { Size = Vector3.new(3.7, 0.12, 0.12), CFrame = cf * CFrame.new(0, y, -1.44),
            Color = PURPLE, Material = Enum.Material.Neon, CanCollide = false })
    end
    for _, dx in ipairs({ -1.82, 1.82 }) do
        part(parent, { Size = Vector3.new(0.12, 6.4, 0.12), CFrame = cf * CFrame.new(dx, 3.6, -1.44),
            Color = PURPLE, Material = Enum.Material.Neon, CanCollide = false })
    end

    -- crown emblem on top
    part(parent, { Size = Vector3.new(1.6, 0.2, 0.2), CFrame = cf * CFrame.new(0, 7.15, -1.2),
        Color = PURPLE, Material = Enum.Material.Neon, CanCollide = false })
    for i, h in ipairs({ 0.5, 0.85, 0.5 }) do
        part(parent, { Size = Vector3.new(0.36, h, 0.2),
            CFrame = cf * CFrame.new((i - 2) * 0.55, 7.25 + h / 2, -1.2),
            Color = PURPLE, Material = Enum.Material.Neon, CanCollide = false })
    end

    -- display recess with three shelves of goods
    part(parent, { Size = Vector3.new(2.6, 4.2, 0.15), CFrame = cf * CFrame.new(-0.3, 4.6, -1.5),
        Color = DARK, Material = Enum.Material.SmoothPlastic, CanCollide = false })
    for _, y in ipairs({ 3.1, 4.3, 5.5 }) do
        part(parent, { Size = Vector3.new(2.6, 0.12, 0.3), CFrame = cf * CFrame.new(-0.3, y, -1.55),
            Color = GREY, Material = Enum.Material.Metal, CanCollide = false })
    end
    -- top shelf: gems
    part(parent, { Size = Vector3.new(0.45, 0.6, 0.45),
        CFrame = cf * CFrame.new(-0.85, 5.95, -1.58) * CFrame.Angles(0, math.rad(35), math.rad(10)),
        Color = Color3.fromRGB(100, 200, 255), Material = Enum.Material.Neon, CanCollide = false })
    part(parent, { Size = Vector3.new(0.45, 0.6, 0.45),
        CFrame = cf * CFrame.new(0.25, 5.95, -1.58) * CFrame.Angles(0, math.rad(-25), math.rad(-8)),
        Color = Color3.fromRGB(255, 60, 60), Material = Enum.Material.Neon, CanCollide = false })
    -- middle shelf: money bags
    for _, dx in ipairs({ -0.85, 0.25 }) do
        part(parent, { Size = Vector3.new(0.55, 0.6, 0.45), CFrame = cf * CFrame.new(dx, 4.72, -1.58),
            Color = Color3.fromRGB(200, 170, 120), Material = Enum.Material.SmoothPlastic, CanCollide = false })
        part(parent, { Size = Vector3.new(0.2, 0.2, 0.2), CFrame = cf * CFrame.new(dx, 5.1, -1.58),
            Color = Color3.fromRGB(160, 130, 90), Material = Enum.Material.SmoothPlastic, CanCollide = false })
    end
    -- bottom shelf: potions
    local potionColors = { Color3.fromRGB(80, 160, 255), Color3.fromRGB(255, 80, 90) }
    for i, dx in ipairs({ -0.85, 0.25 }) do
        part(parent, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.55, 0.4, 0.4),
            CFrame = cf * CFrame.new(dx, 3.45, -1.58) * CFrame.Angles(0, 0, math.rad(90)),
            Color = potionColors[i], Material = Enum.Material.Neon, CanCollide = false })
    end

    -- dispense slot + coin panel
    part(parent, { Size = Vector3.new(2.2, 0.7, 0.15), CFrame = cf * CFrame.new(-0.3, 1.4, -1.5),
        Color = DARK, Material = Enum.Material.SmoothPlastic, CanCollide = false })
    part(parent, { Size = Vector3.new(0.5, 1.6, 0.12), CFrame = cf * CFrame.new(1.35, 4.3, -1.5),
        Color = GREY, Material = Enum.Material.Metal, CanCollide = false })
    for _, y in ipairs({ 3.5, 3.15 }) do
        part(parent, { Size = Vector3.new(0.3, 0.18, 0.1), CFrame = cf * CFrame.new(1.35, y, -1.52),
            Color = PURPLE, Material = Enum.Material.Neon, CanCollide = false })
    end

    cables(parent, cf, 2.8)
    body:SetAttribute("StationType", "Shop")
    addPrompt(body, "Open", "Shop")
    labelBillboard(body, 8.4, "🛒 SHOP", "hold [E]", PURPLE)
    return body
end

-- ── 💹 Gem Exchange booth (amber, with robot vendor) ─────────────────────────
function StationModels.BuildExchange(parent, cf)
    local AMBER = Color3.fromRGB(255, 170, 90)
    local BOOTH = Color3.fromRGB(105, 108, 120)

    -- counter: center segment + two angled wings, each with an amber ticker strip
    local segs = {
        cf * CFrame.new(0, 0, -1.9),
        cf * CFrame.new(-3.1, 0, -0.9) * CFrame.Angles(0, math.rad(35), 0),
        cf * CFrame.new(3.1, 0, -0.9) * CFrame.Angles(0, math.rad(-35), 0),
    }
    local centerCounter
    for i, segCF in ipairs(segs) do
        local w = (i == 1) and 4.6 or 3.2
        local seg = part(parent, {
            Size = Vector3.new(w, 2.2, 1.3), CFrame = segCF * CFrame.new(0, 1.1, 0),
            Color = BOOTH, Material = Enum.Material.Metal })
        part(parent, { Size = Vector3.new(w + 0.3, 0.25, 1.6), CFrame = segCF * CFrame.new(0, 2.3, 0),
            Color = GREY, Material = Enum.Material.Metal })
        part(parent, { Size = Vector3.new(w, 0.18, 0.1), CFrame = segCF * CFrame.new(0, 1.85, -0.68),
            Color = AMBER, Material = Enum.Material.Neon, CanCollide = false })
        if i == 1 then centerCounter = seg end
    end

    -- back frame: pillars, glass wall, top beam, amber light strip
    for _, dx in ipairs({ -2.8, 2.8 }) do
        part(parent, { Size = Vector3.new(0.6, 5.4, 0.6), CFrame = cf * CFrame.new(dx, 2.7, 1.6),
            Color = GREY, Material = Enum.Material.Metal })
    end
    part(parent, { Size = Vector3.new(5.2, 2.8, 0.15), CFrame = cf * CFrame.new(0, 3.9, 1.65),
        Color = GLASS, Material = Enum.Material.Glass, Transparency = 0.5, CanCollide = false })
    part(parent, { Size = Vector3.new(6.4, 0.5, 0.7), CFrame = cf * CFrame.new(0, 5.55, 1.6),
        Color = GREY, Material = Enum.Material.Metal, CanCollide = false })
    part(parent, { Size = Vector3.new(0.12, 2.2, 0.12), CFrame = cf * CFrame.new(-3.15, 2.4, 1.35),
        Color = AMBER, Material = Enum.Material.Neon, CanCollide = false })

    -- robot vendor behind the counter
    part(parent, { Size = Vector3.new(1.2, 1.6, 1.2), CFrame = cf * CFrame.new(0, 0.8, 0.5),
        Color = DARK, Material = Enum.Material.Metal })
    local torso = part(parent, { Name = "VendorTorso",
        Size = Vector3.new(2.2, 2.4, 1.3), CFrame = cf * CFrame.new(0, 2.9, 0.5),
        Color = Color3.fromRGB(60, 60, 85), Material = Enum.Material.Metal })
    for _, dx in ipairs({ -1.35, 1.35 }) do
        part(parent, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.5, 0.9, 0.9),
            CFrame = cf * CFrame.new(dx, 3.7, 0.5),
            Color = Color3.fromRGB(75, 75, 105), Material = Enum.Material.Metal, CanCollide = false })
    end
    part(parent, { Size = Vector3.new(1.5, 1.3, 1.4), CFrame = cf * CFrame.new(0, 4.75, 0.5),
        Color = Color3.fromRGB(75, 75, 105), Material = Enum.Material.Metal, CanCollide = false })
    part(parent, { Size = Vector3.new(1.3, 0.45, 0.12), CFrame = cf * CFrame.new(0, 4.8, -0.25),
        Color = AMBER, Material = Enum.Material.Neon, CanCollide = false })
    local light = Instance.new("PointLight")
    light.Color = AMBER; light.Range = 14; light.Brightness = 1.4; light.Parent = torso

    -- floating holographic candlestick chart above the counter
    local slabCF = cf * CFrame.new(1.3, 4.4, -1.1) * CFrame.Angles(0, math.rad(-12), 0)
    part(parent, { Size = Vector3.new(4.6, 2.5, 0.1), CFrame = slabCF,
        Color = AMBER, Material = Enum.Material.Glass, Transparency = 0.45, CanCollide = false })
    local heights = { 0.6, 0.9, 0.7, 1.2, 1.0, 1.5, 1.8 }
    for i, h in ipairs(heights) do
        part(parent, { Size = Vector3.new(0.28, h, 0.1),
            CFrame = slabCF * CFrame.new(-1.8 + (i - 1) * 0.6, -0.9 + h / 2, -0.1),
            Color = AMBER, Material = Enum.Material.Neon, CanCollide = false })
    end

    -- countertop props: two small dark screens
    for _, dx in ipairs({ -1.3, 1.1 }) do
        part(parent, { Size = Vector3.new(0.9, 0.6, 0.08),
            CFrame = cf * CFrame.new(dx, 2.75, -1.7) * CFrame.Angles(math.rad(-18), 0, 0),
            Color = Color3.fromRGB(25, 25, 32), Material = Enum.Material.SmoothPlastic, CanCollide = false })
    end

    cables(parent, cf, 4.0)
    torso:SetAttribute("StationType", "GemMarket")
    addPrompt(torso, "Sell Gems", "Gem Exchange")
    labelBillboard(torso, 6.6, "💹 GEM EXCHANGE", "hold [E]", AMBER)
    return torso
end

-- ── ⛏ Drill rig (orange) ────────────────────────────────────────────────────
-- Returns (interactPart, augerParts). augerParts is a list of { part, rest }
-- flight blades, each centered on the shaft axis so rotating one about its own
-- Y axis spins the whole helix (WorldBuilder drives this while mining).
function StationModels.BuildDrill(parent, cf)
    local ORANGE = Color3.fromRGB(255, 150, 60)
    local NEON_O = Color3.fromRGB(255, 120, 40)

    -- two glass gantry towers with inner neon strips and caution lights
    for _, dx in ipairs({ -2.7, 2.7 }) do
        for _, dz in ipairs({ -0.55, 0.55 }) do
            part(parent, { Size = Vector3.new(0.35, 6.2, 0.35), CFrame = cf * CFrame.new(dx, 3.1, dz),
                Color = GREY, Material = Enum.Material.Metal })
        end
        part(parent, { Size = Vector3.new(0.7, 5.6, 0.1), CFrame = cf * CFrame.new(dx, 3.0, 0),
            Color = GLASS, Material = Enum.Material.Glass, Transparency = 0.5, CanCollide = false })
        part(parent, { Size = Vector3.new(1.2, 0.5, 1.2), CFrame = cf * CFrame.new(dx, 6.45, 0),
            Color = GREY, Material = Enum.Material.Metal })
        part(parent, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.35, 0.4, 0.4),
            CFrame = cf * CFrame.new(dx, 6.9, 0) * CFrame.Angles(0, 0, math.rad(90)),
            Color = ORANGE, Material = Enum.Material.Neon, CanCollide = false })
        local inner = (dx < 0) and (dx + 0.62) or (dx - 0.62)
        part(parent, { Size = Vector3.new(0.1, 5.4, 0.1), CFrame = cf * CFrame.new(inner, 3.2, -0.35),
            Color = NEON_O, Material = Enum.Material.Neon, CanCollide = false })
    end

    -- top beam with neon lines
    part(parent, { Size = Vector3.new(6.6, 0.9, 1.1), CFrame = cf * CFrame.new(0, 6.15, 0),
        Color = GREY, Material = Enum.Material.Metal })
    for _, dy in ipairs({ 6.35, 5.95 }) do
        part(parent, { Size = Vector3.new(5.6, 0.08, 0.06), CFrame = cf * CFrame.new(0, dy, -0.57),
            Color = NEON_O, Material = Enum.Material.Neon, CanCollide = false })
    end

    -- head housing with the glowing power orb (the interactive part)
    local head = part(parent, { Name = "Drill",
        Size = Vector3.new(2.3, 1.9, 1.7), CFrame = cf * CFrame.new(0, 5.5, 0),
        Color = DARK, Material = Enum.Material.Metal })
    part(parent, { Shape = Enum.PartType.Ball, Size = Vector3.new(1.25, 1.25, 1.25),
        CFrame = cf * CFrame.new(0, 5.75, -0.75),
        Color = ORANGE, Material = Enum.Material.Neon, CanCollide = false })
    part(parent, { Size = Vector3.new(1.0, 0.14, 0.06), CFrame = cf * CFrame.new(0, 4.95, -0.88),
        Color = NEON_O, Material = Enum.Material.Neon, CanCollide = false })
    part(parent, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 1.15, 1.15),
        CFrame = cf * CFrame.new(0, 4.45, 0) * CFrame.Angles(0, 0, math.rad(90)),
        Color = NEON_O, Material = Enum.Material.Neon, CanCollide = false })

    -- auger: static shaft (rotationally symmetric) + spinning helix flights
    part(parent, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(3.8, 0.5, 0.5),
        CFrame = cf * CFrame.new(0, 2.5, 0) * CFrame.Angles(0, 0, math.rad(90)),
        Color = Color3.fromRGB(120, 120, 132), Material = Enum.Material.Metal, CanCollide = false })
    local auger = {}
    for i = 0, 5 do
        local fl = part(parent, { Size = Vector3.new(1.55, 0.14, 0.6),
            CFrame = cf * CFrame.new(0, 4.0 - i * 0.62, 0) * CFrame.Angles(0, math.rad(i * 42), 0),
            Color = Color3.fromRGB(95, 95, 106), Material = Enum.Material.Metal, CanCollide = false })
        table.insert(auger, { part = fl, rest = fl.CFrame })
    end

    -- cracked rock socket around the bit
    for i = 0, 4 do
        local a = math.rad(i * 72 + 20)
        part(parent, { Size = Vector3.new(1.3, 0.45, 0.9),
            CFrame = cf * CFrame.new(math.cos(a) * 1.1, 0.2, math.sin(a) * 1.1) * CFrame.Angles(math.rad(6), a, math.rad(-5)),
            Color = Color3.fromRGB(150, 150, 158), Material = Enum.Material.Slate })
    end
    for _, ang in ipairs({ 30, 140 }) do
        part(parent, { Size = Vector3.new(0.14, 0.06, 1.8),
            CFrame = cf * CFrame.new(0, 0.03, 0) * CFrame.Angles(0, math.rad(ang), 0),
            Color = Color3.fromRGB(40, 40, 48), Material = Enum.Material.SmoothPlastic, CanCollide = false })
    end

    -- hydraulic pistons on the right tower
    for _, dz in ipairs({ -0.35, 0.35 }) do
        part(parent, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(2.4, 0.3, 0.3),
            CFrame = cf * CFrame.new(2.05, 2.4, dz) * CFrame.Angles(0, 0, math.rad(90)),
            Color = GREY, Material = Enum.Material.Metal, CanCollide = false })
        part(parent, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.6, 0.18, 0.18),
            CFrame = cf * CFrame.new(2.05, 4.2, dz) * CFrame.Angles(0, 0, math.rad(90)),
            Color = Color3.fromRGB(200, 200, 210), Material = Enum.Material.Metal, CanCollide = false })
    end

    cables(parent, cf, 3.2)
    head:SetAttribute("StationType", "Drill")
    addPrompt(head, "Open", "Drill")
    labelBillboard(head, 3.4, "⛏ DRILL", "hold [E]", ORANGE)
    return head, auger
end

return StationModels
