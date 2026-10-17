local C=require(script.Parent.Config)
local Concepts=require(script.Parent.PetConcepts)
local Sculpt=require(script.Parent.PetSculpt)
local Factory={}
local V=Vector3.new
local rgb=Color3.fromRGB
local cream=rgb(255,240,215)
local gold=rgb(255,205,93)
local dark=rgb(22,28,51)
local white=rgb(255,255,255)
-- Entirely original primitive models. No external assets, scripts or asset permissions.
local function piece(model,name,size,pos,color,shape,rotation,glow)
    local p=Instance.new("Part"); p.Name=name; p.Size=size
    p.CFrame=CFrame.new(pos)*(rotation or CFrame.identity); p.Color=color
    p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false; p.CastShadow=not glow
    p.Material=glow and Enum.Material.Neon or Enum.Material.SmoothPlastic
    p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
    if shape=="Round" then
        p.Size=Vector3.one
        local mesh=Instance.new("SpecialMesh"); mesh.MeshType=Enum.MeshType.Sphere; mesh.Scale=size; mesh.Parent=p
    elseif shape=="Wedge" then
        local mesh=Instance.new("SpecialMesh"); mesh.MeshType=Enum.MeshType.Wedge; mesh.Scale=Vector3.one; mesh.Parent=p
    end
    p.Parent=model; return p
end
local function turn(x,y,z) return CFrame.Angles(math.rad(x),math.rad(y),math.rad(z)) end
local function halo(model,y,radius,color)
    for i=1,16 do
        local a=(i-1)*math.pi*2/16
        piece(model,"Halo",V(.12,.12,.12),V(math.cos(a)*radius,y,math.sin(a)*radius),color,"Round",nil,true)
    end
end
local function crystal(model,pos,size,color,rotation)
    -- Four right triangles meet at the centre: a pointed diamond silhouette in XY.
    -- Opposing wedges at one position would instead fill a rectangular box.
    local basis=CFrame.new(pos)*(rotation or CFrame.identity)
    for _,s in {-1,1} do
        for _,t in {-1,1} do
            local localFrame=CFrame.new(s*size.X/4,t*size.Y/4,0)
                *turn(0,0,t<0 and 180 or 0)*turn(0,-90*s*t,0)
            local frame=basis*localFrame
            piece(model,"CrystalFacet",V(size.Z,size.Y/2,size.X/2),frame.Position,
                color:Lerp(white,s==t and .12 or 0),"Wedge",frame.Rotation)
        end
    end
end
local function egg(model,id,color)
    -- A SINGLE smooth oval shell, without an overlapping crown or seam.
    local shell=piece(model,"ShellBase",V(2.10,3.10,2.10),V(0,0,0),color,"Round")
    if id=="Meadow" then
        for i,pos in {V(-.55,-.4,-.88),V(.48,.05,-.87),V(.1,-.85,-.82)} do
            piece(model,"ShellSpot"..i,V(.32,.42,.16),pos,cream,"Round",turn(-10,0,i*20))
        end
        for _,s in {-1,1} do
            piece(model,"Leaf",V(.5,.16,.95),V(s*.24,1.57,0),rgb(66,169,116),"Round",turn(0,s*30,s*22))
        end
        piece(model,"Stem",V(.15,.35,.15),V(0,1.62,0),rgb(76,121,74),"Round")
    elseif id=="Crystal" then
        for i=1,5 do
            local a=i*math.pi*2/5
            crystal(model,V(math.cos(a)*.83,-.57,math.sin(a)*.83),V(.32,.8,.35),rgb(123,225,255),turn(0,-math.deg(a),20))
        end
        crystal(model,V(0,1.55,0),V(.42,.7,.42),rgb(218,248,255))
        crystal(model,V(0,.25,-.91),V(.36,.65,.16),rgb(235,226,255))
    else
        halo(model,1.84,.68,gold)
        for _,s in {-1,1} do
            for i=1,3 do
                piece(model,"ShellWing",V(.3,.18,.76-i*.09),V(s*(.89+i*.16),.15-i*.16,.05),cream,"Round",turn(0,0,-s*28))
            end
        end
        crystal(model,V(0,.3,-.93),V(.32,.6,.17),gold)
        for _,s in {-1,1} do
            piece(model,"Star",V(.15,.28,.12),V(s*.53,-.45,-.91),gold,"Round",nil,true)
        end
    end
    return shell
