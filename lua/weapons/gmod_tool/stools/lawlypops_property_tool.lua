TOOL.Name = "Property Tool"
TOOL.Category = "Lawlypops"
TOOL.ConfigName = ""

//This should only be a list of entity indexes for network saving!
TOOL.DoorList = {}
TOOL.SelectedSign = nil

if ( SERVER ) then

util.AddNetworkString("lawlyhousing_send_table_to_client")

local function IsDoor(ent)
    local ValidDoors = {
        ["func_door_rotating"] = true,
        ["func_door"] = true,
        ["prop_door_rotating"] = true
    }
    return ValidDoors[ent:GetClass()]
end

local function IsSign(ent)
    if ( ent.IsSign ) then
        return true
    end
    return false
end

//Select/Deselect doors or signs
function TOOL:LeftClick(tr)
    local ent = tr.Entity
    if ( IsValid(ent) and IsDoor(ent) ) then
        local doorExists = false
        for i, doorindex in ipairs( self.DoorList ) do
            local door = Entity( doorindex )
            if ( door ~= ent ) then continue end
            table.remove(self.DoorList, i)
            doorExists = true
        end
        if ( not doorExists ) then
            table.insert(self.DoorList, ent:EntIndex())
        end
        self:UpdateClientTable()
        return true
    end
    if ( IsValid(ent) and IsSign(ent) ) then
        self.SelectedSign = ent
        self:UpdateClientTable()
        return true
    end
    return false
end


