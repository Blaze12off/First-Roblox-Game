local UI={}
local TextStyle=require(game.ReplicatedStorage.SimulatorShared.TextStyle)
local Glass=require(script.Parent.Glass)
local PetCatalog=require(script.Parent.PetCatalog)
local Presentation=require(script.Parent.Presentation)
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
    gui.IgnoreGuiInset=true
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
    local multipliers=frame(gui,UDim2.fromOffset(164,64),UDim2.new(1,-12,0,16),Vector2.new(1,0),palette.Mint)
    multipliers.Name="MultiplierCard"
    local multiplierTitle=label(multipliers,UDim2.fromOffset(10,6),UDim2.new(1,-20,0,14),"ОБЩИЙ МНОЖИТЕЛЬ",10,palette.Muted)
    refs.PowerMultiplier=label(multipliers,UDim2.fromOffset(10,24),UDim2.new(1,-20,0,16),"Сила  x1.00",13,palette.Mint)
    refs.CoinMultiplier=label(multipliers,UDim2.fromOffset(10,42),UDim2.new(1,-20,0,16),"Монеты  x1.00",13,palette.Gold)
    local left=Instance.new("Frame"); left.Name="ActionDock"; left.Size=UDim2.fromOffset(152,186)
    left.Position=UDim2.new(0,16,0.5,0); left.AnchorPoint=Vector2.new(0,0.5); left.BackgroundTransparency=1; left.Parent=gui
    refs.Shop=button(left,UDim2.fromOffset(0,0),UDim2.fromOffset(152,54),"Магазин",palette.Blue)
    refs.Gifts=button(left,UDim2.fromOffset(0,66),UDim2.fromOffset(152,54),"Награды",palette.Gold)
    refs.Pets=button(left,UDim2.fromOffset(0,132),UDim2.fromOffset(152,54),"Яйца и питомцы",palette.Mint)
    for _,info in {{refs.Shop,"Shop",palette.Blue},{refs.Gifts,"Gifts",palette.Gold},{refs.Pets,"Pets",palette.Mint}} do
        info[1].AnchorPoint=Vector2.new(.5,.5)
        info[1].Position+=UDim2.fromOffset(76,27)
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
    refs.InteractCaption=label(refs.Train,UDim2.fromOffset(50,0),UDim2.new(1,-58,1,0),"Тренироваться · E",16)
    refs.Train.Visible=false
    refs.Hint=label(gui,UDim2.new(0.5,-210,1,-120),UDim2.fromOffset(420,34),"Подойди к зелёной платформе и нажми E.",13,palette.Muted)
    refs.Notice=label(gui,UDim2.new(0.5,-190,1,-166),UDim2.fromOffset(380,38),"",15,palette.Gold)
    Glass.Style(refs.Notice,palette.Gold,13)
    refs.Notice.GlassTint:Destroy()
    refs.Notice.Visible=false
    refs.Notice.ZIndex=60 -- Server validation feedback must remain readable above opened menus.
    Glass.Appear(power); Glass.Appear(coins,.06)
    local shade=frame(gui,UDim2.fromScale(1,1),UDim2.fromScale(0,0))
    shade.Name="MenuShade"; shade.BackgroundTransparency=1; shade.Active=true
    for _,child in shade:GetChildren() do child:Destroy() end
    shade.Visible=false; shade.ZIndex=20
    local blur=Instance.new("BlurEffect"); blur.Name="SimulatorMenuBlur"; blur.Size=0; blur.Parent=game:GetService("Lighting")
    local blurTween
    local function focusMenus(open)
        if blurTween then blurTween:Cancel() end
        blurTween=TweenService:Create(blur,TweenInfo.new(.2),{Size=open and 20 or 0}); blurTween:Play()
        for _,item in {power,coins,multipliers,left,refs.Rebirth} do item.Visible=not open end
        refs.Hint.Visible=false; refs.Notice.Visible=false; refs.Train.Visible=false
    end
    refs.Gui.Destroying:Connect(function() blur:Destroy() end)
    local menus,menuScales={},{}
    local function menu(name,title,height,width)
        width=width or 350
        local f=frame(shade,UDim2.fromOffset(width,height),UDim2.fromScale(0.5,0.5),Vector2.new(0.5,0.5))
        f.Name=name; f.Visible=false; f.ZIndex=21
        f.BackgroundTransparency=0.08
        local s=Instance.new("UIScale"); s.Parent=f; menuScales[#menuScales+1]={scale=s,height=height,frame=f}
        label(f,UDim2.fromOffset(20,16),UDim2.new(1,-84,0,34),title,22)
        local close=button(f,UDim2.new(1,-50,0,14),UDim2.fromOffset(36,36),"×",Color3.fromRGB(65,75,95))
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
        if refs.Catalog then refs.Catalog.Reset() end
        for _,m in pairs(menus) do m.Visible=false end
        shade.Visible=false; refs.ActiveMenu=nil; focusMenus(false)
    end
    function refs.Open(name)
        refs.Close(); menus[name].Visible=true; shade.Visible=true
        refs.ActiveMenu=name; focusMenus(true)
        local m=menus[name]; m.Position=UDim2.new(.5,0,.5,12)
        TweenService:Create(m,TweenInfo.new(.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=UDim2.fromScale(.5,.5)}):Play()
    end
    local shop=menu("Shop","МАГАЗИН",272)
    label(shop,UDim2.fromOffset(20,64),UDim2.fromOffset(310,42),"Улучшения усиливают тренировку.\nУровень 3 открывает новую станцию.",15)
    refs.Upgrade=button(shop,UDim2.fromOffset(20,122),UDim2.fromOffset(310,48),"Улучшение: 25 монет")
    refs.Cosmetic=button(shop,UDim2.fromOffset(20,184),UDim2.fromOffset(310,62),"Косметика: за Rebirth",Color3.fromRGB(84,95,131))
    local pets=menu("Pets","ЯЙЦА И ПИТОМЦЫ",580,920)
    refs.Catalog=PetCatalog.Build(pets)
    refs.Animation=Presentation.Build(layout)
    function refs.PlayResult(result,onDone)
        focusMenus(true)
        refs.Animation.Play(result,function()
            focusMenus(refs.ActiveMenu~=nil)
            if onDone then onDone() end
        end)
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
        local inset=game:GetService("GuiService"):GetGuiInset()
        local top=inset.Y+12
        coins.AnchorPoint=Vector2.new(1,0)
        coins.Position=UDim2.new(1,-12,0,top+(compact and 48 or 64)+10)
        local statWidth=small and math.min(164,(v.X-36)/2) or 180
        multipliers.Position=UDim2.new(1,-12,0,top)
        multipliers.Size=UDim2.fromOffset(small and statWidth or 164,compact and 48 or 64)
        multiplierTitle.Position=UDim2.fromOffset(10,compact and 3 or 6)
        refs.PowerMultiplier.Position=UDim2.fromOffset(10,compact and 17 or 24)
        refs.CoinMultiplier.Position=UDim2.fromOffset(10,compact and 31 or 42)
        refs.PowerMultiplier.TextSize=small and 12 or 13; refs.CoinMultiplier.TextSize=small and 12 or 13
        power.Position=UDim2.fromOffset(12,top)
        power.Size=UDim2.fromOffset(statWidth,compact and 72 or 88); coins.Size=UDim2.fromOffset(small and statWidth or 164,compact and 40 or 64)
        refs.Power.Size=UDim2.new(1,-66,0,33); refs.Coins.Size=UDim2.new(1,-66,0,32)
        powerTitle.Size=UDim2.new(1,-66,0,17); coinTitle.Size=UDim2.new(1,-66,0,16)
        refs.Level.Size=UDim2.new(1,-28,0,17)
        refs.Level.Position=UDim2.fromOffset(14,compact and 53 or 65)
        coinTitle.Position=UDim2.fromOffset(46,compact and 3 or 9)
        refs.Coins.Position=UDim2.fromOffset(46,compact and 16 or 26); refs.Coins.Size=UDim2.new(1,-58,0,compact and 22 or 32)
        coins.Icon.Position=UDim2.fromOffset(10,compact and 8 or 16); coins.Icon.Size=UDim2.fromOffset(24,24)
        local actionWidth=small and 138 or 152
        local dockHeight=v.Y<460 and 44 or 54
        local dockGap=v.Y<460 and 6 or 12
        left.Size=UDim2.fromOffset(actionWidth,3*dockHeight+2*dockGap)
        for index,b in {refs.Shop,refs.Gifts,refs.Pets} do
            b.Size=UDim2.fromOffset(actionWidth,dockHeight)
            b.Position=UDim2.fromOffset(actionWidth/2,(index-1)*(dockHeight+dockGap)+dockHeight/2)
            b.Caption.Size=UDim2.new(1,-58,0,dockHeight)
            b.Caption.TextSize=small and 14 or 15
            b.Icon.Position=UDim2.fromOffset(12,(dockHeight-32)/2)
        end
        refs.Rebirth.Size=UDim2.fromOffset(small and 148 or 164,88)
        local sideY=v.Y<460 and 136 or 152
        left.Position=UDim2.new(0,12,0,compact and math.max(sideY,top+82) or v.Y*.5); left.AnchorPoint=Vector2.new(0,compact and 0 or .5)
        refs.Rebirth.Position=UDim2.new(1,-12,0,compact and top+108 or math.max(v.Y*.5,top+182)); refs.Rebirth.AnchorPoint=Vector2.new(1,compact and 0 or .5)
        if v.Y<460 then refs.Rebirth.Size=UDim2.fromOffset(small and 148 or 164,60); refs.RebirthStats.Position=UDim2.fromOffset(12,33) else refs.RebirthStats.Position=UDim2.fromOffset(12,48) end
        -- Centre the animated button; half its height preserves the existing bottom inset.
        refs.Train.Position=UDim2.new(.5,0,1,compact and -65 or -49)
        refs.Train.Size=UDim2.fromOffset(v.Y<460 and math.max(120,math.min(260,v.X-324)) or math.min(260,v.X-32),54)
        -- Short landscape screens reserve the side-button lanes for touch input.
        local width=math.min(420,v.X-32)
        if v.Y<460 and v.X>=560 then width=math.min(width,v.X-360) end
        refs.Hint.Size=UDim2.fromOffset(width,34); refs.Hint.Position=UDim2.new(0.5,-width/2,1,compact and -136 or -120)
        refs.Notice.Size=UDim2.fromOffset(math.min(380,width),38); refs.Notice.Position=UDim2.new(0.5,-math.min(380,width)/2,1,compact and -182 or -166)
        for _,entry in menuScales do
            if entry.frame.Name=="Pets" then
                local width=math.min(920,math.max(240,v.X-24))
                entry.frame.Size=UDim2.fromOffset(width,math.min(580,math.max(230,v.Y-90)))
                entry.scale.Scale=math.min(1,(v.Y-90)/entry.frame.Size.Y.Offset)
                refs.Catalog.Resize(width)
            else
                entry.scale.Scale=math.min(1,(v.X-24)/350,(v.Y-90)/entry.height)
            end
        end
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
