local TweenService=game:GetService("TweenService")
local Glass={}
Glass.Colors={Base=Color3.fromRGB(24,37,59),Text=Color3.fromRGB(242,248,255),Muted=Color3.fromRGB(171,193,217),
    Mint=Color3.fromRGB(104,239,202),Gold=Color3.fromRGB(255,212,119),Blue=Color3.fromRGB(114,198,255),Violet=Color3.fromRGB(199,167,255)}
local function corner(p,r)
    local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r); c.Parent=p
end
function Glass.Style(p,accent,radius)
    accent=accent or Glass.Colors.Blue
    p.BackgroundColor3=Glass.Colors.Base; p.BackgroundTransparency=0.23; p.BorderSizePixel=0
    corner(p,radius or 18)
    local stroke=Instance.new("UIStroke"); stroke.Name="GlassEdge"; stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
    stroke.Color=accent:Lerp(Color3.new(1,1,1),0.55); stroke.Transparency=0.55; stroke.Thickness=1; stroke.Parent=p
    local gradient=Instance.new("UIGradient"); gradient.Name="GlassTint"; gradient.Rotation=105
    gradient.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,accent:Lerp(Color3.new(1,1,1),0.4)),
        ColorSequenceKeypoint.new(0.38,Color3.fromRGB(169,193,220)),ColorSequenceKeypoint.new(1,Color3.fromRGB(92,120,157))})
    gradient.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.08),NumberSequenceKeypoint.new(0.42,0.18),NumberSequenceKeypoint.new(1,0)})
    gradient.Parent=p
    local rim=Instance.new("Frame"); rim.Name="SpecularRim"; rim.Position=UDim2.new(0,16,0,1)
    rim.Size=UDim2.new(1,-32,0,1); rim.BackgroundColor3=Color3.new(1,1,1); rim.BackgroundTransparency=0.52
    rim.BorderSizePixel=0; rim.Parent=p
    local shine=Instance.new("UIGradient"); shine.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),
        NumberSequenceKeypoint.new(0.35,0.1),NumberSequenceKeypoint.new(0.65,0.25),NumberSequenceKeypoint.new(1,1)}); shine.Parent=rim
    return stroke
end
function Glass.Icon(parent,kind,accent,position,size)
    local f=Instance.new("Frame"); f.Name="Icon"; f.BackgroundColor3=accent; f.BackgroundTransparency=0.86
    f.Size=UDim2.fromOffset(size or 32,size or 32); f.Position=position or UDim2.fromOffset(12,11); f.BorderSizePixel=0; f.Parent=parent; corner(f,10)
    local function shape(x,y,w,h,round)
        local s=Instance.new("Frame"); s.Position=UDim2.fromScale(x,y); s.Size=UDim2.fromScale(w,h)
        s.BackgroundColor3=accent; s.BorderSizePixel=0; s.Parent=f; if round then corner(s,round) end; return s
    end
    if kind=="Power" then
        shape(.22,.25,.13,.5,3); shape(.65,.25,.13,.5,3); shape(.35,.44,.3,.12,2)
    elseif kind=="Coins" then
        local disc=shape(.23,.23,.54,.54,50); disc.BackgroundTransparency=.1
        local line=shape(.47,.32,.06,.36,2); line.BackgroundColor3=Glass.Colors.Base
    elseif kind=="Shop" then
        shape(.25,.37,.5,.42,3)
        local handle=shape(.37,.2,.26,.27,3); handle.BackgroundTransparency=1
        local st=Instance.new("UIStroke"); st.Color=accent; st.Thickness=2; st.Parent=handle
    elseif kind=="Pets" then
        shape(.25,.34,.5,.43,6)
        local ear1=shape(.25,.22,.19,.22,2); ear1.Rotation=-20
        local ear2=shape(.56,.22,.19,.22,2); ear2.Rotation=20
        local eye1=shape(.36,.49,.06,.08,2); eye1.BackgroundColor3=Glass.Colors.Base
        local eye2=shape(.58,.49,.06,.08,2); eye2.BackgroundColor3=Glass.Colors.Base
    elseif kind=="Gifts" then
        shape(.22,.4,.56,.1,2); shape(.27,.52,.46,.27,2); shape(.47,.28,.06,.52,2)
        local a=shape(.3,.26,.19,.1,3); a.Rotation=30
        local b=shape(.51,.26,.19,.1,3); b.Rotation=-30
    else
        local ring=shape(.25,.25,.5,.5,50); ring.BackgroundTransparency=1
        local outline=Instance.new("UIStroke"); outline.Color=accent; outline.Thickness=2; outline.Parent=ring
        local tip1=shape(.55,.18,.22,.07,2); tip1.Rotation=22
        local tip2=shape(.7,.22,.07,.22,2); tip2.Rotation=22
    end
    return f
