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
    RebirthBonus = 0.08, RebirthBonusCap = 10000,
    RebirthPower = 2500, RebirthCoins = 2000, RebirthPractice = 90, MaxBatchRebirths=100,
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
        Dog = {Name = "Пёс", Bonus = 0.20, Rarity="Редкая", Description="Помогает быстрее увеличивать прыжок и получать монеты.", Color = {111, 190, 255}},
        Bunny = {Name = "Кролик", Bonus = 0.35, Rarity="Эпическая", Description="Лунный кролик с длинными ушами и пушистым хвостом.", Color = {211, 151, 255}},
        Fox = {Name="Звёздный лис", Bonus=.60, Rarity="Мифическая", Description="Маленький хранитель созвездий с белой манишкой и двумя звёздными хвостами.", Color={245,123,164}},
        Phoenix = {Name="Солнечный феникс", Bonus=1.00, Rarity="Легендарная", Description="Золотая птица с огненными крыльями и тройным хвостом.", Color={255,176,65}},
        Axolotl = {Name="Аксолотль Бездны", Bonus=1.75, Rarity="Секретная", Description="Тёмный водный спутник со светящимися бирюзовыми жабрами.", Color={61,61,114}},
        Dragon = {Name="Небесный дракон", Bonus=3.00, Rarity="Божественная", Description="Жемчужный дракон с золотыми рогами, крыльями и небесным ореолом.", Color={225,239,255}},
    },
    PetOrder = {"Cat", "Dog", "Bunny", "Fox", "Phoenix", "Axolotl", "Dragon"},
    EggOrder = {},
    Eggs = {},
    BaseJumpHeight=7.2, StartJumpRatio=.05, JumpPointsPerBase=2500, MaxJumpHeight=120,
    Zones={
        {Name="Луг",XP=0,Cost=0,Scale=1,Color={112,228,180},Eggs={"Meadow","Crystal"}},
        {Name="Лес",XP=600,Cost=80000,Scale=1.6,Color={109,207,141},Eggs={"Moss","Amber"}},
        {Name="Ледник",XP=1800,Cost=1300000,Scale=2.7,Color={135,219,255},Eggs={"Frost","Aurora"}},
        {Name="Вулкан",XP=3600,Cost=9000000,Scale=4.5,Color={255,143,93},Eggs={"Lava","Ember"}},
        {Name="Небеса",XP=6000,Cost=45000000,Scale=7.5,Color={224,224,255},Eggs={"Star","Celestial"}},
    },
    Stations = {
        Basic = {Position = Vector3.new(-16, 1, 0), MinLevel = 0, Multiplier = 1},
        Advanced = {Position = Vector3.new(24, 1, 0), MinLevel = 3, Multiplier = 1.25},
    },
}
-- Legacy species IDs remain valid; later biomes add stronger variants.
local species=table.clone(C.PetOrder)
local themes={"", "Лесной ","Ледяной ","Огненный ","Небесный "}
local eggNames={Meadow="Луговое яйцо",Crystal="Кристальное яйцо",Moss="Моховое яйцо",Amber="Янтарное яйцо",
 Frost="Ледяное яйцо",Aurora="Полярное яйцо",Lava="Лавовое яйцо",Ember="Пламенное яйцо",Star="Звёздное яйцо",Celestial="Небесное яйцо"}
