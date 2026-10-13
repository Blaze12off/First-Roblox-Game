local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local HttpService=game:GetService("HttpService")
local DataStoreService=game:GetService("DataStoreService")
local C=require(game.ReplicatedStorage.SimulatorShared.Config)
local PlayerData=require(script.Parent.PlayerData)
local Progression=require(script.Parent.Progression)
local Rebirth=require(script.Parent.Rebirth)
local Rewards=require(script.Parent.Rewards)
local Security=require(script.Parent.Security)
local Network=require(script.Parent.Network)
local World=require(script.Parent.World)
local Telemetry=require(script.Parent.Telemetry)
local Pets=require(script.Parent.Pets)
local PetVisuals=require(script.Parent.PetVisuals)
local Runtime={sessions={},started=false}
local dataService,remotes,map,mode
local function stats(player,data)
    local folder=player:FindFirstChild("leaderstats")
    if not folder then
        folder=Instance.new("Folder"); folder.Name="leaderstats"; folder.Parent=player
        for _, name in {"Rebirths","LifetimePower"} do local n=Instance.new("NumberValue"); n.Name=name; n.Parent=folder end
    end
    folder.Rebirths.Value=data.Rebirths; folder.LifetimePower.Value=data.LifetimePower
end
local function publish(player)
    local data=dataService:Get(player.UserId)
    if data and player.Parent==Players then
        stats(player,data)
        local session=Runtime.sessions[player.UserId]
        remotes.State:FireClient(player,Network.Snapshot(data,mode,session and session.saveStatus))
    end
end
local function notice(player,message,extra)
    if player.Parent==Players then remotes.Notice:FireClient(player,message,extra) end
end
-- Shared by the RemoteEvent and ProximityPrompt. Tests call the SAME gate on server.
function Runtime.Dispatch(player,action,...)
    local session=Runtime.sessions[player.UserId]
    if not session then return false,"loading" end
    local now=os.clock()
    if not Security.Allow(session.limiter,"Request",now,0) then return false,"rate" end
    local args=table.pack(...)
    if not Security.Valid(action,args) then return false,"arguments" end
    local cooldown=action=="Train" and C.TrainCooldown or (action=="Hatch" and C.HatchCooldown or (action=="Sync" and 1 or C.ActionCooldown))
    local last=session.actionTimes[action]
    if last and now-last<cooldown then return false,"cooldown" end
    session.actionTimes[action]=now
    local data=dataService:Get(player.UserId)
    if not data then return false,"data_unavailable" end
    if action=="Sync" then publish(player); return true end
    if action=="PetMenu" then
        local near=false
        for id in pairs(C.Eggs) do
            local stand=map:FindFirstChild("Egg"..id)
            if stand and Security.Near(player,stand,C.EggDistance) then near=true; break end
        end
        if not near then return false,"distance" end
        notice(player,"Яйца открываются за игровые монеты.",{OpenPets=true}); return true
    end
    if action=="PrepareRebirth" then
        local power,coins=C.Requirements(data.Rebirths)
        if data.Power<power or data.Coins<coins or data.Rebirths>=C.MaxRebirths then
            notice(player,"Пока не хватает силы или монет для перерождения."); return false,"conditions"
        end
        session.confirm={token=HttpService:GenerateGUID(false),expires=now+20,rebirths=data.Rebirths}
        notice(player,"Перерождение сбросит силу, монеты и уровень. Косметика и рекорд сохранятся.",
            {RebirthToken=session.confirm.token,NextMultiplier=C.Multiplier({Rebirths=data.Rebirths+1})})
        return true
    end
    local ok,message
    if action=="Train" then
        local station=C.Stations[args[1]]
        local pad=map:FindFirstChild(args[1])
        if not pad or not Security.Near(player,pad,C.TrainDistance) then return false,"distance" end
        if data.Level<station.MinLevel then notice(player,"Продвинутая станция: нужен уровень 3."); return false,"level" end
        ok,message=Progression.Train(data,args[1])
    elseif action=="Hatch" then
        local stand=map:FindFirstChild("Egg"..args[1])
        if not stand or not Security.Near(player,stand,C.EggDistance) then
            notice(player,"Подойди к выбранному яйцу."); return false,"distance"
        end
        ok,message=Pets.Hatch(data,args[1])
    elseif action=="PetEquip" then ok,message=Pets.Equip(data,args[1])
    elseif action=="PetUnequip" then ok,message=Pets.Unequip(data,args[1])
    elseif action=="PetEquipBest" then ok,message=Pets.EquipBest(data)
    elseif action=="Upgrade" then ok,message=Progression.Upgrade(data)
    elseif action=="Rebirth" then
        local confirmation=session.confirm
        session.confirm=nil -- Single use, expires, bound to this player's current cycle.
        if not confirmation or confirmation.token~=args[1] or confirmation.expires<now
            or confirmation.rebirths~=data.Rebirths then return false,"confirmation" end
        ok,message=Rebirth.Apply(data)
    elseif action=="Daily" or action=="Weekly" then ok,message=Rewards.Claim(data,action,os.time())
    elseif action=="Equip" then ok,message=Rewards.Equip(data,args[1]) end
    if not ok then notice(player,message or "Действие недоступно."); return false,"conditions" end
    Rewards.Reconcile(data)
    dataService:Changed(player.UserId)
    if action=="Equip" or action=="Rebirth" then Rewards.ApplyCharacter(player,data) end
    if action=="PetEquip" or action=="PetUnequip" or action=="PetEquipBest" or action=="Hatch" then PetVisuals.Apply(player,data) end
    publish(player); notice(player,message)
    if action=="Train" and data.TotalTrainings==1 then Telemetry.Step(player,2,"FirstTraining") end
    if action=="Upgrade" and data.Level==1 then Telemetry.Step(player,3,"FirstUpgrade") end
    if action=="Rebirth" and data.Rebirths==1 then Telemetry.Step(player,4,"FirstRebirth") end
    return true
