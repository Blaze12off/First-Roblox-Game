-- Template rule: floating text must stay legible over bright platforms.
local TextStyle={}
function TextStyle.Apply(textObject)
    textObject.TextStrokeColor3=Color3.fromRGB(10,14,22)
    textObject.TextStrokeTransparency=0.15
    return textObject
end
return TextStyle
