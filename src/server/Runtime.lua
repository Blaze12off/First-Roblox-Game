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
local number=require(game.ReplicatedStorage.SimulatorShared.NumberFormat).Compact
local dataService,remotes,map,mode
local function loadCharacterAtSpawn(player)
    local ok=pcall(function() player:LoadCharacterAsync() end)
    if not ok or player.Parent~=Players then return false end
    local character=player.Character
    local root=character and character:WaitForChild("HumanoidRootPart",10)
    if not root then return false end
    -- LoadCharacterAsync finalizes the engine spawn transform; move only after it returns.
    root.AssemblyLinearVelocity=Vector3.zero; root.AssemblyAngularVelocity=Vector3.zero
    local saved=dataService and dataService:Get(player.UserId)
    character:PivotTo(CFrame.new(saved and C.Zones[saved.Zone].Position or C.SpawnPosition))
    return true
end
local function stats(player,data)
    local folder=player:FindFirstChild("leaderstats")
    if not folder then
        folder=Instance.new("Folder"); folder.Name="leaderstats"; folder.Parent=player
        for _, name in {"Rebirths","JumpRecord"} do local n=Instance.new("NumberValue"); n.Name=name; n.Parent=folder end
    end
    folder.Rebirths.Value=data.Rebirths; folder.JumpRecord.Value=data.LifetimePower
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
    local limiter=(action=="Train" or action=="Jump") and session.trainLimiter or session.limiter
    if not Security.Allow(limiter,"Request",now,0) then return false,"rate" end
    local args=table.pack(...)
    if not Security.Valid(action,args) then return false,"arguments" end
    local cooldown=action=="Jump" and .35 or action=="Train" and C.TrainCooldown or action=="Hatch" and C.HatchCooldown or action=="PetCraft" and C.CraftCooldown or action=="Rebirth" and 2 or action=="Sync" and 1 or C.ActionCooldown
    local last=session.actionTimes[action]
    if last and now-last<cooldown then return false,"cooldown" end
    session.actionTimes[action]=now
    local data=dataService:Get(player.UserId)
    if not data then return false,"data_unavailable" end
    if action=="Sync" then publish(player); return true end
    if action=="PetMenu" then
        local near=false; local selected,nearest=nil,math.huge
        for id in pairs(C.Eggs) do
            local stand=map:FindFirstChild("Egg"..id)
            if stand and Security.Near(player,stand,C.EggDistance) then
                local distance=(player.Character.HumanoidRootPart.Position-stand.Position).Magnitude
                if distance<nearest then near=true; nearest=distance; selected=id end
            end
        end
        if not near then return false,"distance" end
        notice(player,"Яйца открываются за игровые монеты.",{OpenPets=true,EggId=selected}); return true
    end
    if action=="PrepareRebirth" then
        local amount=args[1] or 1
        local power,coins,xp=C.BatchRequirements(data.Rebirths,amount)
        if not power or data.Power<power or data.Coins<coins or C.AvailablePractice(data)<xp then
            notice(player,"Пока не хватает прыжка, монет или опыта для этой суммы."); return false,"conditions"
        end
        session.confirm={token=HttpService:GenerateGUID(false),expires=now+20,rebirths=data.Rebirths,amount=amount}
        notice(player,("Перерождений: %d. Требуется %s прыжка, списание %s монет и %s опыта. Прыжок и улучшения сбросятся; зоны и питомцы сохранятся."):format(amount,number(power),number(coins),number(xp)),
            {RebirthToken=session.confirm.token,NextMultiplier=C.Multiplier({Rebirths=data.Rebirths+amount})})
        return true
    end
    local previousMultiplier=C.Multiplier(data)
    local ok,message,resultId
    if action=="Zone" then
        local target
        for _,gate in map:GetChildren() do if gate:GetAttribute("TargetZone")==args[1] and Security.Near(player,gate,8) then target=gate; break end end
        if not target then return false,"distance" end
        if args[1]<=data.Zone then ok,message=true,"Переход в зону."
        else ok,message=Progression.UnlockZone(data,args[1]) end
        if ok then player.Character:PivotTo(CFrame.new(C.Zones[args[1]].Position)) end
    elseif action=="Jump" then
        local char=player.Character; local human=char and char:FindFirstChildOfClass("Humanoid")
        local root=char and char:FindFirstChild("HumanoidRootPart")
        if not human or human.Health<=0 or not root then return false,"not_jumping" end
        -- Input can reach the server before the network-owned character's physics update.
        -- Wait briefly for actual upward motion; a remote alone never grants a reward.
        local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={char}
        local groundRay=Vector3.new(0,-(human.HipHeight+root.Size.Y/2+3),0)
        local groundAtRequest=workspace:Raycast(root.Position,groundRay,params)
        local initialY=root.Position.Y; local launched=false
        for _=1,6 do
            if root.AssemblyLinearVelocity.Y>1 or root.Position.Y>initialY+.03 then launched=true; break end
            task.wait(.025)
        end
        if not launched or player.Character~=char or human.Health<=0 or dataService:Get(player.UserId)~=data then return false,"not_jumping" end
        if not groundAtRequest and not workspace:Raycast(root.Position,groundRay,params) then return false,"not_ground_launch" end
        ok,message=Progression.Train(data,"Basic"); session.lastPractice=now
    elseif action=="Train" then
        local station=C.Stations[args[1]]
        local pad=map:FindFirstChild(args[1])
        if not pad or not Security.Near(player,pad,C.TrainDistance) then return false,"distance" end
        if data.Level<station.MinLevel then notice(player,"Продвинутая станция: нужен уровень 3."); return false,"level" end
        ok,message=Progression.Train(data,args[1]); if ok then session.lastPractice=now end
    elseif action=="Hatch" then
        local stand=map:FindFirstChild("Egg"..args[1])
        if not stand or not Security.Near(player,stand,C.EggDistance) then
            notice(player,"Подойди к выбранному яйцу."); return false,"distance"
        end
        ok,message,resultId=Pets.Hatch(data,args[1])
    elseif action=="PetCraft" then ok,message,resultId=Pets.Craft(data,args[1],args[2])
    elseif action=="PetEquip" then ok,message=Pets.Equip(data,args[1])
    elseif action=="PetUnequip" then ok,message=Pets.Unequip(data,args[1])
    elseif action=="PetEquipBest" then ok,message=Pets.EquipBest(data)
    elseif action=="Upgrade" then ok,message=Progression.Upgrade(data)
    elseif action=="Rebirth" then
        local confirmation=session.confirm
        session.confirm=nil -- Single use, expires, bound to this player's current cycle.
        if not confirmation or confirmation.token~=args[1] or confirmation.expires<now
            or confirmation.rebirths~=data.Rebirths then return false,"confirmation" end
        ok,message=Rebirth.Apply(data,confirmation.amount)
    elseif action=="Daily" or action=="Weekly" then ok,message=Rewards.Claim(data,action,os.time())
    elseif action=="Equip" then ok,message=Rewards.Equip(data,args[1]) end
    if not ok then notice(player,message or "Действие недоступно."); return false,"conditions" end
    Rewards.Reconcile(data)
    dataService:Changed(player.UserId)
    if action=="Equip" or action=="Rebirth" then Rewards.ApplyCharacter(player,data) end
    if action=="PetEquip" or action=="PetUnequip" or action=="PetEquipBest" or action=="Hatch" or action=="PetCraft" then PetVisuals.Apply(player,data) end
    Progression.ApplyJump(player,data)
    publish(player)
    local extra
    if action=="Hatch" or action=="PetCraft" or action=="Rebirth" then
        extra={Result={Action=action,Id=resultId,Source=args[1],Duration=action=="Rebirth" and 2 or 4,Multiplier=C.Multiplier(data),PreviousMultiplier=previousMultiplier}}
    end
    notice(player,message,extra)
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
    Runtime.sessions[player.UserId]={limiter=Security.NewLimiter(),trainLimiter=Security.NewLimiter(C.TrainRemoteBurst,C.TrainRemotePerSecond),actionTimes={},saveStatus="ready"}
    local data=dataService:Get(player.UserId)
    if not data then player:Kick("Сессия данных истекла. Войди снова."); return end
    if Rewards.Reconcile(data) then dataService:Changed(player.UserId) end
    stats(player,data)
    player.CharacterAdded:Connect(function(char)
        local root=char:WaitForChild("HumanoidRootPart",10)
        local current=dataService:Get(player.UserId)
        if root and current then Rewards.ApplyCharacter(player,current); PetVisuals.Apply(player,current); Progression.ApplyJump(player,current) end
        local humanoid=char:WaitForChild("Humanoid",10)
        if humanoid then
            humanoid.Died:Connect(function()
                task.delay(3,function()
                    if player.Parent==Players and dataService:Get(player.UserId) then
                        local loaded=loadCharacterAtSpawn(player)
                        if not loaded then player:Kick("Не удалось загрузить персонажа. Войди снова.") end
                    end
                end)
            end)
        end
    end)
    local loaded=loadCharacterAtSpawn(player)
    if not loaded then player:Kick("Не удалось загрузить персонажа. Войди снова."); return end
    Progression.ApplyJump(player,data)
    if data.Zone>1 then player.Character:PivotTo(CFrame.new(C.Zones[data.Zone].Position)) end
    publish(player); Telemetry.Step(player,1,"Joined")
end
-- Test access is server-only and fails closed outside an offline Studio sandbox.
function Runtime.StudioProfile(player)
    assert(RunService:IsStudio() and mode=="sandbox","Studio sandbox only")
    return dataService:Get(player.UserId)
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
    for _,gate in map:GetChildren() do
        local target=gate:GetAttribute("TargetZone")
        if target then gate.ZonePrompt.Triggered:Connect(function(player) Runtime.Dispatch(player,"Zone",target) end) end
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
    task.spawn(function()
        while not dataService.closing do
            task.wait(1)
            for _,player in Players:GetPlayers() do
                local session=Runtime.sessions[player.UserId]; local data=dataService:Get(player.UserId)
                local human=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
                -- At most one XP per elapsed second; no AFK/offline/click-rate or pet multiplier.
                if data and session and human and human.Health>0 and session.lastPractice and os.clock()-session.lastPractice<=1.5 then
                    Progression.Practice(data,1); dataService:Changed(player.UserId); publish(player)
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
