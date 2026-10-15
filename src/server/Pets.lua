local number=require(game.ReplicatedStorage.SimulatorShared.NumberFormat).Compact
local C = require(game.ReplicatedStorage.SimulatorShared.Config)
local Pets = {}
function Pets.Count(data)
    local count = 0
    for _, amount in pairs(data.Pets) do count += amount end
    return count
end
function Pets.EquippedCount(data)
    local count=0
    for _,amount in pairs(data.EquippedPets) do count+=amount end
    return count
end
-- Randomness is chosen on the server. An injectable roll supports deterministic unit tests.
function Pets.Hatch(data, eggId, roll)
    local egg = C.Eggs[eggId]
    if not egg then return false, "Неизвестное яйцо." end
    if data.Level < egg.MinLevel then return false, "Яйцо недоступно: нужен уровень "..number(egg.MinLevel).."." end
    if Pets.Count(data) >= C.MaxPets then return false, "Инвентарь питомцев заполнен (50)." end
    if data.Coins < egg.Cost then return false, "Не хватает монет на яйцо." end
    local value = roll and roll() or math.random()
    if type(value) ~= "number" or value ~= value or value < 0 or value >= 1 then
        return false, "Не удалось открыть яйцо. Монеты не списаны."
    end
    local total = 0
    for _, id in C.PetOrder do total += egg.Weights[id] or 0 end
    if total<=0 then return false,"В этом яйце пока нет питомцев. Монеты не списаны." end
    local threshold, selected = 0, nil
    for _, id in C.PetOrder do
        local weight=egg.Weights[id] or 0
        if weight<=0 then continue end
        selected=id -- Last eligible drop also handles floating-point rounding at the upper boundary.
        threshold += weight / total
        if value < threshold then selected = id; break end
    end
    data.Coins -= egg.Cost
    data.Pets[selected] = (data.Pets[selected] or 0) + 1
    if Pets.EquippedCount(data) < C.PetEquipSlots then
        data.EquippedPets[selected]=(data.EquippedPets[selected] or 0)+1
    end
    return true, "Из яйца: " .. C.PetTypes[selected].Name .. "!", selected
end
function Pets.Equip(data, id)
    if id ~= "" and (not C.PetTypes[id] or not data.Pets[id]) then
        return false, "Этот питомец не получен."
    end
    if id == "" then data.EquippedPets={}; return true,"Все питомцы сняты." end
    if Pets.EquippedCount(data)>=C.PetEquipSlots then return false,"Все 3 обычных слота заняты." end
    if (data.EquippedPets[id] or 0)>=data.Pets[id] then return false,"Нет свободного экземпляра питомца." end
    data.EquippedPets[id]=(data.EquippedPets[id] or 0)+1
    return true, "Питомец экипирован: " .. C.PetTypes[id].Name
end
function Pets.Unequip(data,id)
    local count=data.EquippedPets[id] or 0
    if count<1 then return false,"Этот питомец не экипирован." end
    data.EquippedPets[id]=count>1 and count-1 or nil
    return true,"Питомец снят."
end
function Pets.EquipBest(data)
    if Pets.Count(data)==0 then return false,"Сначала получите питомца." end
    local order=table.clone(C.InventoryOrder)
    table.sort(order,function(a,b)
        if C.PetTypes[a].Bonus==C.PetTypes[b].Bonus then return a<b end
        return C.PetTypes[a].Bonus>C.PetTypes[b].Bonus
    end)
    local selected,remaining={},C.PetEquipSlots
    for _,id in order do
        local amount=math.min(data.Pets[id] or 0,remaining)
        if amount>0 then selected[id]=amount; remaining-=amount end
        if remaining==0 then break end
    end
    data.EquippedPets=selected
    return true,"Лучшие питомцы экипированы."
end
-- Count-based inventory: three identical copies, validated and consumed atomically.
function Pets.Craft(data,id,copies)
    local info=C.PetTypes[id]
    if not info or info.Upgraded then return false,"Можно совместить только обычные экземпляры одного вида." end
    local owned=data.Pets[id] or 0
    if owned<3 then return false,"Нужно три одинаковых питомца." end
    if type(copies)~="table" or #copies~=3 then return false,"Выберите три экземпляра." end
    local seen,removedEquipped,selectionCount={},0,0
    for key,index in pairs(copies) do
        if type(key)~="number" or key%1~=0 or key<1 or key>3 or type(index)~="number" or index%1~=0 or index<1 or index>owned or seen[index] then
            return false,"Выбор питомцев устарел или некорректен."
        end
        seen[index]=true
        selectionCount+=1
        if index<=(data.EquippedPets[id] or 0) then removedEquipped+=1 end
    end
    if selectionCount~=3 then return false,"Выберите три экземпляра." end
    local remaining=owned-3
    data.Pets[id]=remaining>0 and remaining or nil
    local equipped=(data.EquippedPets[id] or 0)-removedEquipped
    data.EquippedPets[id]=equipped>0 and equipped or nil
    local result=id.."_Upgraded"
    data.Pets[result]=(data.Pets[result] or 0)+1
    if Pets.EquippedCount(data)<C.PetEquipSlots then
        data.EquippedPets[result]=(data.EquippedPets[result] or 0)+1
    end
    return true,"Получен "..C.PetTypes[result].Name.."!",result
end
return Pets
