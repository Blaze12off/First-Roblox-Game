local C=require(game.ReplicatedStorage.SimulatorShared.Config)
local Factory=require(game.ReplicatedStorage.SimulatorShared.ModelFactory)
local TextStyle=require(game.ReplicatedStorage.SimulatorShared.TextStyle)
local Visuals={}
function Visuals.Apply(player,data)
    local character=player.Character
    if not character then return end
    local previous=character:FindFirstChild("SimulatorPet")
    if previous then previous:Destroy() end
    local root=character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local folder=Instance.new("Folder"); folder.Name="SimulatorPet"; folder.Parent=character
    local slot=0
    for _,id in C.InventoryOrder do
        for _=1,data.EquippedPets[id] or 0 do
            slot+=1
            local offset=({Vector3.new(-3,-.6,2),Vector3.new(3,-.6,2),Vector3.new(0,-.6,4)})[slot]
            if not offset then continue end -- Also bound rendering if supplied a malformed team.
            local info=C.PetTypes[id]
            local model=Factory.Build(id,false); model.Name=id..slot; model.Parent=folder
            model:SetAttribute("OwnerUserId",player.UserId)
            model:PivotTo(root.CFrame*CFrame.new(offset))
            for _,p in model:GetDescendants() do
                if p:IsA("BasePart") then
                    p.Anchored=false; p.Massless=true
                    local weld=Instance.new("WeldConstraint"); weld.Part0=root; weld.Part1=p; weld.Parent=p
                end
            end
            local tag=Instance.new("BillboardGui"); tag.Size=UDim2.fromOffset(160,30)
            tag.StudsOffset=Vector3.new(0,2.6,0); tag.MaxDistance=18; tag.Parent=model.PrimaryPart
            local text=Instance.new("TextLabel"); text.Size=UDim2.fromScale(1,1)
            text.BackgroundTransparency=1; text.Font=Enum.Font.GothamBold; text.TextSize=14
            text.TextColor3=Color3.fromRGB(table.unpack(info.Color)); text.Text=info.Name; text.Parent=tag
            TextStyle.Apply(text)
        end
    end
    if slot==0 then folder:Destroy() end
end
return Visuals
