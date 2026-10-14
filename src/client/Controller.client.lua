local Players=game:GetService("Players")
local player=Players.LocalPlayer
local C=require(game.ReplicatedStorage:WaitForChild("SimulatorShared"):WaitForChild("Config"))
local UI=require(script.Parent.UI)
local refs=UI.Build(player)
-- The edge HUD renders the training hint; keep the prompt's E/gamepad input without duplicate default UI.
local function styleTrainingPrompt(obj)
    if obj:IsA("ProximityPrompt") and (obj.Name=="TrainPrompt" or obj.Name=="EggPrompt") then obj.Style=Enum.ProximityPromptStyle.Custom end
end
workspace.DescendantAdded:Connect(styleTrainingPrompt)
for _,obj in workspace:GetDescendants() do styleTrainingPrompt(obj) end
local remotes=game.ReplicatedStorage:WaitForChild("SimulatorRemotes")
local action=remotes:WaitForChild("Action")
local state,rebirthToken,serverOffset
local stationFactor=1
local function renderMultipliers()
    if not state then return end
    local power,coins=C.TrainingMultipliers(state,stationFactor)
    refs.PowerMultiplier.Text=("Сила  x%.2f"):format(power)
    refs.CoinMultiplier.Text=("Монеты  x%.2f"):format(coins)
end
local noticeVersion=0
local function showNotice(message)
    noticeVersion+=1
    local version=noticeVersion
    refs.Notice.Text=message; refs.Notice.Visible=not refs.Animation.Busy
    task.delay(4,function() if noticeVersion==version then refs.Notice.Visible=false end end)
end
local function request(name,...)
    -- This only improves UX. Every limit/condition is rechecked on the server.
    if state and not refs.Animation.Busy then action:FireServer(name,...) end
end
local function cooldownText(last,seconds,title,now)
    if state.TotalTrainings<C.RewardMinTrainings then return title.." • 3 тренировки" end
    local remaining=last==0 and 0 or math.max(0,last+seconds-now)
    if remaining==0 then return title.." • забрать" end
    local hours=math.floor(remaining/3600); local minutes=math.floor(remaining%3600/60)
    return ("%s • %dч %dм"):format(title,hours,minutes)
end
local function render()
    if not state then return end
    renderMultipliers()
    refs.Power.Text=tostring(state.Power)
    refs.Coins.Text=tostring(state.Coins)
    refs.Catalog.Update(state)
    refs.Level.Text="Уровень "..state.Level
    refs.RebirthStats.Text=("%d • x%.2f"):format(state.Rebirths,state.Multiplier)
    refs.Bonus.Text=("Постоянный бонус: x%.2f  •  Рекорд: %d"):format(state.Multiplier,state.LifetimePower)
    refs.Goal.Text=("До Rebirth: %d / %d силы\n%d / %d монет"):format(state.Power,state.RequiredPower,state.Coins,state.RequiredCoins)
    refs.Progress(math.min(1,state.Power/state.RequiredPower,state.Coins/state.RequiredCoins))
    refs.Upgrade.Text=state.UpgradeCost>0 and ("Улучшение: "..state.UpgradeCost.." монет") or "Уровень тренировки: максимум"
    local now=os.time()+(serverOffset or 0)
    local rewardsReady=state.TotalTrainings>=C.RewardMinTrainings
    local dailyReady=rewardsReady and (state.LastDaily==0 or now>=state.LastDaily+C.DailySeconds)
    local weeklyReady=rewardsReady and (state.LastWeekly==0 or now>=state.LastWeekly+C.WeeklySeconds)
    local rebirthReady=state.Rebirths<C.MaxRebirths and state.Power>=state.RequiredPower and state.Coins>=state.RequiredCoins
    refs.Notifications((dailyReady and 1 or 0)+(weeklyReady and 1 or 0),rebirthReady and 1 or 0)
    refs.Daily.Text=cooldownText(state.LastDaily,C.DailySeconds,"Ежедневная",now)
    refs.Weekly.Text=cooldownText(state.LastWeekly,C.WeeklySeconds,"Недельная",now)
    refs.Cosmetic.Text=state.NeonTrail and ("Неоновый след • "..(state.Equipped=="NeonTrail" and "выключить" or "включить"))
        or state.BronzeAura and ("Бронзовая аура • "..(state.Equipped=="BronzeAura" and "выключить" or "включить"))
        or "Косметика: аура за 1, след за 10 Rebirth"
    if state.TotalTrainings==0 then refs.Hint.Text=game:GetService("UserInputService").TouchEnabled and "Подойди к зелёной платформе и нажми «Тренироваться»." or "Подойди к зелёной платформе и нажми E."
    elseif state.Level==0 then refs.Hint.Text="Открой магазин: первое улучшение стоит 25 монет."
    else refs.Hint.Text="" end
    refs.Hint.Visible=refs.Hint.Text~="" and not refs.Animation.Busy and refs.ShouldShow("Hint")
