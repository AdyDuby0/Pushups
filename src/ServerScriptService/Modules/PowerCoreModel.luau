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

-- Where to drop the core: on the plot's raised CoreSpot platform if present.
local function coreCFrame(plot)
    local spot = plot:FindFirstChild("CoreSpot")
    if spot and spot:IsA("BasePart") then
        return spot.CFrame
    end
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

    local GLASS    = Color3.fromRGB(208, 226, 236)
    local FRAME    = Color3.fromRGB(140, 143, 152)
    local BASEGREY = Color3.fromRGB(72, 74, 86)
    local CRYST_T  = Color3.fromRGB(255, 150, 60)    -- warm top
    local CRYST_B  = Color3.fromRGB(90, 200, 255)    -- cyan bottom

    local N        = 8                  -- octagon
    local STEP     = (2 * math.pi) / N
    local DRUM_R   = 3.0                 -- glass octagon radius
    local DRUM_H   = 4.2                 -- glass drum height
    local DRUM_Y0  = 1.0                 -- glass drum starts above the grey base
    local CAGE_R   = 3.35
    local TOP_Y    = DRUM_Y0 + DRUM_H
    local SIDE_W   = 2 * DRUM_R * math.tan(math.pi / N) + 0.12

    -- panel facing outward at local angle `a` (built in the plot-local frame)
    local function outwardPanel(cx, cy, cz, a, w, h, depth, color, mat, trans, target)
        local tgt = target or Vector3.new(cx + math.cos(a), cy, cz + math.sin(a))
        makePart(model, {
            Size     = Vector3.new(w, h, depth),
            CFrame   = baseCF * CFrame.new(Vector3.new(cx, cy, cz), tgt),
            Color    = color, Material = mat, Transparency = trans or 0, CanCollide = false,
        })
    end

    -- Grey faceted base the dome sits on
    makePart(model, {
        Shape    = Enum.PartType.Cylinder,
        Size     = Vector3.new(DRUM_Y0, DRUM_R * 2.1, DRUM_R * 2.1),
        CFrame   = baseCF * CFrame.new(0, DRUM_Y0 / 2, 0) * CFrame.Angles(0, 0, math.rad(90)),
        Color    = BASEGREY, Material = Enum.Material.SmoothPlastic,
    })

    -- 8 glass panels forming the octagon drum
    for i = 0, N - 1 do
        local a = i * STEP + STEP / 2          -- edge midpoints
        outwardPanel(math.cos(a) * DRUM_R, DRUM_Y0 + DRUM_H / 2, math.sin(a) * DRUM_R,
            a, SIDE_W, DRUM_H, 0.12, GLASS, Enum.Material.Glass, 0.55)
    end

    -- Faceted glass roof: 8 slanted panels converging to a cap
    local ROOF_H   = 1.8
    local roofTopR = DRUM_R * 0.32
    local roofLen  = math.sqrt(ROOF_H ^ 2 + (DRUM_R - roofTopR) ^ 2)
    for i = 0, N - 1 do
        local a   = i * STEP + STEP / 2
        local rmid = (DRUM_R + roofTopR) / 2
        local cx, cz = math.cos(a) * rmid, math.sin(a) * rmid
        outwardPanel(cx, TOP_Y + ROOF_H / 2, cz, a, SIDE_W * 0.82, roofLen, 0.12,
            GLASS, Enum.Material.Glass, 0.5, Vector3.new(cx + math.cos(a), TOP_Y, cz + math.sin(a)))
    end
    -- top cap nub
    makePart(model, {
        Size = Vector3.new(0.9, 0.9, 0.9),
        CFrame = baseCF * CFrame.new(0, TOP_Y + ROOF_H + 0.3, 0),
        Color = FRAME, Material = Enum.Material.Metal,
    })

    -- Cage: 8 chunky vertical struts + bottom & top octagon rings
    for i = 0, N - 1 do
        local a = i * STEP                      -- octagon corners (between panels)
        local cx, cz = math.cos(a) * CAGE_R, math.sin(a) * CAGE_R
        makePart(model, {
            Size = Vector3.new(0.55, TOP_Y, 0.55),
            CFrame = baseCF * CFrame.new(cx, TOP_Y / 2, cz),
            Color = FRAME, Material = Enum.Material.Metal,
        })
    end
    for i = 0, N - 1 do
        local a1, a2 = i * STEP, ((i + 1) % N) * STEP
        for _, y in ipairs({ 0.45, TOP_Y }) do
            rod(model,
                baseCF * CFrame.new(math.cos(a1) * CAGE_R, y, math.sin(a1) * CAGE_R),
                baseCF * CFrame.new(math.cos(a2) * CAGE_R, y, math.sin(a2) * CAGE_R),
                0.4, FRAME)
        end
    end

    -- RGB neon pipe rings around the base on the platform
    local ringColors = {
        Color3.fromRGB(60, 120, 255), Color3.fromRGB(60, 230, 90), Color3.fromRGB(255, 60, 60),
    }
    for ri, col in ipairs(ringColors) do
        local rr = CAGE_R + 0.3 + (ri - 1) * 0.45
        for i = 0, N - 1 do
            local a1, a2 = i * STEP, ((i + 1) % N) * STEP
            rod(model,
                baseCF * CFrame.new(math.cos(a1) * rr, 0.28, math.sin(a1) * rr),
                baseCF * CFrame.new(math.cos(a2) * rr, 0.28, math.sin(a2) * rr),
                0.22, col, Enum.Material.Neon)
        end
    end

    -- ── Double bi-pyramid crystal (floating inside the glass) ──────────────────
    local EQUATOR_Y = DRUM_Y0 + DRUM_H * 0.5
    local DIA_W, DIA_H = 2.0, 2.4

    local topCrystal = makePart(model, {
        Size     = Vector3.new(DIA_W, DIA_H, DIA_W),
        CFrame   = baseCF * CFrame.new(0, EQUATOR_Y + DIA_H * 0.38, 0),
        Color    = CRYST_T, Material = Enum.Material.Neon,
    })
    local topMesh = Instance.new("SpecialMesh")
    topMesh.MeshType = Enum.MeshType.Sphere
    topMesh.Parent   = topCrystal

    local botCrystal = makePart(model, {
        Size     = Vector3.new(DIA_W, DIA_H * 0.85, DIA_W),
        CFrame   = baseCF * CFrame.new(0, EQUATOR_Y - DIA_H * 0.3, 0),
        Color    = CRYST_B, Material = Enum.Material.Neon,
    })
    local botMesh = Instance.new("SpecialMesh")
    botMesh.MeshType = Enum.MeshType.Sphere
    botMesh.Parent   = botCrystal

    -- bright white core where the halves meet
    makePart(model, {
        Shape    = Enum.PartType.Cylinder,
        Size     = Vector3.new(0.25, DIA_W * 1.05, DIA_W * 1.05),
        CFrame   = baseCF * CFrame.new(0, EQUATOR_Y, 0) * CFrame.Angles(0, 0, math.rad(90)),
        Color    = Color3.fromRGB(255, 255, 255), Material = Enum.Material.Neon,
    })
    local GLOW1 = CRYST_T   -- used by the light/billboard below

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

    -- Hold-E prompt to open the Power Core panel (client connects Triggered)
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText           = "Open"
    prompt.ObjectText           = "Power Core"
    prompt.KeyboardKeyCode      = Enum.KeyCode.E
    prompt.HoldDuration         = 0.3
    prompt.MaxActivationDistance = 12
    prompt.RequiresLineOfSight  = false
    prompt.Parent               = crystal

    -- Point light at the equator (kept modest — one soft light per core so the
    -- scene stays clean now that node/station lights are gone)
    local light = Instance.new("PointLight")
    light.Color      = GLOW1
    light.Range      = 15
    light.Brightness = 1.8
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
    t2.BackgroundTransparency = 1; t2.Text = "hold [E]"
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
