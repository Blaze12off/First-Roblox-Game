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
        balance[cycle]=actions -- Click pacing belongs to the player, not a training timer.
        check(R.Apply(d),"balance cycle "..cycle)
    end
    check(balance[1]<=90 and balance[2]<=balance[1]*1.2,"early pacing")
    check(balance[26]<balance[1],"later cycles moderately faster")
    print(("SIMULATOR_SPEC_PASS %d assertions; cycle_clicks [1]=%.0f [2]=%.0f [10]=%.0f [26]=%.0f")
        :format(count,balance[1],balance[2],balance[10],balance[26]))
    return {Assertions=count,Balance=balance}
end
return Spec
