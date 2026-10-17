local A={}; local V=Vector3.new
function A.Part(parent,name,size,pos,color,material,solid,rotation,shape)
    local p=Instance.new("Part"); p.Name=name; p.Size=size
    p.CFrame=CFrame.new(pos)*(rotation or CFrame.identity); p.Color=color
    p.Material=material or Enum.Material.SmoothPlastic; p.Anchored=true
    p.CanCollide=solid==true; p.CanTouch=false; p.CanQuery=solid==true
    p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
    if shape=="Ball" then p.Shape=Enum.PartType.Ball end
    p.Parent=parent; return p
end
function A.Beam(parent,name,a,b,width,color,material)
    local p=A.Part(parent,name,V(width,width,(b-a).Magnitude),(a+b)/2,color,material)
    p.CFrame=CFrame.lookAt((a+b)/2,b); return p
end
function A.Column(parent,name,foot,height,width,depth,color,material,solid)
    -- Roblox clamps individual Part dimensions; tall towers must be segmented.
    local used,index=0,0
    while used<height do
        local length=math.min(256,height-used); index+=1
        local p=A.Part(parent,name,V(width,length,depth),foot+V(0,used+length/2,0),color,material,solid)
        p:SetAttribute("ColumnSegment",index); used+=length
    end
end
function A.Label(parent,pos,size,text,color,face)
    local p=A.Part(parent,"Plaque",size,pos,Color3.fromRGB(24,35,52))
    local gui=Instance.new("SurfaceGui"); gui.Face=face or Enum.NormalId.Back
    gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud; gui.PixelsPerStud=48; gui.Parent=p
    local label=Instance.new("TextLabel"); label.Size=UDim2.fromScale(.94,.9)
    label.Position=UDim2.fromScale(.03,.05); label.BackgroundTransparency=1
    label.Font=Enum.Font.GothamBold; label.TextScaled=true; label.TextWrapped=true
    label.TextColor3=color; label.Text=text; label.Parent=gui
    require(game.ReplicatedStorage.SimulatorShared.TextStyle).Apply(label)
    return p
end
function A.Tree(parent,pos,color,scale)
    scale=scale or 1; local brown=Color3.fromRGB(99,71,64)
    A.Part(parent,"Trunk",V(1.6,8,1.6)*scale,pos+V(0,4,0)*scale,brown)
    for i=1,3 do
        A.Part(parent,"Canopy",V(7-i,5,7-i)*scale,pos+V((i-2)*1.1,7+i*1.5,0)*scale,
            color:Lerp(Color3.new(1,1,1),i*.06),nil,false,CFrame.Angles(0,i,.12*i),"Ball")
    end
end
function A.Ring(parent,pos,radius,color,segments)
    segments=segments or 16
    for i=1,segments do
        local a=(i-1)*math.pi*2/segments; local b=i*math.pi*2/segments
        A.Beam(parent,"Ring",pos+V(math.cos(a)*radius,0,math.sin(a)*radius),pos+V(math.cos(b)*radius,0,math.sin(b)*radius),.16,color,Enum.Material.Neon)
    end
end
return A
