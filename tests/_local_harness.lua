-- Generated test adapter. Roblox engine and DataStore network are NOT simulated as verified.
local moduleFactories,cache={},{}
local getModule
local root={}
for _,name in {"Schema","PlayerData","Progression","Rebirth","Rewards","Security","Pets"} do root[name]=name end
local Vector3={new=function(x,y,z) return {X=x,Y=y,Z=z} end,zero={X=0,Y=0,Z=0}}
local nextGuid=0
local Http={GenerateGUID=function() nextGuid+=1; return "test-guid-"..nextGuid end}
local game={ReplicatedStorage={SimulatorShared={Config="Config",NumberFormat="NumberFormat"}},ServerScriptService={Simulator=root}}
function game:GetService(name) assert(name=="HttpService","unexpected engine service"); return Http end
local task={wait=function() error("Unexpected real task.wait in unit tests") end}
moduleFactories["NumberFormat"] = function()
local require=getModule; local script={Parent=root}
-- Display only: economy, validation and saved values always use the original numbers.
local N={}
local suffixes={"K","M","B","T","Qa","Qi","Sx","Sp","Oc","No","Dc"}
local function digits(value)
    return (string.format("%.2f",value):gsub("0+$",""):gsub("%.$",""))
end
function N.Compact(value)
    if type(value)~="number" or value~=value or math.abs(value)==math.huge then return "—" end
    local sign=value<0 and "-" or ""
    local n=math.abs(value)
    if n<1000 then
        local rounded=math.floor(n*100+.5)/100
        if rounded<1000 then return (rounded==0 and "" or sign)..digits(rounded) end
    end
    local tier,scaled=0,n
    while scaled>=1000 do scaled/=1000; tier+=1 end
    scaled=math.floor(scaled*100+.5)/100
    if scaled>=1000 then scaled/=1000; tier+=1 end
    if suffixes[tier] then return sign..digits(scaled)..suffixes[tier] end
    local exponent=math.floor(math.log10(n))
    local mantissa=n/10^exponent
    mantissa=math.floor(mantissa*100+.5)/100
    if mantissa>=10 then mantissa/=10; exponent+=1 end
    return sign..digits(mantissa).."E+"..exponent
end
return N

end
moduleFactories["Config"] = function()
local require=getModule; local script={Parent=root}
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

end
moduleFactories["Schema"] = function()
local require=getModule; local script={Parent=root}
local C = require(game.ReplicatedStorage.SimulatorShared.Config)
local Schema = {}
function Schema.New()
    return {Version = 5, Zone=1, PracticeXP=0, RebirthXPSpent=0, Coins = 0, Power = 0, Level = 0, Rebirths = 0,
        LifetimePower = 0, TotalTrainings = 0, LastDaily = 0, LastWeekly = 0,
        Cosmetics = {}, Equipped = "", Pets = {}, EquippedPets = {}}
end
function Schema.Copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do result[key] = Schema.Copy(item) end
    return result
end
local function integer(value, maximum)
    return type(value) == "number" and value == value and value >= 0
        and value <= maximum and value % 1 == 0
end
-- Corrupt/unknown records fail closed. Defaults only come from a genuinely absent key.
function Schema.Validate(raw)
    if type(raw) ~= "table" or (raw.Version ~= 1 and raw.Version ~= 2 and raw.Version ~= 3 and raw.Version ~= 4 and raw.Version ~= 5) then return nil end
    if raw.Version==5 then
        if not integer(raw.Zone,5) or raw.Zone<1 or not integer(raw.PracticeXP,C.MaxValue) or not integer(raw.RebirthXPSpent,raw.PracticeXP) then return nil end
    end
    local limits = {Coins=C.MaxValue, Power=C.MaxValue, Level=C.MaxLevel,
        Rebirths=C.MaxRebirths, LifetimePower=C.MaxValue, TotalTrainings=C.MaxValue,
        LastDaily=100000000000, LastWeekly=100000000000}
    for key, limit in pairs(limits) do if not integer(raw[key], limit) then return nil end end
    if type(raw.Cosmetics) ~= "table" or type(raw.Equipped) ~= "string" then return nil end
    for key, value in pairs(raw.Cosmetics) do
        if (key ~= "BronzeAura" and key ~= "NeonTrail") or value ~= true then return nil end
    end
    if raw.Equipped ~= "" and not raw.Cosmetics[raw.Equipped] then return nil end
    if raw.Version >= 2 then
        if type(raw.Pets) ~= "table" then return nil end
        local total = 0
        for id, count in pairs(raw.Pets) do
            if not C.PetTypes[id] or not integer(count, C.MaxPets) or count < 1 then return nil end
            total += count
        end
        if total > C.MaxPets then return nil end
        if raw.Version == 2 then
            if type(raw.EquippedPet) ~= "string" or (raw.EquippedPet ~= "" and not raw.Pets[raw.EquippedPet]) then return nil end
        else
            if type(raw.EquippedPets) ~= "table" then return nil end
            local equipped = 0
            for id, count in pairs(raw.EquippedPets) do
                if not C.PetTypes[id] or not integer(count,C.PetEquipSlots) or count<1 or count>(raw.Pets[id] or 0) then return nil end
                equipped += count
            end
            if equipped>C.PetEquipSlots then return nil end
        end
    end
    local clean = Schema.New()
    for key in pairs(clean) do
        if key ~= "Version" and key ~= "EquippedPets" and (raw.Version>=5 or (key~="Zone" and key~="PracticeXP" and key~="RebirthXPSpent")) and (raw.Version >= 2 or key ~= "Pets") then
            clean[key] = Schema.Copy(raw[key])
        end
    end
    if raw.Version >= 3 then clean.EquippedPets=Schema.Copy(raw.EquippedPets)
    elseif raw.Version == 2 and raw.EquippedPet ~= "" then clean.EquippedPets[raw.EquippedPet]=1 end
    return clean
end
return Schema

end
moduleFactories["PlayerData"] = function()
local require=getModule; local script={Parent=root}
local C = require(game.ReplicatedStorage.SimulatorShared.Config)
local Schema = require(script.Parent.Schema)
local HttpService = game:GetService("HttpService")
local PlayerData = {}
PlayerData.__index = PlayerData

