local C = require(game.ReplicatedStorage.SimulatorShared.Config)
local Pets = {}
function Pets.Count(data)
    local count = 0
    for _, amount in pairs(data.Pets) do count += amount end
    return count
end
-- Randomness is chosen on the server. An injectable roll supports deterministic unit tests.
function Pets.Hatch(data, eggId, roll)
    local egg = C.Eggs[eggId]
    if not egg then return false, "Неизвестное яйцо." end
    if Pets.Count(data) >= C.MaxPets then return false, "Инвентарь питомцев заполнен (50)." end
    if data.Coins < egg.Cost then return false, "Не хватает монет на яйцо." end
    local value = roll and roll() or math.random()
    if type(value) ~= "number" or value ~= value or value < 0 or value >= 1 then
        return false, "Не удалось открыть яйцо. Монеты не списаны."
    end
    local total = 0
    for _, id in C.PetOrder do total += egg.Weights[id] end
    local threshold, selected = 0, nil
    for _, id in C.PetOrder do
        threshold += egg.Weights[id] / total
        if value < threshold then selected = id; break end
    end
    selected = selected or C.PetOrder[#C.PetOrder]
    data.Coins -= egg.Cost
    data.Pets[selected] = (data.Pets[selected] or 0) + 1
    if data.EquippedPet == "" then data.EquippedPet = selected end
    return true, "Из яйца: " .. C.PetTypes[selected].Name .. "!", selected
end
function Pets.Equip(data, id)
    if id ~= "" and (not C.PetTypes[id] or not data.Pets[id]) then
        return false, "Этот питомец не получен."
    end
    data.EquippedPet = id
    return true, id == "" and "Питомец снят." or "Питомец экипирован: " .. C.PetTypes[id].Name
end
return Pets