end
local function pet(model,id,color,upgraded)
    local body=piece(model,"Body",V(1.65,1.5,1.5),V(0,0,0),color,"Round")
    local accent=id=="Axolotl" and rgb(92,246,218) or cream
    piece(model,"Muzzle",V(1.15,.65,.30),V(0,-.28,-.65),accent,"Round")
    for _,s in {-1,1} do
        -- Contrasting eye whites, pupils and highlights remain readable on small cards.
        piece(model,"EyeWhite",V(.36,.43,.14),V(s*.36,.16,-.69),white,"Round")
        piece(model,"Eye",V(.22,.29,.12),V(s*.36,.13,-.77),dark,"Round")
        piece(model,"EyeShine",V(.075,.085,.045),V(s*.36-.045,.21,-.827),white,"Round")
        piece(model,"Blush",V(.2,.1,.05),V(s*.60,-.18,-.66),rgb(255,148,172),"Round")
        piece(model,"Foot",V(.4,.25,.5),V(s*.47,-.69,-.37),accent,"Round")
    end
    if id=="Phoenix" then
        piece(model,"Beak",V(.36,.27,.36),V(0,-.14,-.85),gold,"Wedge",turn(180,0,0))
    else
        piece(model,"Nose",V(.18,.13,.12),V(0,-.18,-.83),id=="Dog" and dark or rgb(231,115,150),"Round")
        piece(model,"Mouth",V(.17,.055,.045),V(0,-.36,-.82),dark,"Round")
    end
    if id=="Cat" or id=="Fox" then
        for _,s in {-1,1} do
            piece(model,"PointedEar",V(.5,.7,.44),V(s*.48,.82,-.05),color,"Wedge",turn(0,90,s*-12))
            piece(model,"InnerEar",V(.25,.35,.08),V(s*.48,.85,-.29),rgb(255,190,201),"Wedge",turn(0,90,s*-12))
            if id=="Cat" then
                for i=1,2 do piece(model,"Whisker",V(.35,.035,.035),V(s*.72,-.25-i*.1,-.65),cream,nil,turn(0,0,s*(i*16-24))) end
            else
                piece(model,"CheekTuft",V(.42,.38,.28),V(s*.73,-.24,-.37),cream,"Wedge",turn(0,0,s*-28))
            end
        end
        if id=="Cat" then
            piece(model,"Tail",V(.35,.8,.35),V(.58,.05,.78),color,"Round",turn(25,0,-20))
            piece(model,"TailTip",V(.36,.33,.35),V(.72,.4,.93),cream,"Round")
            for i=-1,1 do piece(model,"ForeheadStripe",V(.13,.32,.07),V(i*.24,.5,-.59),rgb(205,125,67),"Round",turn(15,0,0)) end
        else
            for _,s in {-1,1} do
                piece(model,"TwinTail",V(.65,.55,1.2),V(s*.62,-.05,.78),color,"Round",turn(25,s*26,0))
                piece(model,"StarTailTip",V(.55,.46,.45),V(s*.85,.19,1.18),cream,"Round")
            end
            crystal(model,V(0,.56,-.62),V(.17,.32,.10),gold)
        end
    elseif id=="Dog" then
        for _,s in {-1,1} do piece(model,"FloppyEar",V(.48,1.0,.45),V(s*.77,.30,-.03),rgb(61,125,202),"Round",turn(0,0,s*16)) end
        piece(model,"EyePatch",V(.5,.58,.11),V(.37,.17,-.66),rgb(61,125,202),"Round")
        piece(model,"Tail",V(.25,.5,.28),V(0,.12,.8),color,"Round",turn(35,0,0))
        piece(model,"Collar",V(.85,.13,.22),V(0,-.57,-.66),rgb(55,113,195),"Round")
        piece(model,"Tag",V(.18,.22,.1),V(0,-.62,-.8),gold,"Round")
    elseif id=="Bunny" then
        for _,s in {-1,1} do
            piece(model,"LongEar",V(.38,1.18,.36),V(s*.39,1.03,0),color,"Round",turn(0,0,s*-12))
            piece(model,"InnerEar",V(.20,.80,.09),V(s*.40,1.07,-.17),rgb(255,200,222),"Round",turn(0,0,s*-12))
        end
        piece(model,"CottonTail",V(.65,.65,.65),V(0,-.22,.76),cream,"Round")
        for _,s in {-1,1} do piece(model,"FrontTooth",V(.1,.15,.09),V(s*.065,-.34,-.87),white) end
    elseif id=="Phoenix" then
        for _,s in {-1,1} do
            for i=1,3 do
                piece(model,"FlameWing",V(.68,.3,.6),V(s*(.7+i*.22),.08-i*.17,.12),i==3 and gold or rgb(255,110+i*20,59),"Round",turn(0,s*20,-s*32))
            end
        end
        for i=-1,1 do
            piece(model,"FlameCrest",V(.25,.75-math.abs(i)*.15,.3),V(i*.27,.86,.03),rgb(255,111,57),"Round",turn(-12,0,-i*20))
            piece(model,"FlameTail",V(.25,.23,1.05),V(i*.27,-.2,.94),rgb(255,108,65),"Round",turn(-15,i*18,0))
        end
    elseif id=="Axolotl" then
        for _,s in {-1,1} do
            for i=-1,1 do
                piece(model,"GlowGill",V(.70,.16,.18),V(s*.95,.18+i*.29,0),accent,"Round",turn(0,0,s*i*32),true)
                piece(model,"GillTip",V(.22,.25,.22),V(s*(1.22-math.abs(i)*.06),.18+i*.40,0),rgb(166,255,239),"Round")
            end
        end
        piece(model,"FinTail",V(.26,.65,1.20),V(0,-.18,.98),accent,"Round",turn(-12,0,0))
        for i=-1,1 do piece(model,"StarFreckle",V(.07,.07,.05),V(i*.22,.48,-.61),accent,"Round",nil,true) end
    elseif id=="Dragon" then
        for _,s in {-1,1} do
            piece(model,"Horn",V(.25,.70,.25),V(s*.5,.89,.03),gold,"Round",turn(15,0,s*-20))
            for i=1,3 do
                piece(model,"WingFeather",V(.70,.19,.75),V(s*(.65+i*.20),.10-i*.17,.18),i==3 and gold or rgb(157,205,246),"Round",turn(0,s*22,-s*28))
            end
        end
        halo(model,1.48,.55,gold)
        piece(model,"DragonTail",V(.4,.37,1.25),V(0,-.27,1.02),color,"Round",turn(-10,0,0))
        crystal(model,V(0,-.16,1.62),V(.35,.40,.38),gold)
        crystal(model,V(0,.44,-.63),V(.23,.34,.10),rgb(106,215,244))
    end
    if upgraded then
        -- Keep species ears/horns visible: a floating three-point crown above the silhouette.
        local y=id=="Bunny" and 1.88 or id=="Dragon" and 1.80 or 1.50
        piece(model,"CrownBand",V(.75,.13,.48),V(0,y,0),gold)
        for i=-1,1 do crystal(model,V(i*.25,y+.18,0),V(.16,.35,.22),gold) end
        for _,s in {-1,1} do piece(model,"UpgradeGem",V(.14,.14,.08),V(s*.59,-.42,-.71),gold,"Round",nil,true) end
    end
    return body
