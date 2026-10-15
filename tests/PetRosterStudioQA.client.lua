-- Temporary Studio-only client fixture. Add beside Controller, then remove before saving.
assert(game:GetService("RunService"):IsStudio())
task.wait(5)
local player=game.Players.LocalPlayer
local C=require(game.ReplicatedStorage.SimulatorShared.Config)
local Factory=require(game.ReplicatedStorage.SimulatorShared.ModelFactory)
local ui=require(player.PlayerScripts.SimulatorClient.UI).Build(player)
ui.Gui.Name="RosterFixture"
local refs=ui.Catalog
local function cards(list)
    local n=0
    for _,f in list:GetChildren() do
        if f:IsA("Frame") then n+=1; assert(not f:GetAttribute("Placeholder") and not f.Name:find("Placeholder"),"decorative card remained") end
    end
    return n
end
refs.Update({Level=0,Pets={},EquippedPets={},PetMultiplier=1})
assert(cards(refs.EggList)==3 and cards(refs.PetList)==7 and cards(refs.PaidList)==0,"real catalog card counts")
for _,id in C.PetOrder do
    local f=refs.PetCards[id..":1"]
    assert(f and not refs.PetButtons[id..":1"].Active,"unowned species remains visible without equip permission")
    refs.Inspect(id,false)
    assert(refs.DetailDescription.Text:find("x",1,true),"pet coefficient in detail")
end
refs.Reset(); refs.Select("Inventory"); ui.Open("Pets")
print("PET_ROSTER_CLIENT_PASS 3 eggs 7 base species 0 paid placeholders")
-- P toggles a temporary large contact sheet for visual inspection, not production UI.
local sheet=Instance.new("ScreenGui"); sheet.Name="PetModelContactSheet"; sheet.IgnoreGuiInset=true; sheet.DisplayOrder=100; sheet.Enabled=false; sheet.Parent=player.PlayerGui
local background=Instance.new("Frame"); background.Size=UDim2.fromScale(1,1); background.BackgroundColor3=Color3.fromRGB(18,26,43); background.Parent=sheet
local items={}
for _,id in C.PetOrder do table.insert(items,{id,false}) end
for _,id in C.EggOrder do table.insert(items,{id,true}) end
for i,item in items do
    local col=(i-1)%5; local row=math.floor((i-1)/5)
    local card=Instance.new("Frame"); card.Position=UDim2.new(col/5,6,row/2,6); card.Size=UDim2.new(.2,-12,.5,-12)
    card.BackgroundColor3=Color3.fromRGB(32,45,65); card.Parent=background
    local view=require(player.PlayerScripts.SimulatorClient.PetCatalog).View(card,item[1],item[2],true)
    view.Position=UDim2.fromScale(0,.12); view.Size=UDim2.fromScale(1,.70)
    local title=Instance.new("TextLabel"); title.Size=UDim2.fromScale(1,.12); title.BackgroundTransparency=1; title.Font=Enum.Font.GothamBold; title.TextSize=15
    local info=(item[2] and C.Eggs or C.PetTypes)[item[1]]
    title.Text=info.Name; title.TextColor3=Color3.fromRGB(235,244,255); title.Parent=card
    local sub=title:Clone(); sub.Position=UDim2.fromScale(0,.84); sub.Size=UDim2.fromScale(1,.12)
    sub.Text=item[2] and info.Cost.." монет" or info.Rarity.." · "..string.format("x%.2f",1+info.Bonus)
    sub.TextColor3=Color3.fromRGB(table.unpack(C.RarityColors[info.Rarity])); sub.Parent=card
end
game:GetService("UserInputService").InputBegan:Connect(function(input,processed)
    if not processed and input.KeyCode==Enum.KeyCode.P then sheet.Enabled=not sheet.Enabled end
end)
_G.PetRosterFixture=ui
