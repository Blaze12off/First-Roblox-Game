-- Run in CLIENT Command Bar in Studio Play. Restores temporary UI/config changes.
assert(game:GetService("RunService"):IsStudio(),"Studio only")
task.spawn(function()
    local C=require(game.ReplicatedStorage.SimulatorShared.Config)
    local layout=game.Players.LocalPlayer.PlayerGui.SimulatorUI.HudLayout
    local menu=layout.MenuShade.Pets
    local originalSize=layout.Size
    local eggList=menu.Eggs:FindFirstChildOfClass("ScrollingFrame")
    local petList=menu.Inventory:FindFirstChildOfClass("ScrollingFrame")
    local eggPosition,petPosition=eggList.CanvasPosition,petList.CanvasPosition
    local ok,err=pcall(function()
        for index,list in {eggList,petList,menu.Paid:FindFirstChildOfClass("ScrollingFrame")} do
            local placeholders,cards=0,0
            for _,child in list:GetChildren() do
                if child:IsA("Frame") then cards+=1; if child:GetAttribute("Placeholder") then placeholders+=1 end end
            end
            assert(placeholders==15 and cards==({17,18,15})[index],"real cards plus fifteen empty cards")
            assert(list.ScrollingDirection==Enum.ScrollingDirection.Y,"vertical only")
            assert(list.AbsoluteCanvasSize.Y>list.AbsoluteWindowSize.Y,"scrollable content")
            for _,card in list:GetChildren() do
                if card:IsA("Frame") and not card:GetAttribute("Placeholder") then assert(card.Picture.CurrentCamera,"model picture") end
            end
            list.CanvasPosition=Vector2.new(0,10000); task.wait(.1)
            assert(list.CanvasPosition.Y>0,"can scroll down")
        end
        for _,size in {{320,568},{568,320},{1280,720}} do
            layout.Size=UDim2.fromOffset(size[1],size[2]); task.wait(.3)
            if size[1]==1280 then assert(eggList.UIGridLayout.FillDirectionMaxCells==5,"five desktop columns") end
            local pos=menu.AbsolutePosition-layout.AbsolutePosition
            assert(pos.X>=-1 and pos.Y>=-1 and pos.X+menu.AbsoluteSize.X<=size[1]+1 and pos.Y+menu.AbsoluteSize.Y<=size[2]+1,"catalog bounds")
        end
        -- Isolated UI fixture checks the locked branch without altering the live player's state.
        local fixture=Instance.new("Frame"); fixture.Size=UDim2.fromOffset(350,520); fixture.Visible=false; fixture.Parent=layout
        local built=require(game.StarterPlayer.StarterPlayerScripts.SimulatorClient.PetCatalog).Build(fixture)
        built.UpdateEggs(-1)
        local card=built.EggCards.Crystal
        local hidden=card.Locked.Text:find("Недоступно",1,true) and not card.Button.Active
        built.Inspector:Destroy(); fixture:Destroy()
        assert(hidden,"locked description hidden")
        print("CATALOG_UI_PASS pictures vertical_scroll bounds locked_description five_columns placeholders")
    end)
    layout.Size=originalSize; eggList.CanvasPosition=eggPosition; petList.CanvasPosition=petPosition
    assert(ok,err)
end)
