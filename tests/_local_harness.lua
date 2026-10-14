-- Generated test adapter. Roblox engine and DataStore network are NOT simulated as verified.
local moduleFactories,cache={},{}
local getModule
local root={}
for _,name in {"Schema","PlayerData","Progression","Rebirth","Rewards","Security","Pets"} do root[name]=name end
local Vector3={new=function(x,y,z) return {X=x,Y=y,Z=z} end,zero={X=0,Y=0,Z=0}}
local nextGuid=0
local Http={GenerateGUID=function() nextGuid+=1; return "test-guid-"..nextGuid end}
local game={ReplicatedStorage={SimulatorShared={Config="Config"}},ServerScriptService={Simulator=root}}
function game:GetService(name) assert(name=="HttpService","unexpected engine service"); return Http end
local task={wait=function() error("Unexpected real task.wait in unit tests") end}
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
    ActionCooldown = 0.3, TrainDistance = 6,
    SignRevealDistance = 18, SignHideMargin = 2,
    SignFadeSeconds = 0.25, SignWidth = 220, SignHeight = 70, SignTextSize = 16,
    MilestoneTrail = 10,
    AnalyticsEnabled = false, -- Enable after publishing and checking Dashboard.
    SupportRewardsEnabled = false, PaidItemsEnabled = false,
    MaxPets = 50, PetEquipSlots = 3, HatchCooldown = 4, CraftCooldown = 4, EggDistance = 5.25,
    Rarities = {"Обычная","Редкая","Эпическая","Мифическая","Легендарная","Секретная","Божественная"},
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

