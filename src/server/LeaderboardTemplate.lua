-- Visual draft only: each ranking row is a separate solid plaque, no live data.
local Board={}
-- Intended refresh interval for the future live leaderboard; this draft has no data fetch loop.
Board.RefreshIntervalSeconds=3600
local rgb=Color3.fromRGB
local function part(parent,name,size,pos,color,neon)
    local p=Instance.new("Part"); p.Name=name; p.Size=size; p.Position=pos; p.Anchored=true
    p.Material=neon and Enum.Material.Neon or Enum.Material.SmoothPlastic; p.Color=color
    p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
    p.Parent=parent; return p
end
local function face(p,width,height)
    p.CFrame=CFrame.new(p.Position)*CFrame.Angles(0,math.pi,0)
    local g=Instance.new("SurfaceGui"); g.Name="Lettering"; g.Face=Enum.NormalId.Front
    g.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize; g.CanvasSize=Vector2.new(width,height)
    g.LightInfluence=0; g.AlwaysOnTop=false; g.Parent=p; return g
end
local function text(g,name,value,x,y,w,h,size,color,align)
    local t=Instance.new("TextLabel"); t.Name=name; t.Text=value
    t.Position=UDim2.fromOffset(x,y); t.Size=UDim2.fromOffset(w,h)
    t.BackgroundTransparency=1; t.Font=Enum.Font.GothamBold; t.TextSize=size
    t.TextColor3=color; t.TextXAlignment=align or Enum.TextXAlignment.Left
    t.TextStrokeColor3=rgb(8,12,24); t.TextStrokeTransparency=0.15; t.Parent=g
    return t
end
function Board.Build(parent)
    if parent:FindFirstChild("LeaderboardTemplate") then return parent.LeaderboardTemplate end
    local m=Instance.new("Model"); m.Name="LeaderboardTemplate"; m.Parent=parent
    m:SetAttribute("RefreshIntervalSeconds",Board.RefreshIntervalSeconds)
    -- Ground -> foundation -> pedestal -> feet -> shafts -> capitals -> canopy.
    -- Adjacent pieces touch only at their hidden joints; exposed rear faces have different depths.
    part(m,"Foundation",Vector3.new(57,0.6,8),Vector3.new(4,0.3,-30),rgb(22,30,47))
    part(m,"Pedestal",Vector3.new(55,1.4,6),Vector3.new(4,1.3,-30),rgb(44,55,77))
    -- Full-height backing closes the gaps beside and above the title.
    part(m,"Backing",Vector3.new(51,31.2,2),Vector3.new(4,17.6,-32.2),rgb(15,23,39))
    for _,x in {-22,4,30} do
        part(m,"Pillar",Vector3.new(1.5,29.4,2.6),Vector3.new(x,17.7,-30.7),rgb(65,79,103))
        part(m,"PillarFoot",Vector3.new(2.6,1,3.6),Vector3.new(x,2.5,-30.7),rgb(98,117,147))
        part(m,"PillarCap",Vector3.new(2.6,0.8,3.6),Vector3.new(x,32.8,-30.7),rgb(98,117,147))
    end
    local title=part(m,"HallTitle",Vector3.new(48,4,2.4),Vector3.new(4,30.4,-30),rgb(31,43,66))
    text(face(title,1200,100),"Title","ЗАЛ СЛАВЫ",0,0,1200,100,74,rgb(255,220,125),Enum.TextXAlignment.Center)
    -- Rear edge -33.6, front edge -26.4: a visible forward overhang above the title.
    part(m,"CrownTrim",Vector3.new(58.6,0.6,7.2),Vector3.new(4,33.5,-30),rgb(255,205,96))
    part(m,"TopGlow",Vector3.new(48,0.18,0.2),Vector3.new(4,32.5,-28.65),rgb(255,213,111),true)
    local cols={{name="Players",x=-9,title="ТОП 10 ИГРОКОВ",prefix="Игрок",accent=rgb(86,221,255)},
        {name="Donors",x=17,title="ТОП 10 ДОНАТЕРОВ",prefix="Донатер",accent=rgb(196,147,255)}}
    local medals={rgb(255,205,96),rgb(201,223,245),rgb(234,161,111)}
    for _,c in ipairs(cols) do
        local col=Instance.new("Model"); col.Name=c.name; col.Parent=m
        local header=part(col,"Heading",Vector3.new(23,2.5,1.6),Vector3.new(c.x,26.7,-29.9),rgb(30,42,63))
        local hg=face(header,920,100)
        local heading=text(hg,"Title",c.title,20,4,880,92,74,c.accent,Enum.TextXAlignment.Center)
        heading.TextScaled=true
        for _,x in {c.x-11.7,c.x+11.7} do
            -- Solid saturated rails retain the theme color without white neon bloom.
            local railColor=c.name=="Donors" and rgb(156,76,235) or rgb(40,177,227)
            part(col,"LightRail",Vector3.new(0.14,23.5,0.2),Vector3.new(x,14,-29.15),railColor,false)
        end
        for rank=1,10 do
            local y=23.5-(rank-1)*2.1
            local tint=medals[rank] or c.accent
            -- Winners physically project further from the wall, with separate medal blocks.
            local z=rank<=3 and -29.35 or -29.65
            local row=part(col,"Row"..rank,Vector3.new(22.6,1.85,rank<=3 and 1.6 or 1),Vector3.new(c.x,y,z),rank<=3 and rgb(48,59,79) or (rank%2==0 and rgb(31,44,65) or rgb(25,36,56)))
            local g=face(row,904,74)
            text(g,"PlayerName",string.format("%s_%02d",c.prefix,rank),125,0,610,74,43,rgb(244,248,255))
            text(g,"Value","—",750,0,130,74,46,tint,Enum.TextXAlignment.Right)
            local medal=part(col,"Rank"..rank,Vector3.new(1.8,1.45,0.35),Vector3.new(c.x-9.9,y,z+row.Size.Z/2+0.2),rank<=3 and tint or rgb(57,76,103))
            text(face(medal,80,64),"Rank",tostring(rank),0,0,80,64,48,rank<=3 and rgb(29,25,25) or rgb(232,242,255),Enum.TextXAlignment.Center)
            part(col,"RowAccent"..rank,Vector3.new(0.1,1.3,0.12),Vector3.new(c.x-8.7,y,z+row.Size.Z/2+0.08),tint,true)
        end
    end
    local notice=part(m,"RefreshNotice",Vector3.new(46,1.2,0.4),Vector3.new(4,3,-29),rgb(27,37,56))
    -- Match the 46:1.2 stud face aspect ratio so glyphs are not stretched horizontally.
    text(face(notice,1840,48),"Interval","Таблица обновляется раз в час",400,0,1040,48,32,rgb(210,220,241),Enum.TextXAlignment.Center)
    return m
end
return Board
