assert(game:GetService("RunService"):IsStudio())
task.spawn(function()
    task.wait(3)
    local player=game.Players.LocalPlayer
    local client=player.PlayerScripts.SimulatorClient
    local S=require(client.Settings); local C=require(game.ReplicatedStorage.SimulatorShared.Config)
    local refs=require(client.UI).Build(player); refs.Gui.Name="SettingsFixture"
    local model=Instance.new("Model"); model.Name="SettingsOtherFixture"; model:SetAttribute("OwnerUserId",player.UserId+1); model.Parent=workspace
    local body=Instance.new("Part"); body.Anchored=true; body.Transparency=.3; body.Parent=model
    local trail=Instance.new("Trail"); trail.Enabled=true; trail.Parent=body
    local sound=Instance.new("Sound"); sound:SetAttribute("AudioCategory","Music"); sound.Parent=workspace
    local ok,err=pcall(function()
        for _,v in pairs(S.Volumes) do assert(v==1,"fresh audio starts at 100 percent") end
        refs.Open("Settings"); task.wait(.3)
        assert(refs.Settings.Button.Visible,"settings always accessible")
        refs.Settings.SetAllHUD(false); assert(not refs.HudContent.Visible and refs.Settings.Button.Visible,"master HUD off")
        refs.Settings.SetAllHUD(true); refs.Settings.SetHUD("Power",false); refs.Open("Shop"); assert(not refs.HudContent.PowerCard.Visible,"hidden card survives menu switch")
        refs.Settings.SetHUD("Power",true)
        for _,key in {"Sound","Graphics","Interface"} do refs.Settings.Select(key); assert(refs.Settings.Pages[key].Visible,"settings tab") end
        assert(refs.Settings.Pages.Interface.CanvasSize.Y.Offset>refs.Settings.Pages.Interface.AbsoluteSize.Y,"HUD scroll")
        refs.Settings.Sliders.Master.Set(.2); refs.Settings.Sliders.Music.Set(.4); task.wait(.1)
        assert(math.abs(sound.SoundGroup.Volume-.4)<.001 and math.abs(sound.SoundGroup.Parent.Volume-.2)<.001,("nested sound mixer: %s %.4f / %s %.4f"):format(sound.SoundGroup.Name,sound.SoundGroup.Volume,sound.SoundGroup.Parent.Name,sound.SoundGroup.Parent.Volume))
        S.SetOption("Players",false); assert(body.LocalTransparencyModifier==1 and not trail.Enabled,"other body and trail hidden")
        local pet=Instance.new("Part"); pet.Anchored=true; pet.Parent=model; task.wait(.1); assert(pet.LocalTransparencyModifier==1,"new accessories hidden")
        S.SetOption("Players",true); assert(body.LocalTransparencyModifier==0 and trail.Enabled and math.abs(body.Transparency-.3)<.001,"restore original appearance")
        local shadows=S.Shadows; S.SetOption("Shadows",false); assert(not game.Lighting.GlobalShadows,"local shadows"); S.SetOption("Shadows",shadows)
        refs.Open("Pets"); refs.Catalog.Update({Level=0,Pets={Cat=1,Dog=1,Bunny=1},EquippedPets={}})
        refs.Catalog.Inspect("Crystal",true); assert(refs.Catalog.DetailPrimary.Text:find("240 монет",1,true),"egg price unit")
        refs.Catalog.Return(); refs.Catalog.Select("Inventory")
        local found={}; for _,card in pairs(refs.Catalog.PetCards) do found[card.Rarity.Text]=card.Rarity.TextColor3 end
        assert(found["Обычный"] and found["Редкий"] and found["Эпический"] and found["Обычный"]~=found["Редкий"],"pet rarity names and colors")
        print("SETTINGS_PASS hud_restore scrolling mixer hide_restore new_accessories graphics rarity egg_units")
    end)
    S.SetOption("Players",true); S.SetOption("Effects",true); refs.Settings.SetAllHUD(true); refs.Settings.SetHUD("Power",true)
    refs.Settings.Sliders.Master.Set(1); refs.Settings.Sliders.Music.Set(1)
    model:Destroy(); sound:Destroy(); refs.Gui:Destroy(); assert(ok,err)
end)
