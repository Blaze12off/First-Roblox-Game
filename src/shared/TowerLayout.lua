-- Pure layout: shared by geometry, server checkpoints and CLI reachability tests.
local L={Steps=32,CheckpointEvery=8,PlatformSize=9,Spacing=120,Slab=.8}
local ranges={{.24,6},{3,14},{10,30},{24,65},{48,105}}
local ring={{-18,18},{-9,18},{0,18},{9,18},{18,18},{18,9},{18,0},{18,-9},
    {18,-18},{9,-18},{0,-18},{-9,-18},{-18,-18},{-18,-9},{-18,0},{-18,9}}
function L.Build(zone)
    assert(type(zone)=="number" and zone%1==0 and zone>=1 and zone<=5,"Invalid tower zone")
    local range=ranges[zone]; local x=(zone-1)*L.Spacing+8; local z=-76
    local result={Zone=zone,X=x,Z=z,Stages={}}; local height=.2
    for i=1,L.Steps do
        local rise=range[1]+(range[2]-range[1])*((i-1)/(L.Steps-1))^1.35
        height+=rise
        local offset=ring[(i-1)%#ring+1]
        result.Stages[i]={Index=i,X=x+offset[1],Y=height,Z=z+offset[2],Rise=rise,
            Bottom=height-rise-L.Slab,Height=rise+L.Slab,Checkpoint=i%L.CheckpointEvery==0}
    end
    -- The final tread meets the deck at the same height. Leave the western stairwell open.
    result.SummitY=height; result.LastRise=0
    result.DeckX=x+3.75; result.DeckWidth=34.5; result.DeckDepth=42
    return result
end
return table.freeze(L)
