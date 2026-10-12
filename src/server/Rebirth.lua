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
