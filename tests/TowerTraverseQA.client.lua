assert(game:GetService("RunService"):IsStudio())
local player=game.Players.LocalPlayer
repeat task.wait(.1) until player:GetAttribute("TraverseReady")
local human=player.Character:WaitForChild("Humanoid")
local root=player.Character:WaitForChild("HumanoidRootPart")
local Layout=require(game.ReplicatedStorage.SimulatorShared.TowerLayout)
local run=game:GetService("RunService"); local direction=Vector3.zero
run:BindToRenderStep("TowerTraverseQA",Enum.RenderPriority.Character.Value+1,function() human:Move(direction,false) end)
for index=2,3 do
    local step=Layout.Build(1).Stages[index]; local goal=Vector3.new(step.X,0,step.Z)
    direction=(goal-Vector3.new(root.Position.X,0,root.Position.Z)).Unit
    human:ChangeState(Enum.HumanoidStateType.Jumping)
    local deadline=os.clock()+4
    repeat
        task.wait(.025)
        local delta=goal-Vector3.new(root.Position.X,0,root.Position.Z)
        if delta.Magnitude<.5 then direction=Vector3.zero else direction=delta.Unit end
    until (goal-Vector3.new(root.Position.X,0,root.Position.Z)).Magnitude<.6 or os.clock()>deadline
    direction=Vector3.zero; task.wait(.5)
    local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={player.Character}
    local hit=workspace:Raycast(root.Position,Vector3.new(0,-6,0),params)
    assert(hit and hit.Instance:GetAttribute("TowerStep")==index,"Jump landing "..index)
end
run:UnbindFromRenderStep("TowerTraverseQA")
print("TOWER_TRAVERSE_CLIENT_PASS Humanoid_Move Jumping actual_landings")
