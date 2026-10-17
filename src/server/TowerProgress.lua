local Players=game:GetService("Players")
local C=require(game.ReplicatedStorage.SimulatorShared.Config)
local Layout=require(game.ReplicatedStorage.SimulatorShared.TowerLayout)
local Security=require(script.Parent.Security)
local T={}
-- Checkpoints are recovery aids for the current server session, never currency or XP.
function T.Start(map,getData,notice)
    local sessions={}; local closed=false
    local function state(player)
        local s=sessions[player.UserId]
        if not s then s={Checkpoints={},Zone=1,LastRecall=-10}; sessions[player.UserId]=s end
        return s
    end
    local function move(player,pos)
        local char=player.Character; local root=char and char:FindFirstChild("HumanoidRootPart")
        local human=char and char:FindFirstChildOfClass("Humanoid")
        if not root or not human or human.Health<=0 then return false end
        root.AssemblyLinearVelocity=Vector3.zero; root.AssemblyAngularVelocity=Vector3.zero
        char:PivotTo(CFrame.new(pos)); return true
    end
    function T.Recall(player,zone,down)
        if type(zone)~="number" or zone%1~=0 or zone<1 or zone>#C.Zones or type(down)~="boolean" then return false end
        local base=map:FindFirstChild((down and "TowerDown" or "TowerRecall")..zone)
        local data=getData(player); if not base or not data or zone>data.Zone or not Security.Near(player,base,7) then return false end
        local s=state(player); if os.clock()-s.LastRecall<2 then return false end; s.LastRecall=os.clock()
        local checkpoint=s.Checkpoints[zone] or 0
        local stage=checkpoint>0 and Layout.Build(zone).Stages[checkpoint]
        if down or not stage then move(player,C.Zones[zone].Position)
        else move(player,Vector3.new(stage.X,stage.Y+3.5,stage.Z)) end
        notice(player,down and "У подножия башни." or stage and ("Возврат к ступени "..checkpoint..".") or "Сначала достигни отметки на ступени 8.")
        return true
    end
    for _,base in map:GetChildren() do
        local zone=base:GetAttribute("RecallZone"); local down=base:GetAttribute("TowerDownZone")
        if zone then base.RecallPrompt.Triggered:Connect(function(player) T.Recall(player,zone,false) end)
        elseif down then base.DownPrompt.Triggered:Connect(function(player) T.Recall(player,down,true) end) end
    end
    Players.PlayerRemoving:Connect(function(player) sessions[player.UserId]=nil end)
    game:BindToClose(function() closed=true end)
    task.spawn(function()
        while not closed do
            task.wait(.15)
            for _,player in Players:GetPlayers() do
                local data=getData(player); local char=player.Character
                local root=char and char:FindFirstChild("HumanoidRootPart")
                local human=char and char:FindFirstChildOfClass("Humanoid")
                if not data or not root or not human or human.Health<=0 then continue end
                local s=state(player)
                if root.Position.Y < -25 then
                    local zone=math.min(s.Zone,data.Zone); local cp=s.Checkpoints[zone]
                    local stage=cp and Layout.Build(zone).Stages[cp]
                    move(player,stage and Vector3.new(stage.X,stage.Y+3.5,stage.Z) or C.Zones[zone].Position)
                elseif math.abs(root.AssemblyLinearVelocity.Y)<3 and human.FloorMaterial~=Enum.Material.Air then
                    local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={char}
                    local hit=workspace:Raycast(root.Position,Vector3.new(0,-(human.HipHeight+root.Size.Y/2+1),0),params)
                    local step=hit and hit.Instance:GetAttribute("TowerStep"); local zone=hit and hit.Instance:GetAttribute("TowerZone")
                    if step and zone and zone<=data.Zone then
                        s.Zone=zone; player:SetAttribute("TowerZone",zone); player:SetAttribute("TowerStep",step)
                        local checkpoint=math.min(Layout.Steps,step-step%Layout.CheckpointEvery)
                        if checkpoint>0 and checkpoint>(s.Checkpoints[zone] or 0) then
                            s.Checkpoints[zone]=checkpoint; player:SetAttribute("TowerCheckpoint",checkpoint)
                            notice(player,"Отметка башни: "..checkpoint.."/32. Возврат по E у подножия (до выхода из сервера).")
                        end
                    end
                end
            end
        end
    end)
end
return T
