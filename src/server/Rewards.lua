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
