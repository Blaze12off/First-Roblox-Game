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
