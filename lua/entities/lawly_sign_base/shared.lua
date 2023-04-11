ENT.Base = "base_gmodentity"
ENT.Type = "anim"

ENT.Spawnable = false

ENT.model = "models/hunter/plates/plate025x1.mdl"

ENT.IsSign = true

ENT.DoorList = {}

ENT.FriendList = {}

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "Price")
    self:NetworkVar("Int", 1, "DoorCount")
    self:NetworkVar("String", 0, "Property")
    self:NetworkVar("String", 1, "OriginalName")
    self:NetworkVar("Entity", 0, "PropertyOwner")
    self:NetworkVar("Bool", 0, "SaleType") //False = sale; True = rent
    self:NetworkVar("Bool", 1, "IsSaved")

    if ( SERVER ) then
        self:SetPrice(0)
        self:SetDoorCount(0)
        self:SetProperty("Un-Named")
        self:SetOriginalName("Un-Named")
        self:SetPropertyOwner(nil)
        self:SetSaleType(false)
        self:SetIsSaved(false)
    end
end