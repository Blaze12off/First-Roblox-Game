local C=require(game.ReplicatedStorage.SimulatorShared.Config)
local Network={}
function Network.Create()
    local folder=Instance.new("Folder"); folder.Name="SimulatorRemotes"; folder.Parent=game.ReplicatedStorage
    local action=Instance.new("RemoteEvent"); action.Name="Action"; action.Parent=folder
    local state=Instance.new("RemoteEvent"); state.Name="State"; state.Parent=folder
    local notice=Instance.new("RemoteEvent"); notice.Name="Notice"; notice.Parent=folder
    return {Action=action,State=state,Notice=notice}
end
function Network.Snapshot(data, mode, saveStatus)
    local power,coins=C.Requirements(data.Rebirths)
    return {Coins=data.Coins, Power=data.Power, Level=data.Level, Rebirths=data.Rebirths,
        LifetimePower=data.LifetimePower, Multiplier=C.Multiplier(data),
        UpgradeCost=data.Level<C.MaxLevel and C.UpgradeCost(data.Level) or 0,
        RequiredPower=power, RequiredCoins=coins, TotalTrainings=data.TotalTrainings,
        LastDaily=data.LastDaily, LastWeekly=data.LastWeekly, ServerTime=os.time(),
        BronzeAura=data.Cosmetics.BronzeAura==true, NeonTrail=data.Cosmetics.NeonTrail==true,
        Equipped=data.Equipped, Pets=table.clone(data.Pets), EquippedPets=table.clone(data.EquippedPets),
        PetMultiplier=C.PetMultiplier(data), StorageMode=mode, SaveStatus=saveStatus or "ready"}
end
return Network