-- Injectable backend/clock are used by tests, never accessible through remotes.
function PlayerData.new(store, options)
    options = options or {}
    return setmetatable({store=store, profiles={}, loading={}, closing=false,
        now=options.now or os.time, wait=options.wait or task.wait,
        offline=options.offline == true, token=options.token or HttpService:GenerateGUID(false)}, PlayerData)
end
function PlayerData:_request(key, transform)
    for attempt = 1, C.Attempts do
        local ok, result = pcall(function() return self.store:UpdateAsync(key, transform) end)
        if ok then return true, result end
        if attempt < C.Attempts then self.wait(math.min(2 ^ (attempt-1), 4) + math.random()*0.2) end
    end
    return false, "unavailable"
end
local function validRecord(record)
    if type(record) ~= "table" or record.Schema ~= 1 or not Schema.Validate(record.Data) then return false end
    if type(record.Revision) ~= "number" or record.Revision % 1 ~= 0 or record.Revision < 0 then return false end
    local lock = record.Session
    return lock == nil or (type(lock)=="table" and type(lock.Token)=="string"
        and type(lock.Until)=="number" and lock.Until == lock.Until and lock.Until < math.huge)
end
function PlayerData:Load(userId)
    if self.closing or self.profiles[userId] or self.loading[userId] then return false, "busy" end
    self.loading[userId] = true
    if self.offline then
        self.profiles[userId] = {data=Schema.New(), lease=math.huge, status="ready", seq=0, savedSeq=0}
        self.loading[userId] = nil
        return true
    end
    local reason = "unavailable"
    local token = self.token .. ":" .. tostring(userId)
    local ok, record = self:_request("Player_"..userId, function(old)
        local now = self.now()
        if old ~= nil and not validRecord(old) then reason="corrupt"; return nil end
        if old and old.Session and old.Session.Token ~= token and old.Session.Until > now then
            reason="locked"; return nil
        end
        local data = old and Schema.Validate(old.Data) or Schema.New()
        return {Schema=1, Data=data, Revision=old and old.Revision or 0,
            Session={Token=token, Until=now+C.LeaseSeconds}}, {userId}
    end)
    self.loading[userId] = nil
    if not ok or not record or not validRecord(record) or not record.Session or record.Session.Token~=token then
        return false, reason
    end
    self.profiles[userId] = {data=Schema.Validate(record.Data), lease=record.Session.Until,
        status="ready", seq=0, savedSeq=0, token=token, revision=record.Revision}
    return true
end
function PlayerData:Get(userId)
    local p = self.profiles[userId]
    if not p or p.status ~= "ready" or self.closing then return nil end
    -- Stop granting progress before a stale server can overwrite a new session.
    if p.lease <= self.now()+10 then return nil end
    return p.data
end
function PlayerData:Changed(userId)
    local p = self.profiles[userId]
    if p then p.seq += 1 end
end
function PlayerData:Save(userId, release)
    local p = self.profiles[userId]
    if not p then return true end
    if release then p.status="closing" end
    -- One operation per key; exit waits for an autosave then writes the latest snapshot.
    while p.saving do self.wait(0.05) end
    if self.profiles[userId] ~= p then return true end
    p.saving = true
    local snapshot, seq = Schema.Copy(p.data), p.seq
    if not Schema.Validate(snapshot) then p.saving=false; return false, "corrupt" end
    if self.offline then
        p.savedSeq=seq; p.saving=false
        if release then self.profiles[userId]=nil end
        return true
    end
    local reason = "unavailable"
    local ok, result = self:_request("Player_"..userId, function(old)
        local now=self.now()
        if not validRecord(old) then reason="corrupt"; return nil end
        if not old.Session or old.Session.Token~=p.token or old.Session.Until <= now then
            reason="lost_lock"; return nil
        end
        return {Schema=1, Data=snapshot, Revision=old.Revision+1,
            Session=not release and {Token=p.token, Until=now+C.LeaseSeconds} or nil}, {userId}
    end)
    p.saving=false
    if ok and result and validRecord(result) then
        p.savedSeq=seq; p.revision=result.Revision
        if release then self.profiles[userId]=nil else p.lease=result.Session.Until end
        return true
    end
    if reason=="lost_lock" or reason=="corrupt" then p.status="failed" end
    return false, reason
end
return PlayerData

end
moduleFactories["Progression"] = function()
local require=getModule; local script={Parent=root}
local C = require(game.ReplicatedStorage.SimulatorShared.Config)
local number=require(game.ReplicatedStorage.SimulatorShared.NumberFormat).Compact
local P = {}
function P.Train(data, stationId)
    local station = C.Stations[stationId]
    if not station or (data.Zone or 1)<(station.MinZone or 1) or data.Level < station.MinLevel then return false, "Станция откроется на уровне 3." end
    local power, coins = C.Gains(data, station.Multiplier)
    data.Power = math.min(C.MaxValue, data.Power+power)
    data.Coins = math.min(C.MaxValue, data.Coins+coins)
    data.LifetimePower = math.min(C.MaxValue, data.LifetimePower+power)
    data.TotalTrainings = math.min(C.MaxValue, data.TotalTrainings+1)
    return true, ("+%s прыжка, +%s монет"):format(number(power),number(coins))
end
function P.Upgrade(data)
    if data.Level >= C.MaxLevel then return false, "Максимальный уровень тренировки." end
    local cost=C.UpgradeCost(data.Level)
    if data.Coins < cost then return false, "Не хватает монет на улучшение." end
    data.Coins-=cost; data.Level+=1
    return true, "Тренировка усилена! Уровень "..number(data.Level)
end
function P.Practice(data,seconds)
    if type(seconds)~="number" or seconds~=seconds or seconds<0 or seconds>1 then return false end
    data.PracticeXP=math.min(C.MaxValue,data.PracticeXP+math.floor(seconds))
    return true
end
function P.UnlockZone(data,zone)
    if type(zone)~="number" or zone%1~=0 or zone~=(data.Zone or 1)+1 or not C.Zones[zone] then return false,"Открывай зоны по порядку." end
    local target=C.Zones[zone]
    if data.PracticeXP<target.XP or data.Coins<target.Cost then return false,"Нужны опыт и монеты: "..number(target.XP).." опыта / "..number(target.Cost).." монет." end
    data.Coins-=target.Cost; data.Zone=zone
    return true,"Открыта зона «"..target.Name.."»!"