function TOOL:Reload()
    if ( #self.DoorList == 0 ) then self.SelectedSign = nil end
    table.Empty(self.DoorList)
    self:UpdateClientTable()
    return true
end

function TOOL:UpdateClientTable()
    net.Start("lawlyhousing_send_table_to_client")
        net.WriteTable(self.DoorList)
        net.WriteEntity(self.SelectedSign)
    net.Send(self:GetOwner())
end

end //EndServer

if ( CLIENT ) then
    local DoorList = DoorList or {}
    local SelectedSign = SelectedSign or nil
    local toolname = "tool.lawlypops_property_tool"

    TOOL.Information = {
        {name = "info", stage =1 },
        {name = "left"},
        {name = "reload"},
    }

    language.Add(toolname..".name", "Property Tool")
    language.Add(toolname..".desc", "Used for setting up property signs.")
    language.Add(toolname..".left", "Select a door or sign.")
    language.Add(toolname..".reload", "Clear door selection. Press again to remove sign selection.")

    net.Receive("lawlyhousing_send_table_to_client", function()
        local tbl = net.ReadTable()
        local sign = net.ReadEntity()
        DoorList = tbl
        SelectedSign = sign
        PopulateDoorList()
        PopulateSignInfo()
    end)

    function TOOL:DrawHUD()
        if IsValid(SelectedSign) then
            local pos = SelectedSign:GetPos():ToScreen()
            local saved = SelectedSign:GetIsSaved()
            local SavedColor = Color(200,0,0)
            if saved then SavedColor = Color(0,200,0) end
            draw.RoundedBox(10,pos.x-50, pos.y+80, 100,50,Color(0,0,0,200))
            draw.SimpleText("Saved", "DermaLarge", pos.x, pos.y+80, Color(255,255,525), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            draw.SimpleText(tostring(saved), "DermaLarge", pos.x, pos.y+100, SavedColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        end
        cam.Start3D()
            render.SetMaterial(Material("cable/redlaser"))
            local startpos = LocalPlayer():EyePos() + LocalPlayer():EyeAngles():Forward()*10
            for _, entindex in ipairs(DoorList) do
                local ent = Entity( entindex )
                local doorpos = ent:GetPos()
                render.DrawBeam(startpos, doorpos, 0.5, 0, 1)
            end

            if IsValid(SelectedSign) then
                render.SetMaterial(Material("cable/hydra"))
                local ent = SelectedSign
                local signpos = ent:GetPos()
                render.DrawBeam(startpos, signpos, 0.5, 0, 1)
            end
        cam.End3D()
        surface.SetDrawColor(255,255,255)
        for _, entindex in ipairs(DoorList) do
            local ent = Entity( entindex )
            local doorpos = ent:GetPos()
            local scrpos = doorpos:ToScreen()
            draw.SimpleTextOutlined(ent:GetClass() .. " [" .. entindex .. "]", "DermaDefault", scrpos.x, scrpos.y, Color(255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM, 0.5, Color(0,0,0))                
        end
    end

    function MakeSpacer(height, parent)
        if ( parent ) then
            local element = vgui.Create("DLabel", parent)
            element:SetText("")
            element:Dock( TOP )
            element:SetTall(height)
            element.draw = function() end
        end
        return element
    end

    function MakeLabel(text, parent)
        if ( parent ) then
            local element = vgui.Create("DLabel", parent)
            element:SetText(text)
            element:SetTextColor(Color(0,0,0))
            element:Dock(TOP)
            element:SizeToContentsY()
            return element
        end
    end

    local doorListPanel = doorListPanel or nil
    local selectedDoor = selectedDoor or 0
    local signinfo = signinfo or nil

    local nameval = nameval or ""
    local priceval = priceval or 0

    local typeval = typeval or false

    function PopulateDoorList()
        if ( not IsValid(doorListPanel) ) then return end
        doorListPanel:Clear()
        for i, doorindex in ipairs(DoorList) do
            local door = Entity( doorindex )
            doorListPanel:AddLine(door:GetClass(), doorindex)
        end
    end

    function PopulateSignInfo()
        if ( IsValid(SelectedSign) and IsValid(signinfo)) then
            signinfo:Clear()
            local propname = SelectedSign:GetProperty()
            local ownername = "Unknown"
            if IsValid(SelectedSign:GetPropertyOwner()) then
                ownername = SelectedSign:GetPropertyOwner():Nick()
            end
            local price = SelectedSign:GetPrice()
            signinfo:AddLine("Index", SelectedSign:EntIndex())
            signinfo:AddLine("Name", propname)
            signinfo:AddLine("Owner", ownername)
            signinfo:AddLine("Cost", price)
        end
    end

    function BuildCPanel(CPanel)
        MakeSpacer(20, CPanel)
        local doorlistlabel = MakeLabel("Selected Doors", CPanel)

        doorListPanel = vgui.Create("DListView", CPanel)
        doorListPanel:Dock( TOP )
        doorListPanel:SetTall(200)
        doorListPanel:AddColumn("DoorType")
        doorListPanel:AddColumn("Index")

        MakeSpacer(20, CPanel)
        local signlabel = MakeLabel("Selected Sign", CPanel)

        signinfo = vgui.Create("DListView", CPanel)
        signinfo:Dock( TOP )
        signinfo:AddColumn("VarName")
        signinfo:AddColumn("Value")

        signinfo:AddLine("Index", 0)
        signinfo:AddLine("Name", "")
        signinfo:AddLine("Owner", "")
        signinfo:AddLine("Cost", 0)
        signinfo:SetTall(signinfo:DataLayout()+signinfo:GetHeaderHeight())

        MakeSpacer(10, CPanel)
        local plylistlabel = MakeLabel("Authorized Players", CPanel)

        local authplayerlist = vgui.Create("DListView", CPanel)
        authplayerlist:Dock( TOP )
        authplayerlist:SetTall(200)

        MakeSpacer(20, CPanel)
        local optionslabel = MakeLabel("New Sign Creation", CPanel)
        optionslabel:SetContentAlignment(5)

        MakeSpacer(10, CPanel)
        local namelabel = MakeLabel("Property Name", CPanel)

        local nameinput = vgui.Create("DTextEntry", CPanel)
        nameinput:Dock( TOP )
        nameinput.OnTextChanged = function(val)
            nameval = nameinput:GetValue()
        end

        MakeSpacer(10, CPanel)
        local pricelabel = MakeLabel("Price", CPanel)

        local priceinput = vgui.Create("DNumberWang", CPanel)
        priceinput:Dock( TOP )
        priceinput.OnValueChange = function(val)
            priceval = priceinput:GetValue()
        end 
        
        MakeSpacer(10, CPanel)
        local typechk = vgui.Create("DCheckBoxLabel", CPanel)
        typechk:SetText("Select for rent only.")
        typechk:SetTextColor(Color(0,0,0))
        typechk:Dock( TOP )
        typechk:SizeToContentsY()
        typechk.OnChange = function(_, newval)
            typeval = newval
        end

        MakeSpacer(10, CPanel)
        local writebtn = vgui.Create("DButton", CPanel)
        writebtn:SetText("WRITE TO SIGN")
        writebtn:Dock( TOP )
        writebtn:SetTall(20)
        writebtn.OnMousePressed = function()
            if ( IsValid(SelectedSign) ) then
                SelectedSign:ApplyProperties(DoorList, nameval, priceval, typeval)
                timer.Create("SignTimer"..SelectedSign:EntIndex(), LocalPlayer():Ping()/500, 1, function()
                    PopulateSignInfo()
                    notification.AddLegacy("Sent data to sign.", NOTIFY_GENERIC, 2)
                    surface.PlaySound("buttons/button1.wav")
                    timer.Remove("SignTimer"..SelectedSign:EntIndex())
                end)
                return
            end
            notification.AddLegacy("No sign selected!", NOTIFY_ERROR, 2)
            surface.PlaySound("buttons/button2.wav")
        end

        MakeSpacer(10, CPanel)
        local savebtn = vgui.Create("DButton", CPanel)
        savebtn:SetText("Save signs to file")
        savebtn:Dock( TOP )
        savebtn:SetTall(20)
        savebtn.OnMousePressed = function()
            net.Start("lawlyhousing_save_signs")
            net.SendToServer()
        end
        
        MakeSpacer(10, CPanel)
        local reloadBtn = vgui.Create("DButton", CPanel)
        reloadBtn:SetText("Reload all signs from file")
        reloadBtn:Dock(TOP)
        reloadBtn:SetTall(20)
        reloadBtn.OnMousePressed = function()
            net.Start("lawlyhousing_reload_signs")
            net.SendToServer()
        end
    end

    function TOOL.BuildCPanel(panel)
		panel:ClearControls()
		panel:AddControl("Header", {
			Text = "Property Editor",
			Description = "Edit or Create properties."
		})
		local function tryToBuild()
			local CPanel = controlpanel.Get("lawlypops_property_tool")
			if CPanel and CPanel:GetWide()>16 then
				BuildCPanel(CPanel)
			else
				timer.Simple(0.1,tryToBuild)
			end
		end
		tryToBuild()
	end
end