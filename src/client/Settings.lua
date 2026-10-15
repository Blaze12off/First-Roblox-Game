local Players=game:GetService("Players")
local SoundService=game:GetService("SoundService")
local Lighting=game:GetService("Lighting")
local Input=game:GetService("UserInputService")
local Glass=require(script.Parent.Glass)
local TextStyle=require(game.ReplicatedStorage.SimulatorShared.TextStyle)
local S={AllHUD=true,HUD={},Players=true,Shadows=Lighting.GlobalShadows,Effects=true,Post=true,Volumes={Master=1,Music=1,Effects=1,Ambient=1}}
local groups,originals={},setmetatable({},{__mode="k"})
local started=false
local function otherOwner(obj)
    local p=obj
    while p and p~=workspace do
        local id=p:GetAttribute("OwnerUserId")
        if id then return id~=Players.LocalPlayer.UserId end
        if p:IsA("Model") then local owner=Players:GetPlayerFromCharacter(p); if owner then return owner~=Players.LocalPlayer end end
        p=p.Parent
    end
    return false
end
local function property(obj,key,value)
    local record=originals[obj]; if not record then record={}; originals[obj]=record end
    if record[key]==nil then record[key]=obj[key] end
    if value==nil then obj[key]=record[key] else obj[key]=value end
end
function S.ApplyObject(obj)
    local hidden=not S.Players and otherOwner(obj)
    if obj:IsA("BasePart") then
        if hidden or originals[obj] then property(obj,"LocalTransparencyModifier",hidden and 1 or nil) end
    elseif obj:IsA("Decal") then
        if hidden or originals[obj] then property(obj,"Transparency",hidden and 1 or nil) end
    elseif obj:IsA("Humanoid") then
        if hidden or originals[obj] then property(obj,"DisplayDistanceType",hidden and Enum.HumanoidDisplayDistanceType.None or nil) end
    elseif obj:IsA("BillboardGui") then
        if hidden then property(obj,"Enabled",false) elseif originals[obj] then property(obj,"Enabled",nil) end
    elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") or obj:IsA("Light") then
        if hidden or not S.Effects then
            property(obj,"Enabled",false)
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") then obj:Clear() end
        elseif originals[obj] then property(obj,"Enabled",nil) end
    elseif obj:IsA("BloomEffect") or obj:IsA("SunRaysEffect") then
        if not S.Post then property(obj,"Enabled",false) elseif originals[obj] then property(obj,"Enabled",nil) end
    end
end
function S.ApplyWorld()
    Lighting.GlobalShadows=S.Shadows
    for _,obj in workspace:GetDescendants() do S.ApplyObject(obj) end
    for _,obj in Lighting:GetDescendants() do S.ApplyObject(obj) end
end
function S.SetOption(key,value) S[key]=value; S.ApplyWorld() end
function S.SetVolume(key,value)
    S.Volumes[key]=math.clamp(value,0,1)
    if groups[key] then groups[key].Volume=S.Volumes[key] end
end
local function assignSound(sound)
    if not sound:IsA("Sound") then return end
    local category=sound:GetAttribute("AudioCategory")
    if not groups[category or ""] then category=sound.Name:lower():find("music") and "Music" or "Ambient" end
    sound.SoundGroup=groups[category]
end
local function start()
    if started then return end; started=true
    local master=SoundService:FindFirstChild("SimulatorMaster")
    if not master then master=Instance.new("SoundGroup"); master.Name="SimulatorMaster"; master.Volume=1; master.Parent=SoundService end
    groups.Master=master; S.Volumes.Master=master.Volume
    for _,key in {"Music","Effects","Ambient"} do
        local g=master:FindFirstChild("Simulator"..key)
        if not g then g=Instance.new("SoundGroup"); g.Name="Simulator"..key; g.Volume=1; g.Parent=master end
        groups[key]=g; S.Volumes[key]=g.Volume
    end
    for _,sound in game:GetDescendants() do assignSound(sound) end
    game.DescendantAdded:Connect(function(obj) if obj:IsA("Sound") then task.defer(assignSound,obj) end end)
    workspace.DescendantAdded:Connect(function(obj) task.defer(S.ApplyObject,obj) end)
    Lighting.DescendantAdded:Connect(function(obj) task.defer(S.ApplyObject,obj) end)
    local function watch(player)
        player.CharacterAdded:Connect(function(char) task.defer(function() for _,obj in char:GetDescendants() do S.ApplyObject(obj) end end) end)
    end
    for _,player in Players:GetPlayers() do watch(player) end; Players.PlayerAdded:Connect(watch)
