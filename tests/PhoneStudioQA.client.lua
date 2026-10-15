-- Run as a temporary LocalScript in Studio Play. No publication is needed.
assert(game:GetService("RunService"):IsStudio())
task.spawn(function()
    task.wait(3)
    local p=game.Players.LocalPlayer
    local refs=require(p.PlayerScripts.SimulatorClient.UI).Build(p)
    refs.Gui.Name="PhoneFixture"
    local function separate(a,b)
        local p,s,q,t=a.AbsolutePosition,a.AbsoluteSize,b.AbsolutePosition,b.AbsoluteSize
        return p.X+s.X<=q.X+1 or q.X+t.X<=p.X+1 or p.Y+s.Y<=q.Y+1 or q.Y+t.Y<=p.Y+1
    end
    local ok,err=pcall(function()
        refs.Layout:SetAttribute("PhonePreview",true)
        for _,size in {{320,568},{390,844},{430,932},{568,320},{844,390},{932,430}} do
            refs.Close(); refs.Layout.Size=UDim2.fromOffset(size[1],size[2]); task.wait(.25)
            assert(refs.PhoneLayout and refs.ResponsiveScale>=.8,"phone HUD scale")
            local hud=refs.HudContent
            local controls={hud.PowerCard,hud.CoinsCard,hud.MultiplierCard,hud.Rebirth,refs.Shop,refs.Gifts,refs.Pets,refs.Train,refs.Hint}
            for i,a in controls do
                local pos=a.AbsolutePosition-refs.Layout.AbsolutePosition; local s=a.AbsoluteSize
                assert(pos.X>=-1 and pos.Y>=-1 and pos.X+s.X<=size[1]+1 and pos.Y+s.Y<=size[2]+1,a.Name.." HUD bounds")
                for j=i+1,#controls do assert(separate(a,controls[j]),a.Name.." HUD overlaps "..controls[j].Name) end
            end
            assert(refs.Power.TextSize*refs.ResponsiveScale>=19,"readable stat number")
            for _,name in {"Shop","Gifts","Rebirth","Settings","Pets","Confirm"} do
                refs.Open(name); task.wait(.25)
                local panel=refs.Layout.MenuShade[name]
                local pos=panel.AbsolutePosition-refs.Layout.AbsolutePosition; local s=panel.AbsoluteSize
                assert(pos.X>=-1 and pos.Y>=-1 and pos.X+s.X<=size[1]+1 and pos.Y+s.Y<=size[2]+1,name.." bounds")
                for _,obj in {hud.PowerCard,hud.CoinsCard,hud.MultiplierCard,hud.ActionDock,hud.Rebirth,refs.Train} do
                    assert(separate(panel,obj),name.." overlaps "..obj.Name.." "..size[1].."x"..size[2])
                end
                assert(refs.Shop.Visible and refs.Gifts.Visible and refs.Settings.Button.Visible,"sharp navigation remains")
                if name=="Shop" then
                    assert(panel.Body:IsA("ScrollingFrame") and panel.Body.AbsoluteCanvasSize.Y>=panel.Body.AbsoluteSize.Y,"short menu scroll")
                    assert(refs.Upgrade.TextSize*panel:FindFirstChildOfClass("UIScale").Scale>=13.5,"readable menu caption")
                end
            end
            refs.Catalog.Update({Level=0,Pets={Cat=3},EquippedPets={}})
            local catalogBody=refs.Layout.MenuShade.Pets.PhoneCatalogBody
            task.wait(.1)
            assert(catalogBody.Visible and catalogBody.AbsoluteCanvasSize.Y>catalogBody.AbsoluteSize.Y,"whole phone catalog scrolls")
            assert(not refs.Catalog.EggList.ScrollingEnabled,"no competing nested touch scroll")
            refs.Catalog.Inspect("Cat",false); task.wait(.25)
            assert(refs.Catalog.Inspector.PhoneBody.Visible,"phone inspector scroll")
            assert(refs.Catalog.DetailPrimary.Parent==refs.Catalog.Inspector.PhoneBody,"inspector action scrolls")
            refs.Catalog.BeginCraft("Cat"); assert(refs.Catalog.ChooseCopy("Cat",1),"phone crafting selection")
            refs.Catalog.Return(); task.wait(.25)
            assert(not refs.Catalog.Inspector.Visible,"inspector closes")
            print("PHONE_SIZE_PASS",size[1],size[2])
        end
        refs.Layout:SetAttribute("PhonePreview",false); refs.Layout.Size=UDim2.fromOffset(1224,774); task.wait(.3)
        assert(not refs.PhoneLayout,"desktop layout restored")
        assert(math.abs(refs.HudContent.ActionDock.Shop.AbsoluteSize.X-152*math.min(1224/980,774/620))<1,"desktop proportions")
        print("PHONE_UI_PASS 6_phone_sizes desktop_restore readable_text scroll craft navigation")
    end)
    refs.Gui:Destroy(); assert(ok,err)
end)
