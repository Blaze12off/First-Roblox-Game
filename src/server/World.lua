local number=require(game.ReplicatedStorage.SimulatorShared.NumberFormat).Compact
local C=require(game.ReplicatedStorage.SimulatorShared.Config)
local TextStyle=require(game.ReplicatedStorage.SimulatorShared.TextStyle)
local LeaderboardTemplate=require(script.Parent.LeaderboardTemplate)
local ModelFactory=require(game.ReplicatedStorage.SimulatorShared.ModelFactory)
local TowerWorld=require(script.Parent.TowerWorld)
local Layout=require(game.ReplicatedStorage.SimulatorShared.TowerLayout)
local A=require(script.Parent.WorldArt)
local Gallery=require(script.Parent.PetGallery)
local World={}
local builtMap
local function part(parent,name,size,position,color)
    local p=Instance.new("Part"); p.Name=name; p.Size=size; p.Position=position
    p.Color=color; p.Material=Enum.Material.SmoothPlastic; p.Anchored=true; p.Parent=parent
    return p
end
local function sign(parent,name,position,text,color)
    local anchor=part(parent,name,Vector3.new(1,1,1),position,color)
    anchor.Transparency=1; anchor.CanCollide=false
    local gui=Instance.new("BillboardGui"); gui.Name="SimulatorSign"
    gui.Size=UDim2.fromOffset(C.SignWidth,C.SignHeight); gui.AlwaysOnTop=false
    -- Client handles player distance and fading; no hard camera-distance cut during the tween.
    gui.MaxDistance=0; gui.Enabled=false; gui.Parent=anchor
    local label=Instance.new("TextLabel"); label.Name="SignText"; label.Size=UDim2.fromScale(1,1)
    label.AnchorPoint=Vector2.new(0.5,0.5); label.Position=UDim2.fromScale(0.5,0.5)
    label.BackgroundColor3=Color3.fromRGB(22,30,50); label.BackgroundTransparency=1
    label.TextColor3=color; label.TextSize=C.SignTextSize; label.Font=Enum.Font.GothamBold
    label.TextWrapped=true; label.Text=text; label.Parent=gui
    TextStyle.Apply(label)
    label.TextTransparency=1; label.TextStrokeTransparency=1
    local scale=Instance.new("UIScale"); scale.Name="RevealScale"; scale.Scale=0.94; scale.Parent=label
    local corner=Instance.new("UICorner"); corner.Parent=label
