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
            assert(math.abs(horizontal-L.PlatformSize)<.001,"Stairs must share an edge, with zero horizontal gap")
            assert(step.Bottom<prev.Y and step.Y>prev.Y,"Solid riser meets the previous tread")
        end
        if i>16 then assert(step.Bottom-tower.Stages[i-16].Y>6,"Head clearance below solid risers") end
        assert(math.abs(step.X-tower.X)-L.PlatformSize/2>=13.5 or math.abs(step.Z-tower.Z)-L.PlatformSize/2>=13.5,"Stair intersects core")
        assert(math.abs(step.Height-step.Rise-L.Slab)<.001)
        if step.Checkpoint then checkpoints+=1; assert(i%8==0) end
        previousY=step.Y; previousRise=step.Rise; count+=1
    end
    assert(checkpoints==4 and tower.SummitY>lastSummit and tower.LastRise<120)
    local final=tower.Stages[L.Steps]
    assert(final.Y==tower.SummitY and math.abs(final.X+L.PlatformSize/2-(tower.DeckX-tower.DeckWidth/2))<.001,"Final step joins deck without another jump")
    for _,step in tower.Stages do
        local overlapsDeck=step.X+L.PlatformSize/2>tower.DeckX-tower.DeckWidth/2
        if overlapsDeck then assert(tower.SummitY-1-step.Y>6,"Deck must not block the stairwell") end
    end
    print("TOWER_LAYOUT",zone,"height",math.floor(tower.SummitY),"last_jump",tower.LastRise)
    lastSummit=tower.SummitY
end
for _,bad in {0,6,-1,1.5,"1"} do assert(not pcall(L.Build,bad),"Invalid zone") end
print("TOWER_LAYOUT_PASS",count,"solid_stairs zero_gap riser_contact clearance flush_summit")
