local C = require(game.ReplicatedStorage.SimulatorShared.Config)
local number=require(game.ReplicatedStorage.SimulatorShared.NumberFormat).Compact
local P = {}
function P.Train(data, stationId)
    local station = C.Stations[stationId]
    if not station or data.Level < station.MinLevel then return false, "Станция откроется на уровне 3." end
    local power, coins = C.Gains(data, station.Multiplier)
    data.Power = math.min(C.MaxValue, data.Power+power)
    data.Coins = math.min(C.MaxValue, data.Coins+coins)
    data.LifetimePower = math.min(C.MaxValue, data.LifetimePower+power)
    data.TotalTrainings = math.min(C.MaxValue, data.TotalTrainings+1)
    return true, ("+%s силы, +%s монет"):format(number(power),number(coins))
end
function P.Upgrade(data)
    if data.Level >= C.MaxLevel then return false, "Максимальный уровень тренировки." end
    local cost=C.UpgradeCost(data.Level)
    if data.Coins < cost then return false, "Не хватает монет на улучшение." end
    data.Coins-=cost; data.Level+=1
    return true, "Тренировка усилена! Уровень "..number(data.Level)
end
return P
