local C=require(game.ReplicatedStorage.SimulatorShared.Config)
local Concepts=require(game.ReplicatedStorage.SimulatorShared.PetConcepts)
local Factory=require(game.ReplicatedStorage.SimulatorShared.ModelFactory)
local A=require(script.Parent.WorldArt)
local G={}; local V=Vector3.new; local rgb=Color3.fromRGB
local rarityNames={["Обычная"]="Обычный",["Редкая"]="Редкий",["Эпическая"]="Эпический",["Мифическая"]="Мифический",["Легендарная"]="Легендарный",["Секретная"]="Секретный",["Божественная"]="Божественный"}
function G.Build(map)
    local folder=Instance.new("Folder"); folder.Name="PetGallery"; folder.Parent=map
    A.Part(folder,"GalleryGround",V(58,2,108),V(-100,-1,0),rgb(36,49,66),nil,true)
    A.Part(folder,"GalleryBridge",V(25,.2,8),V(-58.5,.1,14),rgb(92,122,137),nil,true)
    for _,z in {9.7,18.3} do A.Beam(folder,"BridgeRim",V(-71,.6,z),V(-46,.6,z),.13,rgb(113,224,199),Enum.Material.Neon) end
    A.Label(folder,V(-100,8,54),V(38,6,.4),"АТЕЛЬЕ ПИТОМЦЕВ\n7 обновлённых видов + 21 концепт",rgb(140,239,219))
    local order={"Cat","Dog","Bunny","Fox","Phoenix","Axolotl","Dragon"}
    for _,id in Concepts.Order do table.insert(order,id) end
    for index,id in order do
        local info=C.PetTypes[id] or Concepts.Types[id]
        local col=(index-1)%4; local row=math.floor((index-1)/4)
        local pos=V(-119+col*12,0,-42+row*13)
        local color=rgb(table.unpack(C.RarityColors[info.Rarity]))
        A.Part(folder,"DisplayBase"..id,V(9,.8,9),pos+V(0,.4,0),rgb(45,61,80),nil,true)
        A.Ring(folder,pos+V(0,.85,0),3.7,color,12)
        local model=Factory.Build(id,false); model.Name="Exhibit_"..id; model.Parent=folder
        model:ScaleTo(1.5); model:PivotTo(CFrame.new(pos+V(0,2.55,0))*CFrame.Angles(0,math.pi,0))
        A.Label(folder,pos+V(0,1,-4.1),V(8,1.8,.22),info.Name.."\n"..(info.Concept and "КОНЦЕПТ · " or "В ИГРЕ · ")..rarityNames[info.Rarity],color,Enum.NormalId.Back)
    end
    for _,x in {-128,-72} do for _,z in {-52,52} do
        A.Part(folder,"PavilionColumn",V(.8,8,.8),V(x,4,z),rgb(105,133,149),nil,true)
    end end
    -- Open-air pavilion; no large opaque roof hiding the collection from the camera.
    for _,x in {-128,-72} do A.Beam(folder,"CanopyFrame",V(x,8,-52),V(x,8,52),.5,rgb(150,199,197)) end
end
return G
