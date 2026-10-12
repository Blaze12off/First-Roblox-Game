local C = require(game.ReplicatedStorage.SimulatorShared.Config)
local TextStyle = require(game.ReplicatedStorage.SimulatorShared.TextStyle)
local Visuals = {}
function Visuals.Apply(player, data)
    local character = player.Character
    if not character then return end
    local previous = character:FindFirstChild("SimulatorPet")
    if previous then previous:Destroy() end
    local root = character:FindFirstChild("HumanoidRootPart")
    local id = data.EquippedPet
    local info = C.PetTypes[id]
    if not root or not info or not data.Pets[id] then return end
    local model = Instance.new("Model"); model.Name = "SimulatorPet"; model.Parent = character
    local origin = root.CFrame * CFrame.new(3, -.6, 2)
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
        piece("Ear", Vector3.new(.38, id == "Bunny" and 1.3 or .55, .45),
            Vector3.new(x, id == "Bunny" and 1.15 or .87, 0), color)
        piece("Eye", Vector3.new(.20, .25, .12), Vector3.new(x * .7, .18, -.78), Color3.fromRGB(22, 30, 48))
    end
    piece("Nose", Vector3.new(.22, .16, .14), Vector3.new(0, -.13, -.8), Color3.fromRGB(255, 125, 161))
    local tag = Instance.new("BillboardGui"); tag.Size = UDim2.fromOffset(140, 30)
    tag.StudsOffset = Vector3.new(0, 2.2, 0); tag.MaxDistance = 18; tag.Parent = body
    local text = Instance.new("TextLabel"); text.Size = UDim2.fromScale(1, 1)
    text.BackgroundTransparency = 1; text.Font = Enum.Font.GothamBold; text.TextSize = 14
    text.TextColor3 = color; text.Text = info.Name; text.Parent = tag; TextStyle.Apply(text)
end
return Visuals
