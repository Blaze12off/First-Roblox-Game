local C=require(script.Parent.Config)
local Factory={}
local function part(model,name,size,position,color)
    local p=Instance.new("Part"); p.Name=name; p.Size=size; p.Position=position; p.Color=color
    p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false
    p.Material=Enum.Material.SmoothPlastic; p.Parent=model; return p
end
local function ellipsoid(model,name,size,position,color)
    local p=part(model,name,Vector3.one,position,color)
    local mesh=Instance.new("SpecialMesh"); mesh.MeshType=Enum.MeshType.Sphere; mesh.Scale=size; mesh.Parent=p
    return p
end
function Factory.Build(id,isEgg)
    local info=(isEgg and C.Eggs or C.PetTypes)[id]; assert(info,"Unknown model")
    local model=Instance.new("Model"); model.Name=id
    local color=Color3.fromRGB(table.unpack(info.Color))
    if isEgg then
        -- Sphere mesh with independent axes: a continuous oval shell, not PartType.Ball's round body.
        model.PrimaryPart=ellipsoid(model,"ShellBase",Vector3.new(2.1,3.0,2.1),Vector3.zero,color)
        for _,x in {-.55,.55} do
            ellipsoid(model,"Spot",Vector3.new(.30,.42,.10),Vector3.new(x,-.4,-.99),color:Lerp(Color3.new(1,1,1),.4))
        end
    else
        model.PrimaryPart=part(model,"Body",Vector3.new(1.6,1.5,1.5),Vector3.zero,color)
        local bunny=(info.BaseId or id)=="Bunny"
        for _,x in {-.48,.48} do
            part(model,"Ear",Vector3.new(.38,bunny and 1.3 or .55,.45),Vector3.new(x,bunny and 1.15 or .87,0),color)
            part(model,"Eye",Vector3.new(.20,.25,.12),Vector3.new(x*.7,.18,-.78),Color3.fromRGB(22,30,48))
        end
        part(model,"Nose",Vector3.new(.22,.16,.14),Vector3.new(0,-.13,-.8),Color3.fromRGB(255,125,161))
        if info.Upgraded then
            part(model,"Crown",Vector3.new(1.2,.25,1),Vector3.new(0,.85,0),Color3.fromRGB(255,212,119))
        end
    end
    return model
end
return Factory
