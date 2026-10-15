local number=require(game.ReplicatedStorage.SimulatorShared.NumberFormat).Compact
local C=require(game.ReplicatedStorage.SimulatorShared.Config)
local TextStyle=require(game.ReplicatedStorage.SimulatorShared.TextStyle)
local LeaderboardTemplate=require(script.Parent.LeaderboardTemplate)
local ModelFactory=require(game.ReplicatedStorage.SimulatorShared.ModelFactory)
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
    part(map,"Ground",Vector3.new(100,2,80),Vector3.new(4,-1,0),Color3.fromRGB(30,40,62))
    part(map,"StartingPlaza",Vector3.new(32,0.2,26),Vector3.new(-12,0.1,0),Color3.fromRGB(47,72,88))
    part(map,"AdvancedPlaza",Vector3.new(28,0.2,26),Vector3.new(24,0.1,0),Color3.fromRGB(67,49,96))
    -- Join x=4..10 exactly: no overlap with either plaza, and a 0.05 stud step below them.
    part(map,"Path",Vector3.new(6,0.2,7),Vector3.new(7,0.05,0),Color3.fromRGB(100,109,134))
    for id, info in pairs(C.Stations) do
        local color=id=="Basic" and Color3.fromRGB(65,220,183) or Color3.fromRGB(160,116,255)
        local pad=part(map,id,Vector3.new(8,1,8),info.Position,color); pad.Material=Enum.Material.Neon
        local prompt=Instance.new("ProximityPrompt"); prompt.Name="TrainPrompt"
        prompt.ActionText="Тренироваться"; prompt.ObjectText=id=="Basic" and "Сила" or "Сила x1.25 • уровень 3"
        prompt.KeyboardKeyCode=Enum.KeyCode.E; prompt.HoldDuration=0; prompt.MaxActivationDistance=C.TrainDistance
        prompt.Exclusivity=Enum.ProximityPromptExclusivity.OneGlobally
        prompt.RequiresLineOfSight=false; prompt.Parent=pad
        sign(map,id.."Sign",info.Position+Vector3.new(0,6,-7),id=="Basic" and "ТРЕНИРОВКА СИЛЫ\nНажми E у платформы" or "ПРОДВИНУТАЯ ЗОНА\nУровень 3 • +25% за тренировку",color)
        -- Simple equipment built from primitives, no external models/scripts.
        local bar=part(map,id.."Bar",Vector3.new(6,0.3,0.3),info.Position+Vector3.new(0,2,-2),Color3.fromRGB(160,175,188))
        for _, x in {-2.5,2.5} do
            local weight=part(map,id.."Weight"..x,Vector3.new(0.8,2,2),bar.Position+Vector3.new(x,0,0),Color3.fromRGB(30,34,44))
            weight.Shape=Enum.PartType.Ball
        end
    end
    sign(map,"Welcome",Vector3.new(-34,7,14),"СИЛА → МОНЕТЫ → УЛУЧШЕНИЯ\nПерерождение даёт постоянный бонус",Color3.fromRGB(245,210,106))
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
    for _, z in {-37,37} do
        part(map,"Border"..z,Vector3.new(94,3,1),Vector3.new(4,1.5,z),Color3.fromRGB(52,67,93))
    end
    for _, x in {-43,51} do
        part(map,"Border"..x,Vector3.new(1,3,74),Vector3.new(x,1.5,0),Color3.fromRGB(52,67,93))
    end
    LeaderboardTemplate.Build(map)
    builtMap=map
    return map
end
return World