end
function P.ApplyJump(player,data)
    local humanoid=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.UseJumpPower=false; humanoid.JumpHeight=C.JumpHeight(data) end
end
return P

end
moduleFactories["Rebirth"] = function()
local require=getModule; local script={Parent=root}
local C=require(game.ReplicatedStorage.SimulatorShared.Config)
local R={}
function R.Apply(data,amount)
    amount=amount or 1
    local power,coins,xp=C.BatchRequirements(data.Rebirths,amount)
    if not power then return false,"Недопустимое количество перерождений." end
    if data.Power<power or data.Coins<coins or C.AvailablePractice(data)<xp then return false,"Не хватает прыжка, монет или опыта тренировки." end
    data.Power=0; data.Coins-=coins; data.Level=0
    data.RebirthXPSpent+=xp; data.Rebirths+=amount
    return true,("Перерождений: %d! Постоянный бонус x%.2f"):format(amount,C.Multiplier(data))
end
return R

end
moduleFactories["Rewards"] = function()
local require=getModule; local script={Parent=root}
local C=require(game.ReplicatedStorage.SimulatorShared.Config)
local number=require(game.ReplicatedStorage.SimulatorShared.NumberFormat).Compact
local Rewards={}
function Rewards.Reconcile(data)
    local changed=false
    if data.Rebirths>=1 and not data.Cosmetics.BronzeAura then data.Cosmetics.BronzeAura=true; changed=true end
    if data.Rebirths>=C.MilestoneTrail and not data.Cosmetics.NeonTrail then data.Cosmetics.NeonTrail=true; changed=true end
    if changed and data.Equipped=="" then data.Equipped=data.Cosmetics.NeonTrail and "NeonTrail" or "BronzeAura" end
    return changed
end
function Rewards.Claim(data, kind, now)
    local key, seconds, count
    if kind=="Daily" then key="LastDaily"; seconds=C.DailySeconds; count=C.DailyTrainingEquivalent
    elseif kind=="Weekly" then key="LastWeekly"; seconds=C.WeeklySeconds; count=C.WeeklyTrainingEquivalent
    else return false, "Неизвестная награда." end
    if data.TotalTrainings<C.RewardMinTrainings then return false, "Сначала потренируйся 3 раза." end
    if data[key]~=0 and now < data[key]+seconds then return false, "Награда ещё не готова." end
    local _, perTraining=C.Gains(data, 1)
    local reward=perTraining*count
    data[key]=now; data.Coins=math.min(C.MaxValue, data.Coins+reward)
    return true, ("Награда: +%s монет"):format(number(reward))
end
function Rewards.Equip(data, cosmetic)
    if cosmetic~="" and not data.Cosmetics[cosmetic] then return false, "Косметика ещё не открыта." end
    data.Equipped=cosmetic
    return true, cosmetic=="" and "Эффект выключен." or "Эффект включён."
end
function Rewards.ApplyCharacter(player, data)
    local char=player.Character
    local root=char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    for _, child in root:GetChildren() do
        if child.Name:sub(1,10)=="Simulator_" then child:Destroy() end
    end
    if data.Equipped=="BronzeAura" and data.Cosmetics.BronzeAura then
        local light=Instance.new("PointLight"); light.Name="Simulator_Aura"
        light.Color=Color3.fromRGB(255,170,65); light.Range=10; light.Brightness=2; light.Parent=root
        local sparks=Instance.new("Sparkles"); sparks.Name="Simulator_Sparks"
        sparks.SparkleColor=light.Color; sparks.Parent=root
    elseif data.Equipped=="NeonTrail" and data.Cosmetics.NeonTrail then
        local a=Instance.new("Attachment"); a.Name="Simulator_TrailA"; a.Position=Vector3.new(-1,0,0); a.Parent=root
        local b=Instance.new("Attachment"); b.Name="Simulator_TrailB"; b.Position=Vector3.new(1,0,0); b.Parent=root
        local trail=Instance.new("Trail"); trail.Name="Simulator_Trail"
        trail.Attachment0=a; trail.Attachment1=b; trail.Lifetime=0.5
        trail.Color=ColorSequence.new(Color3.fromRGB(70,240,255),Color3.fromRGB(160,100,255)); trail.Parent=root
    end
end
return Rewards

end
moduleFactories["Security"] = function()
local require=getModule; local script={Parent=root}
local C=require(game.ReplicatedStorage.SimulatorShared.Config)
local S={}
function S.NewLimiter(burst,perSecond)
    return {tokens=burst or C.RemoteBurst,burst=burst or C.RemoteBurst,perSecond=perSecond or C.RemotePerSecond,at=os.clock(),actions={}}
end
function S.Allow(limiter, action, now, cooldown)
    limiter.tokens=math.min(limiter.burst, limiter.tokens+(now-limiter.at)*limiter.perSecond)
    limiter.at=now
    if limiter.tokens<1 then return false end
    limiter.tokens-=1
    local last=limiter.actions[action]
    if last and now-last<cooldown then return false end
    limiter.actions[action]=now
    return true
end
function S.Valid(action, args)
    if type(action)~="string" or #action>16 then return false end
    if action=="Jump" then return args.n==0 end
    if action=="Zone" then return args.n==1 and type(args[1])=="number" and args[1]%1==0 and args[1]>=1 and args[1]<=5 end
    if action=="PrepareRebirth" then return args.n==0 or (args.n==1 and type(args[1])=="number" and args[1]%1==0 and args[1]>=1 and args[1]<=C.MaxBatchRebirths) end
    if action=="Train" then return args.n==1 and type(args[1])=="string" and C.Stations[args[1]]~=nil end
    if action=="Equip" then return args.n==1 and (args[1]=="" or args[1]=="BronzeAura" or args[1]=="NeonTrail") end
    if action=="Hatch" then return args.n==1 and type(args[1])=="string" and C.Eggs[args[1]]~=nil end
    if action=="PetEquip" then return args.n==1 and type(args[1])=="string" and (args[1]=="" or C.PetTypes[args[1]]~=nil) end
    if action=="PetUnequip" then return args.n==1 and type(args[1])=="string" and C.PetTypes[args[1]]~=nil end
    if action=="PetCraft" then
        if args.n~=2 or type(args[1])~="string" or not C.PetTypes[args[1]] or C.PetTypes[args[1]].Upgraded or type(args[2])~="table" or #args[2]~=3 then return false end
        local seen={}; local count=0
        for key,index in pairs(args[2]) do
            if type(key)~="number" or key%1~=0 or key<1 or key>3 or type(index)~="number" or index%1~=0 or index<1 or index>C.MaxPets or seen[index] then return false end
            seen[index]=true
            count+=1
        end
        return count==3
    end
    if action=="Rebirth" then return args.n==1 and type(args[1])=="string" and #args[1]<=64 end
    return (action=="Sync" or action=="Upgrade" or action=="PrepareRebirth" or action=="Daily" or action=="Weekly" or action=="PetMenu" or action=="PetEquipBest") and args.n==0