end
function Glass.AnimateButton(b)
    b.AutoButtonColor=false
    local s=Instance.new("UIScale"); s.Name="InteractionScale"; s.Parent=b
    local edge=b:FindFirstChild("GlassEdge")
    local currentScale,currentSurface,currentEdge
    local function state(scale,alpha,line)
        if currentScale then currentScale:Cancel() end
        if currentSurface then currentSurface:Cancel() end
        if currentEdge then currentEdge:Cancel() end
        local info=TweenInfo.new(.14,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
        currentScale=TweenService:Create(s,info,{Scale=scale}); currentScale:Play()
        currentSurface=TweenService:Create(b,info,{BackgroundTransparency=alpha}); currentSurface:Play()
        if edge then currentEdge=TweenService:Create(edge,info,{Transparency=line}); currentEdge:Play() end
    end
    b.MouseEnter:Connect(function() state(1.025,.12,.25) end)
    b.MouseLeave:Connect(function() state(1,.23,.55) end)
    b.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then state(.96,.08,.18) end
    end)
    b.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then state(1,.23,.55) end
    end)
    b.SelectionGained:Connect(function() state(1,.12,.25) end)
    b.SelectionLost:Connect(function() state(1,.23,.55) end)
    b:GetPropertyChangedSignal("Visible"):Connect(function()
        if b.Visible then s.Scale=.94; b.BackgroundTransparency=1; state(1,.23,.55) end
    end)
end
function Glass.Appear(p,delaySeconds)
    local scale=Instance.new("UIScale"); scale.Name="RevealScale"; scale.Scale=.94; scale.Parent=p
    p.BackgroundTransparency=1
    task.delay(delaySeconds or 0,function()
        if not p.Parent then return end
        TweenService:Create(scale,TweenInfo.new(.3,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Scale=1}):Play()
        TweenService:Create(p,TweenInfo.new(.3,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{BackgroundTransparency=.23}):Play()
    end)
end
function Glass.Notification(button,side)
    local baseColor=button.BackgroundColor3
    local edge=button:FindFirstChild("GlassEdge"); local baseEdge=edge and edge.Color
    local red=Color3.fromRGB(239,83,104)
    local badge=Instance.new("Frame"); badge.Name="NotificationBadge"; badge.Size=UDim2.fromOffset(22,22)
    badge.AnchorPoint=Vector2.new(.5,.5)
    badge.Position=side=="left" and UDim2.new(0,3,0,3) or UDim2.new(1,-3,0,3)
    badge.BackgroundColor3=red; badge.BackgroundTransparency=.12; badge.BorderSizePixel=0
    badge.ZIndex=button.ZIndex+3; badge.Visible=false; badge.Parent=button; corner(badge,50)
    local border=Instance.new("UIStroke"); border.Color=Color3.fromRGB(255,184,192)
    border.Transparency=.3; border.Thickness=1; border.Parent=badge
    local tint=Instance.new("UIGradient"); tint.Rotation=90
    tint.Color=ColorSequence.new(Color3.fromRGB(255,231,235),Color3.fromRGB(175,189,211)); tint.Parent=badge
    local number=Instance.new("TextLabel"); number.Name="Count"; number.BackgroundTransparency=1
    number.Size=UDim2.fromScale(1,1); number.TextColor3=Glass.Colors.Text; number.Font=Enum.Font.GothamBold
    number.TextSize=12; number.ZIndex=badge.ZIndex+1; number.Parent=badge
    require(game.ReplicatedStorage.SimulatorShared.TextStyle).Apply(number)
    local scale=Instance.new("UIScale"); scale.Parent=badge
    local previous=-1; local surfaceTween,edgeTween,revealTween
    return function(count)
        count=math.max(0,math.floor(count))
        if count==previous then return end
        previous=count; button:SetAttribute("NotificationCount",count)
        number.Text=count>99 and "99+" or tostring(count); badge.Visible=count>0
        if surfaceTween then surfaceTween:Cancel() end
        if edgeTween then edgeTween:Cancel() end
        surfaceTween=TweenService:Create(button,TweenInfo.new(.2),{
            BackgroundColor3=count>0 and baseColor:Lerp(Color3.fromRGB(160,48,67),.38) or baseColor})
        surfaceTween:Play()
        if edge then
            edgeTween=TweenService:Create(edge,TweenInfo.new(.2),{Color=count>0 and baseEdge:Lerp(red,.6) or baseEdge})
            edgeTween:Play()
        end
        if revealTween then revealTween:Cancel() end
        if count>0 then
            scale.Scale=.75
            revealTween=TweenService:Create(scale,TweenInfo.new(.2,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1})
            revealTween:Play()
        end
    end
end
return Glass