end
moduleFactories["Schema"] = function()
local require=getModule; local script={Parent=root}
local C = require(game.ReplicatedStorage.SimulatorShared.Config)
local Schema = {}
function Schema.New()
    return {Version = 4, Coins = 0, Power = 0, Level = 0, Rebirths = 0,
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
    if type(raw) ~= "table" or (raw.Version ~= 1 and raw.Version ~= 2 and raw.Version ~= 3 and raw.Version ~= 4) then return nil end
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
        if key ~= "Version" and key ~= "EquippedPets" and (raw.Version >= 2 or key ~= "Pets") then
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
local P = {}
function P.Train(data, stationId)
    local station = C.Stations[stationId]
    if not station or data.Level < station.MinLevel then return false, "Станция откроется на уровне 3." end
    local power, coins = C.Gains(data, station.Multiplier)
    data.Power = math.min(C.MaxValue, data.Power+power)
    data.Coins = math.min(C.MaxValue, data.Coins+coins)
    data.LifetimePower = math.min(C.MaxValue, data.LifetimePower+power)
    data.TotalTrainings = math.min(C.MaxValue, data.TotalTrainings+1)
    return true, ("+%d силы, +%d монет"):format(power, coins)
end
function P.Upgrade(data)
    if data.Level >= C.MaxLevel then return false, "Максимальный уровень тренировки." end
    local cost=C.UpgradeCost(data.Level)
    if data.Coins < cost then return false, "Не хватает монет на улучшение." end
    data.Coins-=cost; data.Level+=1
    return true, "Тренировка усилена! Уровень "..data.Level
end
return P

end
moduleFactories["Rebirth"] = function()
local require=getModule; local script={Parent=root}
local C = require(game.ReplicatedStorage.SimulatorShared.Config)
local R = {}
function R.Apply(data)
    if data.Rebirths>=C.MaxRebirths then return false, "Достигнут предел перерождений MVP." end
    local power, coins=C.Requirements(data.Rebirths)
    if data.Power<power or data.Coins<coins then return false, "Для перерождения нужны сила и монеты." end
    -- Lifetime score, reward timestamps and cosmetics deliberately survive the reset.
    data.Power=0; data.Coins=0; data.Level=0; data.Rebirths+=1
    return true, ("Перерождение! Постоянный бонус: x%.2f"):format(C.Multiplier(data))
end
return R

end
moduleFactories["Rewards"] = function()
local require=getModule; local script={Parent=root}
local C=require(game.ReplicatedStorage.SimulatorShared.Config)
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
    return true, ("Награда: +%d монет"):format(reward)
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
function S.NewLimiter() return {tokens=C.RemoteBurst, at=os.clock(), actions={}} end
function S.Allow(limiter, action, now, cooldown)
    limiter.tokens=math.min(C.RemoteBurst, limiter.tokens+(now-limiter.at)*C.RemotePerSecond)
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
    if data.Level < egg.MinLevel then return false, "Яйцо недоступно: нужен уровень "..egg.MinLevel.."." end
    if Pets.Count(data) >= C.MaxPets then return false, "Инвентарь питомцев заполнен (50)." end
    if data.Coins < egg.Cost then return false, "Не хватает монет на яйцо." end
    local value = roll and roll() or math.random()
    if type(value) ~= "number" or value ~= value or value < 0 or value >= 1 then
        return false, "Не удалось открыть яйцо. Монеты не списаны."
    end
    local total = 0
    for _, id in C.PetOrder do total += egg.Weights[id] end
    local threshold, selected = 0, nil
    for _, id in C.PetOrder do
        threshold += egg.Weights[id] / total
        if value < threshold then selected = id; break end
    end
    selected = selected or C.PetOrder[#C.PetOrder]
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
    check(upgradedSchema and upgradedSchema.Version==4 and upgradedSchema.Coins==123 and upgradedSchema.EquippedPets.Cat==1,"v3 migration preserves progress and team")
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
    check(migrated and migrated.Version==4 and migrated.Coins==123 and next(migrated.Pets)==nil,"migrate old profile without progress loss")
    local petData=Schema.New()
    check(not Pets.Hatch(petData,"Meadow"),"no coins no hatch")
    petData.Coins=1000
    check(not Pets.Hatch(petData,"Fake"),"unknown egg rejected")
    check(not Pets.Hatch(petData,"Meadow",function() return 0/0 end) and petData.Coins==1000,"bad roll preserves coins")
    for _,case in {{0,"Cat"},{.6,"Dog"},{.9,"Bunny"}} do
        local before=petData.Coins
        local ok,_,id=Pets.Hatch(petData,"Meadow",function() return case[1] end)
        check(ok and id==case[2] and petData.Coins==before-80,"weighted hatch and exact cost")
    end
    check(Pets.Count(petData)==3 and petData.EquippedPets.Cat==1,"auto equip first and inventory count")
    Pets.Equip(petData,"")
    check(Pets.Equip(petData,"Bunny") and C.PetMultiplier(petData)==1.35,"owned pet bonus")
    local power,coins=C.Gains(petData,1)
    check(power==6 and coins==10,"server gains include single pet bonus")
    local bonusData=Schema.New(); bonusData.Level=3; bonusData.Rebirths=2
    bonusData.Pets.Bunny=1; bonusData.EquippedPets.Bunny=1
    local totalPower,totalCoins=C.TrainingMultipliers(bonusData,1.25)
    check(math.abs(totalPower-3.348)<.000001 and math.abs(totalCoins-3.034125)<.000001,"separate total multipliers combine all active bonuses")
    local gainPower,gainCoins=C.Gains(bonusData,1.25)
    check(gainPower==math.floor(C.BasePower*totalPower) and gainCoins==math.floor(C.BaseCoins*totalCoins),"HUD multipliers match server gain formula")
    check(Schema.Validate(petData)~=nil,"pet profile valid")
    local v2=Schema.Copy(petData); v2.Version=2; v2.EquippedPets=nil; v2.EquippedPet="Bunny"
    local v3=Schema.Validate(v2)
    check(v3 and v3.Version==4 and v3.EquippedPets.Bunny==1 and v3.Pets.Bunny==1,"migrate v2 equipment")
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
    petData.Power=200; petData.Coins=150
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
    d.Power=200; d.Coins=150; d.LastDaily=100; d.Cosmetics.BronzeAura=true; d.Equipped="BronzeAura"
    local lifetime=d.LifetimePower
    check(R.Apply(d),"rebirth allowed")
    check(d.Power==0 and d.Coins==0 and d.Level==0 and d.Rebirths==1,"reset only cycle fields")
    check(d.LifetimePower==lifetime and d.LastDaily==100 and d.Equipped=="BronzeAura","preserve persistent fields")
    check(C.Multiplier(d)==1.12,"controlled permanent bonus")
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
    a:Get(77).Coins=250; a:Changed(77)
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

    local balance={}; d=Schema.New()
    for cycle=1,26 do
        local powerReq,coinReq=C.Requirements(d.Rebirths)
        local actions=0
        -- A simple player strategy: buy levels 1..3 while still building power.
        while d.Power<powerReq or d.Coins<coinReq do
            local station=d.Level>=3 and "Advanced" or "Basic"
            P.Train(d,station); actions+=1
            if d.Level<3 and d.Power<powerReq and d.Coins>=C.UpgradeCost(d.Level) then P.Upgrade(d) end
            assert(actions<500,"unreachable rebirth")
        end
        balance[cycle]=actions*C.TrainCooldown
        check(R.Apply(d),"balance cycle "..cycle)
    end
    check(balance[1]<=90 and balance[2]<=balance[1]*1.2,"early pacing")
    check(balance[26]<balance[1],"later cycles moderately faster")
    print(("SIMULATOR_SPEC_PASS %d assertions; cycle_seconds [1]=%.1f [2]=%.1f [10]=%.1f [26]=%.1f")
        :format(count,balance[1],balance[2],balance[10],balance[26]))
    return {Assertions=count,Balance=balance}
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
