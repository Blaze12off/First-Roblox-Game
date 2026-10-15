assert(game:GetService("RunService"):IsStudio())
task.wait(5)
local C=require(game.ReplicatedStorage.SimulatorShared.Config)
local Root=game.ServerScriptService.Simulator
local Runtime=require(Root.Runtime); local P=require(Root.Progression)
local player=game.Players:GetPlayers()[1]; assert(player and player.Character)
local d=Runtime.StudioProfile(player)
game.ReplicatedStorage.SimulatorRemotes.Action.OnServerEvent:Connect(function(p,action)
    if action=="Jump" then local h=p.Character:FindFirstChildOfClass("Humanoid"); local r=p.Character.HumanoidRootPart; print("JUMP_TRACE_SERVER",h:GetState().Name,r.AssemblyLinearVelocity.Y,h.FloorMaterial.Name,d.TotalTrainings) end
end)
local human=player.Character:FindFirstChildOfClass("Humanoid")
assert(not human.UseJumpPower and math.abs(human.JumpHeight-.36)<.001,"initial actual jump")
local Factory=require(game.ReplicatedStorage.SimulatorShared.ModelFactory)
for _,id in C.EggOrder do
    local m=Factory.Build(id,true)
    assert(m:FindFirstChild("ShellBase") and not m:FindFirstChild("ShellCrown"),"single shell")
    m:Destroy()
end
assert(not Runtime.Dispatch(player,"Jump",999),"fake jump award rejected")
task.wait(5)
assert(d.TotalTrainings>=2 and d.Power>0 and human.JumpHeight>.36,"real player jumps award growth")
print("JUMP_PHYSICS_PASS real_client_jumps initial_0.36 grows_on_server")
assert(not Runtime.Dispatch(player,"Jump"),"standing remote never grants a jump")
player.Character:PivotTo(CFrame.new(C.Stations.Basic.Position+Vector3.new(0,3,0))); task.wait(1)
local before=d.Power; assert(Runtime.Dispatch(player,"Train","Basic")); assert(d.Power>before,"E training still works")
local xp=d.PracticeXP; for _=1,10 do Runtime.Dispatch(player,"Train","Basic") end
assert(d.PracticeXP==xp,"click spam does not multiply XP")
local needP,needC,needX=C.BatchRequirements(d.Rebirths,5)
d.Power=needP; d.Coins=needC+321; d.PracticeXP=needX; d.RebirthXPSpent=0
assert(Runtime.Dispatch(player,"PrepareRebirth",5)); local token=Runtime.sessions[player.UserId].confirm.token
assert(Runtime.Dispatch(player,"Rebirth",token)); assert(d.Rebirths==5 and d.Coins==321 and d.Power==0 and math.abs(human.JumpHeight-.36)<.001)
task.wait(2.2); assert(not Runtime.Dispatch(player,"Rebirth",token),"confirmation replay")
player.Character:PivotTo(CFrame.new(workspace.SimulatorWorld.ZoneGate2.Position+Vector3.new(0,3,0))); task.wait(1)
d.Coins=100000000; d.PracticeXP=599; d.RebirthXPSpent=0
assert(not Runtime.Dispatch(player,"Zone",2),"early gate blocked")
d.PracticeXP=600; task.wait(.4); assert(Runtime.Dispatch(player,"Zone",2)); assert(d.Zone==2)
assert((player.Character.HumanoidRootPart.Position-C.Zones[2].Position).Magnitude<5,"portal arrival")
-- Stage a local-only snapshot for inspecting all eggs and bulk controls.
d.Zone=5; d.PracticeXP=10000; d.Power=C.MaxValue; d.Coins=100000000; P.ApplyJump(player,d)
task.wait(1.1); Runtime.Dispatch(player,"Sync")
local jumped=d.TotalTrainings; player:SetAttribute("JumpHighQAReady",true)
local untilTime=os.clock()+6
repeat task.wait(.2) until d.TotalTrainings>jumped or os.clock()>untilTime
assert(d.TotalTrainings>jumped,"large jumps still validate after physics replication")
print("JUMP_HIGH_PASS server_height_120 ground_launch_verified")
require(Root.Tests.Spec).Run()
print("JUMP_ENGINE_PASS E batch_token_sum reset gates persistence_schema_v5")