end
local function label(parent,text,pos,size,font)
    local l=Instance.new("TextLabel"); l.BackgroundTransparency=1; l.Text=text; l.Font=Enum.Font.GothamBold; l.TextSize=font or 14
    l.TextColor3=Glass.Colors.Text; l.TextWrapped=true; l.Position=pos; l.Size=size; l.Parent=parent; TextStyle.Apply(l); return l
end
local function button(parent,text,pos,size)
    local b=Instance.new("TextButton"); b.Text=text; b.Font=Enum.Font.GothamBold; b.TextSize=13; b.TextColor3=Glass.Colors.Text
    b.Size=size; b.Position=pos; b.AnchorPoint=Vector2.new(.5,.5); b.Parent=parent; b.TextWrapped=true
    Glass.Style(b,Glass.Colors.Blue,12); b.GlassTint:Destroy(); TextStyle.Apply(b); Glass.AnimateButton(b); return b
end
function S.Build(refs,menu)
    start()
    local api={Toggles={},Sliders={},Pages={}}
    refs.ShouldShow=function(name) return S.HUD[name]~=false end
    local targets={Power=refs.HudContent.PowerCard,Coins=refs.HudContent.CoinsCard,Multiplier=refs.HudContent.MultiplierCard,Shop=refs.Shop,Gifts=refs.Gifts,Pets=refs.Pets,Rebirth=refs.Rebirth,Train=refs.Train,Hint=refs.Hint}
    local function hudVisibility()
        refs.HudContent.Visible=S.AllHUD
        for name,obj in pairs(targets) do if name~="Train" and name~="Hint" then obj.Visible=refs.ShouldShow(name) elseif not refs.ShouldShow(name) then obj.Visible=false end end
    end
    api.ApplyHUD=hudVisibility; hudVisibility()
    function api.SetHUD(name,value) S.HUD[name]=value; hudVisibility() end
    function api.SetAllHUD(value) S.AllHUD=value; hudVisibility() end
    local top=button(refs.Layout,"Настройки",UDim2.fromOffset(226,34),UDim2.fromOffset(104,36)); top.Name="SettingsButton"; top.ZIndex=70; api.Button=top
    local function positionTop()
        local width=refs.Layout.AbsoluteSize.X
        local inset=game:GetService("GuiService").TopbarInset
        -- Follow Roblox's occupied top bar, including changes to chat/device layout.
        local x=inset.Min.X+8+top.Size.X.Offset/2
        -- Compact Roblox controls sit at y=34 inside the 58px available strip.
        local y=inset.Min.Y+math.max(34,inset.Height/2)
        if inset.Height<=0 then x=width<800 and 222 or 252; y=width<800 and 34 or 44 end
        top.Position=UDim2.fromOffset(math.min(x,width-60),y)
    end
    refs.Layout:GetPropertyChangedSignal("AbsoluteSize"):Connect(positionTop); positionTop()
    local topbarChanged=game:GetService("GuiService"):GetPropertyChangedSignal("TopbarInset"):Connect(positionTop)
    refs.Gui.Destroying:Connect(function() topbarChanged:Disconnect() end)
    top.Activated:Connect(function() if refs.ActiveMenu=="Settings" then refs.Close() else refs.Open("Settings") end end)
    local red,green=Color3.fromRGB(239,83,104),Color3.fromRGB(91,222,169)
    local function toggle(parent,key,caption,y,get,set)
        local b=button(parent,caption,UDim2.new(.5,0,0,y+22),UDim2.new(1,-12,0,42)); b.Name=key
        local function paint() local color=get() and green or red; b.BackgroundColor3=color:Lerp(Glass.Colors.Base,.65); b.GlassEdge.Color=color; b.GlassEdge.Transparency=.2; b.BackgroundTransparency=.12; b:SetAttribute("Selected",get()) end
        b.Activated:Connect(function() set(not get()); paint() end); paint(); api.Toggles[key]=b
        return b
    end
    toggle(menu,"Players","Игроки",60,function() return S.Players end,function(v) S.SetOption("Players",v) end).Size=UDim2.new(1,-40,0,38)
    local tabs={}
    function api.Select(key) for name,page in pairs(api.Pages) do page.Visible=name==key; tabs[name].GlassEdge.Color=name==key and Glass.Colors.Mint or Glass.Colors.Blue end end
    for i,info in {{"Sound","Звук"},{"Graphics","Графика"},{"Interface","Интерфейс"}} do
        local key=info[1]; local b=button(menu,info[2],UDim2.fromOffset(70+(i-1)*105,125),UDim2.fromOffset(100,34)); tabs[key]=b
        local page=Instance.new("ScrollingFrame"); page.Name=key; page.Position=UDim2.fromOffset(20,150); page.Size=UDim2.new(1,-40,1,-168)
        page.BackgroundTransparency=1; page.BorderSizePixel=0; page.ScrollBarThickness=4; page.ScrollingDirection=Enum.ScrollingDirection.Y; page.Parent=menu; api.Pages[key]=page
        b.Activated:Connect(function() api.Select(key) end)
    end
    function api.Resize(width)
        local w=(width-56)/3
        for i,key in {"Sound","Graphics","Interface"} do
            tabs[key].Size=UDim2.fromOffset(w,34)
            tabs[key].Position=UDim2.fromOffset(20+w/2+(i-1)*(w+8),125)
        end
    end
    for i,info in {{"Master","Весь звук"},{"Music","Музыка"},{"Effects","Эффекты"},{"Ambient","Окружение и шаги"}} do
        local key=info[1]; local y=(i-1)*84
        label(api.Pages.Sound,info[2],UDim2.fromOffset(6,y),UDim2.new(1,-12,0,26))
        local track=button(api.Pages.Sound,"",UDim2.new(.5,0,0,y+51),UDim2.new(1,-22,0,28)); track.Name=key
        local fill=Instance.new("Frame"); fill.Name="Fill"; fill.BackgroundColor3=Glass.Colors.Mint; fill.BackgroundTransparency=.2; fill.BorderSizePixel=0; fill.Parent=track
        local corner=Instance.new("UICorner"); corner.CornerRadius=UDim.new(0,10); corner.Parent=fill
        local knob=Instance.new("Frame"); knob.Name="Knob"; knob.AnchorPoint=Vector2.new(.5,.5); knob.Size=UDim2.fromOffset(14,14)
        knob.BackgroundColor3=Glass.Colors.Text; knob.BorderSizePixel=0; knob.ZIndex=3; knob.Parent=track
        local knobCorner=Instance.new("UICorner"); knobCorner.CornerRadius=UDim.new(1,0); knobCorner.Parent=knob
        local value=label(track,"",UDim2.fromScale(0,0),UDim2.fromScale(1,1),12); value.ZIndex=2
        local function update(v) S.SetVolume(key,v); fill.Size=UDim2.fromScale(S.Volumes[key],1); knob.Position=UDim2.new(S.Volumes[key],7-14*S.Volumes[key],.5,0); value.Text=math.floor(S.Volumes[key]*100+.5).."%" end
        api.Sliders[key]={Set=update,Track=track}; update(S.Volumes[key])
        local drag
        local function point(x) update((x-track.AbsolutePosition.X)/math.max(1,track.AbsoluteSize.X)) end
        track.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then drag=input; point(input.Position.X) end end)
        local changed=Input.InputChanged:Connect(function(input) if drag and (input==drag or input.UserInputType==Enum.UserInputType.MouseMovement) then point(input.Position.X) end end)
        local ended=Input.InputEnded:Connect(function(input) if input==drag then drag=nil end end)
        refs.Gui.Destroying:Connect(function() changed:Disconnect(); ended:Disconnect() end)
    end
    api.Pages.Sound.CanvasSize=UDim2.fromOffset(0,336)
    for i,info in {{"Shadows","Тени"},{"Effects","Частицы и следы"},{"Post","Световые эффекты"}} do
        local key=info[1]; toggle(api.Pages.Graphics,key,info[2],(i-1)*54,function() return S[key] end,function(v) S.SetOption(key,v) end)
    end
    api.Pages.Graphics.CanvasSize=UDim2.fromOffset(0,174)
    toggle(api.Pages.Interface,"AllHUD","Весь интерфейс",0,function() return S.AllHUD end,api.SetAllHUD)
    for i,info in {{"Power","Сила"},{"Coins","Монеты"},{"Multiplier","Общий множитель"},{"Shop","Магазин"},{"Gifts","Награды"},{"Pets","Яйца и питомцы"},{"Rebirth","Перерождение"},{"Train","Нижняя кнопка"},{"Hint","Подсказка"}} do
        local key=info[1]; toggle(api.Pages.Interface,key,info[2],i*54,function() return refs.ShouldShow(key) end,function(v) api.SetHUD(key,v) end)
    end
    api.Pages.Interface.CanvasSize=UDim2.fromOffset(0,550)
    api.Select("Sound"); return api
end
return S
