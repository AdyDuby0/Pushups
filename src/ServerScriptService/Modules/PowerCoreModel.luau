-- Physical Power Core model builder.
-- Each player gets a glowing sci-fi core placed on their plot.
-- Structure:
--   • Hexagonal base: 6 flat panels + 6 corner pillars + connecting frame rods
--   • Cage: 6 vertical struts + top hexagonal ring
--   • Crystal: double bi-pyramid (two elongated diamonds, tip-to-tip)
-- The crystal part is tagged with OwnerUserId so the client's proximity loop
-- can find it and open the Power Core menu when the player walks up.

local RunService = game:GetService("RunService")

local PowerCoreModel = {}
local cores = {}   -- userId -> { model, crystal, baseCF }

local function ensureFolder()
    local f = workspace:FindFirstChild("PowerCores")
    if not f then
        f = Instance.new("Folder"); f.Name = "PowerCores"; f.Parent = workspace
    end
    return f
end

-- Where to drop the core: in front of the plot's Spawn pad.
local function coreCFrame(plot)
    local spawn = plot:FindFirstChild("Spawn")
    if spawn and spawn:IsA("BasePart") then
        return spawn.CFrame * CFrame.new(0, 0, -8)
    end
    return plot:GetPivot() + Vector3.new(0, 3, 0)
end

-- Helper: create a part with common properties
local function makePart(model, props)
    local p = Instance.new("Part")
    p.Anchored        = true
    p.CanCollide      = false
    p.TopSurface      = Enum.SurfaceType.Smooth
    p.BottomSurface   = Enum.SurfaceType.Smooth
    p.CastShadow      = false
    for k, v in pairs(props) do p[k] = v end
    p.Parent = model
    return p
end

-- Helper: thin cylinder rod between two CFrame points
local function rod(model, a, b, dia, color, mat)
    local mid = CFrame.new((a.Position + b.Position) / 2,  b.Position)
    local len = (a.Position - b.Position).Magnitude
    return makePart(model, {
        Shape    = Enum.PartType.Cylinder,
        Size     = Vector3.new(len, dia, dia),
        CFrame   = mid * CFrame.Angles(0, math.rad(90), 0),
        Color    = color,
        Material = mat or Enum.Material.Metal,
    })
end

