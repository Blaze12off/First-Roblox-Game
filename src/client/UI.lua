local UI={}
local TextStyle=require(game.ReplicatedStorage.SimulatorShared.TextStyle)
local Glass=require(script.Parent.Glass)
local TweenService=game:GetService("TweenService")
local palette=Glass.Colors
local dark=Color3.fromRGB(22,30,48)
local function rounded(instance,radius)
    local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,radius or 12); c.Parent=instance
end
local function frame(parent,size,position,anchor,color)
    local f=Instance.new("Frame"); f.Size=size; f.Position=position; f.AnchorPoint=anchor or Vector2.zero
    f.BackgroundColor3=color or dark; f.BackgroundTransparency=0.1; f.BorderSizePixel=0
    f.Parent=parent; Glass.Style(f,color); return f
end
local function label(parent,position,size,text,fontSize,color)
    local l=Instance.new("TextLabel"); l.Position=position; l.Size=size; l.Text=text
    l.BackgroundTransparency=1; l.TextColor3=color or Color3.fromRGB(236,242,255)
    l.TextSize=fontSize or 17; l.Font=Enum.Font.GothamBold; l.TextWrapped=true; l.Parent=parent
    TextStyle.Apply(l)
    return l
end
local function button(parent,position,size,text,color)
    local b=Instance.new("TextButton"); b.Position=position; b.Size=size; b.Text=text
    if parent.Parent and parent.Parent.Name=="MenuShade" then
        -- Preserve the resting rectangle, but make UIScale expand around its centre.
        b.AnchorPoint=Vector2.new(.5,.5)
        b.Position=UDim2.new(position.X.Scale+size.X.Scale/2,position.X.Offset+size.X.Offset/2,
            position.Y.Scale+size.Y.Scale/2,position.Y.Offset+size.Y.Offset/2)
    end
    b.BackgroundColor3=color or Color3.fromRGB(58,100,163); b.TextColor3=Color3.new(1,1,1)
    b.TextSize=16; b.Font=Enum.Font.GothamBold; b.TextWrapped=true; b.BorderSizePixel=0
    b.Parent=parent; Glass.Style(b,color,16)
    -- Gradients on TextButton also tint its text; retain bright captions and the glass rim.
    b.GlassTint:Destroy()
    TextStyle.Apply(b); Glass.AnimateButton(b); return b
