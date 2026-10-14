assert(game:GetService("RunService"):IsStudio())
task.spawn(function()
    local C=require(game.ReplicatedStorage.SimulatorShared.Config)
    assert(C.StudioOffline,"sandbox only")
    local R=require(game.ServerScriptService.Simulator.Runtime)
    local player
    repeat task.wait(.1); player=game.Players:GetPlayers()[1] until player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and R.sessions[player.UserId]
    task.wait(2)
    local root=player.Character.HumanoidRootPart
    local origin=root.CFrame
    player.Character:PivotTo(workspace.SimulatorWorld.Basic.CFrame+Vector3.new(0,4,0)); task.wait(.3)
    local before=player.leaderstats.LifetimePower.Value
    for _=1,20 do assert(R.Dispatch(player,"Train","Basic"),"rapid training rejected") end
    assert(player.leaderstats.LifetimePower.Value==before+20*C.BasePower,"twenty server rewards")
    local ok,why=R.Dispatch(player,"Train","Basic",999999)
    assert(not ok and why=="arguments","reward injection rejected")
    player.Character:PivotTo(CFrame.new(0,50,0)); task.wait(.1)
    ok,why=R.Dispatch(player,"Train","Basic")
    assert(not ok and why=="distance","range still enforced")
    player.Character:PivotTo(origin)
    print("RAPID_TRAINING_PASS 20_immediate_rewards distance_validation argument_validation")
end)
