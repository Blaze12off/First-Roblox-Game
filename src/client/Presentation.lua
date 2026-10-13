local Tween=game:GetService("TweenService")
local Run=game:GetService("RunService")
local Catalog=require(script.Parent.PetCatalog)
local C=require(game.ReplicatedStorage.SimulatorShared.Config)
local Glass=require(script.Parent.Glass)
local TextStyle=require(game.ReplicatedStorage.SimulatorShared.TextStyle)
local Presentation={}
function Presentation.Build(parent)
    local api={Busy=false}
    local overlay=Instance.new("Frame"); overlay.Name="ResultAnimation"; overlay.Size=UDim2.fromScale(1,1)
    overlay.BackgroundColor3=Glass.Colors.Base; overlay.BackgroundTransparency=.15; overlay.Visible=false
    overlay.ZIndex=80; overlay.Active=true; overlay.Parent=parent
    local title=Instance.new("TextLabel"); title.Size=UDim2.new(1,-32,0,60); title.Position=UDim2.new(0,16,.15,0)
    title.TextColor3=Glass.Colors.Gold; title.TextSize=24; title.Font=Enum.Font.GothamBold; title.TextWrapped=true
    title.BackgroundTransparency=1; title.Parent=overlay; TextStyle.Apply(title)
    local caption=title:Clone(); caption.Position=UDim2.new(0,16,.78,0); caption.TextSize=19; caption.Parent=overlay
    local function clear() local old=overlay:FindFirstChild("Picture"); if old then old:Destroy() end end
    function api.Play(result,onDone)
        if api.Busy then return false end
        api.Busy=true; overlay.Visible=true; clear()
        local action,id=result.Action,result.Id
        local duration=action=="Rebirth" and 2 or 4
        title.Text=action=="Hatch" and "Яйцо открывается…" or action=="PetCraft" and "Совмещаем питомцев…" or "Перерождение"
        caption.Text=""
        local view,model
        local models={}
        if action~="Rebirth" then
            view,model=Catalog.View(overlay,action=="Hatch" and result.Source or result.Source,action=="Hatch",false)
            view.Position=UDim2.fromScale(.2,.26); view.Size=UDim2.fromScale(.6,.48)
            if action=="PetCraft" then
                for i=1,3 do
                    local m=i==1 and model or model:Clone(); m.Parent=model.Parent; models[i]=m
                end
                view.CurrentCamera.CFrame=CFrame.lookAt(Vector3.new(0,2,-11),Vector3.new(0,.2,0))
            end
        end
        task.spawn(function()
            local start=os.clock(); local revealed=false
            while overlay.Parent and os.clock()-start<duration do
                local elapsed=os.clock()-start
                if action=="Rebirth" then
                    title.Rotation=math.sin(elapsed*5)*5
                    title.Text=("Перерождение\n✦  x%.2f  ✦"):format(result.Multiplier or 1)
                    overlay.BackgroundTransparency=.15+math.sin(elapsed*3)^2*.35
                elseif elapsed<2.8 then
                    if action=="PetCraft" then
                        local spread=2.6*(1-elapsed/3)
                        for i,m in models do m:PivotTo(CFrame.new((i-2)*spread,math.sin(elapsed*4+i)*.1,0)*CFrame.Angles(0,elapsed*2,0)) end
                    else model:PivotTo(CFrame.Angles(0,math.sin(elapsed*12)*elapsed*.12,math.sin(elapsed*15)*elapsed*.04)) end
                elseif not revealed then
                    revealed=true; clear()
                    view,model=Catalog.View(overlay,id,false,false)
                    view.Position=UDim2.fromScale(.2,.26); view.Size=UDim2.fromScale(.6,.48)
                    local info=C.PetTypes[id]
                    title.Text=action=="Hatch" and "Новый питомец!" or "Питомец улучшен!"
                    caption.Text=("%s\n%s · x%.2f"):format(info.Name,info.Rarity,1+info.Bonus)
                    local scale=Instance.new("UIScale"); scale.Scale=.65; scale.Parent=view
                    view.AnchorPoint=Vector2.new(.5,.5); view.Position=UDim2.fromScale(.5,.5)
                    Tween:Create(scale,TweenInfo.new(.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()
                else model:PivotTo(CFrame.Angles(0,(elapsed-2.8)*.5,0)) end
                Run.RenderStepped:Wait()
            end
            clear(); title.Rotation=0; overlay.Visible=false; api.Busy=false
            if onDone then onDone() end
        end)
        return true
    end
    api.Overlay=overlay
    return api
end
return Presentation
