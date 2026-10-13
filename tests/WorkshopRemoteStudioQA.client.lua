-- Fresh Studio sandbox only. Earns pets with normal server actions; no profile injection.
assert(game:GetService("RunService"):IsStudio())
task.spawn(function()
    local player=game.Players.LocalPlayer
    local C=require(game.ReplicatedStorage.SimulatorShared.Config)
    local remote=game.ReplicatedStorage.SimulatorRemotes
    local state,token,result
    local stateConnection=remote.State.OnClientEvent:Connect(function(s) state=s end)
    local noticeConnection=remote.Notice.OnClientEvent:Connect(function(_,extra)
        if extra then token=extra.RebirthToken or token; result=extra.Result or result end
    end)
    local function send(action,...)
        remote.Action:FireServer(action,...)
        task.wait((action=="Hatch" or action=="PetCraft") and 4.3 or action=="Rebirth" and 2.3 or .9)
    end
    local ok,err=pcall(function()
        send("Sync"); assert(state and state.StorageMode=="sandbox" and state.Coins==0,"fresh sandbox only")
        player.Character:PivotTo(workspace.SimulatorWorld.Basic.CFrame+Vector3.new(0,4,0)); task.wait(1)
        for _=1,3 do send("Train","Basic") end
        send("Daily"); send("Weekly")
        while state.Coins<560 do send("Train","Basic") end
        player.Character:PivotTo(workspace.SimulatorWorld.EggMeadow.CFrame+Vector3.new(0,4,0)); task.wait(1)
        for _=1,7 do send("Hatch","Meadow") end
        local id
        for _,key in C.PetOrder do if (state.Pets[key] or 0)>=3 then id=key; break end end
        assert(id,"seven pets guarantee three identical")
        local before=state.Pets[id]
        send("PetCraft",id,{[1]=1,[3]=3}); assert(state.Pets[id]==before,"sparse craft selection rejected")
        send("PetCraft",id,{1,1,2}); assert(state.Pets[id]==before,"malicious duplicate selection rejected")
        send("PetCraft",id,{1,2,3})
        assert((state.Pets[id] or 0)==before-3 and state.Pets[id.."_Upgraded"]==1,"atomic three to one remote craft")
        assert(result.Action=="PetCraft" and result.Id==id.."_Upgraded" and result.Duration==4,"server result acknowledges craft animation")
        send("PetCraft",id.."_Upgraded",{1,2,3}); assert(state.Pets[id.."_Upgraded"]==1,"no recursive craft")
        send("PetEquipBest")
        assert((state.EquippedPets[id.."_Upgraded"] or 0)==1 and #player.Character.SimulatorPet:GetChildren()==3,"upgraded best and followers")
        assert(math.abs(state.PetMultiplier-C.PetMultiplier(state))<.000001,"upgraded gains formula")
        player.Character:PivotTo(workspace.SimulatorWorld.Basic.CFrame+Vector3.new(0,4,0)); task.wait(1)
        while state.Power<state.RequiredPower or state.Coins<state.RequiredCoins do send("Train","Basic") end
        send("PrepareRebirth"); assert(token,"rebirth confirmation")
        send("Rebirth",token)
        assert(state.Rebirths==1 and state.Pets[id.."_Upgraded"]==1 and result.Action=="Rebirth" and result.Duration==2,"rebirth preserves crafted pet and acknowledges animation")
        print("WORKSHOP_REMOTE_PASS crafted_variant exact_ownership best_followers rebirth_preserves result_animations")
    end)
    stateConnection:Disconnect(); noticeConnection:Disconnect(); assert(ok,err)
end)
