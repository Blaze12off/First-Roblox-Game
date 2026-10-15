local C=require(game.ReplicatedStorage.SimulatorShared.Config)
local Factory=require(game.ReplicatedStorage.SimulatorShared.ModelFactory)
local Glass=require(script.Parent.Glass)
local Headings=require(script.Parent.Headings)
local TextStyle=require(game.ReplicatedStorage.SimulatorShared.TextStyle)
local Tween=game:GetService("TweenService")
local Input=game:GetService("UserInputService")
local Catalog={}
local function rarity(info,egg)
    local names={["Обычная"]="Обычный",["Редкая"]="Редкий",["Эпическая"]="Эпический",["Мифическая"]="Мифический",["Легендарная"]="Легендарный",["Секретная"]="Секретный",["Божественная"]="Божественный"}
    return egg and info.Rarity or names[info.Rarity]
end
local function rarityColor(info) return Color3.fromRGB(table.unpack(C.RarityColors[info.Rarity])) end
local function text(parent,pos,size,value,font,color)
    local t=Instance.new("TextLabel"); t.Position=pos; t.Size=size; t.Text=value
    t.BackgroundTransparency=1; t.TextColor3=color or Glass.Colors.Text
    t.Font=Enum.Font.GothamBold; t.TextSize=font or 13; t.TextWrapped=true
    t.Parent=parent; TextStyle.Apply(t); return t
end
local function button(parent,pos,size,value)
    local b=Instance.new("TextButton"); b.AnchorPoint=Vector2.new(.5,.5); b.Position=pos
    b.Size=size; b.Text=value; b.Font=Enum.Font.GothamBold; b.TextSize=12; b.TextWrapped=true
    b.TextColor3=Glass.Colors.Text; b.Parent=parent
    Glass.Style(b,Glass.Colors.Mint,10); b.GlassTint:Destroy(); Glass.AnimateButton(b); TextStyle.Apply(b)
    return b
end
function Catalog.View(parent,id,isEgg,interactive)
    local view=Instance.new("ViewportFrame"); view.Name="Picture"; view.BackgroundTransparency=1
    view.Ambient=Color3.fromRGB(230,230,240); view.LightColor=Color3.new(1,1,1); view.Parent=parent
    local world=Instance.new("WorldModel"); world.Parent=view
    local model=Factory.Build(id,isEgg); model.Parent=world
    local camera=Instance.new("Camera"); camera.FieldOfView=40; camera.Parent=view; view.CurrentCamera=camera
    local yaw,pitch=0,.15
    local function rotate()
        camera.CFrame=CFrame.lookAt(Vector3.new(math.sin(yaw)*6,1+pitch*4,-math.cos(yaw)*6),Vector3.new(0,.2,0))
    end
    rotate()
    if interactive then
        view.Active=true
        local drag,last=nil,nil
        local began=view.InputBegan:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then drag=input; last=input.Position end
        end)
        local changed=Input.InputChanged:Connect(function(input)
            if drag and (input==drag or input.UserInputType==Enum.UserInputType.MouseMovement) then
                local delta=input.Position-last; last=input.Position
                yaw-=delta.X*.015; pitch=math.clamp(pitch+delta.Y*.008,-.4,.65); rotate()
            end
        end)
        local ended=Input.InputEnded:Connect(function(input) if input==drag then drag=nil end end)
        view.Destroying:Connect(function() began:Disconnect(); changed:Disconnect(); ended:Disconnect() end)
    end
    return view,model
