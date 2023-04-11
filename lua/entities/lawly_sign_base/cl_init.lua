include("shared.lua")

surface.CreateFont("Lawlyhousing:SignDefault", {
    size = 60,
    weight = 1000
})
surface.CreateFont("Lawlyhousing:SignSmallName", {
    size = 40,
    weight = 1000
})
surface.CreateFont("Lawlyhousing:SignTinyName", {
    size = 25,
    weight = 1000
})
function ENT:Initialize()
    self:SetModel(self.model)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)

    self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
end

function ENT:ApplyProperties(ls, name, price, typeval)
    net.Start("lawlyhousing_send_data_to_server")
        net.WriteEntity(self)
        net.WriteString(tostring(name))
        net.WriteInt(tonumber(price), 32)
        net.WriteTable(ls)
        net.WriteBool(typeval)
    net.SendToServer()
    self.DoorList = ls
end

function ENT:SetFriends(var)
    self.FriendList = var
    net.Start("lawlyhousing_update_sign_friends")
        net.WriteEntity(self)
        net.WriteTable(self.FriendList)
    net.SendToServer()
end

function ENT:GetFriends()
    return self.FriendList
end

function ENT:UpdateName(txt)
    net.Start("lawlyhousing_update_house_name")
        net.WriteEntity(self)
        net.WriteString(txt)
    net.SendToServer()
end

function ENT:BuyButton()
    net.Start("lawlyhousing_purchase_house_from_menu")
        net.WriteEntity(self)
    net.SendToServer()
end

function ENT:AdminRemovePlayer()
    net.Start("lawlyhousing_remove_player_admin")
        net.WriteEntity(self)
    net.SendToServer()
end

function ENT:Draw()
    local pos = self:GetPos()
    local dist = pos:DistToSqr(LocalPlayer():GetPos())
    if ( dist > 500 * 500 ) then return end
    self:SetMaterial("models/debug/debugwhite")
    self:DrawModel()
    local ang = self:GetAngles()
    -- local w, h = 460, 115
    local h = 115
    local owner = self:GetPropertyOwner()
    ang:RotateAroundAxis(self:GetUp(), 90)
    cam.Start3D2D(pos + self:GetUp() * 2, ang, 0.1)
        local typeText = "SALE"
        if ( self:GetSaleType() ) then
            typeText = "RENT"
        end
        if ( IsValid(owner) ) then
            self:SetColor(Color(37,5,33))
            local propname = self:GetProperty()
            local font = "Lawlyhousing:SignDefault"
            surface.SetFont(font)
            if ( surface.GetTextSize(propname) > 440) then
                font = "Lawlyhousing:SignSmallName"
            end
            surface.SetFont(font)
            if ( surface.GetTextSize(propname) > 440) then
                font = "Lawlyhousing:SignTinyName"
            end
            surface.SetDrawColor(173,173,173)
            surface.DrawRect(-220, 0, 440, 5)
            draw.SimpleTextOutlined(self:GetProperty(), font, 0, -h / 2 + select(2, surface.GetTextSize(propname)) / 2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0.5, Color(0,0,0))
            draw.SimpleTextOutlined(self:GetPropertyOwner():Nick(), "DermaLarge", 0, h / 2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 0.5, Color(0,0,0))
        else
            local pricetext = DarkRP.formatMoney(self:GetPrice())

            self:SetColor(Color(200,0,0))
            draw.SimpleTextOutlined("FOR " .. typeText, "Lawlyhousing:SignDefault", 0, -h / 2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 0.5, Color(0,0,0))
            draw.SimpleTextOutlined(self:GetProperty(), "DermaLarge", 0, 10, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0.5, Color(0,0,0))
            if ( !self:GetSaleType() ) then
                draw.SimpleTextOutlined("Price: " .. pricetext, "DermaLarge", 0, h / 2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 0.5, Color(0,0,0))
            else
                draw.SimpleTextOutlined("Price: " .. pricetext .. "/Month", "DermaLarge", 0, h / 2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 0.5, Color(0,0,0))
            end
        end
    cam.End3D2D()
end
