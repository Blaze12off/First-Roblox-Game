local C=require(game.ReplicatedStorage.SimulatorShared.Config)
local R={}
function R.Apply(data,amount)
    amount=amount or 1
    local power,coins,xp=C.BatchRequirements(data.Rebirths,amount)
    if not power then return false,"Недопустимое количество перерождений." end
    if data.Power<power or data.Coins<coins or C.AvailablePractice(data)<xp then return false,"Не хватает прыжка, монет или опыта тренировки." end
    data.Power=0; data.Coins-=coins; data.Level=0
    data.RebirthXPSpent+=xp; data.Rebirths+=amount
    return true,("Перерождений: %d! Постоянный бонус x%.2f"):format(amount,C.Multiplier(data))
end
return R
