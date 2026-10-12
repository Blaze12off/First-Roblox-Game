local C = require(game.ReplicatedStorage.SimulatorShared.Config)
local Schema = {}
function Schema.New()
    return {Version = 3, Coins = 0, Power = 0, Level = 0, Rebirths = 0,
        LifetimePower = 0, TotalTrainings = 0, LastDaily = 0, LastWeekly = 0,
        Cosmetics = {}, Equipped = "", Pets = {}, EquippedPets = {}}
end
function Schema.Copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do result[key] = Schema.Copy(item) end
    return result
end
local function integer(value, maximum)
    return type(value) == "number" and value == value and value >= 0
        and value <= maximum and value % 1 == 0
end
-- Corrupt/unknown records fail closed. Defaults only come from a genuinely absent key.
function Schema.Validate(raw)
    if type(raw) ~= "table" or (raw.Version ~= 1 and raw.Version ~= 2 and raw.Version ~= 3) then return nil end
    local limits = {Coins=C.MaxValue, Power=C.MaxValue, Level=C.MaxLevel,
        Rebirths=C.MaxRebirths, LifetimePower=C.MaxValue, TotalTrainings=C.MaxValue,
        LastDaily=100000000000, LastWeekly=100000000000}
    for key, limit in pairs(limits) do if not integer(raw[key], limit) then return nil end end
    if type(raw.Cosmetics) ~= "table" or type(raw.Equipped) ~= "string" then return nil end
    for key, value in pairs(raw.Cosmetics) do
        if (key ~= "BronzeAura" and key ~= "NeonTrail") or value ~= true then return nil end
    end
    if raw.Equipped ~= "" and not raw.Cosmetics[raw.Equipped] then return nil end
    if raw.Version >= 2 then
        if type(raw.Pets) ~= "table" then return nil end
        local total = 0
        for id, count in pairs(raw.Pets) do
            if not C.PetTypes[id] or not integer(count, C.MaxPets) or count < 1 then return nil end
            total += count
        end
        if total > C.MaxPets then return nil end
        if raw.Version == 2 then
            if type(raw.EquippedPet) ~= "string" or (raw.EquippedPet ~= "" and not raw.Pets[raw.EquippedPet]) then return nil end
        else
            if type(raw.EquippedPets) ~= "table" then return nil end
            local equipped = 0
            for id, count in pairs(raw.EquippedPets) do
                if not C.PetTypes[id] or not integer(count,C.PetEquipSlots) or count<1 or count>(raw.Pets[id] or 0) then return nil end
                equipped += count
            end
            if equipped>C.PetEquipSlots then return nil end
        end
    end
    local clean = Schema.New()
    for key in pairs(clean) do
        if key ~= "Version" and key ~= "EquippedPets" and (raw.Version >= 2 or key ~= "Pets") then
            clean[key] = Schema.Copy(raw[key])
        end
    end
    if raw.Version == 3 then clean.EquippedPets=Schema.Copy(raw.EquippedPets)
    elseif raw.Version == 2 and raw.EquippedPet ~= "" then clean.EquippedPets[raw.EquippedPet]=1 end
    return clean
end
return Schema