end
local function finishPet(model,info,species,color)
    -- Biomes change the silhouette as well as the palette; all old IDs remain valid.
    local zone=info.Zone or 1
    for _,s in {-1,1} do
        piece(model,"Brow",V(.30,.065,.07),V(s*.36,.43,-.69),dark,"Round",turn(0,0,s*-8))
        piece(model,"ToeHighlight",V(.18,.04,.12),V(s*.47,-.72,-.58),cream,"Round")
    end
    if species=="Cat" then
        piece(model,"ExplorerScarf",V(.87,.12,.2),V(0,-.55,-.69),rgb(87,189,167),"Round")
        piece(model,"ScarfKnot",V(.2,.3,.16),V(.34,-.66,-.7),rgb(87,189,167),"Round",turn(0,0,-22))
    elseif species=="Dog" then
        for i=1,3 do piece(model,"HairTuft",V(.26,.32,.3),V((i-2)*.18,.73,-.26),color,"Round",turn(-20,0,(i-2)*15)) end
    elseif species=="Bunny" then
        piece(model,"MoonPendant",V(.28,.31,.13),V(0,-.5,-.76),gold,"Round")
    elseif species=="Phoenix" then
        for _,s in {-1,1} do for i=1,3 do piece(model,"WingFlameTip",V(.18,.5,.25),V(s*(.8+i*.25),.16-i*.14,.2),gold,"Round",turn(0,0,-s*36),true) end end
    elseif species=="Dragon" then
        for i=1,4 do crystal(model,V(0,.55-(i-1)*.15,.5+i*.24),V(.2,.45,.2),gold) end
    end
    if zone==2 then
        for _,s in {-1,1} do
            piece(model,"ForestLeaf",V(.5,.13,.28),V(s*.64,.54,.37),rgb(106,203,119),"Round",turn(0,s*20,s*28))
            piece(model,"ForestBerry",V(.16,.16,.16),V(s*.76,.61,.23),rgb(239,135,156),"Round")
        end
        piece(model,"AcornCharm",V(.21,.3,.18),V(0,-.48,-.83),rgb(187,128,73),"Round")
    elseif zone==3 then
        for i=-1,1 do crystal(model,V(i*.52,.58,.34),V(.2,.58,.24),rgb(166,237,255),turn(0,0,-i*16)) end
        piece(model,"WinterScarf",V(1.3,.14,1.2),V(0,-.48,0),rgb(118,171,239),"Round")
    elseif zone==4 then
        for _,s in {-1,1} do
            piece(model,"ObsidianShoulder",V(.4,.33,.55),V(s*.75,-.02,.25),rgb(66,54,77),"Round")
            crystal(model,V(s*.75,.2,.25),V(.18,.48,.2),rgb(255,144,70))
            piece(model,"LavaRune",V(.06,.27,.06),V(s*.57,.34,-.63),rgb(255,163,77),"Round",turn(0,0,s*23),true)
        end
    elseif zone==5 then
        for _,s in {-1,1} do
            for i=1,3 do piece(model,"AstralFin",V(.16,.13,.64),V(s*(.65+i*.13),.36-i*.12,.55),cream,"Round",turn(0,s*18,-s*28)) end
            crystal(model,V(s*.69,.65,.14),V(.15,.28,.15),gold)
        end
        halo(model,-.83,.77,rgb(173,210,255))
    end
