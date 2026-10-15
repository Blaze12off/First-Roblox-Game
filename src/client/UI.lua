local UI={}
local TextStyle=require(game.ReplicatedStorage.SimulatorShared.TextStyle)
local Glass=require(script.Parent.Glass)
local PetCatalog=require(script.Parent.PetCatalog)
local Presentation=require(script.Parent.Presentation)
local Headings=require(script.Parent.Headings)
local Settings=require(script.Parent.Settings)
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
    layout.BackgroundTransparency=1; layout.Parent=gui; refs.Layout=layout
    local hud=Instance.new("Frame"); hud.Name="HudContent"; hud.BackgroundTransparency=1; hud.ZIndex=30; hud.Parent=layout
    local hudScale=Instance.new("UIScale"); hudScale.Name="ResponsiveScale"; hudScale.Parent=hud
    refs.HudContent=hud; gui=hud
    -- Independent edge anchors keep the world clear. Only opened menus cover the centre.
    local power=frame(gui,UDim2.fromOffset(180,88),UDim2.fromOffset(16,16),nil,palette.Mint); power.Name="PowerCard"
    Glass.Icon(power,"Power",palette.Mint,UDim2.fromOffset(12,14),32)
    local powerTitle=label(power,UDim2.fromOffset(54,12),UDim2.fromOffset(114,17),Headings.Text("Power"),14,palette.Mint)
    powerTitle.TextXAlignment=Enum.TextXAlignment.Left; Headings.Style(powerTitle,palette.Mint)
    refs.Power=label(power,UDim2.fromOffset(54,29),UDim2.fromOffset(114,33),"0",24)
    refs.Power.TextXAlignment=Enum.TextXAlignment.Left
    refs.Power.TextScaled=false; refs.Power.TextTruncate=Enum.TextTruncate.AtEnd
    local powerFont=Instance.new("UITextSizeConstraint"); powerFont.MinTextSize=12; powerFont.MaxTextSize=29; powerFont.Parent=refs.Power
    refs.Level=label(power,UDim2.fromOffset(14,65),UDim2.fromOffset(152,17),"Уровень 0",12,palette.Muted)
    refs.Level.TextXAlignment=Enum.TextXAlignment.Left
    local coins=frame(gui,UDim2.fromOffset(164,76),UDim2.new(0.5,0,0,16),Vector2.new(0.5,0),palette.Gold); coins.Name="CoinsCard"
    Glass.Icon(coins,"Coins",palette.Gold,UDim2.fromOffset(12,16),32)
    local coinTitle=label(coins,UDim2.fromOffset(54,12),UDim2.fromOffset(106,16),Headings.Text("Coins"),14,palette.Gold)
    coinTitle.TextXAlignment=Enum.TextXAlignment.Left; Headings.Style(coinTitle,palette.Gold)
    refs.Coins=label(coins,UDim2.fromOffset(54,29),UDim2.fromOffset(106,33),"0",24)
    refs.Coins.TextXAlignment=Enum.TextXAlignment.Left
    refs.Coins.TextScaled=false; refs.Coins.TextTruncate=Enum.TextTruncate.AtEnd
    local coinFont=Instance.new("UITextSizeConstraint"); coinFont.MinTextSize=12; coinFont.MaxTextSize=28; coinFont.Parent=refs.Coins
    local multipliers=frame(gui,UDim2.fromOffset(164,64),UDim2.new(1,-12,0,16),Vector2.new(1,0),palette.Mint)
    multipliers.Name="MultiplierCard"
    local multiplierTitle=label(multipliers,UDim2.fromOffset(8,4),UDim2.new(1,-16,0,18),Headings.Text("Total"),12,palette.Muted)
    Headings.Style(multiplierTitle,palette.Mint)
    refs.PowerMultiplier=label(multipliers,UDim2.fromOffset(10,24),UDim2.new(1,-20,0,16),"Сила  x1.00",13,palette.Mint)
    refs.CoinMultiplier=label(multipliers,UDim2.fromOffset(10,42),UDim2.new(1,-20,0,16),"Монеты  x1.00",13,palette.Gold)
    local left=Instance.new("Frame"); left.Name="ActionDock"; left.Size=UDim2.fromOffset(152,186)
    left.Position=UDim2.new(0,16,0.5,0); left.AnchorPoint=Vector2.new(0,0.5); left.BackgroundTransparency=1; left.Parent=gui
    refs.Shop=button(left,UDim2.fromOffset(0,0),UDim2.fromOffset(152,54),Headings.Text("Shop"),palette.Blue)
    refs.Gifts=button(left,UDim2.fromOffset(0,66),UDim2.fromOffset(152,54),Headings.Text("Gifts"),palette.Gold)
    refs.Pets=button(left,UDim2.fromOffset(0,132),UDim2.fromOffset(152,54),Headings.Text("Pets"),palette.Mint)
    for _,info in {{refs.Shop,"Shop",palette.Blue},{refs.Gifts,"Gifts",palette.Gold},{refs.Pets,"Pets",palette.Mint}} do
        info[1].AnchorPoint=Vector2.new(.5,.5)
        info[1].Position+=UDim2.fromOffset(76,27)
        local caption=info[1].Text; info[1].Text=""
        Glass.Icon(info[1],info[2],info[3]); local captionLabel=label(info[1],UDim2.fromOffset(50,0),UDim2.new(1,-58,0,54),caption,15)
        captionLabel.Name="Caption"; captionLabel.Font=Enum.Font.GothamBlack
    end
    refs.Rebirth=button(gui,UDim2.new(1,-16,0.5,0),UDim2.fromOffset(164,88),"",palette.Violet)
    refs.Rebirth.AnchorPoint=Vector2.new(1,0.5)
    Glass.Icon(refs.Rebirth,"Rebirth",palette.Violet,UDim2.fromOffset(12,12),30)
    Headings.Style(label(refs.Rebirth,UDim2.fromOffset(44,8),UDim2.new(1,-50,0,34),Headings.Text("Rebirth"),14,palette.Violet),palette.Violet)
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
    refs.Notice.Parent=layout
    local noticeScale=Instance.new("UIScale"); noticeScale.Name="ResponsiveScale"; noticeScale.Parent=refs.Notice
    refs.Notice.ZIndex=60 -- Server validation feedback must remain readable above opened menus.
    Glass.Appear(power); Glass.Appear(coins,.06)
    local shade=frame(layout,UDim2.fromScale(1,1),UDim2.fromScale(0,0))
    shade.Name="MenuShade"; shade.BackgroundTransparency=1; shade.Active=true
    for _,child in shade:GetChildren() do child:Destroy() end
    shade.Visible=false; shade.ZIndex=20
    local blur=Instance.new("BlurEffect"); blur.Name="SimulatorMenuBlur"; blur.Size=0; blur.Parent=game:GetService("Lighting")
    refs.MenuBlur=blur
    local blurTween
    local function focusMenus(open,animateBlur)
        if animateBlur~=false then
            if blurTween then blurTween:Cancel() end
            blurTween=TweenService:Create(blur,TweenInfo.new(.2),{Size=open and 20 or 0}); blurTween:Play()
        end
        -- ScreenGui stays sharp above the menu shade; world blur never hides navigation.
        for _,info in {{power,"Power"},{coins,"Coins"},{multipliers,"Multiplier"},{refs.Rebirth,"Rebirth"}} do info[1].Visible=not refs.ShouldShow or refs.ShouldShow(info[2]) end
        left.Visible=true
    end
    refs.Gui.Destroying:Connect(function() blur:Destroy() end)
    local menus,menuScales={},{}
    local function menu(name,title,height,width)
        width=width or 350
        local f=frame(shade,UDim2.fromOffset(width,height),UDim2.fromScale(0.5,0.5),Vector2.new(0.5,0.5))
        f.Name=name; f.Visible=false; f.ZIndex=21
        f.BackgroundTransparency=0.08
        local s=Instance.new("UIScale"); s.Parent=f; menuScales[#menuScales+1]={scale=s,height=height,frame=f}
        local heading=label(f,UDim2.fromOffset(56,16),UDim2.new(1,-112,0,34),Headings.Text(name),22)
        heading.Name="Title"; heading.TextScaled=true
        local headingSize=Instance.new("UITextSizeConstraint"); headingSize.MinTextSize=12; headingSize.MaxTextSize=22; headingSize.Parent=heading
        Headings.Style(heading,palette.Text)
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
        if refs.Animation and refs.Animation.Busy then return end
        refs.Close(); menus[name].Visible=true; shade.Visible=true
        refs.ActiveMenu=name; focusMenus(true)
        local m=menus[name]
        if name~="Pets" then
            local target=refs.MenuCentre or UDim2.fromScale(.5,.5)
            m.Position=target+UDim2.fromOffset(0,12)
            TweenService:Create(m,TweenInfo.new(.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=target}):Play()
        end
    end
    local shop=menu("Shop","МАГАЗИН",272)
    label(shop,UDim2.fromOffset(20,64),UDim2.fromOffset(310,42),"Улучшения усиливают тренировку.\nУровень 3 открывает новую станцию.",15)
    refs.Upgrade=button(shop,UDim2.fromOffset(20,122),UDim2.fromOffset(310,48),"Улучшение: 25 монет")
    refs.Cosmetic=button(shop,UDim2.fromOffset(20,184),UDim2.fromOffset(310,62),"Косметика: за Rebirth",Color3.fromRGB(84,95,131))
    local pets=menu("Pets","ЯЙЦА И ПИТОМЦЫ",580,920)
    refs.Catalog=PetCatalog.Build(pets)
    refs.Animation=Presentation.Build(layout)
    function refs.PlayResult(result,onDone)
        if refs.Animation.Busy then return false end
        focusMenus(true,result.Action~="Rebirth")
        return refs.Animation.Play(result,function()
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
    refs.Settings=Settings.Build(refs,menu("Settings","НАСТРОЙКИ",460))
    -- Fixed-height desktop bodies become scrollable when a phone has less vertical room.
    for _,entry in menuScales do
        if entry.frame.Name~="Pets" and entry.frame.Name~="Settings" then
            local body=Instance.new("ScrollingFrame"); body.Name="Body"; body.BackgroundTransparency=1
            body.BorderSizePixel=0; body.Position=UDim2.fromOffset(0,56); body.Size=UDim2.new(1,0,1,-62)
            body.CanvasSize=UDim2.fromOffset(0,entry.height-62); body.ScrollBarThickness=4
            body.ScrollingDirection=Enum.ScrollingDirection.Y
            for _,child in entry.frame:GetChildren() do
                if child:IsA("GuiObject") and child.Name~="Title" and child.Name~="Close" then
                    child.Position-=UDim2.fromOffset(0,56)
                    child.Size=UDim2.new(1,-40,child.Size.Y.Scale,child.Size.Y.Offset)
                    if child:IsA("TextButton") then child.Position=UDim2.new(.5,0,child.Position.Y.Scale,child.Position.Y.Offset) end
                    child.Parent=body
                end
            end
            body.Parent=entry.frame
        end
    end
    local originalFonts=setmetatable({},{__mode="k"})
    local function phoneText(obj)
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            originalFonts[obj]=originalFonts[obj] or obj.TextSize
            obj.TextSize=refs.PhoneLayout and math.max(16,originalFonts[obj]) or originalFonts[obj]
        end
    end
    refs.Gui.DescendantAdded:Connect(phoneText)
    local cameraConnection
    local function resize()
        local camera=workspace.CurrentCamera; if not camera then return end
        local v=refs.Layout.AbsoluteSize; if v.X<1 then v=camera.ViewportSize end
        local phone=(game:GetService("UserInputService").TouchEnabled and math.min(v.X,v.Y)<=600)
            or refs.Layout:GetAttribute("PhonePreview")==true
        refs.PhoneLayout=phone
        -- 980x620 reference canvas reproduces the proportions approved in the screenshot.
        local scale=phone and math.min(.8,v.X/390) or math.min(v.X/980,v.Y/620)
        local logical=Vector2.new(v.X/scale,v.Y/scale)
        hudScale.Scale=scale; hud.Size=UDim2.fromOffset(logical.X,logical.Y)
        refs.ResponsiveScale=scale
        local inset=game:GetService("GuiService"):GetGuiInset()
        local top=math.max(72,inset.Y/scale+12)
        power.Position=UDim2.fromOffset(14,top)
        coins.AnchorPoint=Vector2.new(1,0); coins.Position=UDim2.new(1,-12,0,top+74)
        multipliers.Position=UDim2.new(1,-12,0,top)
        left.Position=UDim2.new(0,14,.5,0); left.AnchorPoint=Vector2.new(0,.5)
        refs.Rebirth.Position=UDim2.new(1,-12,0,math.max(logical.Y*.5,top+74+76+12+44)); refs.Rebirth.AnchorPoint=Vector2.new(1,.5)
        refs.Train.Position=UDim2.new(.5,0,1,-49)
        refs.Notice.Position=UDim2.new(.5,-190*scale,1,-166*scale); noticeScale.Scale=scale
        -- Restore the base geometry before applying either orientation (rotation is live).
        refs.Rebirth.Size=UDim2.fromOffset(164,88)
        refs.RebirthStats.Position=UDim2.fromOffset(12,48); refs.RebirthStats.Size=UDim2.new(1,-24,0,27)
        left.Size=UDim2.fromOffset(152,186)
        for i,b in {refs.Shop,refs.Gifts,refs.Pets} do
            b.Position=UDim2.fromOffset(76,27+(i-1)*66); b.Size=UDim2.fromOffset(152,54)
            local icon=b:FindFirstChild("Icon"); if icon then icon.Visible=true end
            b.Caption.Position=UDim2.fromOffset(50,0); b.Caption.Size=UDim2.new(1,-58,0,54)
        end
        local portrait=phone and v.Y>v.X
        local menuScale,menuTop,menuBottom,menuWidth=scale,0,v.Y,350
        refs.MenuCentre=nil
        -- Keep phone text near its intended size instead of shrinking a 980px canvas.
        if phone then
            local edge=math.max(12,inset.X)
            top=math.max(62,inset.Y+8)/scale
            power.Position=UDim2.fromOffset(edge/scale,top)
            coins.Position=UDim2.new(1,-edge/scale,0,top); coins.Size=UDim2.fromOffset(164,88)
            if portrait then
                multipliers.Position=UDim2.new(1,-edge/scale,0,top+98)
                refs.Rebirth.Position=UDim2.new(0,edge/scale,0,top+98)
                refs.Rebirth.AnchorPoint=Vector2.zero
                refs.Rebirth.Size=UDim2.fromOffset(180,64)
                refs.RebirthStats.Position=UDim2.fromOffset(12,34); refs.RebirthStats.Size=UDim2.new(1,-24,0,26)
                left.AnchorPoint=Vector2.new(.5,1); left.Position=UDim2.new(.5,0,1,-18)
                local bw=(logical.X-32)/3
                left.Size=UDim2.fromOffset(logical.X-24,54)
                for i,b in {refs.Shop,refs.Gifts,refs.Pets} do
                    b.Position=UDim2.fromOffset((i-.5)*bw,27); b.Size=UDim2.fromOffset(bw-6,54)
                    local icon=b:FindFirstChild("Icon"); if icon then icon.Visible=false end
                    b.Caption.Position=UDim2.fromOffset(4,0); b.Caption.Size=UDim2.new(1,-8,1,0)
                end
                refs.Train.Position=UDim2.new(.5,0,1,-114)
                refs.Hint.Position=UDim2.new(.5,-logical.X/2+12,1,-183); refs.Hint.Size=UDim2.fromOffset(logical.X-24,40)
                menuTop=(top+174)*scale; menuBottom=v.Y-190*scale
                menuWidth=math.min(350,(v.X-2*edge)/.9)
            else
                refs.Rebirth.Position=UDim2.new(1,-edge/scale,1,-12); refs.Rebirth.AnchorPoint=Vector2.new(1,1)
                multipliers.Position=UDim2.new(1,-edge/scale,0,top+98)
                left.Position=UDim2.new(0,edge/scale,1,-12); left.AnchorPoint=Vector2.new(0,1)
                menuTop=math.max(54,inset.Y+4); menuBottom=v.Y-104*scale
                menuWidth=math.min(600,(v.X-360*scale-32)/.9)
                refs.Hint.Size=UDim2.fromOffset(math.min(420,logical.X-360),34)
                refs.Hint.Position=UDim2.new(.5,-refs.Hint.Size.X.Offset/2,1,-100)
                refs.Train.Position=UDim2.new(.5,0,1,-38)
            end
            menuScale=math.min(.95,(v.X-2*edge)/350)
            if not portrait then menuWidth=math.min(600,(v.X-2*(180*scale+edge+8))/menuScale) end
            refs.MenuCentre=UDim2.fromOffset(v.X/2,(menuTop+menuBottom)/2)
            refs.Notice.Position=UDim2.new(.5,-190*scale,0,menuTop); noticeScale.Scale=scale
        else
            coins.Size=UDim2.fromOffset(164,76)
            refs.Hint.Size=UDim2.fromOffset(420,34); refs.Hint.Position=UDim2.new(.5,-210,1,-120)
        end
        for _,obj in refs.Gui:GetDescendants() do phoneText(obj) end
        multiplierTitle.TextSize=phone and 13 or 12
        for _,entry in menuScales do
            entry.scale.Scale=phone and menuScale or scale
            local close=entry.frame:FindFirstChild("Close")
            if close then close.Size=UDim2.fromOffset(phone and 44 or 36,phone and 44 or 36) end
            if phone then
                entry.frame.Size=UDim2.fromOffset(math.min(350,menuWidth),math.min(entry.height,(menuBottom-menuTop)/menuScale))
                entry.frame.Position=refs.MenuCentre
            else
                entry.frame.Size=UDim2.fromOffset(entry.frame.Name=="Pets" and 920 or 350,entry.height)
                entry.frame.Position=UDim2.fromScale(.5,.5)
            end
            if entry.frame.Name=="Settings" then refs.Settings.Resize(entry.frame.Size.X.Offset) end
            if entry.frame.Name=="Pets" then
                -- Reserve the HUD columns and the lower hint/interaction strip.
                local width=phone and menuWidth or math.min(920,logical.X-394)
                local safeTop=math.max(24,inset.Y/scale+12)
                entry.frame.Size=UDim2.fromOffset(width,phone and (menuBottom-menuTop)/menuScale or math.min(580,logical.Y-156-safeTop))
                refs.Catalog.Resize(width,phone and menuScale or scale,refs.MenuCentre or UDim2.new(.5,9*scale,.5,(safeTop-156)*scale/2),phone)
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
    refs.Layout:GetAttributeChangedSignal("PhonePreview"):Connect(resize)
    refs.Shop.Activated:Connect(function() refs.Open("Shop") end)
    refs.Gifts.Activated:Connect(function() refs.Open("Gifts") end)
    refs.Rebirth.Activated:Connect(function() refs.Open("Rebirth") end)
    for name,value in pairs(refs) do
        if typeof(value)=="Instance" and value:IsA("GuiObject") and value~=layout then value.Name=name end
    end
    return refs
end
return UI
