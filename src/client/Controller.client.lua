local Players=game:GetService("Players")
local player=Players.LocalPlayer
local C=require(game.ReplicatedStorage:WaitForChild("SimulatorShared"):WaitForChild("Config"))
local UI=require(script.Parent.UI)
local refs=UI.Build(player)
-- The edge HUD renders the training hint; keep the prompt's E/gamepad input without duplicate default UI.
local function styleTrainingPrompt(obj)
    if obj:IsA("ProximityPrompt") and obj.Name=="TrainPrompt" then obj.Style=Enum.ProximityPromptStyle.Custom end
end
workspace.DescendantAdded:Connect(styleTrainingPrompt)
for _,obj in workspace:GetDescendants() do styleTrainingPrompt(obj) end
local remotes=game.ReplicatedStorage:WaitForChild("SimulatorRemotes")
local action=remotes:WaitForChild("Action")
local state,rebirthToken,serverOffset,selectedEgg
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
    refs.Notice.Text=message; refs.Notice.Visible=true
    task.delay(4,function() if noticeVersion==version then refs.Notice.Visible=false end end)
end
local function request(name,...)
    -- This only improves UX. Every limit/condition is rechecked on the server.
    if state then action:FireServer(name,...) end
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
    local petCount=0
    for _,amount in pairs(state.Pets) do petCount+=amount end
    local equippedCount=0
    for _,amount in pairs(state.EquippedPets) do equippedCount+=amount end
    refs.PetSummary.Text=("Получено %d/%d • нанято %d/%d • x%.2f"):format(petCount,C.MaxPets,equippedCount,C.PetEquipSlots,state.PetMultiplier)
    for id,b in pairs(refs.PetButtons) do
        local info=C.PetTypes[id]; local count=state.Pets[id] or 0
        local equipped=state.EquippedPets[id] or 0
        refs.PetCards[id].Text=("Получено: %d\nНанято: %d"):format(count,equipped)
        b.Text=count==0 and "Не получен" or equippedCount>=C.PetEquipSlots and "Слоты заняты" or count==equipped and "Все наняты" or "Нанять +1"
        b.Active=count>equipped and equippedCount<C.PetEquipSlots
        refs.PetRemoveButtons[id].Active=equipped>0
        refs.PetRemoveButtons[id].Text=equipped>0 and "Снять −1" or "Не нанят"
    end
    refs.Catalog.UpdateEggs(state.Level)
    if selectedEgg then
        local egg=C.Eggs[selectedEgg]; local unlocked=state.Level>=egg.MinLevel
        refs.EggChoiceText.Text=unlocked and (egg.Name.."\n"..egg.Description.."\n\n"..egg.Cost.." монет. Для открытия подойди к этой стойке.")
            or (egg.Name.."\nНедоступно. Нужен уровень "..egg.MinLevel..".")
        refs.HatchSelected.Active=unlocked
    end
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
    if state.StorageMode=="sandbox" then refs.Mode.Text="Studio: без сохранений"
    elseif state.SaveStatus=="retry" then refs.Mode.Text="DataStore: повтор сохранения…"
    elseif state.SaveStatus=="saved" then refs.Mode.Text="DataStore: прогресс сохранён"
    else refs.Mode.Text="DataStore: прогресс загружен" end
    if state.TotalTrainings==0 then refs.Hint.Text=game:GetService("UserInputService").TouchEnabled and "Подойди к зелёной платформе и нажми «Тренироваться»." or "Подойди к зелёной платформе и нажми E."
    elseif state.Level==0 then refs.Hint.Text="Открой магазин: первое улучшение стоит 25 монет."
    else refs.Hint.Text="" end
    refs.Hint.Visible=refs.Hint.Text~=""
end
remotes.State.OnClientEvent:Connect(function(snapshot)
    state=snapshot; serverOffset=snapshot.ServerTime-os.time(); render()
end)
remotes.Notice.OnClientEvent:Connect(function(message,extra)
    showNotice(message)
    if extra and extra.OpenPets then refs.Open("Pets") end
    if extra and extra.RebirthToken then
        rebirthToken=extra.RebirthToken
        refs.Dialog.Text=message..("\n\nНовый постоянный бонус: x%.2f\nПодтверждение действует 20 секунд."):format(extra.NextMultiplier)
        refs.Open("Confirm")
    end
end)
refs.Train.Activated:Connect(function()
    local char=player.Character; local root=char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local selected,distance="Basic",math.huge
    for id,station in pairs(C.Stations) do
        local d=(root.Position-station.Position).Magnitude
        if d<distance then selected=id; distance=d end
    end
    if distance>C.TrainDistance then showNotice("Подойди к тренировочной платформе."); return end
    request("Train",selected)
end)
refs.Upgrade.Activated:Connect(function() request("Upgrade") end)
for id,b in pairs(refs.EggButtons) do b.Activated:Connect(function()
    if not state or state.Level<C.Eggs[id].MinLevel then return end
    selectedEgg=id
    local egg=C.Eggs[id]
    refs.EggChoiceText.Text=egg.Name.."\n"..egg.Description.."\n\n"..egg.Cost.." монет. Для открытия подойди к этой стойке."
    refs.HatchSelected.Text="Открыть • "..egg.Cost
    refs.Open("EggChoice")
end) end
refs.HatchSelected.Activated:Connect(function() if selectedEgg then request("Hatch",selectedEgg) end end)
for id,b in pairs(refs.PetButtons) do
    b.Activated:Connect(function()
        if not state then return end
        if not state.Pets[id] then showNotice("Сначала получи этого питомца из яйца."); return end
        request("PetEquip",id)
    end)
end
for id,b in pairs(refs.PetRemoveButtons) do b.Activated:Connect(function() request("PetUnequip",id) end) end
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
-- Visibility is a UX hint; the server checks training distance independently.
task.spawn(function()
    while refs.Gui.Parent do
        local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local near=false
        local selectedFactor,nearest=1,math.huge
        if root and state then
            for _,station in pairs(C.Stations) do
                local distance=(root.Position-station.Position).Magnitude
                if distance<=C.TrainDistance then
                    near=true
                    if distance<nearest and state.Level>=station.MinLevel then
                        nearest=distance; selectedFactor=station.Multiplier
                    end
                end
            end
        end
        refs.Train.Visible=near
        stationFactor=selectedFactor; renderMultipliers()
        task.wait(0.2)
    end
end)
task.spawn(function()
    -- Initial State may arrive before the client listener. Retry only synchronization.
    while not state do action:FireServer("Sync"); task.wait(2) end
    while refs.Gui.Parent do task.wait(1); render() end
end)
