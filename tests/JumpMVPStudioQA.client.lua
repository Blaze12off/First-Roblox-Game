assert(game:GetService("RunService"):IsStudio())
task.wait(6)
local player=game.Players.LocalPlayer
local h=player.Character:FindFirstChildOfClass("Humanoid")
h.Jumping:Connect(function(active) print("JUMP_TRACE_CLIENT",active,player.Character.HumanoidRootPart.AssemblyLinearVelocity.Y) end)
for _=1,3 do h:ChangeState(Enum.HumanoidStateType.Jumping); task.wait(.65); print("JUMP_TRACE_STATE",h:GetState().Name) end
task.wait(12)
repeat task.wait(.1) until player:GetAttribute("JumpHighQAReady")
h:ChangeState(Enum.HumanoidStateType.Jumping)
task.wait(.5)
local UI=require(player.PlayerScripts.SimulatorClient.UI)
local refs=UI.Build(player); refs.Gui.Name="JumpUIFixture"
refs.Catalog.Update({Zone=5,Level=0,Pets={},EquippedPets={},PetMultiplier=1})
assert(#require(game.ReplicatedStorage.SimulatorShared.Config).EggOrder==10)
assert(refs.Catalog.ShowOdds("Celestial"))
local rows=0
for _,row in refs.Catalog.OddsList:GetChildren() do if row:IsA("Frame") then
    rows+=1; assert(row:FindFirstChild("Picture") and row.Picture:FindFirstChildOfClass("WorldModel"),"odds row has real pet model")
end end
assert(rows==6,"rare egg pool rows")
refs.Catalog.Update({Zone=1,Level=0,Pets={},EquippedPets={}})
assert(not refs.Catalog.ShowOdds("Celestial"),"locked odds do not leak the description")
assert(refs.BatchButtons[1] and refs.BatchButtons[5] and refs.BatchButtons[10] and refs.BatchButtons.MAX)
refs.Catalog.Update({Zone=5,Level=0,Pets={},EquippedPets={}})
refs.Open("Pets"); refs.Catalog.ShowOdds("Celestial")
_G.JumpFixture=refs
print("JUMP_CLIENT_PASS ten_eggs odds_models locked_description bulk_controls")

task.wait(2); refs.Gui:Destroy()
