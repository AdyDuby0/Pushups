-- Goals / quests. Progress is read from existing stats; each goal can be claimed
-- once its target is met, granting a reward.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Config.GameConfig)

local QuestManager = {}
local DataManager

function QuestManager.Init(dm)
    DataManager = dm
end

local function metricValue(data, metric)
    if metric == "coreLevel" then return data.coreLevel or 1 end
    if metric == "totalEarned" then return data.totalEarned or 0 end
    return (data.stats and data.stats[metric]) or 0
end

function QuestManager.GetGoals(player)
    local data = DataManager.Get(player)
    local info = {}
    if not data then return info end
    data.claimedGoals = data.claimedGoals or {}
    for _, g in ipairs(GameConfig.GOALS) do
        local cur = metricValue(data, g.metric)
        local claimed = data.claimedGoals[g.id] == true
        table.insert(info, {
            id        = g.id,
            name      = g.name,
            target    = g.target,
            progress  = math.min(cur, g.target),
            claimed   = claimed,
            claimable = (cur >= g.target) and not claimed,
            reward    = g.reward,
        })
    end
    return info
end

function QuestManager.ClaimGoal(player, goalId)
    local data = DataManager.Get(player)
    if not data then return false, "No data" end
    data.claimedGoals = data.claimedGoals or {}

    local goal
    for _, g in ipairs(GameConfig.GOALS) do
        if g.id == goalId then goal = g break end
    end
    if not goal then return false, "Unknown goal" end
    if data.claimedGoals[goalId] then return false, "Already claimed" end
    if metricValue(data, goal.metric) < goal.target then return false, "Goal not complete" end

    data.claimedGoals[goalId] = true
    local r = goal.reward or {}
    if r.credits then data.credits += r.credits end
    if r.gemCurrency then data.gemCurrency = (data.gemCurrency or 0) + r.gemCurrency end
    if r.gems then
        for gt, n in pairs(r.gems) do data.gems[gt] = (data.gems[gt] or 0) + n end
    end

    DataManager.Save(player)
    return true, { credits = data.credits, gemCurrency = data.gemCurrency, gems = data.gems }
end

return QuestManager
