-- Balance lives here. No secrets and no client-supplied reward values.
local C = {
    StoreName = "StrengthSimulator_v1",
    StudioStoreName = "StrengthSimulator_STUDIO_v1",
    StudioOffline = true, -- Studio-only sandbox; production ALWAYS uses DataStore.
    AutoSaveSeconds = 45, LeaseSeconds = 180, Attempts = 4,
    MaxValue = 1000000000000, MaxLevel = 15, MaxRebirths = 10000,
    TrainCooldown = 0.8, BaseCoins = 8, BasePower = 5,
    UpgradeBase = 25, UpgradeGrowth = 1.6,
    CoinLevelBonus = 0.15, PowerLevelBonus = 0.20,
    RebirthBonus = 0.12, RebirthBonusCap = 25,
    RebirthPower = 200, RebirthCoins = 150,
    RebirthRequirementGrowth = 0.08, RequirementGrowthCap = 10,
    DailySeconds = 86400, WeeklySeconds = 604800,
    DailyTrainingEquivalent = 8, WeeklyTrainingEquivalent = 25,
    RewardMinTrainings = 3,
    RemoteBurst = 8, RemotePerSecond = 4,
    ActionCooldown = 0.3, TrainDistance = 11,
    SignRevealDistance = 18, SignHideMargin = 2,
    SignFadeSeconds = 0.25, SignWidth = 220, SignHeight = 70, SignTextSize = 16,
    MilestoneTrail = 10,
    AnalyticsEnabled = false, -- Enable after publishing and checking Dashboard.
    SupportRewardsEnabled = false, PaidItemsEnabled = false,
    Stations = {
        Basic = {Position = Vector3.new(-16, 1, 0), MinLevel = 0, Multiplier = 1},
        Advanced = {Position = Vector3.new(24, 1, 0), MinLevel = 3, Multiplier = 1.25},
    },
}
function C.Multiplier(data)
    return 1 + math.min(data.Rebirths, C.RebirthBonusCap) * C.RebirthBonus
end
function C.UpgradeCost(level)
    return math.floor(C.UpgradeBase * C.UpgradeGrowth ^ level)
end
function C.Requirements(rebirths)
    local factor = 1 + math.min(rebirths, C.RequirementGrowthCap) * C.RebirthRequirementGrowth
    return math.floor(C.RebirthPower * factor), math.floor(C.RebirthCoins * factor)
end
function C.Gains(data, stationMultiplier)
    local m = C.Multiplier(data) * (stationMultiplier or 1)
    return math.floor(C.BasePower * (1 + data.Level * C.PowerLevelBonus) * m),
        math.floor(C.BaseCoins * (1 + data.Level * C.CoinLevelBonus) * m)
end
return table.freeze(C)
