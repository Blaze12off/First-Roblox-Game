-- Pure simulation against production progression/pets/rebirth code, never a live profile.
return function(C,Schema,P,Pets,R)
    for _,scenario in {{"slow",1},{"normal",2},{"rapid",10},{"max_pets",2}} do
        math.randomseed(20261016)
        local d=Schema.New(); local arrivals={[1]=0}; local nextEgg=4
        if scenario[1]=="max_pets" then d.Pets={Dragon_Z5_Upgraded=3}; d.EquippedPets={Dragon_Z5_Upgraded=3} end
        for second=1,10000 do
            for _=1,scenario[2] do assert(P.Train(d,"Basic")) end
            assert(P.Practice(d,1))
            if d.Level<8 and d.Coins>=C.UpgradeCost(d.Level)*2 then P.Upgrade(d) end
            local trainedTeam=Pets.EquippedCount(d)==3
            for id in d.EquippedPets do if not C.PetTypes[id].Upgraded or C.PetTypes[id].Zone~=d.Zone then trainedTeam=false end end
            if not trainedTeam and second>=nextEgg and Pets.Count(d)<C.MaxPets then
                local chosen=C.Zones[d.Zone].Eggs[second%2+1]
                if d.Coins>=C.Eggs[chosen].Cost*2 then
                    Pets.Hatch(d,chosen); Pets.EquipBest(d); nextEgg=second+8
                end
            end
            if second%4==0 then
                for _,id in C.PetOrder do
                    if (d.Pets[id] or 0)>=3 then Pets.Craft(d,id,{1,2,3}); Pets.EquipBest(d); break end
                end
            end
            if second%60==0 then
                local amount=C.MaxAffordableRebirths(d)
                if amount>0 then assert(R.Apply(d,amount)) end
            end
            if d.Zone<5 and P.UnlockZone(d,d.Zone+1) then arrivals[d.Zone]=second end
        end
        assert(arrivals[3] and arrivals[3]>=1800,"third zone too fast or unreachable: "..scenario[1])
        if scenario[1]=="normal" then assert(arrivals[3]<=2400,"normal progression exceeds 40 active minutes") end
        print(string.format("JUMP_BALANCE %s zone2=%ss zone3=%ss zone4=%ss zone5=%ss rebirths=%d",scenario[1],tostring(arrivals[2]),tostring(arrivals[3]),tostring(arrivals[4]),tostring(arrivals[5]),d.Rebirths))
    end
    print("JUMP_BALANCE_PASS third_zone_min_30min normal_max_40min pets_do_not_multiply_XP")
end