end
function UI.Build(player)
    local gui=Instance.new("ScreenGui"); gui.Name="SimulatorUI"; gui.ResetOnSpawn=false
    gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; gui.Parent=player:WaitForChild("PlayerGui")
    local refs={Gui=gui}
    local layout=Instance.new("Frame"); layout.Name="HudLayout"; layout.Size=UDim2.fromScale(1,1)
    layout.BackgroundTransparency=1; layout.Parent=gui; refs.Layout=layout; gui=layout
    -- Independent edge anchors keep the world clear. Only opened menus cover the centre.
    local power=frame(gui,UDim2.fromOffset(180,88),UDim2.fromOffset(16,16),nil,palette.Mint); power.Name="PowerCard"
    Glass.Icon(power,"Power",palette.Mint,UDim2.fromOffset(12,14),32)
    local powerTitle=label(power,UDim2.fromOffset(54,12),UDim2.fromOffset(114,17),"СИЛА",11,palette.Mint)
    powerTitle.TextXAlignment=Enum.TextXAlignment.Left
    refs.Power=label(power,UDim2.fromOffset(54,29),UDim2.fromOffset(114,33),"0",29)
    refs.Power.TextXAlignment=Enum.TextXAlignment.Left
    refs.Power.TextScaled=true
    local powerFont=Instance.new("UITextSizeConstraint"); powerFont.MinTextSize=12; powerFont.MaxTextSize=29; powerFont.Parent=refs.Power
    refs.Level=label(power,UDim2.fromOffset(14,65),UDim2.fromOffset(152,17),"Уровень 0",12,palette.Muted)
    refs.Level.TextXAlignment=Enum.TextXAlignment.Left
    local coins=frame(gui,UDim2.fromOffset(172,72),UDim2.new(0.5,0,0,16),Vector2.new(0.5,0),palette.Gold); coins.Name="CoinsCard"
    Glass.Icon(coins,"Coins",palette.Gold,UDim2.fromOffset(12,19),32)
    local coinTitle=label(coins,UDim2.fromOffset(54,12),UDim2.fromOffset(106,16),"МОНЕТЫ",11,palette.Gold)
    coinTitle.TextXAlignment=Enum.TextXAlignment.Left
    refs.Coins=label(coins,UDim2.fromOffset(54,29),UDim2.fromOffset(106,32),"0",28)
    refs.Coins.TextXAlignment=Enum.TextXAlignment.Left
    refs.Coins.TextScaled=true
    local coinFont=Instance.new("UITextSizeConstraint"); coinFont.MinTextSize=12; coinFont.MaxTextSize=28; coinFont.Parent=refs.Coins
    refs.Mode=label(gui,UDim2.fromOffset(18,110),UDim2.fromOffset(240,19),"Загрузка данных…",11,palette.Muted)
    refs.Mode.TextXAlignment=Enum.TextXAlignment.Left
    local left=Instance.new("Frame"); left.Name="ActionDock"; left.Size=UDim2.fromOffset(152,120)
    left.Position=UDim2.new(0,16,0.5,0); left.AnchorPoint=Vector2.new(0,0.5); left.BackgroundTransparency=1; left.Parent=gui
    refs.Shop=button(left,UDim2.fromOffset(0,0),UDim2.fromOffset(152,54),"Магазин",palette.Blue)
    refs.Gifts=button(left,UDim2.fromOffset(0,66),UDim2.fromOffset(152,54),"Награды",palette.Gold)
    for _,info in {{refs.Shop,"Shop",palette.Blue},{refs.Gifts,"Gifts",palette.Gold}} do
        local caption=info[1].Text; info[1].Text=""
        Glass.Icon(info[1],info[2],info[3]); local captionLabel=label(info[1],UDim2.fromOffset(50,0),UDim2.new(1,-58,0,54),caption,15)
        captionLabel.Name="Caption"
    end
    refs.Rebirth=button(gui,UDim2.new(1,-16,0.5,0),UDim2.fromOffset(164,88),"",palette.Violet)
    refs.Rebirth.AnchorPoint=Vector2.new(1,0.5)
    Glass.Icon(refs.Rebirth,"Rebirth",palette.Violet,UDim2.fromOffset(12,12),30)
    label(refs.Rebirth,UDim2.fromOffset(48,13),UDim2.new(1,-56,0,27),"Перерождения",12,palette.Violet)
    refs.RebirthStats=label(refs.Rebirth,UDim2.fromOffset(12,48),UDim2.new(1,-24,0,27),"0 • x1.00",21)
    local notifyGifts=Glass.Notification(refs.Gifts,"right")
    local notifyRebirth=Glass.Notification(refs.Rebirth,"left")
    function refs.Notifications(giftsCount,rebirthCount)
        notifyGifts(giftsCount); notifyRebirth(rebirthCount)
    end
    refs.Train=button(gui,UDim2.new(0.5,0,1,-49),UDim2.fromOffset(260,54),"Тренироваться  ·  E",palette.Mint)
    refs.Train.AnchorPoint=Vector2.new(.5,.5)
    Glass.Icon(refs.Train,"Power",palette.Mint,UDim2.fromOffset(12,11),32)
    refs.Train.Text=""
    label(refs.Train,UDim2.fromOffset(50,0),UDim2.fromOffset(198,54),game:GetService("UserInputService").TouchEnabled and "Тренироваться" or "Тренироваться · E",16)
    refs.Train.Visible=false
    refs.Hint=label(gui,UDim2.new(0.5,-210,1,-120),UDim2.fromOffset(420,34),"Подойди к зелёной платформе и нажми E.",13,palette.Muted)
    refs.Notice=label(gui,UDim2.new(0.5,-190,1,-166),UDim2.fromOffset(380,38),"",15,palette.Gold)
    Glass.Style(refs.Notice,palette.Gold,13)
    refs.Notice.GlassTint:Destroy()
    refs.Notice.Visible=false
    Glass.Appear(power); Glass.Appear(coins,.06)
    local shade=frame(gui,UDim2.fromScale(1,1),UDim2.fromScale(0,0))
    shade.Name="MenuShade"; shade.BackgroundColor3=Color3.new(0,0,0); shade.BackgroundTransparency=0.4
    for _,child in shade:GetChildren() do child:Destroy() end
    shade.Visible=false; shade.ZIndex=20
    local menus,menuScales={},{}
    local function menu(name,title,height)
        local f=frame(shade,UDim2.fromOffset(350,height),UDim2.fromScale(0.5,0.5),Vector2.new(0.5,0.5))
        f.Name=name; f.Visible=false; f.ZIndex=21
        f.BackgroundTransparency=0.08
        local s=Instance.new("UIScale"); s.Parent=f; menuScales[#menuScales+1]={scale=s,height=height}
        label(f,UDim2.fromOffset(20,16),UDim2.fromOffset(266,34),title,22)
        local close=button(f,UDim2.fromOffset(300,14),UDim2.fromOffset(36,36),"×",Color3.fromRGB(65,75,95))
        close.Name="Close"; close.Text=""
        close.SpecularRim:Destroy()
        -- Each rounded diagonal is 75% of the button width, with clear inset from the rim.
        local glyph=Instance.new("Frame"); glyph.Name="CloseGlyph"; glyph.BackgroundTransparency=1
        glyph.AnchorPoint=Vector2.new(.5,.5); glyph.Position=UDim2.fromScale(.5,.5)
        glyph.Size=UDim2.fromScale(.75,.75); glyph.Parent=close
        for _,angle in {45,-45} do
            local line=Instance.new("Frame"); line.Name="Stroke"; line.BorderSizePixel=0
            line.AnchorPoint=Vector2.new(.5,.5); line.Position=UDim2.fromScale(.5,.5)
            line.Size=UDim2.new(1,0,0,3.5); line.Rotation=angle
            line.BackgroundColor3=palette.Text; line.Parent=glyph; rounded(line,50)
        end
        close.Activated:Connect(function() refs.Close() end)
        menus[name]=f; return f
    end
    function refs.Close()
        for _,m in pairs(menus) do m.Visible=false end
        shade.Visible=false
    end
    function refs.Open(name)
        refs.Close(); menus[name].Visible=true; shade.Visible=true
        local m=menus[name]; m.Position=UDim2.new(.5,0,.5,12)
        TweenService:Create(m,TweenInfo.new(.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=UDim2.fromScale(.5,.5)}):Play()
    end
    local shop=menu("Shop","МАГАЗИН",338)
    label(shop,UDim2.fromOffset(20,64),UDim2.fromOffset(310,42),"Улучшения усиливают тренировку.\nУровень 3 открывает новую станцию.",15)
    refs.Upgrade=button(shop,UDim2.fromOffset(20,122),UDim2.fromOffset(310,48),"Улучшение: 25 монет")
    refs.Cosmetic=button(shop,UDim2.fromOffset(20,184),UDim2.fromOffset(310,62),"Косметика: за Rebirth",Color3.fromRGB(84,95,131))
    refs.Pets=button(shop,UDim2.fromOffset(20,264),UDim2.fromOffset(310,48),"Яйца и питомцы",palette.Mint)
    local pets=menu("Pets","ЯЙЦА И ПИТОМЦЫ",520)
    local C=require(game.ReplicatedStorage.SimulatorShared.Config)
    refs.PetSummary=label(pets,UDim2.fromOffset(20,58),UDim2.fromOffset(310,34),"Питомцы: 0/50 • бонус x1.00",14)
    refs.EggButtons={}; refs.PetButtons={}
    for index,id in C.EggOrder do
        local egg=C.Eggs[id]
        local y=98+(index-1)*86
        refs.EggButtons[id]=button(pets,UDim2.fromOffset(20,y),UDim2.fromOffset(310,46),egg.Name.." • "..egg.Cost.." монет",Color3.fromRGB(table.unpack(egg.Color)))
        label(pets,UDim2.fromOffset(20,y+48),UDim2.fromOffset(310,30),
            ("Кот %d%% • Пёс %d%% • Кролик %d%%"):format(egg.Weights.Cat,egg.Weights.Dog,egg.Weights.Bunny),12,palette.Muted)
    end
    label(pets,UDim2.fromOffset(20,270),UDim2.fromOffset(310,30),"Инвентарь • экипирован один питомец",14,palette.Mint)
    for index,id in C.PetOrder do
        refs.PetButtons[id]=button(pets,UDim2.fromOffset(20,304+(index-1)*62),UDim2.fromOffset(310,52),C.PetTypes[id].Name,Color3.fromRGB(table.unpack(C.PetTypes[id].Color)))
    end
    refs.Pets.Activated:Connect(function() refs.Open("Pets") end)
    local gifts=menu("Gifts","НАГРАДЫ",250)
    label(gifts,UDim2.fromOffset(20,62),UDim2.fromOffset(310,42),"Бонусы за возвращение.\nПропуск дня не сбрасывает прогресс.",15)
    refs.Daily=button(gifts,UDim2.fromOffset(20,118),UDim2.fromOffset(310,48),"Ежедневная награда")
    refs.Weekly=button(gifts,UDim2.fromOffset(20,180),UDim2.fromOffset(310,48),"Недельная награда")
    local rebirth=menu("Rebirth","ПЕРЕРОЖДЕНИЕ",342)
    refs.Bonus=label(rebirth,UDim2.fromOffset(20,62),UDim2.fromOffset(310,40),"Постоянный бонус: x1.00",16)
    refs.Goal=label(rebirth,UDim2.fromOffset(20,114),UDim2.fromOffset(310,52),"200 силы и 150 монет",18)
    local bar=frame(rebirth,UDim2.fromOffset(310,10),UDim2.fromOffset(20,180))
    bar.BackgroundColor3=Color3.fromRGB(50,62,85)
    refs.Fill=frame(bar,UDim2.fromScale(0,1),UDim2.fromScale(0,0),nil,Color3.fromRGB(105,226,193))
    for _,child in refs.Fill:GetChildren() do child:Destroy() end
    refs.Fill.BackgroundColor3=palette.Mint; refs.Fill.BackgroundTransparency=0; rounded(refs.Fill,5)
    local progressTween,lastProgress
    function refs.Progress(value)
        if value==lastProgress then return end
        lastProgress=value
        if progressTween then progressTween:Cancel() end
        progressTween=TweenService:Create(refs.Fill,TweenInfo.new(.22,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=UDim2.fromScale(value,1)})
        progressTween:Play()
    end
    label(rebirth,UDim2.fromOffset(20,202),UDim2.fromOffset(310,54),"Сбросятся сила, монеты и уровень.\nРекорд, косметика и бонус сохранятся.",15)
    refs.Prepare=button(rebirth,UDim2.fromOffset(20,274),UDim2.fromOffset(310,48),"Переродиться…",Color3.fromRGB(131,82,189))
    local confirmation=menu("Confirm","ПОДТВЕРЖДЕНИЕ",350)
    refs.Dialog=label(confirmation,UDim2.fromOffset(20,62),UDim2.fromOffset(310,148),"",17)
    refs.Confirm=button(confirmation,UDim2.fromOffset(20,226),UDim2.fromOffset(310,48),"Подтвердить",Color3.fromRGB(131,82,189))
    refs.Cancel=button(confirmation,UDim2.fromOffset(20,288),UDim2.fromOffset(310,42),"Отмена",Color3.fromRGB(68,81,105))
    local cameraConnection
    local function resize()
        local camera=workspace.CurrentCamera; if not camera then return end
        local v=refs.Layout.AbsoluteSize; if v.X<1 then v=camera.ViewportSize end
        local small=v.X<640; local compact=small or v.Y<460
        coins.AnchorPoint=small and Vector2.new(1,0) or Vector2.new(0.5,0)
        coins.Position=small and UDim2.new(1,-12,0,16) or UDim2.new(0.5,0,0,16)
        local statWidth=small and math.min(164,(v.X-36)/2) or 180
        power.Size=UDim2.fromOffset(statWidth,88); coins.Size=UDim2.fromOffset(small and statWidth or 172,72)
        refs.Power.Size=UDim2.new(1,-66,0,33); refs.Coins.Size=UDim2.new(1,-66,0,32)
        powerTitle.Size=UDim2.new(1,-66,0,17); coinTitle.Size=UDim2.new(1,-66,0,16)
        refs.Level.Size=UDim2.new(1,-28,0,17)
        local actionWidth=small and 138 or 152
        left.Size=UDim2.fromOffset(actionWidth,120)
        refs.Shop.Size=UDim2.fromOffset(actionWidth,54); refs.Gifts.Size=UDim2.fromOffset(actionWidth,54)
        refs.Shop.Caption.TextSize=small and 14 or 15; refs.Gifts.Caption.TextSize=small and 14 or 15
        refs.Rebirth.Size=UDim2.fromOffset(small and 148 or 164,88)
        local sideY=v.Y<460 and 136 or 152
        left.Position=UDim2.new(0,12,0,compact and sideY or v.Y*.5); left.AnchorPoint=Vector2.new(0,compact and 0 or .5)
        refs.Rebirth.Position=UDim2.new(1,-12,0,compact and sideY or v.Y*.5); refs.Rebirth.AnchorPoint=Vector2.new(1,compact and 0 or .5)
        -- Centre the animated button; half its height preserves the existing bottom inset.
        refs.Train.Position=UDim2.new(.5,0,1,compact and -65 or -49)
        -- Short landscape screens reserve the side-button lanes for touch input.
        local width=math.min(420,v.X-32)
        if v.Y<460 and v.X>=560 then width=math.min(width,v.X-360) end
        refs.Hint.Size=UDim2.fromOffset(width,34); refs.Hint.Position=UDim2.new(0.5,-width/2,1,compact and -136 or -120)
        refs.Notice.Size=UDim2.fromOffset(math.min(380,width),38); refs.Notice.Position=UDim2.new(0.5,-math.min(380,width)/2,1,compact and -182 or -166)
        for _,entry in menuScales do entry.scale.Scale=math.min(1,(v.X-24)/350,(v.Y-90)/entry.height) end
    end
    local function bindCamera()
        if cameraConnection then cameraConnection:Disconnect() end
        if workspace.CurrentCamera then cameraConnection=workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
        resize()
    end
    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera); bindCamera()
    refs.Layout:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
    refs.Shop.Activated:Connect(function() refs.Open("Shop") end)
    refs.Gifts.Activated:Connect(function() refs.Open("Gifts") end)
    refs.Rebirth.Activated:Connect(function() refs.Open("Rebirth") end)
    for name,value in pairs(refs) do
        if typeof(value)=="Instance" and value:IsA("GuiObject") and value~=layout then value.Name=name end
    end
    return refs
end
return UI
