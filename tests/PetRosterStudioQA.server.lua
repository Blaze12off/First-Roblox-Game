-- Studio-only engine checks, no DataStore writes or permanent player-profile edits.
assert(game:GetService("RunService"):IsStudio())
local C=require(game.ReplicatedStorage.SimulatorShared.Config)
assert(C.StudioOffline)
local Factory=require(game.ReplicatedStorage.SimulatorShared.ModelFactory)
local Schema=require(game.ServerScriptService.Simulator.Schema)
local Visuals=require(game.ServerScriptService.Simulator.PetVisuals)
for _,group in {{C.InventoryOrder,false},{C.EggOrder,true}} do
    for _,id in group[1] do
        local m=Factory.Build(id,group[2]); assert(m.PrimaryPart)
        local n=0
        for _,p in m:GetDescendants() do
            if p:IsA("BasePart") then
                n+=1; assert(p.Anchored and not p.CanCollide and not p.CanTouch and not p.CanQuery)
                assert(p.Position.Magnitude<4,"model part far from origin")
            end
        end
        assert(n>=8 and n<=80,"model part budget: "..id.." = "..n)
        m:PivotTo(CFrame.new(10,10,10)); assert((m:GetPivot().Position-Vector3.new(10,10,10)).Magnitude<.001)
        m:Destroy()
    end
end
for i,id in C.EggOrder do
    for j,other in C.EggOrder do
        if i~=j then assert((C.Eggs[id].Position-C.Eggs[other].Position).Magnitude>C.EggDistance*2,"egg interaction overlap") end
    end
end
task.wait(5)
local player=game.Players:GetPlayers()[1]; assert(player and player.Character)
local fake=Schema.New(); fake.Pets={Dragon=1,Phoenix=1,Axolotl_Upgraded=1}; fake.EquippedPets=table.clone(fake.Pets)
Visuals.Apply(player,fake)
local pets=player.Character:FindFirstChild("SimulatorPet"); assert(pets and #pets:GetChildren()==3)
for _,m in pets:GetChildren() do
    assert(m:GetAttribute("OwnerUserId")==player.UserId)
    for _,p in m:GetDescendants() do if p:IsA("BasePart") then
        assert(not p.Anchored and p.Massless and p:FindFirstChildOfClass("WeldConstraint"),"follow geometry welded")
    end end
end
print("PET_ROSTER_ENGINE_PASS 17 models bounded safe pivotable shared follow geometry")
require(game.ServerScriptService.Simulator.Tests.Spec).Run()