function PowerCoreModel.Spawn(player, plot)
    if not plot then return end
    PowerCoreModel.Despawn(player)

    local folder = ensureFolder()
    local baseCF = coreCFrame(plot)
    local origin = baseCF.Position

    local model = Instance.new("Model")
    model.Name = "Core_" .. player.UserId

    local DARK   = Color3.fromRGB(22, 12, 44)
    local FRAME  = Color3.fromRGB(90, 60, 160)
    local GLOW1  = Color3.fromRGB(160, 80, 255)
    local GLOW2  = Color3.fromRGB(80, 200, 255)

    -- ── Hexagonal base ────────────────────────────────────────────────────────
    local HEX_R     = 3.8   -- radius to hex corner
    local BASE_Y    = 0.3   -- base plate height (half)
    local PANEL_H   = 0.5   -- panel height
    local PILLAR_H  = 5.5   -- cage pillar height above base

    -- Flat hexagonal floor: 6 trapezoidal panels arranged around center
    for i = 0, 5 do
        local angle = math.rad(i * 60)
        local midA  = math.rad(i * 60 + 30)
        local cx    = math.cos(midA) * HEX_R * 0.62
        local cz    = math.sin(midA) * HEX_R * 0.62
        makePart(model, {
            Size     = Vector3.new(HEX_R * 0.98, PANEL_H, HEX_R * 0.58),
            CFrame   = baseCF * CFrame.new(cx, BASE_Y, cz) * CFrame.Angles(0, -midA, 0),
            Color    = DARK,
            Material = Enum.Material.SmoothPlastic,
        })
    end

    -- Thin center disk (glowing)
    makePart(model, {
        Shape    = Enum.PartType.Cylinder,
        Size     = Vector3.new(0.18, HEX_R * 1.85, HEX_R * 1.85),
        CFrame   = baseCF * CFrame.new(0, BASE_Y + PANEL_H * 0.5, 0) * CFrame.Angles(0, 0, math.rad(90)),
        Color    = GLOW1,
        Material = Enum.Material.Neon,
    })

    -- 6 corner pillars + edge rods at base level
    local pillarTops = {}   -- Vector3 positions, for cage ring
    for i = 0, 5 do
        local angle = math.rad(i * 60)
        local px = math.cos(angle) * HEX_R
        local pz = math.sin(angle) * HEX_R
        local basePos  = origin + Vector3.new(px, 0, pz)
        local topPos   = origin + Vector3.new(px, PILLAR_H, pz)
        pillarTops[i + 1] = topPos

        -- Pillar
        makePart(model, {
            Shape    = Enum.PartType.Cylinder,
            Size     = Vector3.new(PILLAR_H, 0.22, 0.22),
            CFrame   = CFrame.new(basePos + Vector3.new(0, PILLAR_H / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
            Color    = FRAME,
            Material = Enum.Material.Metal,
        })

        -- Base ring connecting adjacent pillar bottoms
        local nextAngle = math.rad((i + 1) * 60)
        local nx = math.cos(nextAngle) * HEX_R
        local nz = math.sin(nextAngle) * HEX_R
        rod(model,
            CFrame.new(origin + Vector3.new(px, BASE_Y, pz)),
            CFrame.new(origin + Vector3.new(nx, BASE_Y, nz)),
            0.18, FRAME)
    end

    -- Cage top ring
    for i = 1, 6 do
        local a = pillarTops[i]
        local b = pillarTops[(i % 6) + 1]
        rod(model, CFrame.new(a), CFrame.new(b), 0.18, FRAME)
    end

    -- 6 diagonal braces: mid-pillar → center-top of cage
    local cageCenter = origin + Vector3.new(0, PILLAR_H + 0.5, 0)
    for i = 0, 5 do
        local angle = math.rad(i * 60 + 30)
        local mx = math.cos(angle) * HEX_R * 0.55
        local mz = math.sin(angle) * HEX_R * 0.55
        rod(model,
            CFrame.new(pillarTops[i + 1]),
            CFrame.new(cageCenter + Vector3.new(mx, 0, mz)),
            0.14, GLOW1, Enum.Material.Neon)
    end

    -- ── Double bi-pyramid crystal ─────────────────────────────────────────────
    -- Two elongated spheres (SpecialMesh.Sphere) sharing an equator:
    --   upper half: tall and narrow, glowing purple
    --   lower half: same but below the equator, glowing cyan
    -- Together they form the silhouette of an octahedron (double diamond).

    local EQUATOR_Y = PILLAR_H * 0.62 + 0.5   -- y offset above base for equator center
    local DIA_W, DIA_H = 2.2, 3.4             -- width and half-height of each diamond

    -- Upper diamond half
    local topCrystal = makePart(model, {
        Size     = Vector3.new(DIA_W, DIA_H, DIA_W),
        CFrame   = baseCF * CFrame.new(0, EQUATOR_Y + DIA_H * 0.38, 0),
        Color    = GLOW1,
        Material = Enum.Material.Neon,
    })
    local topMesh = Instance.new("SpecialMesh")
    topMesh.MeshType = Enum.MeshType.Sphere
    topMesh.Scale    = Vector3.new(1, 1, 1)
    topMesh.Parent   = topCrystal

    -- Lower diamond half (slightly smaller, cyan accent)
    local botCrystal = makePart(model, {
        Size     = Vector3.new(DIA_W, DIA_H * 0.8, DIA_W),
        CFrame   = baseCF * CFrame.new(0, EQUATOR_Y - DIA_H * 0.28, 0),
        Color    = GLOW2,
        Material = Enum.Material.Neon,
    })
    local botMesh = Instance.new("SpecialMesh")
    botMesh.MeshType = Enum.MeshType.Sphere
    botMesh.Scale    = Vector3.new(1, 1, 1)
    botMesh.Parent   = botCrystal

    -- Central equator ring (glows where the two halves meet)
    makePart(model, {
        Shape    = Enum.PartType.Cylinder,
        Size     = Vector3.new(0.25, DIA_W * 1.05, DIA_W * 1.05),
        CFrame   = baseCF * CFrame.new(0, EQUATOR_Y, 0) * CFrame.Angles(0, 0, math.rad(90)),
        Color    = Color3.fromRGB(255, 255, 255),
        Material = Enum.Material.Neon,
    })

    -- ── Crystal anchor + billboard tag ────────────────────────────────────────
    -- The "crystal" anchor is a transparent sphere at equator height tagged with
    -- OwnerUserId — the client proximity loop targets this.
    local crystal = makePart(model, {
        Shape     = Enum.PartType.Ball,
        Size      = Vector3.new(1, 1, 1),
        CFrame    = baseCF * CFrame.new(0, EQUATOR_Y, 0),
        Color     = GLOW1,
        Material  = Enum.Material.Neon,
        Transparency = 1,
        CanCollide   = false,
    })
    crystal.Name = "PowerCore"
    crystal:SetAttribute("OwnerUserId", player.UserId)

    -- Point light at the equator
    local light = Instance.new("PointLight")
    light.Color      = GLOW1
    light.Range      = 22
    light.Brightness = 5
    light.Parent     = crystal

    -- Billboard "walk up to open" hint
    local bb = Instance.new("BillboardGui")
    bb.Name        = "CoreLabel"
    bb.Size        = UDim2.new(0, 200, 0, 52)
    bb.StudsOffset = Vector3.new(0, DIA_H + 2.5, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 50
    bb.Adornee     = crystal
    bb.Parent      = crystal

    local t1 = Instance.new("TextLabel")
    t1.Size = UDim2.new(1, 0, 0.55, 0); t1.BackgroundTransparency = 1
    t1.Text = "⚡ POWER CORE"; t1.Font = Enum.Font.GothamBold; t1.TextScaled = true
    t1.TextColor3 = GLOW1; t1.TextStrokeTransparency = 0.3; t1.Parent = bb

    local t2 = Instance.new("TextLabel")
    t2.Size = UDim2.new(1, 0, 0.42, 0); t2.Position = UDim2.new(0, 0, 0.56, 0)
    t2.BackgroundTransparency = 1; t2.Text = "walk up to open"
    t2.Font = Enum.Font.Gotham; t2.TextScaled = true
    t2.TextColor3 = Color3.fromRGB(180, 170, 220); t2.TextStrokeTransparency = 0.4
    t2.Parent = bb

    model.PrimaryPart = crystal
    model.Parent = folder

    cores[player.UserId] = {
        model    = model,
        crystal  = crystal,
        topCryst = topCrystal,
        botCryst = botCrystal,
        baseCF   = baseCF,
        equatorY = EQUATOR_Y,
    }
end

function PowerCoreModel.Despawn(player)
    local e = cores[player.UserId]
    if e and e.model then e.model:Destroy() end
    cores[player.UserId] = nil
end

-- Gentle float + slow spin for both crystal halves
local started = false
function PowerCoreModel.StartAnimation()
    if started then return end
    started = true
    task.spawn(function()
        while true do
            RunService.Heartbeat:Wait()
            local t = os.clock()
            for _, e in pairs(cores) do
                if e.crystal and e.crystal.Parent then
                    local bob = math.sin(t * 1.2) * 0.5
                    local spin = CFrame.Angles(0, t * 0.6, 0)

                    -- Anchor (invisible) floats
                    e.crystal.CFrame = e.baseCF * CFrame.new(0, e.equatorY + bob, 0)

                    -- Top crystal spins slightly faster
                    e.topCryst.CFrame = e.baseCF
                        * CFrame.new(0, e.equatorY + bob, 0)
                        * spin
                        * CFrame.new(0, 1.4, 0)

                    -- Bottom crystal spins opposite
                    e.botCryst.CFrame = e.baseCF
                        * CFrame.new(0, e.equatorY + bob, 0)
                        * CFrame.Angles(0, -t * 0.6, 0)
                        * CFrame.new(0, -1.0, 0)
                end
            end
        end
    end)
end

return PowerCoreModel
