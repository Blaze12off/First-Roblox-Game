local C=require(game.ReplicatedStorage.SimulatorShared.Config)
local S={}
function S.NewLimiter() return {tokens=C.RemoteBurst, at=os.clock(), actions={}} end
function S.Allow(limiter, action, now, cooldown)
    limiter.tokens=math.min(C.RemoteBurst, limiter.tokens+(now-limiter.at)*C.RemotePerSecond)
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
    if action=="Train" then return args.n==1 and type(args[1])=="string" and C.Stations[args[1]]~=nil end
    if action=="Equip" then return args.n==1 and (args[1]=="" or args[1]=="BronzeAura" or args[1]=="NeonTrail") end
    if action=="Hatch" then return args.n==1 and type(args[1])=="string" and C.Eggs[args[1]]~=nil end
    if action=="PetEquip" then return args.n==1 and type(args[1])=="string" and (args[1]=="" or C.PetTypes[args[1]]~=nil) end
    if action=="PetUnequip" then return args.n==1 and type(args[1])=="string" and C.PetTypes[args[1]]~=nil end
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
