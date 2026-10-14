-- Fresh Studio sandbox: interaction metadata, egg HUD button, full-scene blur and menu feedback.
assert(game:GetService("RunService"):IsStudio())
task.spawn(function()
    local player=game.Players.LocalPlayer
    local layout=player.PlayerGui.SimulatorUI.HudLayout
    local hud=layout.HudContent
    local map=workspace.SimulatorWorld
    for _,prompt in map:GetDescendants() do
        if prompt:IsA("ProximityPrompt") then
            assert(prompt.KeyboardKeyCode==Enum.KeyCode.E and prompt.Exclusivity==Enum.ProximityPromptExclusivity.OneGlobally and prompt.Style==Enum.ProximityPromptStyle.Custom,"exclusive E custom prompts")
        end
    end
    local mesh=map.MeadowShell.ShellBase:FindFirstChildOfClass("SpecialMesh")
    assert(mesh and mesh.Scale.Y>mesh.Scale.X and not map:FindFirstChild("MeadowBand"),"continuous oval shell without band")
    player.Character:PivotTo(map.EggMeadow.CFrame+Vector3.new(0,4,0)); task.wait(1)
    assert(hud.Train.Visible and hud.Train.InteractCaption.Text:find("Открыть яйцо",1,true),"egg HUD interaction button")
    local remote=game.ReplicatedStorage.SimulatorRemotes.Action
    remote:FireServer("PetMenu"); task.wait(.7)
    assert(layout.MenuShade.Visible and layout.Parent.IgnoreGuiInset and game.Lighting.SimulatorMenuBlur.Size>0,"full scene blur")
    assert(not hud.CoinsCard.Visible and not hud.PowerCard.Visible,"HUD hidden behind menu")
    remote:FireServer("Hatch","Meadow"); task.wait(.7)
    assert(layout.Notice.Visible and layout.Notice.ZIndex>layout.MenuShade.ZIndex and layout.Notice.Text:find("Не хватает монет",1,true),"validation feedback above menu in fresh zero-coin sandbox")
    print("INTERACTION_MODEL_PASS E_exclusive oval_shell no_band")
    print("MENU_FEEDBACK_PASS egg_hud full_scene_blur validation_notice")
end)