end
function Catalog.Build(parent)
    local refs={EggCards={},PetCards={},PetButtons={},EggButtons={},PetRemoveButtons={},EditButtons={}}
    local panes,tabs,grids={},{},{}
    local state,width,selected={},parent.Size.X.Offset,nil
    local responsiveScale,transition=1,0
    local phoneLayout=false
    local slideTweens={}
    local centre=UDim2.fromScale(.5,.5)
    local selectedCopies={}; local callbacks={}
    local inspector=Instance.new("Frame"); inspector.Name="Inspector"; inspector.AnchorPoint=Vector2.new(.5,.5)
    inspector.Visible=false; inspector.Parent=parent.Parent; inspector.ZIndex=22; Glass.Style(inspector,Glass.Colors.Violet)
    refs.Inspector=inspector
    local inspectorScale=Instance.new("UIScale"); inspectorScale.Name="ResponsiveScale"; inspectorScale.Parent=inspector
    local title=text(inspector,UDim2.fromOffset(56,12),UDim2.new(1,-112,0,40),"",17,Glass.Colors.Mint)
    title.Name="Title"; title.TextScaled=true
    local titleSize=Instance.new("UITextSizeConstraint"); titleSize.MinTextSize=11; titleSize.MaxTextSize=17; titleSize.Parent=title
    Headings.Style(title,Glass.Colors.Mint)
    local back=button(inspector,UDim2.new(1,-28,0,30),UDim2.fromOffset(36,36),"")
    back.Name="Back"; back.SpecularRim:Destroy()
    local glyph=Instance.new("Frame"); glyph.Name="BackGlyph"; glyph.BackgroundTransparency=1
    glyph.AnchorPoint=Vector2.new(.5,.5); glyph.Position=UDim2.fromScale(.5,.5); glyph.Size=UDim2.fromScale(.75,.75); glyph.Parent=back
    for _,info in {{1,.5,.5,0},{.6,.22,.28,-45},{.6,.22,.72,45}} do
        local line=Instance.new("Frame"); line.AnchorPoint=Vector2.new(.5,.5)
        line.Size=UDim2.new(info[1],0,0,3.5); line.Position=UDim2.fromScale(info[2],info[3]); line.Rotation=info[4]
        line.BackgroundColor3=Glass.Colors.Text; line.BorderSizePixel=0; line.Parent=glyph
        local corner=Instance.new("UICorner"); corner.CornerRadius=UDim.new(1,0); corner.Parent=line
    end
    refs.Back=back
    local description=text(inspector,UDim2.fromOffset(14,240),UDim2.new(1,-28,0,120),"",13)
    local primary=button(inspector,UDim2.new(.5,0,1,-80),UDim2.new(1,-28,0,42),"Экипировать")
    local combine=button(inspector,UDim2.new(.5,0,1,-30),UDim2.new(1,-28,0,42),"Совместить")
    refs.DetailPrimary=primary; refs.DetailCombine=combine; refs.DetailDescription=description
    local detailBody=Instance.new("ScrollingFrame"); detailBody.Name="PhoneBody"
    detailBody.Position=UDim2.fromOffset(0,56); detailBody.Size=UDim2.new(1,0,1,-62)
    detailBody.CanvasSize=UDim2.fromOffset(0,390); detailBody.ScrollingDirection=Enum.ScrollingDirection.Y
    detailBody.ScrollBarThickness=4; detailBody.BackgroundTransparency=1; detailBody.BorderSizePixel=0
    detailBody.Visible=false; detailBody.Parent=inspector
    refs.PetSummary=text(parent,UDim2.fromOffset(20,58),UDim2.new(1,-40,0,28),"Загрузка…",12)
    local phoneBody=Instance.new("ScrollingFrame"); phoneBody.Name="PhoneCatalogBody"
    phoneBody.Position=UDim2.fromOffset(0,56); phoneBody.Size=UDim2.new(1,0,1,-62)
    phoneBody.BackgroundTransparency=1; phoneBody.BorderSizePixel=0; phoneBody.ScrollBarThickness=4
    phoneBody.ScrollingDirection=Enum.ScrollingDirection.Y; phoneBody.AutomaticCanvasSize=Enum.AutomaticSize.Y
    phoneBody.CanvasSize=UDim2.new(); phoneBody.Visible=false; phoneBody.Parent=parent
    for i,info in {{"Eggs","Выбор яйца"},{"Inventory","Питомцы"},{"Paid","Донатные предметы"}} do
        local name=info[1]; tabs[name]=button(parent,UDim2.fromOffset(70+(i-1)*105,109),UDim2.fromOffset(100,38),Headings.Text(name))
        local pane=Instance.new("Frame"); pane.Name=name; pane.BackgroundTransparency=1
        pane.Position=UDim2.fromOffset(20,138); pane.Size=UDim2.new(1,-40,1,-152); pane.Parent=parent; panes[name]=pane
    end
    local function list(pane)
        local scroll=Instance.new("ScrollingFrame"); scroll.Name="Cards"; scroll.Size=UDim2.fromScale(1,1)
        scroll.BackgroundTransparency=1; scroll.BorderSizePixel=0; scroll.ScrollingDirection=Enum.ScrollingDirection.Y
        scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y; scroll.CanvasSize=UDim2.new(); scroll.ScrollBarThickness=4
        scroll.ScrollBarImageColor3=Glass.Colors.Mint; scroll.Parent=pane
        local grid=Instance.new("UIGridLayout"); grid.CellPadding=UDim2.fromOffset(8,8); grid.SortOrder=Enum.SortOrder.LayoutOrder
        grid.Parent=scroll; grids[#grids+1]=grid
        local pad=Instance.new("UIPadding"); pad.PaddingTop=UDim.new(0,4); pad.PaddingBottom=UDim.new(0,8); pad.PaddingLeft=UDim.new(0,4); pad.Parent=scroll
        return scroll
    end
    refs.EggList=list(panes.Eggs); refs.PetList=list(panes.Inventory); refs.PaidList=list(panes.Paid)
    refs.EquipBest=button(panes.Inventory,UDim2.new(.5,0,0,20),UDim2.new(1,-16,0,38),"Экипировать лучшее")
    refs.PetList.Position=UDim2.fromOffset(0,48); refs.PetList.Size=UDim2.new(1,0,1,-48)
    text(panes.Paid,UDim2.fromOffset(4,0),UDim2.new(1,-8,0,44),"Донатные предметы — скоро",13,Glass.Colors.Muted)
    refs.PaidList.Position=UDim2.fromOffset(0,48); refs.PaidList.Size=UDim2.new(1,0,1,-48)
    local function phoneLists()
        for _,scroll in {refs.EggList,refs.PetList,refs.PaidList} do
            scroll.ScrollingEnabled=not phoneLayout
            if phoneLayout then
                local content=scroll:FindFirstChildOfClass("UIGridLayout").AbsoluteContentSize.Y+12
                scroll.Size=UDim2.new(1,0,0,content)
                scroll.Parent.Size=UDim2.new(1,-40,0,content+scroll.Position.Y.Offset)
            else
                scroll.Size=UDim2.new(1,0,1,-scroll.Position.Y.Offset)
            end
        end
    end
    for _,grid in grids do grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(phoneLists) end
    local function card(scroll,index,placeholder)
        local f=Instance.new("Frame"); f.Name=placeholder and "Placeholder"..index or "Card"..index
        f.LayoutOrder=index; f.Parent=scroll; Glass.Style(f,Glass.Colors.Mint,12)
        if placeholder then f:SetAttribute("Placeholder",true); f.BackgroundTransparency=.55 end
        return f
    end
    local function placeholders(scroll)
        for i=1,15 do card(scroll,1000+i,true) end
    end
    local function emit(action,id,copies) if callbacks.Action then callbacks.Action(action,id,copies) end end
    local function selectedCount() local count=0; for _ in pairs(selectedCopies) do count+=1 end; return count end
    local function craft()
        if selectedCount()~=3 then return end
        local copies={}
        for key in pairs(selectedCopies) do table.insert(copies,tonumber(key:match(":(%d+)$"))) end
        table.sort(copies); emit("PetCraft",refs.CraftId,copies)
    end
    refs.ConfirmCraft=craft
    refs.SelectedCopiesCount=selectedCount
    local function layout(animated,closing)
        for _,t in slideTweens do t:Cancel() end; slideTweens={}
        local split=selected~=nil; local mobile=width<560
        local detailWidth=math.clamp(math.floor(width*.36),200,300); if mobile then detailWidth=width end
        local mainWidth=split and not mobile and width-detailWidth-12 or width
        local h=parent.Size.Y.Offset
        local mainPos=split and not mobile and centre-UDim2.fromOffset((detailWidth+12)*responsiveScale/2,0) or centre
        local detailPos=mobile and centre or centre+UDim2.fromOffset((mainWidth+12)*responsiveScale/2,0)
        local foldedPos=centre+UDim2.fromOffset(width*responsiveScale/2,0)
        inspector.ClipsDescendants=true
        if animated then
            local timing=TweenInfo.new(.2,Enum.EasingStyle.Quart,Enum.EasingDirection.Out)
            local mainTween=Tween:Create(parent,timing,{Size=UDim2.fromOffset(mainWidth,h),Position=mainPos})
            if not closing and not inspector.Visible then inspector.Size=UDim2.fromOffset(0,h); inspector.Position=foldedPos end
            local sideTween=Tween:Create(inspector,timing,{Position=closing and foldedPos or detailPos,Size=UDim2.fromOffset(closing and 0 or detailWidth,h)})
            slideTweens={mainTween,sideTween}; mainTween:Play(); sideTween:Play()
        else parent.Size=UDim2.fromOffset(mainWidth,h); parent.Position=mainPos; inspector.Position=detailPos end
        if not animated and not closing then inspector.Size=UDim2.fromOffset(detailWidth,h) end
        if not closing then inspector.Visible=split and (not mobile or refs.CraftId==nil) end
        if split and mobile and refs.CraftId==nil then
            refs.HiddenByInspector=true; parent.Visible=false
        elseif refs.HiddenByInspector then refs.HiddenByInspector=nil; parent.Visible=true end
        local columns=phoneLayout and math.min(2,math.max(1,math.floor((mainWidth-42)/156)))
            or math.min(split and 3 or 5,math.max(1,math.floor((mainWidth-42)/85)))
        local cell=math.floor((mainWidth-54-(columns-1)*8)/columns)
        for _,grid in grids do grid.FillDirectionMaxCells=columns; grid.CellSize=UDim2.fromOffset(cell,216) end
        local tabWidth=(mainWidth-56)/3
        phoneBody.Visible=phoneLayout
        for i,name in {"Eggs","Inventory","Paid"} do
            tabs[name].Parent=phoneLayout and phoneBody or parent
            tabs[name].Position=UDim2.fromOffset(20+tabWidth/2+(i-1)*(tabWidth+8),phoneLayout and 56 or 109)
            tabs[name].Size=UDim2.fromOffset(tabWidth,38)
            tabs[name].Text=phoneLayout and name=="Paid" and "Донат" or Headings.Text(name)
            tabs[name].TextSize=phoneLayout and 14 or 12
        end
        for _,pane in panes do
            pane.Parent=phoneLayout and phoneBody or parent
            pane.Position=UDim2.fromOffset(20,phoneLayout and 82 or 138); pane.Size=UDim2.new(1,-40,1,-152)
        end
        refs.PetSummary.Parent=phoneLayout and phoneBody or parent
        refs.PetSummary.Position=UDim2.fromOffset(20,phoneLayout and 0 or 58)
        refs.PetSummary.Size=UDim2.new(1,-40,0,phoneLayout and 34 or 28)
        phoneLists()
        local picture=inspector:FindFirstChild("Picture") or detailBody:FindFirstChild("Picture")
        local viewHeight=math.max(65,math.min(190,h*.34))
        if picture then picture.Position=UDim2.fromOffset(12,60); picture.Size=UDim2.new(1,-24,0,viewHeight) end
        description.Position=UDim2.fromOffset(14,64+viewHeight); description.Size=UDim2.new(1,-28,0,math.max(30,h-viewHeight-182))
        detailBody.Visible=phoneLayout
        for _,obj in {description,primary,combine} do obj.Parent=phoneLayout and detailBody or inspector end
        if phoneLayout then
            if picture then picture.Parent=detailBody; picture.Position=UDim2.fromOffset(12,0); picture.Size=UDim2.new(1,-24,0,110) end
            description.Position=UDim2.fromOffset(14,116); description.Size=UDim2.new(1,-28,0,148)
            primary.Position=UDim2.new(.5,0,0,292); primary.Size=UDim2.new(1,-28,0,44)
            combine.Position=UDim2.new(.5,0,0,348); combine.Size=UDim2.new(1,-28,0,44)
            back.Size=UDim2.fromOffset(44,44)
        else
            if picture then picture.Parent=inspector end
            primary.Position=UDim2.new(.5,0,1,-80); combine.Position=UDim2.new(.5,0,1,-30)
            back.Size=UDim2.fromOffset(36,36)
        end
    end
    local refresh
    function refs.Resize(newWidth,scale,newCentre,isPhone)
        width=newWidth; responsiveScale=scale or 1; centre=newCentre or centre; phoneLayout=isPhone==true
        inspectorScale.Scale=responsiveScale; layout(false)
    end
    function refs.Reset()
        transition+=1
        selected=nil; refs.CraftId=nil; selectedCopies={}; inspector.Visible=false
        layout(false)
    end
    function refs.Return()
        transition+=1; local version=transition
        selected=nil; refs.CraftId=nil; selectedCopies={}
        layout(true,true)
        task.delay(.2,function() if transition==version and selected==nil then inspector.Visible=false end end)
        if refresh then refresh() end
    end
    function refs.Select(name)
        phoneBody.CanvasPosition=Vector2.zero
        if selected then refs.Return() else refs.Reset() end
        for key,pane in pairs(panes) do pane.Visible=key==name; tabs[key].GlassEdge.Transparency=key==name and .1 or .65 end
        refs.Selected=name
    end
    for name,tab in pairs(tabs) do tab.Activated:Connect(function() refs.Select(name); if refresh then refresh() end end) end
    local function detail()
        if not selected then return end
        local info=(selected.Egg and C.Eggs or C.PetTypes)[selected.Id]
        title.Text=Headings.Item(selected.Id)
        local unlocked=not selected.Egg or (state.Level or 0)>=info.MinLevel
        description.Text=not unlocked and "Недоступно: уровень "..info.MinLevel or
            (rarity(info,selected.Egg).."\n"..(selected.Egg and info.Cost.." монет" or ("Сила и монеты x%.2f"):format(1+info.Bonus)).."\n"..info.Description)
        description.TextColor3=rarityColor(info)
        if selected.Egg then primary.Text="Открыть · "..info.Cost.." монет"; primary.Active=unlocked; combine.Visible=false
        else
            local owned=(state.Pets or {})[selected.Id] or 0; local eq=(state.EquippedPets or {})[selected.Id] or 0
            primary.Text=eq>0 and "Снять" or "Экипировать"; primary.Active=owned>0
            combine.Visible=true; combine.Active=not info.Upgraded and owned>=3
            combine.Text=info.Upgraded and "Уже улучшенный" or refs.CraftId and ("Совместить · %d/3"):format(selectedCount()) or "Совместить 3 одинаковых"
        end
    end
    function refs.Inspect(id,isEgg)
        transition+=1
        selected={Id=id,Egg=isEgg}; refs.CraftId=nil; selectedCopies={}
        local old=inspector:FindFirstChild("Picture") or detailBody:FindFirstChild("Picture"); if old then old:Destroy() end
        refs.DetailView=Catalog.View(inspector,id,isEgg,true)
        detail(); layout(true)
    end
    function refs.BeginCraft(id)
        local info=C.PetTypes[id]
        if not info or info.Upgraded or ((state.Pets or {})[id] or 0)<3 then return false end
        if not selected or selected.Id~=id or selected.Egg then refs.Inspect(id,false) end
        refs.CraftId=id; selectedCopies={}; layout(false); refresh(); return true
    end
    function refs.ChooseCopy(id,index)
        if id~=refs.CraftId or not C.PetTypes[id] or C.PetTypes[id].Upgraded or type(index)~="number" or index%1~=0 or index<1 or index>((state.Pets or {})[id] or 0) then return false end
        local key=id..":"..index
        if selectedCopies[key] then selectedCopies[key]=nil elseif selectedCount()<3 then selectedCopies[key]=true else return false end
        refresh(); return true
    end
    back.Activated:Connect(refs.Return)
    primary.Activated:Connect(function()
        if not selected or not primary.Active then return end
        if selected.Egg then emit("Hatch",selected.Id)
        else emit(((state.EquippedPets or {})[selected.Id] or 0)>0 and "PetUnequip" or "PetEquip",selected.Id) end
    end)
    combine.Activated:Connect(function()
        if not selected or selected.Egg or not combine.Active then return end
        if refs.CraftId then craft()
        else refs.BeginCraft(selected.Id) end
    end)
    refs.EquipBest.Activated:Connect(function()
        if refs.CraftId then craft()
        else emit("PetEquipBest") end
    end)
    for index,id in C.EggOrder do
        local info=C.Eggs[id]; local f=card(refs.EggList,index)
        local view=Catalog.View(f,id,true); view.Position=UDim2.fromOffset(6,4); view.Size=UDim2.new(1,-12,0,52)
        text(f,UDim2.fromOffset(6,57),UDim2.new(1,-12,0,30),Headings.Item(id),13,Glass.Colors.Mint)
        local rarity=text(f,UDim2.fromOffset(6,89),UDim2.new(1,-12,0,18),info.Rarity,11,rarityColor(info))
        local locked=text(f,UDim2.fromOffset(6,109),UDim2.new(1,-12,0,24),info.Cost.." монет",12)
        local open=button(f,UDim2.new(.5,0,0,159),UDim2.new(1,-16,0,36),"Открыть")
        local edit=button(f,UDim2.new(.5,0,0,198),UDim2.new(1,-16,0,32),"Редактировать")
        open.Activated:Connect(function() if open.Active then emit("Hatch",id) end end)
        edit.Activated:Connect(function() refs.Inspect(id,true) end)
        refs.EggButtons[id]=open; refs.EggCards[id]={Button=open,Locked=locked,Rarity=rarity}; refs.EditButtons[id]=edit
    end
    placeholders(refs.EggList); placeholders(refs.PaidList)
    local signature
    refresh=function()
        local owned,equipped,totalEq=state.Pets or {},state.EquippedPets or {},0
        local total=0; for _,amount in pairs(owned) do total+=amount end; for _,amount in pairs(equipped) do totalEq+=amount end
        refs.PetSummary.Text=("Получено %d/%d · экипировано %d/3 · x%.2f"):format(total,C.MaxPets,totalEq,state.PetMultiplier or 1)
        refs.EquipBest.Text=refs.CraftId and ("Совместить · выбрано %d/3"):format(selectedCount()) or "Экипировать лучшее"
        for id,item in pairs(refs.EggCards) do
            local unlocked=(state.Level or 0)>=C.Eggs[id].MinLevel
            item.Button.Active=unlocked; item.Button.Text=unlocked and "Открыть" or "Недоступно"
            item.Locked.Text=unlocked and C.Eggs[id].Cost.." монет" or "Недоступно · уровень "..C.Eggs[id].MinLevel
        end
        -- Rebuild only when counts/equipment/craft selections change; preserve scroll on state ticks.
        local parts={refs.CraftId or ""}
        for _,id in C.InventoryOrder do parts[#parts+1]=id..":"..(owned[id] or 0)..":"..(equipped[id] or 0) end
        for key in pairs(selectedCopies) do parts[#parts+1]=key end; table.sort(parts)
        local nextSignature=table.concat(parts,"|")
        if nextSignature~=signature then
            signature=nextSignature
            for _,child in refs.PetList:GetChildren() do if child:IsA("Frame") then child:Destroy() end end
            refs.PetCards={}; refs.PetButtons={}; refs.PetRemoveButtons={}
            local index=0
            for _,id in C.InventoryOrder do
                local info=C.PetTypes[id]; local count=owned[id] or 0
                if not info.Upgraded or count>0 then
                    for copy=1,math.max(1,count) do
                        index+=1; local key=id..":"..copy; local f=card(refs.PetList,index)
                        f:SetAttribute("PetId",id); f:SetAttribute("Copy",copy)
                        local view=Catalog.View(f,id,false); view.Position=UDim2.fromOffset(6,4); view.Size=UDim2.new(1,-12,0,52)
                        text(f,UDim2.fromOffset(6,57),UDim2.new(1,-12,0,30),Headings.Item(id),13,Glass.Colors.Mint)
                        local rarityLabel=text(f,UDim2.fromOffset(6,89),UDim2.new(1,-12,0,16),rarity(info,false),11,rarityColor(info)); rarityLabel.Name="Rarity"
                        text(f,UDim2.fromOffset(6,106),UDim2.new(1,-12,0,18),("x%.2f"):format(1+info.Bonus),13)
                        local eq=copy<=(equipped[id] or 0)
                        text(f,UDim2.fromOffset(6,126),UDim2.new(1,-12,0,16),count==0 and "Не получен" or eq and "Экипирован" or "В инвентаре",10,Glass.Colors.Muted)
                        local allowed=not refs.CraftId or (id==refs.CraftId and not info.Upgraded and copy<=count)
                        local equip=button(f,UDim2.new(.5,0,0,159),UDim2.new(1,-16,0,36),refs.CraftId and (selectedCopies[key] and "Выбран ✓" or "Выбрать") or eq and "Снять" or "Экипировать")
                        equip.Active=count>0 and allowed
                        local edit=button(f,UDim2.new(.5,0,0,198),UDim2.new(1,-16,0,32),"Редактировать"); edit.Active=refs.CraftId==nil
                        equip.Activated:Connect(function()
                            if not equip.Active then return end
                            if refs.CraftId then
                                refs.ChooseCopy(id,copy)
                            else emit(eq and "PetUnequip" or "PetEquip",id) end
                        end)
                        edit.Activated:Connect(function() if edit.Active then refs.Inspect(id,false) end end)
                        if not allowed then
                            local cover=Instance.new("Frame"); cover.Name="CraftUnavailable"; cover.Size=UDim2.fromScale(1,1)
                            cover.BackgroundColor3=Color3.new(0,0,0); cover.BackgroundTransparency=.35; cover.ZIndex=5; cover.Parent=f
                            local corner=Instance.new("UICorner"); corner.CornerRadius=UDim.new(0,12); corner.Parent=cover
                        end
                        refs.PetCards[key]=f; refs.PetButtons[key]=equip; refs.EditButtons[key]=edit
                    end
                end
            end
            placeholders(refs.PetList)
        end
        detail()
    end
    function refs.Update(snapshot)
        state=snapshot
        if refs.CraftId and ((state.Pets or {})[refs.CraftId] or 0)<3 then refs.CraftId=nil; selectedCopies={} end
        refresh()
    end
    function refs.SetCallbacks(newCallbacks) callbacks=newCallbacks end
    function refs.UpdateEggs(level) state.Level=level; refresh() end
    refs.Select("Eggs"); refresh(); refs.Resize(width)
    return refs
end
return Catalog
