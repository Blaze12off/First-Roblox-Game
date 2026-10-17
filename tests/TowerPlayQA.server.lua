assert(game:GetService("RunService"):IsStudio())
task.wait(5)
local root=game.ServerScriptService.Simulator
local R=require(root.Runtime); local T=require(root.TowerProgress)
local C=require(game.ReplicatedStorage.SimulatorShared.Config)
local L=require(game.ReplicatedStorage.SimulatorShared.TowerLayout)
local p=game.Players:GetPlayers()[1]; assert(p and p.Character)
local data=R.StudioProfile(p); local originalCoins=data.Coins; local originalXP=data.PracticeXP
local function settle(pos)
    p.Character:PivotTo(CFrame.new(pos)); p.Character.HumanoidRootPart.AssemblyLinearVelocity=Vector3.zero
    task.wait(1.3)
end
assert(not T.Recall(p,1,false),"Off-site recall")
assert(not T.Recall(p,6,false) and not T.Recall(p,1.5,false),"Invalid tower")
settle(workspace.SimulatorWorld.TowerRecall2.Position+Vector3.new(0,3,0))
assert(not T.Recall(p,2,false),"Locked zone recall")
local stage=L.Build(1).Stages[8]
settle(Vector3.new(stage.X,stage.Y+3,stage.Z))
assert(p:GetAttribute("TowerCheckpoint")==8,"Server verifies grounded checkpoint")
settle(workspace.SimulatorWorld.TowerRecall1.Position+Vector3.new(0,3,0))
assert(T.Recall(p,1,false),"Valid E recall handler")
assert((p.Character.HumanoidRootPart.Position-Vector3.new(stage.X,stage.Y+3.5,stage.Z)).Magnitude<1)
assert(not T.Recall(p,1,false),"Remote-location/cooldown recheck")
settle(Vector3.new(-10,-40,-58))
assert(p.Character.HumanoidRootPart.Position.Y>stage.Y,"Void recovery")
task.wait(2.1)
settle(workspace.SimulatorWorld.TowerDown1.Position+Vector3.new(0,3,0))
assert(T.Recall(p,1,true)); assert((p.Character.HumanoidRootPart.Position-C.Zones[1].Position).Magnitude<1)
assert(data.Coins==originalCoins and data.PracticeXP==originalXP,"No extra currency/XP from checkpoints")
require(root.Tests.TowerArtQA).Run()
print("TOWER_PLAY_PASS grounded_checkpoint recall distance locked_zone cooldown void down no_rewards")
-- Earn jump height through the real training gate, then traverse actual platforms.
settle(workspace.SimulatorWorld.Basic.Position+Vector3.new(0,3,0))
for _=1,60 do assert(R.Dispatch(p,"Train","Basic")) end
local first=L.Build(1).Stages[1]
settle(Vector3.new(first.X,first.Y+3,first.Z))
p:SetAttribute("TraverseReady",true)
local deadline=os.clock()+12
repeat task.wait(.1) until p:GetAttribute("TowerStep")==3 or os.clock()>deadline
assert(p:GetAttribute("TowerStep")==3,"Actual client climb reaches step 3 on server")
print("TOWER_TRAVERSE_SERVER_PASS actual_jumps steps_1_2_3")
p:SetAttribute("ArtQAComplete",true)
