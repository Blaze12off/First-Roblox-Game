-- Balance lives here. No secrets and no client-supplied reward values.
local C = {
    StoreName = "StrengthSimulator_v1",
    StudioStoreName = "StrengthSimulator_STUDIO_v1",
    StudioOffline = true, -- Studio-only sandbox; production ALWAYS uses DataStore.
    SpawnPosition = Vector3.new(-16,4,12), -- Temporary spawn point, never a visible platform.
    AutoSaveSeconds = 45, LeaseSeconds = 180, Attempts = 4,
    MaxValue = 1000000000000, MaxLevel = 15, MaxRebirths = 10000,
    TrainCooldown = 0, BaseCoins = 8, BasePower = 5,
    UpgradeBase = 25, UpgradeGrowth = 1.6,
    CoinLevelBonus = 0.15, PowerLevelBonus = 0.20,
    RebirthBonus = 0.12, RebirthBonusCap = 25,
    RebirthPower = 200, RebirthCoins = 150,
    RebirthRequirementGrowth = 0.08, RequirementGrowthCap = 10,
    DailySeconds = 86400, WeeklySeconds = 604800,
    DailyTrainingEquivalent = 8, WeeklyTrainingEquivalent = 25,
    RewardMinTrainings = 3,
    RemoteBurst = 8, RemotePerSecond = 4,
    TrainRemoteBurst = 64, TrainRemotePerSecond = 32, -- No click cooldown; bounded abuse budget.
    ActionCooldown = 0.3, TrainDistance = 6,
    SignRevealDistance = 18, SignHideMargin = 2,
    SignFadeSeconds = 0.25, SignWidth = 220, SignHeight = 70, SignTextSize = 16,
    MilestoneTrail = 10,
    AnalyticsEnabled = false, -- Enable after publishing and checking Dashboard.
    SupportRewardsEnabled = false, PaidItemsEnabled = false,
    MaxPets = 50, PetEquipSlots = 3, HatchCooldown = 4, CraftCooldown = 4, EggDistance = 5.25,
    Rarities = {"Обычная","Редкая","Эпическая","Мифическая","Легендарная","Секретная","Божественная"},
    RarityColors = { ["Обычная"]={195,208,224},["Редкая"]={100,185,255},["Эпическая"]={192,125,255},["Мифическая"]={255,103,153},["Легендарная"]={255,203,77},["Секретная"]={93,241,220},["Божественная"]={255,241,181} },
    PetTypes = {
        Cat = {Name = "Кот", Bonus = 0.10, Rarity="Обычная", Description="Верный спутник для первых тренировок.", Color = {255, 182, 103}},
        Dog = {Name = "Пёс", Bonus = 0.20, Rarity="Редкая", Description="Помогает быстрее набирать силу и монеты.", Color = {111, 190, 255}},
        Bunny = {Name = "Кролик", Bonus = 0.35, Rarity="Эпическая", Description="Самый сильный спутник из тестовых яиц.", Color = {211, 151, 255}},
    },
    PetOrder = {"Cat", "Dog", "Bunny"},
    EggOrder = {"Meadow", "Crystal"},
    Eggs = {
        Meadow = {Name = "Луговое яйцо", Description = "Первое яйцо для твоей команды. Кот 60% • Пёс 30% • Кролик 10%.", MinLevel = 0, Cost = 80, Position = Vector3.new(-31, 0.8, -8),
            Color = {112, 228, 180}, Weights = {Cat = 60, Dog = 30, Bunny = 10}},
        Crystal = {Name = "Кристальное яйцо", Description = "Больше шансов на редкого питомца. Кот 20% • Пёс 45% • Кролик 35%.", MinLevel = 0, Cost = 240, Position = Vector3.new(-31, 0.8, 3),
            Color = {180, 143, 255}, Weights = {Cat = 20, Dog = 45, Bunny = 35}},
    },
    Stations = {
        Basic = {Position = Vector3.new(-16, 1, 0), MinLevel = 0, Multiplier = 1},
        Advanced = {Position = Vector3.new(24, 1, 0), MinLevel = 3, Multiplier = 1.25},
    },
}
C.InventoryOrder=table.clone(C.PetOrder)
for _,id in C.PetOrder do
    local base=C.PetTypes[id]
    C.PetTypes[id.."_Upgraded"]={Name=base.Name.." · Улучшенный",Bonus=(1+base.Bonus)*4-1,
        Rarity=base.Rarity,Description="Совмещён из трёх одинаковых питомцев. Множитель увеличен в 4 раза.",
        Color=base.Color,BaseId=id,Upgraded=true}
    table.insert(C.InventoryOrder,id.."_Upgraded")
end
C.Eggs.Meadow.Rarity="Обычная"; C.Eggs.Crystal.Rarity="Редкая"
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
function C.TrainingMultipliers(data, stationMultiplier)
    local m = C.Multiplier(data) * (stationMultiplier or 1) * C.PetMultiplier(data)
    return (1 + data.Level * C.PowerLevelBonus) * m,
        (1 + data.Level * C.CoinLevelBonus) * m
end
function C.Gains(data, stationMultiplier)
    local power, coins = C.TrainingMultipliers(data, stationMultiplier)
    return math.floor(C.BasePower * power), math.floor(C.BaseCoins * coins)
end
function C.PetMultiplier(data)
    local bonus = 0
    for id, count in pairs(data.EquippedPets or {}) do
        if C.PetTypes[id] then bonus += C.PetTypes[id].Bonus * count end
    end
    return 1 + bonus
end
return table.freeze(C)
