-- Tiny sound player. Reads asset IDs from GameConfig.SOUNDS; no-ops on empty IDs
-- so the game is safe before you add sounds.

local SoundService      = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("GameConfig"))

local Sounds = {}
local cache = {}

local function get(name)
    local id = GameConfig.SOUNDS[name]
    if not id or id == "" or id == 0 then return nil end
    local s = cache[name]
    if not s then
        s = Instance.new("Sound")
        s.Name = "SFX_" .. name
        s.SoundId = tostring(id)
        s.Parent = SoundService
        cache[name] = s
    end
    return s
end

function Sounds.Play(name, volume, pitch)
    local s = get(name)
    if not s then return end
    s.Volume = volume or 0.5
    s.PlaybackSpeed = pitch or 1
    s:Play()
end

return Sounds
