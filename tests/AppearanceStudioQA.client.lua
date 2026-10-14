-- Studio client-only fixtures: proportions, headings, mirrored inspector transition, rebirth phases and spawn.
assert(game:GetService("RunService"):IsStudio())
task.spawn(function()
    task.wait(3) -- Let the first camera/viewport and HUD entrance animations settle.
    local player=game.Players.LocalPlayer
    local UI=require(game.StarterPlayer.StarterPlayerScripts.SimulatorClient.UI)
    local H=require(game.StarterPlayer.StarterPlayerScripts.SimulatorClient.Headings)
    local C=require(game.ReplicatedStorage.SimulatorShared.Config)
    local refs=UI.Build(player); refs.Gui.Name="AppearanceFixture"
    local ok,err=pcall(function()
        assert(H.Text("Shop","ru")=="Магазин" and H.Text("Shop","en-US")=="Shop" and H.Item("Cat_Upgraded","en")=="Cat · Upgraded","RU/EN heading dictionary")
        for _,obj in workspace.SimulatorWorld:GetDescendants() do assert(not obj:IsA("SpawnLocation"),"no spawn platform") end
        assert(not workspace.SimulatorWorld:FindFirstChild("SimulatorSpawn"),"old spawn removed")
        for _,size in {{320,568},{568,320},{1224,774},{1280,720},{1920,1080},{1920,720}} do
            refs.Layout.Size=UDim2.fromOffset(size[1],size[2]); task.wait(.4)
            local s=math.min(size[1]/980,size[2]/620)
            assert(math.abs(refs.Shop.AbsoluteSize.X-152*s)<1 and math.abs(refs.Shop.AbsoluteSize.Y-54*s)<1,"fixed relative size")
            assert(math.abs(refs.Catalog.Back.AbsoluteSize.X-36*s)<1,"arrow same scale as close")
            assert(refs.Catalog.Back.BackGlyph.Size.X.Scale==.75,"three quarter arrow glyph")
        end
        refs.Layout.Size=UDim2.fromOffset(1224,774); task.wait(.25)
        refs.Open("Pets"); refs.Catalog.Update({Level=0,Pets={Cat=3},EquippedPets={},PetMultiplier=1})
        refs.Catalog.Inspect("Cat",false); task.wait(.25)
        local menu=refs.Layout.MenuShade.Pets
        assert(refs.Catalog.Inspector.Visible and refs.Catalog.PetList.UIGridLayout.FillDirectionMaxCells==3,"inspector open")
        local narrow=menu.AbsoluteSize.X
        refs.Catalog.Return(); task.wait(.08)
        assert(refs.Catalog.Inspector.Visible and menu.AbsoluteSize.X>narrow,"reverse transition still animating")
        task.wait(.2); assert(not refs.Catalog.Inspector.Visible and refs.Catalog.PetList.UIGridLayout.FillDirectionMaxCells==5,"reverse finished")
        assert(menu.Close.CloseGlyph.Size.X.Scale==refs.Catalog.Back.BackGlyph.Size.X.Scale,"matching close and back proportions")
        local headingCount=0; for _,obj in refs.Gui:GetDescendants() do if obj:GetAttribute("HeadingStyle")=="GlassTypography" then headingCount+=1 end end
        assert(headingCount>=8,"shared heading style")
        for _,obj in refs.Gui:GetDescendants() do assert(obj.Name~="HeadingAccent","no heading underlines") end
        for _,window in refs.Layout.MenuShade:GetChildren() do
            if window:IsA("Frame") and window:FindFirstChild("Title") then
                local heading=window.Title
                assert(math.abs(heading.AbsolutePosition.X+heading.AbsoluteSize.X/2-window.AbsolutePosition.X-window.AbsoluteSize.X/2)<1,"heading centred in entire window: "..window.Name)
            end
        end
        assert(refs.Layout.HudContent.PowerCard:FindFirstChildWhichIsA("TextLabel").TextColor3==Color3.fromRGB(104,239,202),"power theme restored")
        assert(refs.Layout.HudContent.CoinsCard:FindFirstChildWhichIsA("TextLabel").TextColor3==Color3.fromRGB(255,212,119),"coins theme restored")
        refs.Close()
        local completed=false
        refs.PlayResult({Action="Rebirth",PreviousMultiplier=1,Multiplier=1.12},function() completed=true end)
        task.wait(.29); assert(refs.Animation.Phase=="Old" and refs.Animation.Overlay.RebirthMultiplier.Text=="x1.00","old coefficient holds")
        task.wait(.3); assert(refs.Animation.Phase=="New" and refs.Animation.Overlay.RebirthMultiplier.Text=="x1.12","new coefficient")
        assert(game.Lighting:FindFirstChild("SimulatorRebirthBlur") and game.Lighting.SimulatorRebirthBlur.Size>19,"rebirth blur")
        task.wait(1.18); assert(refs.Animation.Phase=="Exit","opposite exit")
        task.wait(.4); assert(completed and not refs.Animation.Busy and not game.Lighting:FindFirstChild("SimulatorRebirthBlur"),"fade and cleanup")
        print("APPEARANCE_UI_PASS proportional_scale back_glyph reverse_slide headings_ru_en rebirth_phases no_spawn_platform")
    end)
    refs.Gui:Destroy(); assert(ok,err)
    -- Check actual respawn callback, not a simulated spawn point.
    local old=player.Character; old.Humanoid.Health=0
    local deadline=os.clock()+12
    repeat task.wait(.1) until player.Character~=old or os.clock()>deadline
    assert(player.Character~=old,"respawn after death")
    local root=player.Character:WaitForChild("HumanoidRootPart",10)
    local settleDeadline=os.clock()+5
    repeat task.wait(.1) until not root or (math.abs(root.Position.X-C.SpawnPosition.X)<1 and math.abs(root.Position.Z-C.SpawnPosition.Z)<1) or os.clock()>settleDeadline
    assert(root and math.abs(root.Position.X-C.SpawnPosition.X)<1 and math.abs(root.Position.Z-C.SpawnPosition.Z)<1,"spawn coordinate without platform")
    print("SPAWN_POSITION_PASS initial_point respawn_without_platform")
end)
