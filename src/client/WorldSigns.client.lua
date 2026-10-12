local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")
local C=require(game.ReplicatedStorage:WaitForChild("SimulatorShared"):WaitForChild("Config"))
local player=Players.LocalPlayer
local entries={}
local current
local tweenInfo=TweenInfo.new(C.SignFadeSeconds,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)

local function register(gui)
    if not gui:IsA("BillboardGui") or gui.Name~="SimulatorSign" or entries[gui] then return end
    local text=gui:WaitForChild("SignText",5)
    local scale=text and text:WaitForChild("RevealScale",5)
    if not text or not scale or not gui:IsDescendantOf(workspace) then return end
    gui.Enabled=false; text.TextTransparency=1; text.TextStrokeTransparency=1; text.BackgroundTransparency=1
    scale.Scale=0.94
    entries[gui]={gui=gui,text=text,scale=scale,shown=false,generation=0}
end
local function reveal(entry,show)
    if entry.shown==show then return end
    entry.shown=show; entry.generation+=1
    local generation=entry.generation
    if entry.fade then entry.fade:Cancel() end
    if entry.grow then entry.grow:Cancel() end
    if show then entry.gui.Enabled=true end
    entry.fade=TweenService:Create(entry.text,tweenInfo,{
        TextTransparency=show and 0 or 1,
        TextStrokeTransparency=show and 0.15 or 1,
        BackgroundTransparency=show and 0.1 or 1,
    })
    entry.grow=TweenService:Create(entry.scale,tweenInfo,{Scale=show and 1 or 0.94})
    if not show then
        entry.fade.Completed:Once(function(state)
            if state==Enum.PlaybackState.Completed and entry.generation==generation and not entry.shown then
                entry.gui.Enabled=false
            end
        end)
    end
    entry.fade:Play(); entry.grow:Play()
end
workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("BillboardGui") and obj.Name=="SimulatorSign" then task.spawn(register,obj) end
end)
for _,obj in workspace:GetDescendants() do
    if obj:IsA("BillboardGui") and obj.Name=="SimulatorSign" then task.spawn(register,obj) end
end
while script.Parent do
    local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local nearest,nearestDistance=nil,C.SignRevealDistance
    local currentDistance=math.huge
    for gui,entry in pairs(entries) do
        local anchor=gui.Adornee or gui.Parent
        if not gui:IsDescendantOf(workspace) or not anchor:IsA("BasePart") then
            if entry.fade then entry.fade:Cancel() end
            if entry.grow then entry.grow:Cancel() end
            entries[gui]=nil; if current==entry then current=nil end
        elseif root then
            local distance=(root.Position-anchor.Position).Magnitude
            if entry==current then currentDistance=distance end
            if distance<nearestDistance then nearest=entry; nearestDistance=distance end
        end
    end
    -- Show one nearby sign. A small hysteresis prevents rapid switching at the boundary.
    if current and currentDistance<=C.SignRevealDistance+C.SignHideMargin
        and (not nearest or nearestDistance+C.SignHideMargin>=currentDistance) then nearest=current end
    for _,entry in pairs(entries) do reveal(entry,entry==nearest) end
    current=nearest
    task.wait(0.1)
end
