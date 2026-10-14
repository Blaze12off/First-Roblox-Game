local Tween=game:GetService("TweenService")
local Run=game:GetService("RunService")
local Catalog=require(script.Parent.PetCatalog)
local C=require(game.ReplicatedStorage.SimulatorShared.Config)
local Glass=require(script.Parent.Glass)
local Headings=require(script.Parent.Headings)
local TextStyle=require(game.ReplicatedStorage.SimulatorShared.TextStyle)
local Presentation={}
function Presentation.Build(parent)
    local api={Busy=false}
    local overlay=Instance.new("Frame"); overlay.Name="ResultAnimation"; overlay.Size=UDim2.fromScale(1,1)
    overlay.BackgroundColor3=Glass.Colors.Base; overlay.BackgroundTransparency=.15; overlay.Visible=false
    overlay.ZIndex=80; overlay.Active=true; overlay.Parent=parent
    local title=Instance.new("TextLabel"); title.Size=UDim2.new(1,-32,0,60); title.Position=UDim2.new(0,16,.15,0)
    title.TextColor3=Glass.Colors.Gold; title.TextSize=24; title.Font=Enum.Font.GothamBold; title.TextWrapped=true
    title.BackgroundTransparency=1; title.Parent=overlay; TextStyle.Apply(title); Headings.Style(title,Glass.Colors.Gold)
    local caption=title:Clone(); caption.Position=UDim2.new(0,16,.78,0); caption.TextSize=19; caption.Parent=overlay
    local hero=Instance.new("TextLabel"); hero.Name="RebirthMultiplier"; hero.AnchorPoint=Vector2.new(.5,.5)
    hero.Size=UDim2.fromScale(.75,.25); hero.Position=UDim2.fromScale(.5,.5); hero.BackgroundTransparency=1
    hero.Font=Enum.Font.GothamBlack; hero.TextScaled=true; hero.TextColor3=Glass.Colors.Violet; hero.Visible=false; hero.Parent=overlay; TextStyle.Apply(hero)
    local heroLimit=Instance.new("UITextSizeConstraint"); heroLimit.MinTextSize=18; heroLimit.MaxTextSize=120; heroLimit.Parent=hero
    local heroScale=Instance.new("UIScale"); heroScale.Name="ZoomScale"; heroScale.Parent=hero
    local function clear() local old=overlay:FindFirstChild("Picture"); if old then old:Destroy() end end
    function api.Play(result,onDone)
        if api.Busy then return false end
        api.Busy=true; overlay.Visible=true; clear()
        local action,id=result.Action,result.Id
        local duration=action=="Rebirth" and 2 or 4
        title.Text=Headings.Text(action=="Hatch" and "HatchOpening" or action=="PetCraft" and "Crafting" or "Rebirth")
        caption.Text=""
        if action=="Rebirth" then
            title.Visible=false; caption.Visible=false; overlay.BackgroundTransparency=1
            hero.Visible=true; hero.Text=("x%.2f"):format(result.PreviousMultiplier or 1)
            hero.TextColor3=Glass.Colors.Violet; hero.TextTransparency=1
            hero.Position=UDim2.new(.5,0,.5,30); heroScale.Scale=.2
            local blur=Instance.new("BlurEffect"); blur.Name="SimulatorRebirthBlur"; blur.Size=0; blur.Parent=game:GetService("Lighting")
            task.spawn(function()
                api.Phase="Approach"
                Tween:Create(heroScale,TweenInfo.new(.25,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Scale=1}):Play()
                Tween:Create(hero,TweenInfo.new(.25),{TextTransparency=0,Position=UDim2.fromScale(.5,.5)}):Play()
                Tween:Create(blur,TweenInfo.new(.25),{Size=20}):Play(); task.wait(.25)
                api.Phase="Old"; task.wait(.2)
                if not overlay.Parent then blur:Destroy(); return end
                api.Phase="Change"
                local old=hero:Clone(); old.Name="PreviousMultiplier"; old.Parent=overlay
                hero.Text=("x%.2f"):format(result.Multiplier or 1); hero.TextColor3=Glass.Colors.Gold; hero.TextTransparency=1
                Tween:Create(old,TweenInfo.new(.1),{TextTransparency=1}):Play()
                Tween:Create(hero,TweenInfo.new(.1),{TextTransparency=0,TextColor3=Glass.Colors.Violet}):Play()
                task.wait(.1); old:Destroy()
                api.Phase="New"; task.wait(1.15)
                api.Phase="Exit"
                Tween:Create(heroScale,TweenInfo.new(.3,Enum.EasingStyle.Quart,Enum.EasingDirection.In),{Scale=.2}):Play()
                Tween:Create(hero,TweenInfo.new(.3),{TextTransparency=1,Position=UDim2.new(.5,0,.5,-30)}):Play()
                Tween:Create(blur,TweenInfo.new(.3),{Size=0}):Play(); task.wait(.3)
                blur:Destroy(); hero.Visible=false; overlay.Visible=false; title.Visible=true; caption.Visible=true
                overlay.BackgroundTransparency=.15; api.Busy=false; api.Phase="Done"
                if onDone then onDone() end
            end)
            return true
        end
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
                    title.Text=Headings.Text(action=="Hatch" and "Hatched" or "Crafted")
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