end
remotes.State.OnClientEvent:Connect(function(snapshot)
    state=snapshot; serverOffset=snapshot.ServerTime-os.time(); render()
end)
remotes.Notice.OnClientEvent:Connect(function(message,extra)
    showNotice(message)
    if extra and extra.OpenPets then
        refs.Open("Pets"); refs.Catalog.Select("Eggs")
        if extra.EggId then refs.Catalog.Inspect(extra.EggId,true) end
    end
    if extra and extra.Result then
        if extra.Result.Action=="Rebirth" then refs.Close() end
        refs.PlayResult(extra.Result,function()
            if extra.Result.Action=="PetCraft" and refs.ActiveMenu=="Pets" then refs.Catalog.Inspect(extra.Result.Id,false) end
            render()
        end)
    end
    if extra and extra.RebirthToken then
        rebirthToken=extra.RebirthToken
        refs.Dialog.Text=message..("\n\nНовый постоянный бонус: x%.2f\nПодтверждение действует 20 секунд."):format(extra.NextMultiplier)
        refs.Open("Confirm")
    end
end)
local nearestAction,nearestId
refs.Train.Activated:Connect(function()
    if not nearestId then showNotice("Подойди к платформе или яйцу."); return end
    if nearestAction=="Egg" then request("PetMenu") else request("Train",nearestId) end
end)
refs.Upgrade.Activated:Connect(function() request("Upgrade") end)
refs.Catalog.SetCallbacks({Action=function(name,id,copies)
    if copies then request(name,id,copies) elseif id then request(name,id) else request(name) end
end})
refs.Prepare.Activated:Connect(function() request("PrepareRebirth") end)
refs.Daily.Activated:Connect(function() request("Daily") end)
refs.Weekly.Activated:Connect(function() request("Weekly") end)
refs.Cosmetic.Activated:Connect(function()
    if not state then return end
    local item=state.NeonTrail and "NeonTrail" or state.BronzeAura and "BronzeAura" or nil
    if item then request("Equip",state.Equipped==item and "" or item) end
end)
refs.Cancel.Activated:Connect(function() rebirthToken=nil; refs.Close() end)
refs.Confirm.Activated:Connect(function()
    local token=rebirthToken; rebirthToken=nil; refs.Close()
    if token then request("Rebirth",token) end
end)
-- Single nearest interaction and mutually exclusive reach volumes, shared with server checks.
task.spawn(function()
    while refs.Gui.Parent do
        local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        nearestAction,nearestId=nil,nil
        local selectedFactor,nearest=1,math.huge
        if root and state then
            for id,station in pairs(C.Stations) do
                local distance=(root.Position-station.Position).Magnitude
                if distance<=C.TrainDistance and distance<nearest then
                    nearest=distance; nearestAction="Train"; nearestId=id
                    selectedFactor=state.Level>=station.MinLevel and station.Multiplier or 1
                end
            end
            for id,egg in pairs(C.Eggs) do
                local distance=(root.Position-egg.Position).Magnitude
                if distance<=C.EggDistance and distance<nearest then
                    nearest=distance; nearestAction="Egg"; nearestId=id; selectedFactor=1
                end
            end
        end
        local available=refs.ActiveMenu==nil and not refs.Animation.Busy
        refs.Train.Visible=nearestId~=nil and not refs.Animation.Busy and refs.ShouldShow("Train")
        refs.InteractCaption.Text=(nearestAction=="Egg" and "Открыть яйцо" or "Тренироваться")..(game:GetService("UserInputService").TouchEnabled and "" or " · E")
        for _,obj in workspace:GetDescendants() do
            if obj:IsA("ProximityPrompt") and (obj.Name=="TrainPrompt" or obj.Name=="EggPrompt") then obj.Enabled=available end
        end
        stationFactor=selectedFactor; renderMultipliers()
        task.wait(.2)
    end
end)

task.spawn(function()
    -- Initial State may arrive before the client listener. Retry only synchronization.
    while not state do action:FireServer("Sync"); task.wait(2) end
    while refs.Gui.Parent do task.wait(1); render() end
end)
