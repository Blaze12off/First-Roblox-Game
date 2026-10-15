local C=require(game.ReplicatedStorage.SimulatorShared.Config)
local S={}
function S.NewLimiter(burst,perSecond)
    return {tokens=burst or C.RemoteBurst,burst=burst or C.RemoteBurst,perSecond=perSecond or C.RemotePerSecond,at=os.clock(),actions={}}
end
function S.Allow(limiter, action, now, cooldown)
    limiter.tokens=math.min(limiter.burst, limiter.tokens+(now-limiter.at)*limiter.perSecond)
    limiter.at=now
    if limiter.tokens<1 then return false end
    limiter.tokens-=1
    local last=limiter.actions[action]
    if last and now-last<cooldown then return false end
    limiter.actions[action]=now
    return true
end
function S.Valid(action, args)
    if type(action)~="string" or #action>16 then return false end
    if action=="Jump" then return args.n==0 end
    if action=="Zone" then return args.n==1 and type(args[1])=="number" and args[1]%1==0 and args[1]>=1 and args[1]<=5 end
    if action=="PrepareRebirth" then return args.n==0 or (args.n==1 and type(args[1])=="number" and args[1]%1==0 and args[1]>=1 and args[1]<=C.MaxBatchRebirths) end
    if action=="Train" then return args.n==1 and type(args[1])=="string" and C.Stations[args[1]]~=nil end
    if action=="Equip" then return args.n==1 and (args[1]=="" or args[1]=="BronzeAura" or args[1]=="NeonTrail") end
    if action=="Hatch" then return args.n==1 and type(args[1])=="string" and C.Eggs[args[1]]~=nil end
    if action=="PetEquip" then return args.n==1 and type(args[1])=="string" and (args[1]=="" or C.PetTypes[args[1]]~=nil) end
    if action=="PetUnequip" then return args.n==1 and type(args[1])=="string" and C.PetTypes[args[1]]~=nil end
    if action=="PetCraft" then
        if args.n~=2 or type(args[1])~="string" or not C.PetTypes[args[1]] or C.PetTypes[args[1]].Upgraded or type(args[2])~="table" or #args[2]~=3 then return false end
        local seen={}; local count=0
        for key,index in pairs(args[2]) do
            if type(key)~="number" or key%1~=0 or key<1 or key>3 or type(index)~="number" or index%1~=0 or index<1 or index>C.MaxPets or seen[index] then return false end
            seen[index]=true
            count+=1
        end
        return count==3
    end
    if action=="Rebirth" then return args.n==1 and type(args[1])=="string" and #args[1]<=64 end
    return (action=="Sync" or action=="Upgrade" or action=="PrepareRebirth" or action=="Daily" or action=="Weekly" or action=="PetMenu" or action=="PetEquipBest") and args.n==0
end
function S.Near(player, part, radius)
    local char=player.Character
    local root=char and char:FindFirstChild("HumanoidRootPart")
    local human=char and char:FindFirstChildOfClass("Humanoid")
    return root~=nil and human~=nil and human.Health>0 and (root.Position-part.Position).Magnitude<=radius
end
return S