end
function S.Near(player, part, radius)
    local char=player.Character
    local root=char and char:FindFirstChild("HumanoidRootPart")
    local human=char and char:FindFirstChildOfClass("Humanoid")
    return root~=nil and human~=nil and human.Health>0 and (root.Position-part.Position).Magnitude<=radius
end
return S

end
moduleFactories["Pets"] = function()
local require=getModule; local script={Parent=root}
local number=require(game.ReplicatedStorage.SimulatorShared.NumberFormat).Compact
local C = require(game.ReplicatedStorage.SimulatorShared.Config)
local Pets = {}
function Pets.Count(data)
    local count = 0
    for _, amount in pairs(data.Pets) do count += amount end
    return count
end
function Pets.EquippedCount(data)
    local count=0
    for _,amount in pairs(data.EquippedPets) do count+=amount end
    return count
end
-- Randomness is chosen on the server. An injectable roll supports deterministic unit tests.
function Pets.Hatch(data, eggId, roll)
    local egg = C.Eggs[eggId]
    if not egg then return false, "Неизвестное яйцо." end
    if (data.Zone or 1)<(egg.Zone or 1) then return false,"Яйцо недоступно: сначала открой зону "..number(egg.Zone).."." end
    if data.Level < egg.MinLevel then return false, "Яйцо недоступно: нужен уровень "..number(egg.MinLevel).."." end
    if Pets.Count(data) >= C.MaxPets then return false, "Инвентарь питомцев заполнен (50)." end
    if data.Coins < egg.Cost then return false, "Не хватает монет на яйцо." end
    local value = roll and roll() or math.random()
    if type(value) ~= "number" or value ~= value or value < 0 or value >= 1 then
        return false, "Не удалось открыть яйцо. Монеты не списаны."
    end
    local total = 0
    for _, id in C.PetOrder do total += egg.Weights[id] or 0 end
    if total<=0 then return false,"В этом яйце пока нет питомцев. Монеты не списаны." end
    local threshold, selected = 0, nil
    for _, id in C.PetOrder do
        local weight=egg.Weights[id] or 0
        if weight<=0 then continue end
        selected=id -- Last eligible drop also handles floating-point rounding at the upper boundary.
        threshold += weight / total
        if value < threshold then selected = id; break end
    end
    data.Coins -= egg.Cost
    data.Pets[selected] = (data.Pets[selected] or 0) + 1
    if Pets.EquippedCount(data) < C.PetEquipSlots then
        data.EquippedPets[selected]=(data.EquippedPets[selected] or 0)+1
    end
    return true, "Из яйца: " .. C.PetTypes[selected].Name .. "!", selected
end
function Pets.Equip(data, id)
    if id ~= "" and (not C.PetTypes[id] or not data.Pets[id]) then
        return false, "Этот питомец не получен."
    end
    if id == "" then data.EquippedPets={}; return true,"Все питомцы сняты." end
    if Pets.EquippedCount(data)>=C.PetEquipSlots then return false,"Все 3 обычных слота заняты." end
    if (data.EquippedPets[id] or 0)>=data.Pets[id] then return false,"Нет свободного экземпляра питомца." end
    data.EquippedPets[id]=(data.EquippedPets[id] or 0)+1
    return true, "Питомец экипирован: " .. C.PetTypes[id].Name
end
function Pets.Unequip(data,id)
    local count=data.EquippedPets[id] or 0
    if count<1 then return false,"Этот питомец не экипирован." end
    data.EquippedPets[id]=count>1 and count-1 or nil
    return true,"Питомец снят."
end
function Pets.EquipBest(data)
    if Pets.Count(data)==0 then return false,"Сначала получите питомца." end
    local order=table.clone(C.InventoryOrder)
    table.sort(order,function(a,b)
        if C.PetTypes[a].Bonus==C.PetTypes[b].Bonus then return a<b end
        return C.PetTypes[a].Bonus>C.PetTypes[b].Bonus
    end)
    local selected,remaining={},C.PetEquipSlots
    for _,id in order do
        local amount=math.min(data.Pets[id] or 0,remaining)
        if amount>0 then selected[id]=amount; remaining-=amount end
        if remaining==0 then break end
    end
    data.EquippedPets=selected
    return true,"Лучшие питомцы экипированы."
end
-- Count-based inventory: three identical copies, validated and consumed atomically.
function Pets.Craft(data,id,copies)
    local info=C.PetTypes[id]
    if not info or info.Upgraded then return false,"Можно совместить только обычные экземпляры одного вида." end
    local owned=data.Pets[id] or 0
    if owned<3 then return false,"Нужно три одинаковых питомца." end
    if type(copies)~="table" or #copies~=3 then return false,"Выберите три экземпляра." end
    local seen,removedEquipped,selectionCount={},0,0
    for key,index in pairs(copies) do
        if type(key)~="number" or key%1~=0 or key<1 or key>3 or type(index)~="number" or index%1~=0 or index<1 or index>owned or seen[index] then
            return false,"Выбор питомцев устарел или некорректен."
        end
        seen[index]=true
        selectionCount+=1
        if index<=(data.EquippedPets[id] or 0) then removedEquipped+=1 end
    end
    if selectionCount~=3 then return false,"Выберите три экземпляра." end
    local remaining=owned-3
    data.Pets[id]=remaining>0 and remaining or nil
    local equipped=(data.EquippedPets[id] or 0)-removedEquipped
    data.EquippedPets[id]=equipped>0 and equipped or nil
    local result=id.."_Upgraded"
    data.Pets[result]=(data.Pets[result] or 0)+1
    if Pets.EquippedCount(data)<C.PetEquipSlots then
        data.EquippedPets[result]=(data.EquippedPets[result] or 0)+1
    end
    return true,"Получен "..C.PetTypes[result].Name.."!",result