end
function Factory.Build(id,isEgg)
    local info=(isEgg and C.Eggs or C.PetTypes)[id] or (not isEgg and Concepts.Types[id]); assert(info,"Unknown model: "..tostring(id))
    local model=Instance.new("Model"); model.Name=id
    local color=rgb(table.unpack(info.Color))
    if isEgg then
        model.PrimaryPart=egg(model,info.ModelStyle or id,color)
        -- Zone-specific ornaments leave the single uninterrupted shell intact.
        if info.Zone==2 then
            for _,s in {-1,1} do piece(model,"AmberVine",V(.18,1.4,.18),V(s*.82,0,0),rgb(118,170,98),"Round",turn(0,0,s*18)) end
        elseif info.Zone==3 then halo(model,-1.37,1.1,rgb(159,234,255))
        elseif info.Zone==4 then
            for i=1,4 do crystal(model,V(math.sin(i*1.6)*.78,-1,math.cos(i*1.6)*.78),V(.28,.65,.3),rgb(255,147,72)) end
        elseif info.Zone==5 then halo(model,-1.35,1.2,gold) end
    elseif info.Concept then model.PrimaryPart=Sculpt.Build(model,id,color,piece,crystal,halo,turn)
    else
        local species=info.Species or info.BaseId or id
        model.PrimaryPart=pet(model,species,color,info.Upgraded); finishPet(model,info,species,color)
    end
    model:SetAttribute("ModelRevision",2); model:SetAttribute("Species",info.Species or id)
    return model
end
return Factory
