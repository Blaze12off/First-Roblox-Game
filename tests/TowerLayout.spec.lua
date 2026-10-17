local L=require("../src/shared/TowerLayout")
local lastSummit=0; local count=0
for zone=1,5 do
    local tower=L.Build(zone); assert(#tower.Stages==32)
    local previousY=.2; local previousRise=0; local checkpoints=0
    for i,step in tower.Stages do
        assert(step.Index==i and step.Y>previousY and step.Rise>=previousRise)
        assert(step.Rise<120,"Rise exceeds the real jump cap")
        if i>1 then
            local prev=tower.Stages[i-1]
            local horizontal=math.sqrt((prev.X-step.X)^2+(prev.Z-step.Z)^2)
            assert(math.abs(horizontal-9)<.001,"Route must have short cardinal gaps")
        end
        if i>16 then assert(step.Y-tower.Stages[i-16].Y>6,"Head clearance between turns") end
        assert(math.abs(step.X-tower.X)-L.PlatformSize/2>=13.6 or math.abs(step.Z-tower.Z)-L.PlatformSize/2>=13.6,"Platform intersects core")
        if step.Checkpoint then checkpoints+=1; assert(i%8==0) end
        previousY=step.Y; previousRise=step.Rise; count+=1
    end
    assert(checkpoints==4 and tower.SummitY>lastSummit and tower.LastRise<120)
    print("TOWER_LAYOUT",zone,"height",math.floor(tower.SummitY),"last_jump",tower.LastRise)
    lastSummit=tower.SummitY
end
for _,bad in {0,6,-1,1.5,"1"} do assert(not pcall(L.Build,bad),"Invalid zone") end
print("TOWER_LAYOUT_PASS",count,"steps progressive clearance route jump_cap")
