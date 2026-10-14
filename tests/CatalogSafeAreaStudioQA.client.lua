assert(game:GetService("RunService"):IsStudio())
task.spawn(function()
    task.wait(3)
    local refs=require(game.StarterPlayer.StarterPlayerScripts.SimulatorClient.UI).Build(game.Players.LocalPlayer)
    refs.Gui.Name="CatalogSafeFixture"
    local function separate(a,b)
        local p,s,q,t=a.AbsolutePosition,a.AbsoluteSize,b.AbsolutePosition,b.AbsoluteSize
        return p.X+s.X<=q.X+1 or q.X+t.X<=p.X+1 or p.Y+s.Y<=q.Y+1 or q.Y+t.Y<=p.Y+1
    end
    local ok,err=pcall(function()
        for _,size in {{320,568},{568,320},{774,700},{1340,816},{1920,1080}} do
            refs.Close(); refs.Layout.Size=UDim2.fromOffset(size[1],size[2]); task.wait(.4)
            refs.Open("Pets"); refs.Catalog.Update({Level=0,Pets={Cat=3},EquippedPets={}})
            local main=refs.Layout.MenuShade.Pets
            local hud=refs.HudContent
            local function clear(panel)
                for _,item in {hud.PowerCard,hud.CoinsCard,hud.MultiplierCard,hud.ActionDock,hud.Rebirth,hud.Train,hud.Hint} do assert(separate(panel,item),"catalog overlaps "..item.Name) end
            end
            task.wait(.25); clear(main)
            refs.Catalog.Inspect("Cat",false)
            for _=1,6 do task.wait(.04); clear(main); clear(refs.Catalog.Inspector); assert(separate(main,refs.Catalog.Inspector),"opening panels overlap") end
            refs.Catalog.Return()
            for _=1,6 do task.wait(.04); clear(main); if refs.Catalog.Inspector.Visible then assert(separate(main,refs.Catalog.Inspector),"closing panels overlap") end end
            assert(not refs.Catalog.Inspector.Visible,"both transitions complete")
        end
        print("CATALOG_SAFE_PASS 5_sizes HUD_clear synchronized_open_close")
    end)
    refs.Gui:Destroy(); assert(ok,err)
end)
