local Localization=game:GetService("LocalizationService")
local H={}
local C=require(game.ReplicatedStorage.SimulatorShared.Config)
local labels={
    Settings={"Настройки","Settings"},
    Power={"ПРЫЖОК","JUMP"}, Coins={"МОНЕТЫ","COINS"}, Total={"ОБЩИЙ МНОЖИТЕЛЬ","TOTAL MULTIPLIER"},
    Shop={"Магазин","Shop"}, Gifts={"Награды","Rewards"}, Pets={"Яйца и питомцы","Eggs & Pets"},
    Rebirth={"Перерождение","Rebirth"}, Confirm={"ПОДТВЕРЖДЕНИЕ","CONFIRMATION"},
    Eggs={"Выбор яйца","Egg selection"}, Inventory={"Питомцы","Pets"}, Paid={"Донатные предметы","Paid items"},
    Cat={"Кот","Cat"}, Dog={"Пёс","Dog"}, Bunny={"Кролик","Bunny"},
    Fox={"Звёздный лис","Star Fox"}, Phoenix={"Солнечный феникс","Solar Phoenix"},
    Axolotl={"Аксолотль Бездны","Void Axolotl"}, Dragon={"Небесный дракон","Celestial Dragon"},
    Meadow={"Луговое яйцо","Meadow egg"}, Crystal={"Кристальное яйцо","Crystal egg"},
    Celestial={"Небесное яйцо","Celestial egg"},
    Upgraded={"Улучшенный","Upgraded"},
    HatchOpening={"Яйцо открывается…","Hatching…"}, Crafting={"Совмещаем питомцев…","Combining pets…"},
    Hatched={"Новый питомец!","New pet!"}, Crafted={"Питомец улучшен!","Pet upgraded!"},
}
function H.Language(locale)
    local detected=Localization.SystemLocaleId
    if detected=="" then detected=Localization.RobloxLocaleId end
    return tostring(locale or detected):lower():sub(1,2)=="ru" and "ru" or "en"
end
function H.Text(key,locale)
    local pair=labels[key]; return pair and pair[H.Language(locale)=="ru" and 1 or 2] or key
end
function H.Item(id,locale)
    local egg=C.Eggs[id]
    if egg and not labels[id] then return egg.Name end
    local pet=C.PetTypes[id]
    if pet and pet.Zone and pet.Zone>1 then
        local zoneLabel=H.Language(locale)=="ru" and "Ур. " or "Lv. "
        return H.Text(pet.Species,locale).." · "..zoneLabel..pet.Zone..(pet.Upgraded and " · "..H.Text("Upgraded",locale) or "")
    end
    local base=id:gsub("_Upgraded$","")
    return H.Text(base,locale)..(base~=id and " · "..H.Text("Upgraded",locale) or "")
end
function H.Style(label,color,size)
    label:SetAttribute("HeadingStyle","GlassTypography")
    label.Font=Enum.Font.GothamBold; label.TextSize=size or label.TextSize
    label.TextColor3=color or Color3.fromRGB(239,248,255)
    -- Heading decoration belongs to the text; no underline or extra geometry.
    return label
end
return H