for zone,info in C.Zones do
    info.Position=Vector3.new((zone-1)*120-16,4,12)
    if zone>1 then C.Stations["Zone"..zone]={Position=Vector3.new((zone-1)*120-16,1,0),MinLevel=0,MinZone=zone,Multiplier=1+(zone-1)*.15} end
    for _,id in species do
        if zone>1 then
            local base=C.PetTypes[id]; local key=id.."_Z"..zone
            C.PetTypes[key]={Name=themes[zone]..base.Name,Bonus=(1+base.Bonus)*info.Scale-1,
                Rarity=base.Rarity,Description="Спутник зоны «"..info.Name.."». "..base.Description,
                Color={math.floor((base.Color[1]+info.Color[1])/2),math.floor((base.Color[2]+info.Color[2])/2),math.floor((base.Color[3]+info.Color[3])/2)},Species=id,Zone=zone}
            table.insert(C.PetOrder,key)
        else C.PetTypes[id].Species=id; C.PetTypes[id].Zone=1 end
    end
    for category,id in info.Eggs do
        local weights=category==1 and {Cat=55,Dog=30,Bunny=12,Fox=2.5,Phoenix=.5} or {Dog=20,Bunny=35,Fox=28,Phoenix=12,Axolotl=4,Dragon=1}
        local keyed={}
        for pet,weight in weights do keyed[zone==1 and pet or pet.."_Z"..zone]=weight end
        C.Eggs[id]={Name=eggNames[id],Description=category==1 and "Спутники для начала исследования этой зоны." or "Повышенные шансы редких спутников этой зоны.",
            MinLevel=0,Zone=zone,Category=category,Cost=({120,1500,10000,65000,400000})[zone]*(category==1 and 1 or 4),
            Position=Vector3.new((zone-1)*120-31,.8,category==1 and -8 or 3),Color=category==1 and info.Color or {math.min(255,info.Color[1]+25),math.max(90,info.Color[2]-35),255},
            Weights=keyed,Rarity=category==1 and "Обычная" or "Эпическая",ModelStyle=category==1 and "Meadow" or zone==5 and "Celestial" or "Crystal"}
        table.insert(C.EggOrder,id)
    end
end
C.InventoryOrder=table.clone(C.PetOrder)
for _,id in C.PetOrder do
    local base=C.PetTypes[id]
    C.PetTypes[id.."_Upgraded"]={Name=base.Name.." · Улучшенный",Bonus=(1+base.Bonus)*4-1,
        Rarity=base.Rarity,Description="Совмещён из трёх одинаковых питомцев. Множитель увеличен в 4 раза.",
        Color=base.Color,BaseId=id,Species=base.Species,Zone=base.Zone,Upgraded=true}
    table.insert(C.InventoryOrder,id.."_Upgraded")
end
-- Serialized Power keys now hold jump training points, preserving old records.
function C.JumpHeight(data)
    return math.min(C.MaxJumpHeight,C.BaseJumpHeight*(C.StartJumpRatio+math.sqrt(math.max(0,data.Power)/C.JumpPointsPerBase)))
end
function C.AvailablePractice(data) return math.max(0,(data.PracticeXP or 0)-(data.RebirthXPSpent or 0)) end
function C.Multiplier(data)
    return 1 + math.min(data.Rebirths, C.RebirthBonusCap) * C.RebirthBonus
end
function C.UpgradeCost(level)
    return math.floor(C.UpgradeBase * C.UpgradeGrowth ^ level)
end
function C.Requirements(rebirths)
    local n=rebirths+1
    return math.floor(C.RebirthPower*n^1.45),math.floor(C.RebirthCoins*n^1.4),math.floor(C.RebirthPractice*n^.5)
end
function C.BatchRequirements(rebirths,amount)
    if type(amount)~="number" or amount%1~=0 or amount<1 or amount>C.MaxBatchRebirths or rebirths+amount>C.MaxRebirths then return nil end
    local power,coins,xp=0,0,0
    for i=0,amount-1 do
        local p,c,x=C.Requirements(rebirths+i); power+=p; coins+=c; xp+=x
    end
    return power,coins,xp
end
function C.MaxAffordableRebirths(data)
    local power,coins,xp=0,0,0; local count=0
    for i=0,math.min(C.MaxBatchRebirths,C.MaxRebirths-data.Rebirths)-1 do
        local p,c,x=C.Requirements(data.Rebirths+i); power+=p; coins+=c; xp+=x
        if power>data.Power or coins>data.Coins or xp>C.AvailablePractice(data) then break end
        count+=1
    end
    return count
end
function C.TrainingMultipliers(data, stationMultiplier)
    local m = C.Multiplier(data) * (stationMultiplier or 1) * C.PetMultiplier(data)
    return (1 + data.Level * C.PowerLevelBonus) * m * (1+((data.Zone or 1)-1)*.25),
        (1 + data.Level * C.CoinLevelBonus) * m * (1+((data.Zone or 1)-1)*.25)
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
