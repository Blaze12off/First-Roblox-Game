-- Pair with a Studio-only SERVER snapshot from Schema.New (never a saved record).
assert(game:GetService("RunService"):IsStudio())
task.spawn(function()
    task.wait(6)
    local p=game.Players.LocalPlayer
    local hud=p.PlayerGui.SimulatorUI.HudLayout.HudContent
    assert(hud.PowerCard.Power.Text=="65.26K","power compact rendering")
    assert(hud.CoinsCard.Coins.Text=="100.08K","coins compact rendering")
    assert(hud.Rebirth.RebirthStats.Text:match("^1K • x"),"rebirth count")
    local menu=p.PlayerGui.SimulatorUI.HudLayout.MenuShade
    assert(menu.Rebirth.Body.Bonus.Text:find("1B",1,true),"record compact rendering")
    local C=require(game.ReplicatedStorage.SimulatorShared.Config)
    local refs=require(p.PlayerScripts.SimulatorClient.UI).Build(p)
    refs.Gui.Name="NumbersFixture"
    local old=C.Eggs.Meadow.Cost
    local ok,err=pcall(function()
        C.Eggs.Meadow.Cost=123456
        refs.Catalog.Update({Level=0,Pets={},EquippedPets={}})
        assert(refs.Catalog.EggCards.Meadow.Locked.Text=="123.46K монет","egg card cost")
        refs.Catalog.Inspect("Meadow",true)
        assert(refs.Catalog.DetailPrimary.Text=="Открыть · 123.46K монет","egg detail cost")
        assert(refs.Catalog.DetailDescription.Text:find("123.46K монет",1,true),"description cost")
    end)
    C.Eggs.Meadow.Cost=old; refs.Gui:Destroy(); assert(ok,err)
    print("NUMBER_DISPLAY_PASS HUD rebirth record egg_card egg_detail unchanged_multipliers")
end)
