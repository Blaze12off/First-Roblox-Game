-- SERVER Command Bar in a fresh Play. Only runs in Studio sandbox.
assert(game:GetService("RunService"):IsStudio(),"Studio only")
local Integration={}
function Integration.Run()
local C=require(game.ReplicatedStorage.SimulatorShared.Config)
assert(C.StudioOffline,"Only run integration in offline sandbox")
local Runtime=require(game.ServerScriptService.Simulator.Runtime)
local player=game.Players:GetPlayers()[1]
assert(player and player.Character,"Wait for character to spawn")
local remotes=game.ReplicatedStorage.SimulatorRemotes
local map=workspace.SimulatorWorld
local function send(action,...)
    local ok,reason=Runtime.Dispatch(player,action,...)
    return ok,reason
end
task.spawn(function()
    local function settle(pad)
        local root=player.Character.HumanoidRootPart
        root.AssemblyLinearVelocity=Vector3.zero
        player.Character:PivotTo(pad.CFrame+Vector3.new(0,4,0))
        task.wait(1)
    end
    assert(player.leaderstats.LifetimePower.Value==0,"Fresh Play needed")
    player.Character:PivotTo(CFrame.new(-16,4,12)); task.wait(1)
    local ok,reason=send("Train","Basic")
    assert(not ok and reason=="distance","distance validation")
    settle(map.Basic)
    assert(not send("Train","Basic",1000000),"malicious reward argument")
    task.wait(0.85)
    assert(send("Train","Basic"),"valid training")
    assert(not send("Train","Basic"),"training cooldown")
    assert(player.leaderstats.LifetimePower.Value==5,"leaderboard server score")
    for _=1,3 do task.wait(0.85); assert(send("Train","Basic")) end
    assert(send("Upgrade"),"buy improvement")
    assert(not send("Rebirth","invented"),"confirmation token rejected")
    settle(map.Advanced)
    local allowed,why=send("Train","Advanced")
    assert(not allowed and why=="level","locked advanced zone")
    settle(map.Basic)
    -- Earn the first cycle normally, without injecting coins or power into a profile.
    for _=1,40 do task.wait(0.85); assert(send("Train","Basic")) end
    assert(send("Daily"),"daily reward")
    task.wait(0.35); assert(not send("Daily"),"duplicate daily reward")
    task.wait(0.35); assert(send("PrepareRebirth"),"rebirth preparation")
    local token=Runtime.sessions[player.UserId].confirm.token
    task.wait(0.35); assert(send("Rebirth",token),"rebirth confirmed")
    assert(player.leaderstats.Rebirths.Value==1,"leaderboard rebirth")
    task.wait(0.35); assert(not send("Rebirth",token),"token cannot replay")
    local oldCharacter=player.Character
    oldCharacter.Humanoid.Health=0
    local deadline=os.clock()+15
    repeat task.wait(0.2) until player.Character~=oldCharacter or os.clock()>deadline
    assert(player.Character~=oldCharacter,"respawn")
    local root=player.Character:WaitForChild("HumanoidRootPart",10)
    assert(root:WaitForChild("Simulator_Aura",10),"cosmetic restored on respawn")
    assert(player.leaderstats.Rebirths.Value==1,"progress survives death")
    print("SIMULATOR_INTEGRATION_PASS training, distance, malformed args, cooldown, upgrade, daily, rebirth, replay, cosmetics, respawn")
end)
end
return Integration
