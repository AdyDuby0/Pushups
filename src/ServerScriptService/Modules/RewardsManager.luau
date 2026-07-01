-- Playtime + daily rewards.
--   ⚡ Core Charge  — charges over CHARGE_INTERVAL of playtime; claim for credits
--                     (~2 min of income, growing each claim) + a Core Surge buff.
--   🌌 Cosmic Cache — a 7-day login streak; resets if you miss more than 48h.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Config.GameConfig)

local RewardsManager = {}
local DataManager

local DAY = 86400
local charge = {}   -- userId -> { start = os.clock(), count = 0 }  (per session)

function RewardsManager.Init(dm)
    DataManager = dm
end

local function grant(data, reward)
    if reward.credits then data.credits += reward.credits end
    if reward.gemCurrency then data.gemCurrency = (data.gemCurrency or 0) + reward.gemCurrency end
    if reward.gems then
        for gt, n in pairs(reward.gems) do
            data.gems[gt] = math.min((data.gems[gt] or 0) + n, GameConfig.INVENTORY_MAX)
        end
    end
end

-- ── Cosmic Cache (daily) ────────────────────────────────────────────────────
function RewardsManager.GetDailyInfo(player)
    local data = DataManager.Get(player)
    if not data then return {} end
    local now  = os.time()
    local last = data.lastDailyClaim or 0
    local gap  = now - last
    local canClaim = (last == 0) or (gap >= DAY)

    local streak = data.dailyStreak or 0
    local nextStreak
    if last == 0 or gap >= 2 * DAY then nextStreak = 1 else nextStreak = streak + 1 end
    local nextDay = ((nextStreak - 1) % #GameConfig.DAILY_REWARDS) + 1

    return {
        canClaim = canClaim,
        streak   = streak,
        nextDay  = nextDay,
        nextIn   = canClaim and 0 or math.max(0, DAY - gap),
        rewards  = GameConfig.DAILY_REWARDS,
    }
end

function RewardsManager.ClaimDaily(player)
    local data = DataManager.Get(player)
    if not data then return false, "No data" end
    local now  = os.time()
    local last = data.lastDailyClaim or 0
    if last ~= 0 and (now - last) < DAY then return false, "Come back tomorrow" end

    local streak = data.dailyStreak or 0
    local newStreak = (last == 0 or (now - last) >= 2 * DAY) and 1 or (streak + 1)
    local day = ((newStreak - 1) % #GameConfig.DAILY_REWARDS) + 1
    local reward = GameConfig.DAILY_REWARDS[day]

    grant(data, reward)
    data.dailyStreak    = newStreak
    data.lastDailyClaim = now
    DataManager.Save(player)

    return true, {
        streak = newStreak, day = day, reward = reward,
        credits = data.credits, gemCurrency = data.gemCurrency, gems = data.gems,
    }
end

-- ── Core Charge (playtime) ──────────────────────────────────────────────────
local function chargeState(uid)
    if not charge[uid] then charge[uid] = { start = os.clock(), count = 0 } end
    return charge[uid]
end

function RewardsManager.GetChargeInfo(player)
    local s = chargeState(player.UserId)
    local elapsed = os.clock() - s.start
    return {
        interval    = GameConfig.CHARGE_INTERVAL,
        secondsLeft = math.max(0, math.floor(GameConfig.CHARGE_INTERVAL - elapsed)),
        ready       = elapsed >= GameConfig.CHARGE_INTERVAL,
        count       = s.count,
    }
end

function RewardsManager.ClaimCharge(player, incomeRate)
    local data = DataManager.Get(player)
    if not data then return false, "No data" end
    local s = chargeState(player.UserId)
    if (os.clock() - s.start) < GameConfig.CHARGE_INTERVAL then return false, "Still charging" end

    local reward = math.max(GameConfig.CHARGE_BASE, math.floor((incomeRate or 0) * 120))
    reward = math.floor(reward * (1 + s.count * 0.25))

    data.credits             += reward
    data.totalEarned         += reward
    data.stats.creditsEarned += reward

    -- apply the Core Surge income buff
    local buff = GameConfig.BUFFS.CoreSurge
    if buff then
        data.activePotions.CoreSurge = os.time() + buff.duration
    end

    s.start = os.clock()
    s.count += 1
    DataManager.Save(player)
    return true, { reward = reward, credits = data.credits, count = s.count }
end

function RewardsManager.Cleanup(player)
    charge[player.UserId] = nil
end

return RewardsManager
