local C=require(game.ReplicatedStorage.SimulatorShared.Config)
local Glass=require(script.Parent.Glass)
local TextStyle=require(game.ReplicatedStorage.SimulatorShared.TextStyle)
local Catalog={}
local function text(parent,pos,size,value,font,color)
    local t=Instance.new("TextLabel"); t.Position=pos; t.Size=size; t.Text=value
    t.BackgroundTransparency=1; t.TextColor3=color or Glass.Colors.Text
    t.Font=Enum.Font.GothamBold; t.TextSize=font or 14; t.TextWrapped=true
    t.Parent=parent; TextStyle.Apply(t); return t
end
local function button(parent,pos,size,value)
    local b=Instance.new("TextButton"); b.AnchorPoint=Vector2.new(.5,.5)
    b.Position=pos; b.Size=size; b.Text=value; b.TextColor3=Glass.Colors.Text
    b.Font=Enum.Font.GothamBold; b.TextSize=13; b.TextWrapped=true; b.Parent=parent
    Glass.Style(b,Glass.Colors.Mint,12); b.GlassTint:Destroy(); Glass.AnimateButton(b)
    TextStyle.Apply(b); return b
end
local function picture(parent,color,id,isEgg)
    local view=Instance.new("ViewportFrame"); view.Name="Picture"; view.Size=UDim2.new(1,-16,0,68)
    view.Position=UDim2.fromOffset(8,6); view.BackgroundTransparency=1
    view.Ambient=Color3.fromRGB(220,220,230); view.LightColor=Color3.new(1,1,1); view.Parent=parent
    local world=Instance.new("WorldModel"); world.Parent=view
    local camera=Instance.new("Camera"); camera.FieldOfView=40
    camera.CFrame=CFrame.lookAt(Vector3.new(3,2,6),Vector3.new(0,.4,0)); camera.Parent=view; view.CurrentCamera=camera
    local function part(size,pos,tint,ball)
        local p=Instance.new("Part"); p.Size=size; p.Position=pos; p.Color=tint
        p.Anchored=true; p.CanCollide=false; p.Material=Enum.Material.SmoothPlastic
        if ball then p.Shape=Enum.PartType.Ball end
        p.Parent=world
    end
    if isEgg then
        part(Vector3.new(2,2.7,2),Vector3.zero,color,true)
        part(Vector3.new(2.1,.18,2.1),Vector3.zero,Glass.Colors.Gold,false)
    else
        part(Vector3.new(1.6,1.5,1.5),Vector3.zero,color,false)
        for _,x in {-.48,.48} do
            part(Vector3.new(.38,id=="Bunny" and 1.3 or .55,.45),Vector3.new(x,id=="Bunny" and 1.15 or .87,0),color,false)
            part(Vector3.new(.2,.25,.12),Vector3.new(x*.7,.18,.0+ .78),Glass.Colors.Base,false)
        end
    end
    return view