end
return Pets

end
moduleFactories["Spec"] = function()
local require=getModule; local script={Parent=root}
-- Server-only deterministic tests. No production DataStore, no real user records.
local Root=game.ServerScriptService.Simulator
local C=require(game.ReplicatedStorage.SimulatorShared.Config)
local Schema=require(Root.Schema)
local Data=require(Root.PlayerData)
local P=require(Root.Progression)
local R=require(Root.Rebirth)
local Rewards=require(Root.Rewards)
local S=require(Root.Security)
local Pets=require(Root.Pets)
local Spec={}
function Spec.Run()
    local count=0
    local function check(value,message) assert(value,message); count+=1 end
    local obtainable={}
    for _,eggId in C.EggOrder do
        local egg=C.Eggs[eggId]; local total=0
        for id,weight in egg.Weights do
            check(C.PetTypes[id] and not C.PetTypes[id].Upgraded and weight>0,"valid base egg drop "..id)
            total+=weight
        end
        check(total==100,"published egg odds sum to 100 "..eggId)
        local threshold=0
        for _,id in C.PetOrder do
            local weight=egg.Weights[id] or 0
            if weight>0 then
                local sample=Schema.New(); sample.Zone=5; sample.Coins=egg.Cost
                local ok,_,drop=Pets.Hatch(sample,eggId,function() return (threshold+weight/2)/total end)
                check(ok and drop==id and sample.Coins==0 and sample.Pets[id]==1,"paid midpoint drop "..eggId..id)
                check(Schema.Validate(sample)~=nil,"new drop profile validates "..id)
                obtainable[C.PetTypes[id].Rarity]=true
                threshold+=weight
            end
        end
        local sample=Schema.New(); sample.Zone=5; sample.Coins=egg.Cost
        local ok,_,drop=Pets.Hatch(sample,eggId,function() return 1-1e-12 end)
        check(ok and (egg.Weights[drop] or 0)>0,"upper endpoint never selects a zero-weight pet")
    end
    for _,rarity in C.Rarities do check(obtainable[rarity],"each rarity obtainable "..rarity) end
    for _,id in C.PetOrder do
        local sample=Schema.New(); sample.Pets={[id]=3}; sample.EquippedPets={[id]=3}
        check(Pets.Craft(sample,id,{1,2,3}),"craft each species "..id)
        check(math.abs(C.PetMultiplier(sample)-(1+C.PetTypes[id].Bonus)*4)<1e-9,"fourfold coefficient "..id)
        check(Schema.Validate(sample)~=nil and Pets.EquipBest(sample),"new crafted species survives validation and best equip")
    end
    local best=Schema.New()
    check(not Pets.EquipBest(best),"empty best selection rejected")
    best.Pets={Cat=5,Dog=2,Bunny=2}; best.EquippedPets={Cat=3}
    check(Pets.EquipBest(best) and best.EquippedPets.Bunny==2 and best.EquippedPets.Dog==1 and best.EquippedPets.Cat==nil,"best selects strongest owned copies")
    check(Pets.EquippedCount(best)==3 and math.abs(C.PetMultiplier(best)-1.90)<.00001,"best team multiplier and cap")
    check(Pets.EquipBest(best) and best.EquippedPets.Bunny==2 and best.EquippedPets.Dog==1,"best repeat stable")
    best.Pets={Cat=1}; best.EquippedPets={}
    check(Pets.EquipBest(best) and best.EquippedPets.Cat==1 and Pets.EquippedCount(best)==1,"best handles fewer than three")
    check(S.Valid("PetEquipBest",{n=0}) and not S.Valid("PetEquipBest",{n=1,"Bunny"}),"best ignores client pet choice")
    local craft=Schema.New(); craft.Pets={Cat=3}; craft.EquippedPets={Cat=3}; craft.Coins=99
    local crafted,_,result=Pets.Craft(craft,"Cat",{1,2,3})
    check(crafted and result=="Cat_Upgraded" and craft.Pets.Cat==nil and craft.Pets.Cat_Upgraded==1,"three become one upgraded")
    check(craft.Coins==99 and craft.EquippedPets.Cat==nil and craft.EquippedPets.Cat_Upgraded==1,"craft consumes equipped originals and equips result")
    check(math.abs(C.PetMultiplier(craft)-4.4)<.000001,"upgraded multiplier exactly four times x1.10")
    check(Schema.Validate(craft)~=nil,"crafted profile validates")
    check(not Pets.Craft(craft,"Cat_Upgraded",{1,2,3}),"upgraded cannot craft again")
    check(not Pets.Craft(craft,"Cat",{1,2,3}) and craft.Pets.Cat_Upgraded==1,"craft replay cannot duplicate")
    local partial=Schema.New(); partial.Pets={Dog=5}; partial.EquippedPets={Dog=3}
    check(not Pets.Craft(partial,"Dog",{1,1,2}) and partial.Pets.Dog==5,"duplicate craft indices rejected without consumption")
    check(not Pets.Craft(partial,"Dog",{1,2,6}) and partial.Pets.Dog==5,"unowned copy rejected")
    check(not Pets.Craft(partial,"Dog",{[1]=1,[3]=3}) and partial.Pets.Dog==5,"sparse craft selection rejected")
    check(Pets.Craft(partial,"Dog",{2,4,5}) and partial.Pets.Dog==2 and partial.EquippedPets.Dog==2 and partial.EquippedPets.Dog_Upgraded==1,"mixed equipped selection preserves unconsumed copies")
    check(Pets.EquipBest(partial) and partial.EquippedPets.Dog_Upgraded==1,"best includes upgraded")
    check(S.Valid("PetCraft",table.pack("Cat",{1,2,3})) and not S.Valid("PetCraft",table.pack("Cat",{1,2,3},999)),"craft strict arguments")
    check(not S.Valid("PetCraft",table.pack("Cat",{1,2,2})) and not S.Valid("PetCraft",table.pack("Cat_Upgraded",{1,2,3})),"craft invalid selection and variant rejected")
    local legacy=Schema.New(); legacy.Version=3; legacy.Coins=123; legacy.Pets={Cat=2}; legacy.EquippedPets={Cat=1}
    local upgradedSchema=Schema.Validate(legacy)
    check(upgradedSchema and upgradedSchema.Version==5 and upgradedSchema.Coins==123 and upgradedSchema.EquippedPets.Cat==1,"v3 migration preserves progress and team")
    local d=Schema.New()
    check(Schema.Validate(d)~=nil,"default schema")
    local interactions={}
    for _,info in pairs(C.Stations) do table.insert(interactions,{Position=info.Position,Radius=C.TrainDistance}) end
    for _,info in pairs(C.Eggs) do table.insert(interactions,{Position=info.Position,Radius=C.EggDistance}) end
    for i,a in interactions do
        for j=i+1,#interactions do
            local b=interactions[j]; local dx=a.Position.X-b.Position.X; local dy=a.Position.Y-b.Position.Y; local dz=a.Position.Z-b.Position.Z
            check(math.sqrt(dx*dx+dy*dy+dz*dz)>a.Radius+b.Radius,"interaction reach volumes do not overlap")
        end
    end
    local old=Schema.New(); old.Version=1; old.Pets=nil; old.EquippedPet=nil; old.Coins=123
    local migrated=Schema.Validate(old)
    check(migrated and migrated.Version==5 and migrated.Coins==123 and next(migrated.Pets)==nil,"migrate old profile without progress loss")
    local petData=Schema.New()
    check(not Pets.Hatch(petData,"Meadow"),"no coins no hatch")
    petData.Coins=1000
    check(not Pets.Hatch(petData,"Fake"),"unknown egg rejected")
    check(not Pets.Hatch(petData,"Meadow",function() return 0/0 end) and petData.Coins==1000,"bad roll preserves coins")
    for _,case in {{0,"Cat"},{.6,"Dog"},{.9,"Bunny"}} do
        local before=petData.Coins
        local ok,_,id=Pets.Hatch(petData,"Meadow",function() return case[1] end)
        check(ok and id==case[2] and petData.Coins==before-C.Eggs.Meadow.Cost,"weighted hatch and exact cost")
    end
    check(Pets.Count(petData)==3 and petData.EquippedPets.Cat==1,"auto equip first and inventory count")
    Pets.Equip(petData,"")
    check(Pets.Equip(petData,"Bunny") and C.PetMultiplier(petData)==1.35,"owned pet bonus")
    local power,coins=C.Gains(petData,1)
    check(power==6 and coins==10,"server gains include single pet bonus")
    local bonusData=Schema.New(); bonusData.Level=3; bonusData.Rebirths=2
    bonusData.Pets.Bunny=1; bonusData.EquippedPets.Bunny=1
    local totalPower,totalCoins=C.TrainingMultipliers(bonusData,1.25)
    check(math.abs(totalPower-1.6*1.16*1.25*1.35)<.000001 and math.abs(totalCoins-1.45*1.16*1.25*1.35)<.000001,"separate total multipliers combine all active bonuses")
    local gainPower,gainCoins=C.Gains(bonusData,1.25)
    check(gainPower==math.floor(C.BasePower*totalPower) and gainCoins==math.floor(C.BaseCoins*totalCoins),"HUD multipliers match server gain formula")
    check(Schema.Validate(petData)~=nil,"pet profile valid")
    local v2=Schema.Copy(petData); v2.Version=2; v2.EquippedPets=nil; v2.EquippedPet="Bunny"
    local v3=Schema.Validate(v2)
    check(v3 and v3.Version==5 and v3.EquippedPets.Bunny==1 and v3.Pets.Bunny==1,"migrate v2 equipment")
    local team=Schema.New(); team.Pets.Cat=4
    check(Pets.Equip(team,"Cat") and Pets.Equip(team,"Cat") and Pets.Equip(team,"Cat"),"three owned copies can equip")
    check(not Pets.Equip(team,"Cat") and Pets.EquippedCount(team)==3,"fourth ordinary slot denied")
    check(math.abs(C.PetMultiplier(team)-1.3)<.000001,"three active bonuses sum")
    check(Pets.Unequip(team,"Cat") and Pets.EquippedCount(team)==2 and Pets.Equip(team,"Cat"),"remove one and refill")
    team.EquippedPets.Cat=4; check(Schema.Validate(team)==nil,"persisted fourth slot denied")
    local lockedData=Schema.New(); lockedData.Coins=1000
    local minLevel=C.Eggs.Meadow.MinLevel; C.Eggs.Meadow.MinLevel=3
    local lockedOk=Pets.Hatch(lockedData,"Meadow")
    C.Eggs.Meadow.MinLevel=minLevel
    check(not lockedOk and lockedData.Coins==1000,"locked egg never charges")
    petData.Power=C.Requirements(0); petData.Coins=2000; petData.PracticeXP=90
    check(R.Apply(petData) and petData.Pets.Bunny==1 and petData.EquippedPets.Bunny==1,"rebirth preserves pets")
    check(Pets.Equip(petData,"") and C.PetMultiplier(petData)==1,"unequip removes bonus")
    check(not Pets.Equip(Schema.New(),"Dog"),"cannot equip unowned pet")
    local full=Schema.New(); full.Coins=1000; full.Pets.Cat=C.MaxPets
    check(not Pets.Hatch(full,"Meadow") and full.Coins==1000,"capacity blocks without charge")
    full.Pets.Cat+=1; check(Schema.Validate(full)==nil,"oversized inventory rejected")
    local corrupt=Schema.New(); corrupt.Pets.Cat=-1; check(Schema.Validate(corrupt)==nil,"negative pets rejected")
    corrupt=Schema.New(); corrupt.Pets.Fake=1; check(Schema.Validate(corrupt)==nil,"unknown pet rejected")
    corrupt=Schema.New(); corrupt.EquippedPets.Dog=1; check(Schema.Validate(corrupt)==nil,"unowned equipped pet rejected")
    check(S.Valid("Hatch",table.pack("Meadow")) and not S.Valid("Hatch",table.pack("Meadow","Bunny")),"client cannot choose hatch result")
    check(not S.Valid("PetEquip",table.pack({})) and not S.Valid("Hatch",table.pack("Fake")),"malformed pet remotes rejected")
    d.Coins=0/0; check(Schema.Validate(d)==nil,"reject NaN")
    d=Schema.New(); d.Power=math.huge; check(Schema.Validate(d)==nil,"reject infinity")
    d=Schema.New(); d.Coins=-1; check(Schema.Validate(d)==nil,"reject negative")
    d=Schema.New(); check(not P.Upgrade(d),"cannot buy without coins")
    check(not P.Train(d,"Advanced"),"zone level locked")
    P.Train(d,"Basic"); check(d.Power==5 and d.Coins==8 and d.LifetimePower==5,"server training gains")
    for _=1,3 do P.Train(d,"Basic") end
    check(P.Upgrade(d) and d.Level==1 and d.Coins==7,"deduct exact cost")
    check(not R.Apply(d),"early rebirth rejected")
    d.Power=C.Requirements(0); d.Coins=2000; d.PracticeXP=90; d.LastDaily=100; d.Cosmetics.BronzeAura=true; d.Equipped="BronzeAura"
    local lifetime=d.LifetimePower
    check(R.Apply(d),"rebirth allowed")
    check(d.Power==0 and d.Coins==0 and d.Level==0 and d.Rebirths==1,"reset only cycle fields")
    check(d.LifetimePower==lifetime and d.LastDaily==100 and d.Equipped=="BronzeAura","preserve persistent fields")
    check(C.Multiplier(d)==1.08,"controlled permanent bonus")
    d.Rebirths=10; check(Rewards.Reconcile(d) and d.Cosmetics.NeonTrail,"milestone")
    check(not Rewards.Reconcile(d),"milestone idempotent")
    check(not Rewards.Equip(Schema.New(),"NeonTrail"),"unowned cosmetic rejected")
    d=Schema.New(); check(not Rewards.Claim(d,"Daily",1000),"new account reward gated")
    d.TotalTrainings=3
    check(Rewards.Claim(d,"Daily",1000),"daily first claim")
    local coins=d.Coins
    check(not Rewards.Claim(d,"Daily",1001) and d.Coins==coins,"daily duplication rejected")
    check(not Rewards.Claim(d,"Daily",999),"clock rollback")
    check(Rewards.Claim(d,"Daily",1000+C.DailySeconds),"daily interval boundary")
    check(Rewards.Claim(d,"Weekly",1000),"weekly first claim")
    check(not Rewards.Claim(d,"Weekly",1000+C.WeeklySeconds-1),"weekly interval")
    check(Rewards.Claim(d,"Weekly",1000+C.WeeklySeconds),"weekly ready")
    check(not S.Valid("Train",table.pack("Basic",1000000)),"extra reward arg rejected")
    check(not S.Valid("Train",table.pack({})),"wrong type rejected")
    check(not S.Valid("Train",table.pack("Fake")),"unknown station rejected")
    check(not S.Valid("Rebirth",table.pack(true)),"confirmation type rejected")
    check(not S.Valid("Coins",table.pack(100000)),"no give currency action")
    local limiter=S.NewLimiter()
    check(S.Allow(limiter,"Train",limiter.at,0.8),"first request allowed")
    check(not S.Allow(limiter,"Train",limiter.at+0.1,0.8),"cooldown")
    limiter=S.NewLimiter(); local accepted=0; local instant=limiter.at
    for _=1,50 do if S.Allow(limiter,"Request",instant,0) then accepted+=1 end end
    check(accepted==C.RemoteBurst,"bounded remote burst")
    local training=S.NewLimiter(C.TrainRemoteBurst,C.TrainRemotePerSecond)
    local rapid=0; local at=training.at
    for _=1,20 do if S.Allow(training,"Train",at,C.TrainCooldown) then rapid+=1 end end
    check(rapid==20,"twenty taps without cooldown")
    for _=1,100 do S.Allow(training,"Train",at,0) end
    check(not S.Allow(training,"Train",at,0),"training abuse budget bounded")
    check(S.Allow(training,"Train",at+1,0),"training budget refills")
    check(not S.Near({Character=nil},{Position=Vector3.zero},11),"no dead/missing character activity")

    local clock=1000
    local store={records={},calls=0,fail=false,doubleCallback=false,afterWriteFailure=false}
    function store:UpdateAsync(key,callback)
        self.calls+=1
        if self.fail then error("simulated outage") end
        local old=Schema.Copy(self.records[key])
        if self.doubleCallback then callback(Schema.Copy(old)) end
        local result=callback(old)
        if result then self.records[key]=Schema.Copy(result) end
        if result and self.afterWriteFailure then self.afterWriteFailure=false; error("response lost after commit") end
        return Schema.Copy(result)
    end
    local opts={now=function() return clock end,wait=function() end,token="A"}
    local a=Data.new(store,opts)
    check(a:Load(77),"load new player")
    a:Get(77).Pets.Bunny=2; a:Get(77).EquippedPets.Bunny=1; a:Get(77).Pets.Cat_Upgraded=1; a:Get(77).EquippedPets.Cat_Upgraded=1
    a:Get(77).Coins=250; a:Get(77).Zone=3; a:Get(77).PracticeXP=1800; a:Get(77).RebirthXPSpent=90; a:Changed(77)
    store.doubleCallback=true
    check(a:Save(77,false) and store.records.Player_77.Data.Coins==250,"callback retry safe")
    local b=Data.new(store,{now=opts.now,wait=opts.wait,token="B"})
    check(not b:Load(77),"second server session locked")
    local before=Schema.Copy(store.records.Player_77)
    store.fail=true
    local c=Data.new(store,{now=opts.now,wait=opts.wait,token="C"})
    check(not c:Load(77) and c:Get(77)==nil,"load error never exposes default profile")
    check(c:Save(77,true) and store.records.Player_77.Data.Coins==before.Data.Coins,"load error cannot overwrite")
    check(not a:Save(77,false),"save outage handled")
    store.fail=false; store.afterWriteFailure=true
    check(a:Save(77,false) and store.records.Player_77.Data.Coins==250,"commit response lost retry safe")
    check(a:Save(77,true) and store.records.Player_77.Session==nil,"release lock")
    check(b:Load(77) and b:Get(77).Coins==250,"reload persisted progress")
    check(b:Get(77).Zone==3 and b:Get(77).PracticeXP==1800 and b:Get(77).RebirthXPSpent==90,"new zone and XP persistence roundtrip")
    check(b:Get(77).Pets.Bunny==2 and b:Get(77).EquippedPets.Bunny==1,"pet save reload roundtrip")
    check(b:Get(77).Pets.Cat_Upgraded==1 and b:Get(77).EquippedPets.Cat_Upgraded==1,"upgraded pet persistence roundtrip")
    b:Get(77).Coins=400; b:Changed(77); check(b:Save(77,false),"second session saves")
    clock+=C.LeaseSeconds+1
    check(b:Get(77)==nil,"expired lease freezes actions")
    check(c:Load(77),"stale lease takeover")
    check(not b:Save(77,false),"old server cannot overwrite takeover")
    check(store.records.Player_77.Data.Coins==400,"takeover data intact")
    store.records.Player_88={Schema=99,Data=Schema.New(),Revision=0}
    check(not a:Load(88) and store.records.Player_88.Schema==99,"unknown schema preserved")
    store.records.Player_89={Schema=1,Data=Schema.New(),Revision=0}
    store.records.Player_89.Data.Coins=-20
    check(not a:Load(89) and store.records.Player_89.Data.Coins==-20,"corrupt data not overwritten")
    check(c:Save(77,true),"final save")
    local offline=Data.new(nil,{offline=true})
    check(offline:Load(1) and offline:Get(1).Coins==0,"explicit offline default")
    offline.closing=true; check(offline:Get(1)==nil and not offline:Load(2),"shutdown freezes operations")
    check(offline:Save(1,true),"shutdown release")

    local v4=Schema.New(); v4.Version=4; v4.Zone=nil; v4.PracticeXP=nil; v4.RebirthXPSpent=nil
    v4.Power=12345; v4.Pets={Dragon_Upgraded=1}; v4.EquippedPets={Dragon_Upgraded=1}
    local migrated4=Schema.Validate(v4)
    check(migrated4 and migrated4.Version==5 and migrated4.Zone==1 and migrated4.PracticeXP==0 and migrated4.Power==12345 and migrated4.EquippedPets.Dragon_Upgraded==1,"v4 migration keeps jump progress and legacy pets")
    local invalid=Schema.New(); invalid.RebirthXPSpent=1; check(not Schema.Validate(invalid),"cannot spend more XP than earned")
    invalid=Schema.New(); invalid.Zone=6; check(not Schema.Validate(invalid),"unknown zone rejected")
    check(S.Valid("PrepareRebirth",table.pack(5)) and not S.Valid("PrepareRebirth",table.pack(101)) and not S.Valid("PrepareRebirth",table.pack(0/0)),"strict batch prepare arguments")
    check(math.abs(C.JumpHeight(Schema.New())-C.BaseJumpHeight*.05)<1e-9,"initial jump is five percent of baseline")
    local growth=Schema.New(); local before=C.JumpHeight(growth); P.Train(growth,"Basic")
    check(C.JumpHeight(growth)>before,"training actually increases jump height")
    growth.Power=C.MaxValue; check(C.JumpHeight(growth)==C.MaxJumpHeight,"physics height capped")
    local priceP,priceC,priceX=C.BatchRequirements(2,5); local p,c,x=0,0,0
    for i=2,6 do local a,b,d=C.Requirements(i); p+=a;c+=b;x+=d end
    check(priceP==p and priceC==c and priceX==x,"bulk includes exact sum of every ascending cost")
    local batch=Schema.New(); batch.Rebirths=2; batch.Power=p; batch.Coins=c+123; batch.PracticeXP=x; batch.Zone=3; batch.Level=7
    check(C.MaxAffordableRebirths(batch)==5,"maximum affordability includes XP and following costs")
    check(R.Apply(batch,5) and batch.Rebirths==7 and batch.Coins==123 and batch.Power==0 and batch.Level==0 and batch.RebirthXPSpent==x and batch.Zone==3,"bulk atomic reset preserves zone and exact change")
    check(not R.Apply(batch,5),"bulk replay lacks resources")
    for _,bad in {0,-1,.5,101,math.huge,0/0,"5"} do check(C.BatchRequirements(0,bad)==nil,"invalid bulk quantity") end
    check(C.BatchRequirements(C.MaxRebirths-1,2)==nil,"bulk respects rebirth cap")
    local zone=Schema.New(); zone.Coins=10000000; zone.PracticeXP=1799
    check(not P.UnlockZone(zone,3),"cannot skip a zone")
    check(P.UnlockZone(zone,2),"unlock second zone")
    check(not P.UnlockZone(zone,3),"third zone requires at least 1800 active XP")
    P.Practice(zone,1); check(P.UnlockZone(zone,3) and zone.Zone==3,"third zone at activity threshold")
    check(not P.Practice(zone,10000) and not P.Practice(zone,-1),"XP rejects unbounded time")
    local locked=Schema.New(); locked.Coins=C.MaxValue
    check(not Pets.Hatch(locked,"Celestial") and locked.Coins==C.MaxValue,"zone lock cannot be bypassed by coins")
    for i=1,5 do
        check(#C.Zones[i].Eggs==2,"two eggs per zone")
        for _,id in C.Zones[i].Eggs do
            check(C.Eggs[id].Zone==i,"egg belongs to advertised zone")
            for pet in C.Eggs[id].Weights do check(C.PetTypes[pet].Zone==i,"drop belongs to same zone") end
        end
        if i>1 then check(C.PetTypes["Cat_Z"..i].Bonus>C.PetTypes[i==2 and "Cat" or "Cat_Z"..(i-1)].Bonus,"later pets stronger") end
    end
    print(("SIMULATOR_SPEC_PASS %d assertions; jump bulk zones migration leases pets"):format(count))
    return {Assertions=count}
end
return Spec

end
getModule=function(name)
    if cache[name] then return cache[name] end
    assert(moduleFactories[name],"Missing module: "..tostring(name))
    cache[name]=moduleFactories[name]()
    return cache[name]
end
getModule("Spec").Run()
