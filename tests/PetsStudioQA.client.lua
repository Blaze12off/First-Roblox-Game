-- Paste into CLIENT Command Bar during a fresh Studio sandbox Play.
assert(game:GetService("RunService"):IsStudio(), "Studio only")
task.spawn(function()
    local player=game.Players.LocalPlayer
    local C=require(game.ReplicatedStorage.SimulatorShared.Config)
    local remote=game.ReplicatedStorage.SimulatorRemotes
    local state
    local connection=remote.State.OnClientEvent:Connect(function(snapshot) state=snapshot end)
    local function request(action,...)
        remote.Action:FireServer(action,...); task.wait(1.4)
    end
    local ok,err=pcall(function()
        request("Sync")
        assert(state and state.StorageMode=="sandbox" and state.Coins==0,"fresh sandbox required")
        player.Character:PivotTo(workspace.SimulatorWorld.Basic.CFrame+Vector3.new(0,4,0)); task.wait(1)
        for _=1,12 do request("Train","Basic") end
        assert(state.Coins==96,"training setup")
        request("Hatch","Meadow")
        assert(state.Coins==96 and next(state.Pets)==nil,"remote hatch must reject distance")
        player.Character:PivotTo(workspace.SimulatorWorld.EggMeadow.CFrame+Vector3.new(0,4,3)); task.wait(1)
        request("PetMenu")
        assert(player.PlayerGui.SimulatorUI.HudLayout.MenuShade.Pets.Visible,"egg prompt menu")
        request("Hatch","Meadow")
        local id=state.EquippedPet
        assert(state.Coins==16 and state.Pets[id]==1 and C.PetTypes[id],"hatch cost and owned pet")
        assert(player.Character:FindFirstChild("SimulatorPet"),"replicated follower")
        request("Hatch","Meadow")
        assert(state.Coins==16 and state.Pets[id]==1,"insufficient coins never charge")
        request("PetEquip","")
        assert(state.PetMultiplier==1 and not player.Character:FindFirstChild("SimulatorPet"),"unequip")
        request("PetEquip",id)
        assert(state.PetMultiplier==1+C.PetTypes[id].Bonus and player.Character:FindFirstChild("SimulatorPet"),"equip")
        player.Character:PivotTo(workspace.SimulatorWorld.Basic.CFrame+Vector3.new(0,4,0)); task.wait(1)
        local beforePower,beforeCoins=state.Power,state.Coins
        request("Train","Basic")
        assert(state.Power-beforePower==math.floor(5*state.PetMultiplier)
            and state.Coins-beforeCoins==math.floor(8*state.PetMultiplier),"server bonus")
        print("PETS_STUDIO_PASS distance cost inventory follower unequip equip server_bonus")
    end)
    connection:Disconnect()
    assert(ok,err)
end)
