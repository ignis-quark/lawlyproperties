local MENU = MENU or {}

net.Receive("lawlyhousing_open_client_menu", function()
    local sign = net.ReadEntity()
    local isAdmin = net.ReadBool()
    GenerateMenu(sign, isAdmin)
end )

MENU.Frame = nil
MENU.Options = nil

MENU.Tab = 1
MENU.Tabs = {
    "Purchase Options",
    "Manage Owners",
    "Admin Menu" //MUST be last in list for permissions to work!
}

MENU.Sign = nil


function GenerateMenu(sign, isAdmin)
    if ( MENU.Frame ) then
        MENU.Frame = nil
    end
    MENU.Sign = sign

    MENU.Frame = vgui.Create("DFrame")
    MENU.Frame:SetSize(ScrW() * 0.3, ScrH() * 0.3)
    MENU.Frame:SetVisible(true)
    MENU.Frame:Center()
    MENU.Frame:SetTitle("Property Sign")
    MENU.Frame:MakePopup()
    MENU.Frame:SetMouseInputEnabled(true)
    MENU.Frame:ParentToHUD()

    local tablist = vgui.Create("DPanel", MENU.Frame)
    tablist:Dock( TOP )
    tablist:SetTall(20)
    tablist:DockMargin(5,0,5,10)
    tablist.Paint = function() end

    for i, tab in ipairs(MENU.Tabs) do
        if i == #MENU.Tabs and !isAdmin then continue end
        local tabbtn = vgui.Create("DButton", tablist)
        tabbtn:SetText(tab)
        tabbtn:SetTextColor(Color(0,0,0))
        tabbtn:SetTextInset(10,0)
        tabbtn:SizeToContentsX()
        tabbtn:Dock( LEFT )
        tabbtn:DockMargin(5,0,10,0)
        tabbtn.OnMousePressed = function()
            MENU.Tab = i
            MENU.Options:ChangeTab()
        end
    end
    MENU.Options = vgui.Create("DPanel", MENU.Frame)
    MENU.Options:Dock( FILL )
    MENU.Options:DockPadding(5,5,5,5)
    MENU.Options.Paint = function() end
    MENU.Options.ChangeTab = function()
        for _, pnl in ipairs(MENU.Options:GetChildren()) do
            pnl:Remove()
        end
        timer.Create("lawlyhousing_menu_waitforpanel", 0.01, 1, function()
            PopulateTab(MENU.Tab, MENU.Options)
            timer.Remove("lawlyhousing_menu_waitforpanel")
        end)
    end
    MENU.Options.ChangeTab()
end

MENU.LastUse = CurTime()