end
local function savePlayer(player,release)
    local ok,reason=dataService:Save(player.UserId,release)
    local session=Runtime.sessions[player.UserId]
    if not release and session then
        session.saveStatus=ok and "saved" or "retry"
        publish(player)
        if not ok then notice(player,"Сохранение задерживается. Игра повторит попытку.") end
    end
    if not ok then warn("Simulator save failed: "..tostring(reason)) end
    return ok
end
local function joined(player)
    local ok,reason=dataService:Load(player.UserId)
    if not ok then
        if player.Parent==Players then player:Kick("Не удалось безопасно загрузить прогресс ("..reason.."). Подожди и войди снова. Данные не сброшены.") end
        return
    end
    if player.Parent~=Players or dataService.closing then dataService:Save(player.UserId,true); return end
    Runtime.sessions[player.UserId]={limiter=Security.NewLimiter(),actionTimes={},saveStatus="ready"}
    local data=dataService:Get(player.UserId)
    if not data then player:Kick("Сессия данных истекла. Войди снова."); return end
    if Rewards.Reconcile(data) then dataService:Changed(player.UserId) end
    stats(player,data)
    player.RespawnLocation=map.SimulatorSpawn
    player.CharacterAdded:Connect(function(char)
        local root=char:WaitForChild("HumanoidRootPart",10)
        local current=dataService:Get(player.UserId)
        if root and current then Rewards.ApplyCharacter(player,current); PetVisuals.Apply(player,current) end
        local humanoid=char:WaitForChild("Humanoid",10)
        if humanoid then
            humanoid.Died:Connect(function()
                task.delay(3,function()
                    if player.Parent==Players and dataService:Get(player.UserId) then
                        local loaded=pcall(function() player:LoadCharacterAsync() end)
                        if not loaded then player:Kick("Не удалось загрузить персонажа. Войди снова.") end
                    end
                end)
            end)
        end
    end)
    local loaded=pcall(function() player:LoadCharacterAsync() end)
    if not loaded then player:Kick("Не удалось загрузить персонажа. Войди снова."); return end
    publish(player); Telemetry.Step(player,1,"Joined")
end
function Runtime.Start()
    assert(not Runtime.started,"Runtime already started"); Runtime.started=true
    Players.CharacterAutoLoads=false
    mode=RunService:IsStudio() and C.StudioOffline and "sandbox" or "datastore"
    local store
    if mode=="datastore" then
        store=DataStoreService:GetDataStore(RunService:IsStudio() and C.StudioStoreName or C.StoreName)
    end
    dataService=PlayerData.new(store,{offline=mode=="sandbox"})
    map=World.Build(); remotes=Network.Create()
    remotes.Action.OnServerEvent:Connect(function(player,action,...) Runtime.Dispatch(player,action,...) end)
    for id in pairs(C.Stations) do
        map[id].TrainPrompt.Triggered:Connect(function(player) Runtime.Dispatch(player,"Train",id) end)
    end
    for id in pairs(C.Eggs) do
        map["Egg"..id].EggPrompt.Triggered:Connect(function(player) Runtime.Dispatch(player,"PetMenu") end)
    end
    Players.PlayerAdded:Connect(joined)
    Players.PlayerRemoving:Connect(function(player)
        savePlayer(player,true); Runtime.sessions[player.UserId]=nil
    end)
    for _, player in Players:GetPlayers() do task.spawn(joined,player) end
    task.spawn(function()
        while not dataService.closing do
            task.wait(C.AutoSaveSeconds)
            if dataService.closing then break end
            for _,player in Players:GetPlayers() do task.spawn(savePlayer,player,false) end
        end
    end)
    task.spawn(function()
        while not dataService.closing do
            task.wait(2)
            for _,player in Players:GetPlayers() do
                if Runtime.sessions[player.UserId] and not dataService:Get(player.UserId) then
                    player:Kick("Защита данных: сохранение недоступно или сессия истекла. Войди снова позже.")
                end
            end
        end
    end)
    game:BindToClose(function()
        dataService.closing=true
        local pending=0
        for userId in pairs(dataService.profiles) do
            pending+=1
            task.spawn(function()
                local ok=dataService:Save(userId,true)
                if not ok then warn("Simulator final save failed") end
                pending-=1
            end)
        end
        local deadline=os.clock()+25
        while (pending>0 or next(dataService.loading)~=nil) and os.clock()<deadline do task.wait(0.1) end
    end)
    print("SIMULATOR_READY mode="..mode)
end
return Runtime
