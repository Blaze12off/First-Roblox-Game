local C = require(game.ReplicatedStorage.SimulatorShared.Config)
local TextStyle = require(game.ReplicatedStorage.SimulatorShared.TextStyle)
local Visuals = {}
function Visuals.Apply(player, data)
    local character = player.Character
    if not character then return end
    local previous = character:FindFirstChild("SimulatorPet")
    if previous then previous:Destroy() end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local folder=Instance.new("Folder"); folder.Name="SimulatorPet"; folder.Parent=character
    local slot=0
    for _,id in C.InventoryOrder do
      for _=1,data.EquippedPets[id] or 0 do
    slot+=1
    local info=C.PetTypes[id]
    local model = Instance.new("Model"); model.Name = id..slot; model.Parent = folder
    local offset=({Vector3.new(-3,-.6,2),Vector3.new(3,-.6,2),Vector3.new(0,-.6,4)})[slot]
    local origin = root.CFrame * CFrame.new(offset)
    local function piece(name, size, offset, color)
        local p = Instance.new("Part"); p.Name = name; p.Size = size; p.Color = color
        p.Material = Enum.Material.SmoothPlastic; p.CanCollide = false; p.CanTouch = false
        p.CanQuery = false; p.Massless = true; p.CFrame = origin * CFrame.new(offset); p.Parent = model
        local weld = Instance.new("WeldConstraint"); weld.Part0 = root; weld.Part1 = p; weld.Parent = p
        return p
    end
    local color = Color3.fromRGB(table.unpack(info.Color))
    local body = piece("Body", Vector3.new(1.6, 1.5, 1.5), Vector3.zero, color)
    model.PrimaryPart = body
    for _, x in {-.48, .48} do
        piece("Ear", Vector3.new(.38, (info.BaseId or id) == "Bunny" and 1.3 or .55, .45),
            Vector3.new(x, (info.BaseId or id) == "Bunny" and 1.15 or .87, 0), color)
        piece("Eye", Vector3.new(.20, .25, .12), Vector3.new(x * .7, .18, -.78), Color3.fromRGB(22, 30, 48))
    end
    piece("Nose", Vector3.new(.22, .16, .14), Vector3.new(0, -.13, -.8), Color3.fromRGB(255, 125, 161))
    if info.Upgraded then piece("Crown",Vector3.new(1.2,.25,1),Vector3.new(0,.85,0),Color3.fromRGB(255,212,119)) end
    local tag = Instance.new("BillboardGui"); tag.Size = UDim2.fromOffset(140, 30)
    tag.StudsOffset = Vector3.new(0, 2.2, 0); tag.MaxDistance = 18; tag.Parent = body
    local text = Instance.new("TextLabel"); text.Size = UDim2.fromScale(1, 1)
    text.BackgroundTransparency = 1; text.Font = Enum.Font.GothamBold; text.TextSize = 14
    text.TextColor3 = color; text.Text = info.Name; text.Parent = tag; TextStyle.Apply(text)
      end
    end
    if slot==0 then folder:Destroy() end
end
return Visuals
