-- Additional original silhouettes built with the same safe primitive factory.
local S={}; local V=Vector3.new; local rgb=Color3.fromRGB
local cream=rgb(255,241,216); local dark=rgb(24,33,58); local gold=rgb(255,205,91)
function S.Build(model,id,color,p,crystal,halo,turn)
    local function add(name,size,pos,c,shape,rot,glow) return p(model,name,size,pos,c or color,shape or "Round",rot,glow) end
    local wide=id=="Whale" or id=="Shark" or id=="Turtle"; local body
    if id=="Robot" or id=="Golem" then body=add("Body",V(1.65,1.45,1.4),V(0,0,0),color,"Block")
    else body=add("Body",wide and V(1.65,1.25,2.2) or V(1.65,1.5,1.5),V(0,0,0)) end
    local faceZ=wide and -1.02 or -.71
    if id=="Robot" then
        add("Screen",V(1.4,.85,.09),V(0,.13,-.75),dark,"Block")
        for _,s in {-1,1} do add("PixelEye",V(.27,.34,.07),V(s*.36,.18,-.82),rgb(108,255,237),"Block",nil,true) end
    else
        for _,s in {-1,1} do
            if id=="Owl" then add("FaceDisk",V(.76,.92,.17),V(s*.36,.08,faceZ+.06),cream) end
            if id=="Panda" then add("EyePatch",V(.58,.7,.13),V(s*.36,.12,faceZ+.02),dark,nil,turn(0,0,s*-18)) end
            add("EyeWhite",V(.36,.42,.14),V(s*.34,.14,faceZ),cream)
            add("Pupil",V(.23,.3,.1),V(s*.34,.12,faceZ-.08),dark)
            add("Highlight",V(.075,.085,.035),V(s*.34-.04,.2,faceZ-.14),rgb(255,255,255))
            add("Blush",V(.23,.11,.05),V(s*.61,-.17,faceZ+.01),rgb(245,142,170))
        end
        add("Smile",V(.21,.055,.05),V(0,-.32,faceZ-.04),dark)
    end
    if not wide and id~="Serpent" and id~="Octopus" and id~="Slime" then
        for _,s in {-1,1} do add("Paw",V(.44,.28,.52),V(s*.49,-.7,-.36),id=="Panda" and dark or cream) end
    end
    if id=="Bee" then
        for i=1,3 do add("Stripe",V(1.69,.19,1.54),V(0,-.48+i*.31,0),dark) end
        for _,s in {-1,1} do
            local wing=add("HoneyWing",V(.85,.13,1.2),V(s*.9,.42,.3),rgb(213,246,255),nil,turn(0,s*25,s*20)); wing.Transparency=.3
            add("Antenna",V(.08,.5,.08),V(s*.32,.93,-.15),dark,nil,turn(0,0,s*-22))
            add("AntennaTip",V(.19,.19,.19),V(s*.42,1.18,-.15),gold)
        end
        add("HoneyPot",V(.58,.56,.45),V(.83,-.45,-.15),gold)
    elseif id=="Mushroom" then
        body.Color=cream
        add("MushroomCap",V(2.45,.9,2.1),V(0,.79,.02))
        add("CapRim",V(2.42,.15,2.08),V(0,.5,.02),cream)
        for i=1,7 do local a=i*2.4; add("CapSpot",V(.28,.09,.32),V(math.cos(a)*.75,1.15,math.sin(a)*.5),cream) end
    elseif id=="Turtle" then
        add("Shell",V(1.82,1.08,1.9),V(0,.38,.37),rgb(65,132,109))
        for x=-1,1 do for z=0,1 do add("ShellTile",V(.48,.16,.55),V(x*.49,.91,z*.58),gold) end end
        for _,s in {-1,1} do for z=0,1 do add("Flipper",V(.65,.2,.65),V(s*.91,-.5,z*.95-.15)) end end
        add("SproutStem",V(.12,.55,.12),V(0,1.15,.4),rgb(68,133,91))
        for _,s in {-1,1} do add("GardenLeaf",V(.5,.14,.3),V(s*.22,1.38,.4),rgb(146,228,112),nil,turn(0,0,s*22)) end
    elseif id=="Owl" or id=="Griffin" then
        add("Beak",V(.32,.33,.35),V(0,-.15,-.89),gold,"Wedge",turn(180,0,0))
        for _,s in {-1,1} do
            add("BrowFeather",V(.55,.17,.22),V(s*.37,.58,-.6),cream,nil,turn(0,0,s*18))
            for i=1,4 do add("Feather",V(.4,.19,.9),V(s*(.71+i*.16),.17-i*.13,.15),i%2==0 and cream or color,nil,turn(0,s*24,-s*32)) end
        end
        if id=="Griffin" then add("Tail",V(.23,.25,1.25),V(0,-.27,1)); add("TailTuft",V(.45,.4,.5),V(0,-.1,1.58),gold) end
    elseif id=="Panda" or id=="Lion" then
        for _,s in {-1,1} do add("RoundEar",V(.55,.55,.35),V(s*.57,.68,0),id=="Panda" and dark or gold) end
        if id=="Panda" then
            add("Bamboo",V(.2,1.8,.2),V(.85,.1,.6),rgb(92,177,106),nil,turn(0,0,-18))
            for i=1,3 do add("BambooNode",V(.24,.09,.24),V(.85+i*.08,-.7+i*.45,.6),cream) end
        else
            for i=1,12 do local a=i*math.pi/6; add("ManeLock",V(.56,.66,.53),V(math.cos(a)*.87,math.sin(a)*.89,.1),i%2==0 and gold or rgb(204,119,53),nil,turn(0,0,math.deg(a))) end
            add("Muzzle",V(.8,.45,.25),V(0,-.19,-.7),cream); add("Nose",V(.22,.15,.14),V(0,-.12,-.87),dark)
        end
    elseif id=="Deer" or id=="Unicorn" then
        for _,s in {-1,1} do
            add("Ear",V(.34,.64,.3),V(s*.62,.65,.02),cream,nil,turn(0,0,-s*30))
            if id=="Deer" then
                for i=1,3 do
                    add("Antler",V(.13,.47,.13),V(s*(.27+i*.12),.7+i*.3,.13),gold,nil,turn(0,0,-s*18))
                    add("AntlerBranch",V(.34,.11,.13),V(s*(.4+i*.12),.83+i*.3,.13),gold,nil,turn(0,0,s*25))
                end
            end
        end
        if id=="Unicorn" then
            for i=1,5 do crystal(model,V(0,.65+i*.17,-.2),V(.38-i*.05,.3,.32-i*.04),i%2==0 and gold or cream) end
            for i=1,6 do add("RainbowMane",V(.4,.36,.42),V(.38,.65-i*.18,.52),Color3.fromHSV(i/7,.4,1)) end
        else for i=-1,1 do add("Freckle",V(.09,.09,.04),V(i*.2,.43,-.64),cream) end end
    elseif id=="Shark" or id=="Whale" then
        add("Belly",V(1.3,.48,1.6),V(0,-.43,-.16),cream)
        for _,s in {-1,1} do
            add("SideFin",V(.85,.18,.8),V(s*.9,-.13,.16),color,nil,turn(0,s*28,s*-20))
            add("TailFan",V(.85,.17,.65),V(s*.36,.1,1.4),color,nil,turn(0,s*30,s*15))
        end
        if id=="Shark" then add("DorsalFin",V(.28,.95,.8),V(0,.76,.35),color,"Wedge",turn(0,90,0))
            for _,s in {-1,1} do for i=1,3 do add("Gill",V(.04,.28,.07),V(s*.78,-.02,i*.16-.15),dark) end end
        else halo(model,1,.65,rgb(193,224,255)); for i=1,6 do add("Constellation",V(.08,.08,.08),V(math.sin(i)*.6,.55,math.cos(i)*.6),gold,nil,nil,true) end end
    elseif id=="Octopus" then
        for i=1,8 do
            local a=i*math.pi/4; local r=V(math.cos(a),0,math.sin(a))
            add("Tentacle",V(.33,.35,1),r*.73+V(0,-.65,0),color,nil,turn(0,-math.deg(a)+90,0))
            add("CurledTip",V(.4,.5,.4),r*1.18+V(0,-.52,0),color)
            add("Sucker",V(.17,.1,.17),r*.99+V(0,-.83,0),rgb(139,247,229))
        end
    elseif id=="Kitsune" then
        for _,s in {-1,1} do add("SpiritEar",V(.45,.8,.4),V(s*.5,.83,0),color,"Wedge",turn(0,90,-s*12)); add("RedMark",V(.14,.3,.04),V(s*.56,.09,-.68),rgb(224,93,116),nil,turn(0,0,s*22)) end
        for i=1,9 do
            local a=(i-5)*.25; local h=math.abs(i-5)*.1
            add("SpiritTail",V(.36,.6,1.6),V(math.sin(a)*1.5,-.05+h,1.03),color,nil,turn(-22,math.deg(a),0))
            add("TailFlame",V(.3,.4,.48),V(math.sin(a)*1.9,.32+h,1.65),rgb(249,137,174))
        end
    elseif id=="Golem" or id=="Robot" then
        for _,s in {-1,1} do
            add("Shoulder",V(.58,.68,.65),V(s*.92,.16,0),color,"Block",turn(0,0,-s*12))
            add("Fist",V(.58,.5,.6),V(s*1.05,-.4,-.1),color,"Block")
            if id=="Robot" then add("Antenna",V(.09,.5,.09),V(s*.45,.92,0),gold); add("SignalLight",V(.18,.18,.18),V(s*.45,1.2,0),rgb(110,255,218),nil,nil,true) end
        end
        crystal(model,V(0,-.35,-.78),V(.32,.5,.12),rgb(104,245,224))
        if id=="Golem" then for i=-1,1 do crystal(model,V(i*.45,.82,0),V(.28,.7,.38),rgb(135,229,246)) end end
    elseif id=="Serpent" then
        for i=1,7 do local a=i*.55; add("Coil",V(.9-i*.06,.8-i*.05,.9-i*.06),V(math.sin(a)*.7,-i*.16,.5+i*.3)); add("SpineStar",V(.12,.28,.12),V(math.sin(a)*.7,.4-i*.16,.5+i*.3),gold,nil,nil,true) end
        for _,s in {-1,1} do add("HeadFin",V(.32,.8,.5),V(s*.72,.45,0),cream,nil,turn(0,0,-s*35)) end
        halo(model,1.2,.53,gold)
    elseif id=="Slime" then
        body.Transparency=.22
        add("InnerHeart",V(.5,.45,.45),V(0,-.05,.05),rgb(113,255,198),nil,nil,true)
        for _,s in {-1,1} do add("Sprout",V(.6,.13,.36),V(s*.22,.94,0),rgb(78,163,106),nil,turn(0,0,s*30)) end
        add("Bubble",V(.26,.26,.26),V(.92,.6,.1),cream).Transparency=.4
    elseif id=="Butterfly" or id=="Bat" then
        for _,s in {-1,1} do
            if id=="Butterfly" then
                for i=1,2 do
                    add("ButterflyWing",V(1.25,.16,1.5-i*.22),V(s*(.88+i*.12),.18-(i-1)*.6,.1),i==1 and color or rgb(125,228,220),nil,turn(0,0,s*20))
                    add("WingEye",V(.4,.1,.5),V(s*1.12,.3-(i-1)*.6,.04),gold)
                end
            else
                for i=1,3 do add("BatMembrane",V(.65,.12,.95-i*.1),V(s*(.76+i*.24),.15-i*.13,.16),color,"Wedge",turn(0,s*20,-s*25)) end
                add("PointedEar",V(.4,.9,.3),V(s*.4,.87,0),color,"Wedge",turn(0,90,0))
            end
            add("Antenna",V(.07,.55,.07),V(s*.25,.93,0),dark,nil,turn(0,0,-s*25))
        end
    elseif id=="Chameleon" then
        for _,s in {-1,1} do add("EyeTurret",V(.55,.58,.5),V(s*.62,.33,-.48),color) end
        for i=1,8 do local a=i*math.pi/4; add("CoilTail",V(.22,.22,.28),V(math.cos(a)*.45,-.14+math.sin(a)*.45,1.1),Color3.fromHSV(i/9,.45,.95)) end
        for i=1,5 do add("Crest",V(.16,.3,.24),V(0,.69,.1+(i-1)*.18),Color3.fromHSV(i/8,.5,1),"Wedge") end
    elseif id=="Penguin" then
        add("Bib",V(1.22,1.18,.2),V(0,-.05,-.65),cream)
        add("Beak",V(.34,.24,.35),V(0,-.1,-.87),gold,"Wedge",turn(180,0,0))
        add("Scarf",V(1.6,.2,1.45),V(0,-.43,0),rgb(246,123,149))
        add("ScarfTail",V(.3,.7,.15),V(.47,-.65,-.74),rgb(246,123,149),nil,turn(0,0,-16))
        for _,s in {-1,1} do add("Flipper",V(.27,.86,.5),V(s*.83,-.18,0),color,nil,turn(0,0,s*18)) end
    end
    return body
end
return S
