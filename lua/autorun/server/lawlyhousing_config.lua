LAWLYHOUSING = LAWLYHOUSING or {}

LAWLYHOUSING.MaxOwnedProperies = 2
LAWLYHOUSING.SellReturn = 0.75
LAWLYHOUSING.RentTime = 3600


hook.Add("playerSellDoor", "lawlyhousing_catch_door_sale", function(ply, ent)
	local entindex = ent:EntIndex()
    for _, doorsign in ipairs(ents.GetAll()) do
        if not doorsign.IsSign then continue end
        for _, doorindex in ipairs(doorsign:GetDoors()) do
            if doorindex == entindex then
                doorsign:SellProperty()
                return false, "Held by sign." end
        end
    end
end)