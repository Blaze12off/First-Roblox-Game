assert(game:GetService("RunService"):IsStudio())
task.spawn(function()
    task.wait(3)
    local player=game.Players.LocalPlayer
    local UI=require(game.StarterPlayer.StarterPlayerScripts.SimulatorClient.UI)
    local refs=UI.Build(player); refs.Gui.Name="NavigationFixture"
    local ok,err=pcall(function()
        refs.Train.Visible=true; refs.Hint.Visible=true
        for _,section in {"Shop","Rebirth","Gifts","Pets","Shop"} do
            refs.Open(section); task.wait(.25)
            local hud=refs.HudContent
            for _,card in {hud.PowerCard,hud.CoinsCard,hud.MultiplierCard,hud.ActionDock,hud.Rebirth,hud.Train,hud.Hint} do assert(card.Visible,"HUD stays visible: "..card.Name) end
            assert(refs.ActiveMenu==section and refs.Layout.MenuShade[section].Visible,"direct switch")
            assert(hud.ZIndex>refs.Layout.MenuShade.ZIndex,"clickable navigation layer")
            assert(refs.MenuBlur.Size>19,"world blur")
        end
        refs.Close(); task.wait(.25)
        assert(refs.MenuBlur.Size<.1,"blur clears on close")
        print("MENU_NAVIGATION_PASS visible_hud bottom_button direct_switch sharp_gui")
    end)
    refs.Gui:Destroy(); assert(ok,err)
end)