end
function Catalog.Build(parent)
    local refs={EggButtons={},PetButtons={},PetRemoveButtons={},EggCards={},PetCards={}}
    refs.PetSummary=text(parent,UDim2.fromOffset(20,58),UDim2.new(1,-40,0,30),"Загрузка питомцев…",13)
    local panes,tabs,grids={},{},{}
    for i,info in {{"Eggs","Выбор яйца"},{"Inventory","Питомцы"},{"Paid","Донатные предметы"}} do
        local name=info[1]
        local tab=button(parent,UDim2.fromOffset(70+(i-1)*105,109),UDim2.fromOffset(100,40),info[2])
        tabs[name]=tab
        local pane=Instance.new("Frame"); pane.Name=name; pane.BackgroundTransparency=1
        pane.Position=UDim2.fromOffset(20,140); pane.Size=UDim2.new(1,-40,1,-158); pane.Parent=parent; panes[name]=pane
    end
    function refs.Select(name)
        for key,pane in pairs(panes) do
            pane.Visible=key==name; tabs[key].GlassEdge.Transparency=key==name and .1 or .65
        end
        refs.Selected=name
        refs.EquipBest.Visible=name=="Inventory"
    end
    for name,tab in pairs(tabs) do tab.Activated:Connect(function() refs.Select(name) end) end
    local function list(pane)
        local scroll=Instance.new("ScrollingFrame"); scroll.Name="Cards"
        scroll.Size=UDim2.fromScale(1,1); scroll.BackgroundTransparency=1; scroll.BorderSizePixel=0
        scroll.ScrollingDirection=Enum.ScrollingDirection.Y; scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
        scroll.CanvasSize=UDim2.new(); scroll.ScrollBarThickness=5; scroll.ScrollBarImageColor3=Glass.Colors.Mint
        scroll.Parent=pane
        local layout=Instance.new("UIGridLayout"); layout.CellPadding=UDim2.fromOffset(10,10)
        layout.CellSize=UDim2.fromOffset(160,250); grids[#grids+1]=layout
        layout.SortOrder=Enum.SortOrder.LayoutOrder; layout.Parent=scroll
        local padding=Instance.new("UIPadding"); padding.PaddingTop=UDim.new(0,4)
        padding.PaddingBottom=UDim.new(0,8); padding.PaddingLeft=UDim.new(0,4); padding.Parent=scroll
        return scroll
    end
    local function card(scroll,height,index)
        local f=Instance.new("Frame"); f.Name="Card"..index; f.Size=UDim2.new(1,-14,0,height)
        f.LayoutOrder=index; f.Parent=scroll; Glass.Style(f,Glass.Colors.Mint,16); return f
    end
    refs.EggList=list(panes.Eggs); refs.PetList=list(panes.Inventory); refs.PaidList=list(panes.Paid)
    refs.EquipBest=button(panes.Inventory,UDim2.new(.5,0,0,22),UDim2.new(1,-16,0,44),"Экипировать лучшее")
    refs.PetList.Position=UDim2.fromOffset(0,54); refs.PetList.Size=UDim2.new(1,0,1,-54)
    text(panes.Paid,UDim2.fromOffset(4,0),UDim2.new(1,-8,0,48),"Донатные предметы — скоро. Четвёртый слот пока недоступен.",13,Glass.Colors.Muted)
    refs.PaidList.Position=UDim2.fromOffset(0,54); refs.PaidList.Size=UDim2.new(1,0,1,-54)
    for index,id in C.EggOrder do
        local info=C.Eggs[id]; local f=card(refs.EggList,192,index)
        picture(f,Color3.fromRGB(table.unpack(info.Color)),id,true)
        text(f,UDim2.fromOffset(8,76),UDim2.new(1,-16,0,36),info.Name,15,Glass.Colors.Mint)
        local description=text(f,UDim2.fromOffset(8,116),UDim2.new(1,-16,0,68),info.Description,12)
        local locked=text(f,UDim2.fromOffset(8,116),UDim2.new(1,-16,0,68),"Недоступно",13,Glass.Colors.Muted)
        local b=button(f,UDim2.new(.5,0,0,220),UDim2.new(1,-24,0,44),"Выбрать • "..info.Cost.." монет")
        refs.EggButtons[id]=b; refs.EggCards[id]={Description=description,Locked=locked,Button=b}
    end
    for index,id in C.PetOrder do
        local info=C.PetTypes[id]; local f=card(refs.PetList,168,index)
        picture(f,Color3.fromRGB(table.unpack(info.Color)),id,false)
        text(f,UDim2.fromOffset(8,76),UDim2.new(1,-16,0,28),info.Name,16,Glass.Colors.Mint)
        text(f,UDim2.fromOffset(8,104),UDim2.new(1,-16,0,28),("Сила и монеты x%.2f"):format(1+info.Bonus),13)
        refs.PetCards[id]=text(f,UDim2.fromOffset(8,132),UDim2.new(1,-16,0,32),"Получено: 0 • нанято: 0",12,Glass.Colors.Muted)
        refs.PetButtons[id]=button(f,UDim2.new(.5,0,0,188),UDim2.new(1,-24,0,40),"Нанять +1")
        refs.PetRemoveButtons[id]=button(f,UDim2.new(.5,0,0,230),UDim2.new(1,-24,0,32),"Снять −1")
    end
    -- Decorative placeholders never participate in inventory or remotes.
    for _,scroll in {refs.EggList,refs.PetList,refs.PaidList} do
        for i=1,15 do
            local f=card(scroll,250,100+i); f.Name="Placeholder"..i
            f:SetAttribute("Placeholder",true); f.BackgroundTransparency=.55
        end
    end
    function refs.Resize(width)
        local available=width-58
        local columns=math.clamp(math.floor((available+10)/135),1,5)
        local cell=math.floor((available-(columns-1)*10)/columns)
        for _,grid in grids do
            grid.FillDirectionMaxCells=columns; grid.CellSize=UDim2.fromOffset(cell,250)
        end
        local tabWidth=(width-60)/3
        for i,name in {"Eggs","Inventory","Paid"} do
            tabs[name].Position=UDim2.fromOffset(20+tabWidth/2+(i-1)*(tabWidth+10),109)
            tabs[name].Size=UDim2.fromOffset(tabWidth,40)
        end
    end
    refs.Resize(parent.Size.X.Offset)
    function refs.UpdateEggs(level)
        for id,card in pairs(refs.EggCards) do
            local unlocked=level>=C.Eggs[id].MinLevel
            card.Description.Visible=unlocked; card.Locked.Visible=not unlocked
            card.Locked.Text="Недоступно\nУровень "..C.Eggs[id].MinLevel
            card.Button.Text=unlocked and ("Выбрать • "..C.Eggs[id].Cost.." монет") or "Недоступно"
            card.Button.Active=unlocked
        end
    end
    refs.Select("Eggs")
    return refs
end
return Catalog
