-- Run in Studio only. No profile writes, reward grants or cloud API calls.
local Q={}
function Q.Run()
    assert(game:GetService("RunService"):IsStudio())
    local shared=game.ReplicatedStorage.SimulatorShared
    local C=require(shared.Config); local Layout=require(shared.TowerLayout)
    local Concepts=require(shared.PetConcepts); local Factory=require(shared.ModelFactory)
    local built,parts=0,0
    local function inspect(id,isEgg)
        local m=Factory.Build(id,isEgg); assert(m.PrimaryPart and m:GetAttribute("ModelRevision")==2)
        local n=0
        for _,p in m:GetDescendants() do
            assert(not p:IsA("LuaSourceContainer"),"No embedded scripts")
            if p:IsA("BasePart") then
                n+=1; assert(p.Anchored and not p.CanCollide and not p.CanTouch and not p.CanQuery)
                assert(p.Size.X>0 and p.Size.Y>0 and p.Size.Z>0)
            end
        end
        assert(n>=(isEgg and 1 or 8) and n<=140,"Model detail budget: "..id.." "..n)
        local _,size=m:GetBoundingBox(); assert(size.Magnitude<12,"Follower bounds")
        if isEgg then assert(m:FindFirstChild("ShellBase") and not m:FindFirstChild("ShellCrown")) end
        m:PivotTo(CFrame.new(12,4,8)*CFrame.Angles(0,.8,0))
        parts+=n; built+=1; m:Destroy()
    end
    for _,id in C.InventoryOrder do inspect(id,false) end
    for _,id in Concepts.Order do assert(not C.PetTypes[id]); inspect(id,false) end
    for _,id in C.EggOrder do inspect(id,true) end
    local map=workspace:FindFirstChild("SimulatorWorld"); assert(map)
    local platforms=0
    for zone=1,5 do
        local tower=map:FindFirstChild("Tower"..zone); assert(tower)
        local layout=Layout.Build(zone)
        local segments={}
        for _,p in tower:GetChildren() do if p.Name=="Core" then table.insert(segments,p) end end
        table.sort(segments,function(a,b) return a.Position.Y<b.Position.Y end)
        local top=0
        for _,p in segments do
            assert(p.Size.Y<=256.001 and p.CanCollide and math.abs(p.Position.Y-p.Size.Y/2-top)<.002,"Core segment contact")
            top=p.Position.Y+p.Size.Y/2
        end
        assert(math.abs(top-layout.SummitY+1)<.002,"Core supports summit without a gap")
        for i,stage in layout.Stages do
            local part=tower:FindFirstChild("Step"..i); assert(part and part.CanCollide and part.CanQuery)
            assert(part:GetAttribute("TowerZone")==zone and part:GetAttribute("TowerStep")==i)
            assert(math.abs(part.Position.Y+part.Size.Y/2-stage.Y)<.001); platforms+=1
            assert(math.abs(part.Size.Y-stage.Height)<.002 and math.abs(part.Size.X-9)<.001,"Solid stair block")
            if i>1 then
                local previous=tower["Step"..(i-1)]
                local dx,dz=math.abs(part.Position.X-previous.Position.X),math.abs(part.Position.Z-previous.Position.Z)
                assert((math.abs(dx-9)<.001 and dz<.001) or (math.abs(dz-9)<.001 and dx<.001),"Tread faces touch")
                assert(part.Position.Y-part.Size.Y/2<previous.Position.Y+previous.Size.Y/2,"Riser closes the vertical gap")
            end
        end
        local final=tower["Step"..Layout.Steps]; local deck=tower.Summit
        assert(math.abs(final.Position.Y+final.Size.Y/2-deck.Position.Y-deck.Size.Y/2)<.002,"Flush summit")
        assert(math.abs(final.Position.X+final.Size.X/2-deck.Position.X+deck.Size.X/2)<.002,"Summit shares stair edge")
        local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Include; params.FilterDescendantsInstances={deck}
        assert(not workspace:Raycast(Vector3.new(final.Position.X,layout.SummitY+2,final.Position.Z),Vector3.new(0,8,0),params),"Stairwell is not capped by the deck")
        if zone<5 then assert(math.abs(map["ZoneGate"..(zone+1)].Position.Y-layout.SummitY-.45)<.001) end
    end
    local exhibits=0
    for _,m in map.PetGallery:GetChildren() do if m:IsA("Model") then exhibits+=1 end end
    assert(exhibits==28 and platforms==160)
    local prompts={}
    for _,obj in map:GetDescendants() do if obj:IsA("ProximityPrompt") then table.insert(prompts,obj) end end
    for i,a in prompts do for j=i+1,#prompts do
        local b=prompts[j]
        assert((a.Parent.Position-b.Parent.Position).Magnitude>a.MaxActivationDistance+b.MaxActivationDistance,
            "Overlapping E prompts: "..a.Parent.Name.." / "..b.Parent.Name)
    end end
    for _,p in workspace:GetDescendants() do assert(not p:IsA("SpawnLocation"),"No spawn platform") end
    print("TOWER_ART_ENGINE_PASS",built,"models",parts,"model_parts",platforms,"steps",exhibits,"exhibits")
    return true
end
return Q
