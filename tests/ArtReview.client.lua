-- Temporary visual review only; never included by BuildPlace.ps1.
assert(game:GetService("RunService"):IsStudio())
local player=game.Players.LocalPlayer
repeat task.wait(.2) until player:GetAttribute("ArtQAComplete")
local camera=workspace.CurrentCamera; camera.CameraType=Enum.CameraType.Scriptable
-- Set Focus as well as CFrame to stop the Studio editor's old orbit pivot carrying over.
local target=Vector3.new(-101,2.5,-28)
camera.CFrame=CFrame.lookAt(target+Vector3.new(0,10,22),target); camera.Focus=CFrame.new(target)
print("ART_REVIEW_CAMERA_READY")
