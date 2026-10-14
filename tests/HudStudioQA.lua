-- Execute this entire file in the CLIENT Command Bar during Studio Play.
-- Checks actual engine layout, restores the live canvas even on failure.
assert(game:GetService("RunService"):IsStudio(),"Studio only")
task.spawn(function()
    local layout=game.Players.LocalPlayer.PlayerGui.SimulatorUI.HudLayout
    local original=layout.Size
    local hud=layout.HudContent
    local ok,err=pcall(function()
        local controls={hud.PowerCard,hud.CoinsCard,hud.MultiplierCard,hud.ActionDock.Shop,
            hud.ActionDock.Gifts,hud.ActionDock.Pets,hud.Rebirth,hud.Train,hud.Hint,layout.Notice}
        for _,size in {{320,568},{390,700},{568,320},{844,390},{1224,774},{1280,720},{1920,1080},{1920,720}} do
            layout.Size=UDim2.fromOffset(size[1],size[2]); task.wait(.4)
            local origin=layout.AbsolutePosition
            for _,a in controls do
                local p=a.AbsolutePosition-origin; local s=a.AbsoluteSize
                assert(p.X>=-1 and p.Y>=-1 and p.X+s.X<=size[1]+1 and p.Y+s.Y<=size[2]+1,
                    a.Name.." outside "..size[1].."x"..size[2])
            end
            for i,a in controls do
                for j=i+1,#controls do
                    local b=controls[j]; local ap,as=a.AbsolutePosition,a.AbsoluteSize
                    local bp,bs=b.AbsolutePosition,b.AbsoluteSize
                    assert(not (ap.X<bp.X+bs.X-1 and bp.X<ap.X+as.X-1 and ap.Y<bp.Y+bs.Y-1 and bp.Y<ap.Y+as.Y-1),
                        a.Name.." overlaps "..b.Name.." at "..size[1].."x"..size[2])
                end
            end
            local expected=math.min(size[1]/980,size[2]/620)
            assert(math.abs(hud.ActionDock.Shop.AbsoluteSize.X-152*expected)<1 and math.abs(hud.ActionDock.Shop.AbsoluteSize.Y-54*expected)<1,"uniform proportions")
            assert(math.abs(hud.Rebirth.AbsoluteSize.X-164*expected)<1 and math.abs(hud.Rebirth.AbsoluteSize.Y-88*expected)<1,"rebirth proportions")
            local scale=hud.Train.InteractionScale
            scale.Scale=1; task.wait(.1)
            local centre=hud.Train.AbsolutePosition+hud.Train.AbsoluteSize/2
            for _,factor in {1.025,.96,1} do
                scale.Scale=factor; task.wait(.1)
                local changed=hud.Train.AbsolutePosition+hud.Train.AbsoluteSize/2
                assert((changed-centre).Magnitude<=1,"Training button centre moves during scale at "..size[1].."x"..size[2])
            end
        end
    end)
    layout.Size=original
    hud.Train.InteractionScale.Scale=1
    assert(ok,err)
    print("HUD_LAYOUT_PASS 8 sizes; uniform proportions bounds separation centred animation")
end)