function PopulateTab(tab, panel)

    local propname = MENU.Sign:GetProperty()
    local propowner = "Un-Owned"
        if IsValid( MENU.Sign:GetPropertyOwner() ) then
            propowner = MENU.Sign:GetPropertyOwner():Nick()
        end
    local proptype = "Buy"
    if MENU.Sign:GetSaleType() then
        proptype = "Rent"
    end
    local propprice = MENU.Sign:GetPrice()
    local propdoors = MENU.Sign:GetDoorCount()

    --[[============= TAB 1 =============]]
    if ( tab == 1 ) then
        local FrameName = vgui.Create("Panel", panel)

        if !IsValid( MENU.Sign ) then
            local errmsg = vgui.Create("DLabel", panel)
            errmsg:SetText("WARNING! SIGN IS INVALID!")
            errmsg:SetTextColor(Color(255,0,0))
            errmsg:Dock(TOP)
            return
        end

        FrameName:Dock( TOP )

            local nameLabel = vgui.Create("DLabel")
            nameLabel:SetText("Custom Property Name:")
            nameLabel:SetTextColor(Color(255,255,255))
            nameLabel:Dock( LEFT )
            nameLabel:SetContentAlignment(5)
            nameLabel:SizeToContentsX()

            local nameBtn = vgui.Create("DButton")
            nameBtn:SetText("Apply Name")
            nameBtn:Dock( RIGHT )
            nameBtn:SetTextInset(10,0)
            nameBtn:SizeToContentsX()
            nameBtn.OnMousePressed = function(pnl)
                local txt = string.Left(nameInput:GetText(), 30)
                MENU.Sign:UpdateName(txt)
                nameInput:SetPlaceholderText(txt)
                nameInput:SetText("")
            end

            nameInput = vgui.Create("DTextEntry")
            nameInput:Dock( FILL )
            nameInput:DockMargin(10,0,10,0)
            nameInput:SetPlaceholderText(propname)

        FrameName:Add(nameLabel)
        FrameName:Add(nameBtn)
        FrameName:Add(nameInput)

        local FrameInfo = vgui.Create("Panel", panel)
        FrameInfo:Dock( LEFT )
        FrameInfo:DockPadding(5,30,5,0)
        FrameInfo:SetWide(panel:GetWide() * 0.3)

            local infoLabel = vgui.Create("DLabel", FrameInfo)
            infoLabel:SetText("House Information")
            infoLabel:Dock( TOP )
            infoLabel:SetContentAlignment(5)

        FrameInfo.AddInfoPanel = function(pnl, txt, val)

            local labelContainer = vgui.Create("Panel", pnl)
                local labelname = vgui.Create("DLabel", labelContainer)
                labelname:SetText(tostring(txt) .. ": ")
                labelname:Dock(LEFT)
                labelname:SizeToContentsX()

                local labelvalue = vgui.Create("DLabel", labelContainer)
                labelvalue:SetText(val)
                labelvalue:Dock(RIGHT)
                labelvalue:SizeToContentsX()
            labelContainer:Dock( TOP )
        end

        FrameInfo:AddInfoPanel("Name", propname)
        FrameInfo:AddInfoPanel("Price", "$" .. propprice)
        FrameInfo:AddInfoPanel("Type", proptype)
        FrameInfo:AddInfoPanel("Owner", propowner)
        FrameInfo:AddInfoPanel("Doors", propdoors)

        local buyBtn = vgui.Create("DButton", panel)
        buyBtn:SetMouseInputEnabled(true)
        buyBtn.UpdateText = function()
            local textType = "Purchase"
            if MENU.Sign:GetSaleType() then
                textType = "Rent"
            end
            local btnText = textType.." Property"
            if IsValid( MENU.Sign:GetPropertyOwner() ) then
                    btnText = "Sell Property"
                if MENU.Sign:GetPropertyOwner() ~= LocalPlayer() then
                    btnText = "This house is already owned."
                    buyBtn:SetMouseInputEnabled(false)
                end
            end
            buyBtn:SetText(btnText)
        end
        buyBtn:UpdateText()
        buyBtn:Dock( TOP )
        buyBtn:DockMargin(10,30,0,0)
        buyBtn.OnMousePressed = function()
            MENU.Sign:UpdateName(nameInput:GetText())
            nameInput:SetText("")
            MENU.Sign:BuyButton()
            buyBtn.Depressed = true
            timer.Create("lawlyhousing_wait_to_update_btn_text", 0.1, 1, function()
                buyBtn:UpdateText()
                timer.Remove("lawlyhousing_wait_to_update_btn_text")
            end)
        end
    end

    --[[============= TAB 2 =============]]
    if ( tab == 2 ) then
        local signFriends = MENU.Sign:GetFriends()
        local allPlayers = {}

        local playerList = vgui.Create("DListView", panel)
        playerList:Dock( LEFT )
        playerList:DockMargin(5,5,5,5)
        playerList:SetWide(MENU.Options:GetWide() * 0.4)
        playerList:AddColumn("Player List")
        playerList:SetMultiSelect(false)
        playerList.Selection = 0
        playerList.RefreshList = function()
            playerList:Clear()
            playerList.Selection = 0
            for _, ply in ipairs(allPlayers) do
                playerList:AddLine(ply:Nick())
            end
        end
        playerList.OnRowSelected = function(pnl, index)
            playerList.Selection = index
        end


        local ownerList = vgui.Create("DListView", panel)
        ownerList:Dock( RIGHT )
        ownerList:DockMargin(5,5,5,5)
        ownerList:SetWide(MENU.Options:GetWide() * 0.4)
        ownerList:AddColumn("Co-Owners")
        ownerList:SetMultiSelect(false)
        ownerList.Selection = 0
        ownerList.RefreshList = function()
            ownerList:Clear()
            ownerList.Selection = 0
            for _, ply in ipairs(signFriends) do
                if IsValid( ply ) then
                    ownerList:AddLine(ply:Nick())
                end
            end
        end
        ownerList.OnRowSelected = function(pnl, index)
            ownerList.Selection = index
        end

        local btnHolder = vgui.Create("Panel", panel)
        btnHolder.Paint = function() end
        btnHolder:SetSize(panel:GetWide() * 0.1, 140)

        local addPlyBtn = vgui.Create("DButton", btnHolder)
        addPlyBtn:SetTall(25)
        addPlyBtn:SetText("  >")
        addPlyBtn:Dock( TOP )
        addPlyBtn:DockMargin(10,0,10,5)
        addPlyBtn.OnMousePressed = function()
            if playerList.Selection then
                local index = playerList.Selection
                local ply = allPlayers[index]
                table.insert(signFriends, ply)
                panel.RefreshAll()
                addPlyBtn.Depressed = true
            end
        end

        local remPlyBtn = vgui.Create("DButton", btnHolder)
        remPlyBtn:SetTall(25)
        remPlyBtn:SetText("<  ")
        remPlyBtn:Dock( TOP )
        remPlyBtn:DockMargin(10,0,10,15)
        remPlyBtn.OnMousePressed = function()
            if ownerList.Selection then
                local index = ownerList.Selection
                table.remove(signFriends, index)
                panel:RefreshAll()
                remPlyBtn.Depressed = true
            end
        end


        local addAllBtn = vgui.Create("DButton", btnHolder)
        addAllBtn:SetTall(25)
        addAllBtn:SetText(">>")
        addAllBtn:Dock( TOP )
        addAllBtn:DockMargin(10,0,10,5)
        addAllBtn.OnMousePressed = function()
            table.Empty(signFriends) //Need to do these 2 lines, otherwise the button will just swap lists
            panel:RefreshPlyList() //
            signFriends = table.Copy(allPlayers)
            panel:RefreshAll()
            addAllBtn.Depressed = true
        end

        local remAllBtn = vgui.Create("DButton", btnHolder)
        remAllBtn:SetTall(25)
        remAllBtn:SetText("<<")
        remAllBtn:Dock( TOP )
        remAllBtn:DockMargin(10,0,10,5)
        remAllBtn.OnMousePressed = function()
            table.Empty(signFriends)
            panel:RefreshAll()
            remAllBtn.Depressed = true
        end

        btnHolder:Center()

        panel.RefreshPlyList = function()
            table.Empty(allPlayers)
            for _, ply in ipairs(player.GetAll()) do
                if table.HasValue(signFriends, ply) or ply == LocalPlayer() then continue end
                table.insert(allPlayers, ply)
            end
        end

        panel.RefreshAll = function()
            if !IsValid( MENU.Sign ) then
                notification.AddLegacy("The sign is no longer valid!", NOTIFY_ERROR, 3)
                return
            end
            if MENU.LastUse > CurTime() then
                notification.AddLegacy("Slow down!", NOTIFY_ERROR, 2)
                MENU.LastUse = CurTime() + 1
                return
            end
            panel.RefreshPlyList()
            MENU.Sign:SetFriends(signFriends)
            ownerList:RefreshList()
            playerList:RefreshList()
            MENU.LastUse = CurTime() + 0.5
        end
        panel:RefreshAll()
        return
    end

    if ( tab == 3 ) then
        local ownerlabel = vgui.Create("DLabel", panel)
        ownerlabel:SetText("Owner: " .. propowner)
        ownerlabel:Dock(TOP)
        ownerlabel:SetTextColor(Color(255,255,255))

        local clearButton = vgui.Create("DButton", panel)
        clearButton:SetText("Remove Owner")
        clearButton:Dock(TOP)
        clearButton:DockMargin(10,10,10,10)
        clearButton.OnMousePressed = function()
            MENU.Sign:AdminRemovePlayer()
            notification.AddLegacy("Removed player " .. propowner .. " from property.", NOTIFY_GENERIC, 2)
            clearButton.Depressed = true
        end
    end
end