end
function World.Build()
    if builtMap and builtMap.Parent then return builtMap end
    local existing=workspace:FindFirstChild("SimulatorWorld")
    -- Editor preview is recreated from this module at Play; balance/layout source stays authoritative.
    if existing then existing:Destroy() end
    local map=Instance.new("Folder"); map.Name="SimulatorWorld"; map.Parent=workspace
    part(map,"Ground",Vector3.new(100,2,80),Vector3.new(4,-1,0),Color3.fromRGB(111,157,133))
    part(map,"StartingPlaza",Vector3.new(32,0.2,26),Vector3.new(-12,0.1,0),Color3.fromRGB(47,72,88))
    part(map,"AdvancedPlaza",Vector3.new(28,0.2,26),Vector3.new(24,0.1,0),Color3.fromRGB(67,49,96))
    -- Join x=4..10 exactly: no overlap with either plaza, and a 0.05 stud step below them.
    part(map,"Path",Vector3.new(6,0.2,7),Vector3.new(7,0.05,0),Color3.fromRGB(100,109,134))
    for zone=2,#C.Zones do
        local info=C.Zones[zone]; local x=(zone-1)*120
        local groundColors={Color3.fromRGB(111,157,133),Color3.fromRGB(92,138,106),Color3.fromRGB(183,216,231),Color3.fromRGB(81,69,83),Color3.fromRGB(185,195,221)}
        part(map,"GroundZ"..zone,Vector3.new(100,2,80),Vector3.new(x+4,-1,0),groundColors[zone])
        part(map,"PlazaZ"..zone,Vector3.new(32,.2,26),Vector3.new(x-12,.1,0),Color3.fromRGB(table.unpack(info.Color)):Lerp(Color3.fromRGB(25,35,55),.65))
        sign(map,"ZoneTitle"..zone,Vector3.new(x-16,8,-15),"УРОВЕНЬ "..zone.." · "..info.Name,Color3.fromRGB(table.unpack(info.Color)))
    end
    local function gate(name,target,pos,returning)
        local info=C.Zones[target]; local color=Color3.fromRGB(table.unpack(info.Color))
        local base=part(map,name,Vector3.new(6,.5,6),pos,color); base:SetAttribute("TargetZone",target)
        for _,side in {-1,1} do part(map,name.."Post",Vector3.new(.5,7,.5),pos+Vector3.new(side*3,3.5,0),color) end
        part(map,name.."Arch",Vector3.new(6.5,.5,.5),pos+Vector3.new(0,7,0),color)
        local prompt=Instance.new("ProximityPrompt"); prompt.Name="ZonePrompt"; prompt.KeyboardKeyCode=Enum.KeyCode.E
        prompt.ActionText="Перейти / открыть"; prompt.ObjectText="Уровень "..target.." · "..info.Name; prompt.MaxActivationDistance=8
        prompt.RequiresLineOfSight=false; prompt.Exclusivity=Enum.ProximityPromptExclusivity.OneGlobally; prompt.Parent=base
        sign(map,name.."Label",pos+Vector3.new(0,8,0),"УРОВЕНЬ "..target.." · "..info.Name..(returning and "\nНазад · E" or "\n"..number(info.XP).." опыта · "..number(info.Cost).." монет · E"),color)
    end
    for zone=2,#C.Zones do
        local summit=Layout.Build(zone-1)
        gate("ZoneGate"..zone,zone,Vector3.new(summit.X,summit.SummitY+.45,summit.Z+4),false)
        gate("ZoneReturn"..zone,zone-1,Vector3.new((zone-1)*120-31,.45,24),true)
    end
    for id, info in pairs(C.Stations) do
        local color=id=="Basic" and Color3.fromRGB(65,220,183) or Color3.fromRGB(160,116,255)
        local pad=part(map,id,Vector3.new(8,1,8),info.Position,color); pad.Material=Enum.Material.Neon
        local prompt=Instance.new("ProximityPrompt"); prompt.Name="TrainPrompt"
        prompt.ActionText="Тренироваться"; prompt.ObjectText="Тренировка прыжка"
        prompt.KeyboardKeyCode=Enum.KeyCode.E; prompt.HoldDuration=0; prompt.MaxActivationDistance=C.TrainDistance
        prompt.Exclusivity=Enum.ProximityPromptExclusivity.OneGlobally
        prompt.RequiresLineOfSight=false; prompt.Parent=pad
        sign(map,id.."Sign",info.Position+Vector3.new(0,6,-7),"ТРЕНИРОВКА ПРЫЖКА\nПрыгай или нажимай E",color)
        -- Springboard instead of strength-training barbells.
        part(map,id.."Spring",Vector3.new(3,.4,3),info.Position+Vector3.new(0,.7,0),Color3.fromRGB(210,231,246))

    end
    sign(map,"Welcome",Vector3.new(-34,7,14),"ПРЫЖКИ → ПИТОМЦЫ → НОВЫЕ ЗОНЫ\nПерерождение даёт постоянный бонус",Color3.fromRGB(245,210,106))
    for _,id in C.EggOrder do
        local info=C.Eggs[id]; local color=Color3.fromRGB(table.unpack(info.Color))
        local stand=part(map,"Egg"..id,Vector3.new(5,1.6,5),info.Position,color)
        local egg=ModelFactory.Build(id,true); egg.Name=id.."Shell"; egg.Parent=map
        egg:PivotTo(CFrame.new(info.Position+Vector3.new(0,2.6,0)))
        local prompt=Instance.new("ProximityPrompt"); prompt.Name="EggPrompt"
        prompt.ActionText="Яйца и питомцы"; prompt.ObjectText=info.Name.." • "..number(info.Cost).." монет"
        prompt.KeyboardKeyCode=Enum.KeyCode.E; prompt.MaxActivationDistance=C.EggDistance
        prompt.Exclusivity=Enum.ProximityPromptExclusivity.OneGlobally
        prompt.RequiresLineOfSight=false; prompt.Parent=stand
        sign(map,id.."EggSign",info.Position+Vector3.new(0,6,0),info.Name.."\n"..number(info.Cost).." монет • нажми E",color)
    end
    sign(map,"Milestone",Vector3.new(24,7,-13),"НАГРАДЫ ЗА ПРОГРЕСС\n1 Rebirth: аура • 10 Rebirth: неоновый след",Color3.fromRGB(120,223,255))
    TowerWorld.Build(map)
    Gallery.Build(map)
    for _, z in {37} do
        part(map,"Border"..z,Vector3.new(94,3,1),Vector3.new(4,1.5,z),Color3.fromRGB(52,67,93))
    end
    -- Open west edge for the atelier and north edge for the tower approach.
    for _, x in {51} do
        part(map,"Border"..x,Vector3.new(1,3,74),Vector3.new(x,1.5,0),Color3.fromRGB(52,67,93))
    end
    for zone,info in C.Zones do
        local x=(zone-1)*120; local color=Color3.fromRGB(table.unpack(info.Color))
        for _,side in {-1,1} do
            if zone==2 or zone==1 then A.Tree(map,Vector3.new(x+side*32,0,-25),color,zone==2 and 1.5 or 1)
            elseif zone==3 then
                A.Part(map,"IceGarden",Vector3.new(5,8,5),Vector3.new(x+side*32,3,-25),color,Enum.Material.Ice,false,CFrame.Angles(.15,.5,side*.2))
            elseif zone==4 then
                A.Part(map,"Basalt",Vector3.new(6,9,6),Vector3.new(x+side*32,3,-25),Color3.fromRGB(61,48,64),nil,false,CFrame.Angles(.1,.5,side*.13))
                A.Ring(map,Vector3.new(x+side*32,1,-25),4,color)
            else
                A.Ring(map,Vector3.new(x+side*32,4,-25),4,color)
                A.Part(map,"FloatingStar",Vector3.new(2,3,2),Vector3.new(x+side*32,5,-25),color,Enum.Material.Neon,false,CFrame.Angles(.4,.4,.4))
            end
        end
        -- Decorative paving stays below the gameplay floor, preventing coplanar flashing.
        A.Part(map,"EggWalk"..zone,Vector3.new(8,.12,26),Vector3.new(x-31,.06,-3),color:Lerp(Color3.fromRGB(40,54,72),.7),nil,true)
        A.Label(map,Vector3.new(x-16,3,23),Vector3.new(19,3,.3),"ПРЫГАЙ → ПОДНИМИСЬ НА БАШНЮ\nПортал следующей зоны — на вершине",color)
    end
    local lighting=game:GetService("Lighting")
    lighting.ClockTime=13.5; lighting.Brightness=2; lighting.Ambient=Color3.fromRGB(112,123,145)
    lighting.OutdoorAmbient=Color3.fromRGB(146,158,177)
    local bloom=lighting:FindFirstChild("SimulatorBloom") or Instance.new("BloomEffect")
    bloom.Name="SimulatorBloom"; bloom.Intensity=.12; bloom.Size=18; bloom.Threshold=1.8; bloom.Parent=lighting
    local board=LeaderboardTemplate.Build(map)
    local pivot=board:GetPivot()
    board:PivotTo(CFrame.new(4,pivot.Position.Y,31)*CFrame.Angles(0,math.pi,0))
    builtMap=map
    return map
end
return World
