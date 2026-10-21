local C=require(game.ReplicatedStorage.SimulatorShared.Config)
local Layout=require(game.ReplicatedStorage.SimulatorShared.TowerLayout)
local A=require(script.Parent.WorldArt)
local Factory=require(game.ReplicatedStorage.SimulatorShared.ModelFactory)
local T={}; local V=Vector3.new; local rgb=Color3.fromRGB
local stone=rgb(53,64,83); local gold=rgb(245,202,112)
local names={"САД НЕБЕСНЫХ СТУПЕНЕЙ","ДРЕВО ВЫСОТЫ","ШПИЛЬ СЕВЕРНОГО СИЯНИЯ","СЕРДЦЕ ВУЛКАНА","НЕБЕСНАЯ ОБСЕРВАТОРИЯ"}
local function prompt(base,name,action,object)
    local p=Instance.new("ProximityPrompt"); p.Name=name; p.ActionText=action; p.ObjectText=object
    p.KeyboardKeyCode=Enum.KeyCode.E; p.HoldDuration=0; p.MaxActivationDistance=7
    p.RequiresLineOfSight=false; p.Exclusivity=Enum.ProximityPromptExclusivity.OneGlobally; p.Parent=base
end
function T.Build(map)
    for zone,info in C.Zones do
        local layout=Layout.Build(zone); local color=rgb(table.unpack(info.Color))
        local folder=Instance.new("Folder"); folder.Name="Tower"..zone; folder.Parent=map
        folder:SetAttribute("Zone",zone); folder:SetAttribute("SummitHeight",layout.SummitY)
        local origin=V(layout.X,0,layout.Z)
        A.Part(folder,"Courtyard",V(76,2,60),origin+V(0,-1,3),color:Lerp(stone,.47),nil,true)
        A.Part(folder,"Approach",V(12,.2,14),V(layout.X-18,.1,-39),color:Lerp(stone,.6),nil,true)
        -- Starts at ground level, with no SpawnLocation/visible spawn platform.
        A.Label(folder,V(layout.X,5,-45),V(20,5,.4),names[zone].."\n32 ступени · растущая высота",color)
        local recall=A.Part(map,"TowerRecall"..zone,V(4,.5,4),V(layout.X-29,.25,-48),color,nil,true)
        recall:SetAttribute("RecallZone",zone); prompt(recall,"RecallPrompt","Вернуться к отметке","Башня · точка отдыха")
        A.Label(folder,recall.Position+V(0,2.7,0),V(5,2.6,.3),"ВОЗВРАТ · E\nОтметки: каждые 8 ступеней",color)
        -- Collidable central structure stays clear of the continuous stair flights.
        local coreColors={rgb(182,186,154),rgb(105,76,64),rgb(151,191,215),rgb(53,44,54),rgb(188,193,221)}
        local coreColor=coreColors[zone]
        A.Column(folder,"Core",origin,layout.SummitY-1,21,21,coreColor,nil,true)
        for _,s in {-1,1} do
            for _,t in {-1,1} do
                A.Column(folder,"Spine",origin+V(s*10.8,0,t*10.8),layout.SummitY,.45,.45,color,Enum.Material.Neon)
            end
        end
        for _,stage in layout.Stages do
            local pos=V(stage.X,stage.Y-stage.Height/2,stage.Z)
            -- Solid risers fill the old vertical air gaps; neighboring treads share an edge.
            local pad=A.Part(folder,"Step"..stage.Index,V(Layout.PlatformSize,stage.Height,Layout.PlatformSize),pos,
                stage.Checkpoint and color or color:Lerp(stone,.48+(stage.Index%2)*.13),nil,true)
            pad:SetAttribute("TowerZone",zone); pad:SetAttribute("TowerStep",stage.Index)
            local surface=V(stage.X,stage.Y,stage.Z)
            A.Part(folder,"StepEdge",V(7,.06,.13),surface+V(0,.03,-4.3),stage.Checkpoint and gold or color,Enum.Material.Neon)
            A.Label(folder,surface+V(0,.05,0),V(7,.02,5),tostring(stage.Index)..(stage.Checkpoint and "  ◆" or "").."\n↑ "..string.format("%.1f",stage.Rise),stage.Checkpoint and gold or rgb(230,243,255),Enum.NormalId.Top)
            local dx,dz=stage.X-layout.X,stage.Z-layout.Z
            A.Beam(folder,"StairStringer",V(layout.X+math.clamp(dx,-10.5,10.5),stage.Bottom+.2,layout.Z+math.clamp(dz,-10.5,10.5)),
                V(stage.X,stage.Bottom+.2,stage.Z),.35,stone)
            if stage.Checkpoint then
                A.Beam(folder,"RestFlagPole",surface+V(3.8,0,3.8),surface+V(3.8,4.6,3.8),.13,gold)
                A.Part(folder,"RestFlag",V(1.6,1,.12),surface+V(3.1,4,3.8),color)
            end
        end
        local summit=A.Part(folder,"Summit",V(layout.DeckWidth,1,layout.DeckDepth),V(layout.DeckX,layout.SummitY-.5,layout.Z),color:Lerp(stone,.45),nil,true)
        summit:SetAttribute("TowerZone",zone); summit:SetAttribute("TowerStep",33)
        for _,s in {1} do
            -- Open front/back, low rails only on the far left/right edges.
            A.Part(folder,"CrownRail",V(.4,2,38),origin+V(s*20.6,layout.SummitY+1,0),gold)
        end
        A.Ring(folder,origin+V(0,layout.SummitY+.1,0),9,color)
        A.Label(folder,origin+V(0,layout.SummitY+7,-12),V(18,4,.4),"ВЕРШИНА · "..info.Name.."\n"..math.floor(layout.SummitY).." studs",color)
        local statueIds={"Bunny","Deer","Owl","Phoenix","Dragon_Z5_Upgraded"}
        local statue=Factory.Build(statueIds[zone],false); statue.Name="SummitMascot"; statue.Parent=folder
        statue:ScaleTo(zone==5 and 2.6 or 2)
        statue:PivotTo(CFrame.new(origin+V(0,layout.SummitY+4,-7))*CFrame.Angles(0,math.pi,0))
        A.Part(folder,"MascotPedestal",V(7,2,7),origin+V(0,layout.SummitY+1,-7),stone,nil,true)
        local down=A.Part(map,"TowerDown"..zone,V(4,.5,4),origin+V(15,layout.SummitY+.25,14),color,nil,true)
        down:SetAttribute("TowerDownZone",zone); prompt(down,"DownPrompt","Вниз","Вернуться к яйцам")
        A.Label(folder,down.Position+V(0,2.4,0),V(5,1.5,.25),"К ЯЙЦАМ · E",color)
        -- Four rings frame the vertical scale; biome details keep each tower recognizable.
        for tier=1,4 do
            local y=layout.SummitY*tier/5
            A.Part(folder,"Belt",V(22,.35,22),origin+V(0,y,0),color)
            for side=0,3 do
                local basis=CFrame.new(origin)*CFrame.Angles(0,side*math.pi/2,0)
                for _,s in {-1,1} do
                    local window=basis*CFrame.new(s*5,y-4,-10.65)
                    A.Part(folder,"Recess",V(3.2,7,.14),window.Position,coreColor:Lerp(stone,.7),nil,false,window.Rotation)
                    for _,edge in {-1,1} do
                        local rim=window*CFrame.new(edge*1.75,0,-.09)
                        A.Part(folder,"WindowRim",V(.16,7.4,.14),rim.Position,gold,nil,false,rim.Rotation)
                    end
                    local light=window*CFrame.new(0,0,-.1)
                    A.Part(folder,"WindowLight",V(.16,5,.08),light.Position,color,Enum.Material.Neon,false,light.Rotation)
                end
            end
            if zone==2 then
                for _,s in {-1,1} do
                    A.Beam(folder,"Branch",origin+V(s*10,y,0),origin+V(s*16,y+5,0),1.3,coreColor)
                    A.Part(folder,"Foliage",V(8,5,7),origin+V(s*14,y+7,0),color,nil,false,nil,"Ball")
                end
            elseif zone==3 then
                for _,s in {-1,1} do
                    A.Part(folder,"IceShard",V(3,13,3),origin+V(s*8,y,0),color:Lerp(rgb(255,255,255),.4),Enum.Material.Ice,false,CFrame.Angles(0,.6,s*.18))
                end
            elseif zone==4 then
                for _,s in {-1,1} do A.Beam(folder,"LavaVein",origin+V(s*10.6,y-12,-8),origin+V(s*10.6,y+12,8),.55,rgb(255,103,47),Enum.Material.Neon) end
            elseif zone==5 then
                A.Ring(folder,origin+V(0,y,0),12,gold,20)
            else
                for _,s in {-1,1} do A.Part(folder,"GardenWindow",V(3,4,.2),origin+V(s*5,y, -10.6),gold) end
            end
        end
        if zone==2 then A.Tree(folder,origin+V(0,layout.SummitY+2,0),color,2)
        elseif zone==5 then
            A.Ring(folder,origin+V(0,layout.SummitY+15,0),7,gold)
            A.Part(folder,"AstralHeart",V(5,7,5),origin+V(0,layout.SummitY+12,0),color,Enum.Material.Neon,false,CFrame.Angles(.4,.4,.4))
        end
    end
end
return T
