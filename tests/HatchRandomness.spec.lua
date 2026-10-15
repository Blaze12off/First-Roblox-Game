-- CLI-only audit. Seeds are set in a separate Luau process, NEVER on a game server.
return function(C,Schema,Pets)
    local data=Schema.New()
    local function hatch(eggId,roll)
        -- Reset this fake inventory so the real capacity/cost guards remain active.
        data.Zone=5; data.Pets={}; data.EquippedPets={}; data.Coins=C.Eggs[eggId].Cost
        local ok,message,id=Pets.Hatch(data,eggId,roll)
        assert(ok,message)
        assert(data.Coins==0 and data.Pets[id]==1,"one paid opening must grant exactly one pet")
        return id
    end
    -- Exhaustively sample uniform bucket midpoints through the ACTUAL hatch function.
    for _,eggId in C.EggOrder do
        local counts={}
        for i=0,9999 do
            local id=hatch(eggId,function() return (i+.5)/10000 end)
            counts[id]=(counts[id] or 0)+1
        end
        for _,id in C.PetOrder do
            assert((counts[id] or 0)==(C.Eggs[eggId].Weights[id] or 0)*100,"drop interval mismatch: "..eggId.."/"..id)
        end
    end
    -- Changing accumulated pets must never lock the next result to the previous species.
    local history=Schema.New(); history.Coins=C.Eggs.Crystal.Cost*20
    for _=1,14 do
        local ok,_,id=Pets.Hatch(history,"Crystal",function() return .6 end)
        assert(ok and id=="Fox")
    end
    local ok,_,id=Pets.Hatch(history,"Crystal",function() return .9 end)
    assert(ok and id=="Phoenix" and history.Pets.Fox==14 and history.Pets.Phoenix==1,"history altered the next drop")
    local callbacks=0
    local a=hatch("Crystal",function() callbacks+=1; return .98 end)
    local b=hatch("Crystal",function() callbacks+=1; return .995 end)
    assert(callbacks==2 and a=="Axolotl" and b=="Dragon","each opening must consume a fresh roll")

    local counts={}; local longest,streaks14=0,0
    local total=1000000
    for seed=1,10 do
        math.randomseed(20261016+seed)
        local streak=0
        for _=1,total/10 do
            -- No injected callback: exercise the production math.random path.
            local drop=hatch("Crystal")
            counts[drop]=(counts[drop] or 0)+1
            streak=drop=="Fox" and streak+1 or 0
            if streak==14 then streaks14+=1 end
            longest=math.max(longest,streak)
        end
    end
    for _,id in C.PetOrder do
        local probability=(C.Eggs.Crystal.Weights[id] or 0)/100
        local actual=counts[id] or 0
        -- Six standard deviations: diagnostic smoke check, not proof of randomness.
        assert(math.abs(actual-total*probability)<=6*math.sqrt(total*probability*(1-probability))+1,"unexpected distribution: "..id)
        if probability>0 then print(string.format("HATCH_AUDIT %s %d/1000000 %.4f%% expected %.0f%%",id,actual,actual/total*100,probability*100)) end
    end
    print(string.format("HATCH_RANDOMNESS_PASS midpoint_opens=100000 random_opens=%d seeds=10 fox_longest_run=%d fox_runs_at_least_14=%d",total,longest,streaks14))
    print(string.format("FOX_FIXED_14_PROBABILITY %.8f%% one_in=%.0f",100*.28^14,1/.28^14))
end
