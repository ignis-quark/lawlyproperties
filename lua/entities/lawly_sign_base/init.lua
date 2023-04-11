AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

util.AddNetworkString("lawlyhousing_send_data_to_server")
util.AddNetworkString("lawlyhousing_open_client_menu")
util.AddNetworkString("lawlyhousing_update_sign_friends")
util.AddNetworkString("lawlyhousing_purchase_house_from_menu")
util.AddNetworkString("lawlyhousing_update_house_name")
util.AddNetworkString("lawlyhousing_remove_player_admin")

function ENT:Initialize()
	self:SetModel(self.model)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	self:GetPhysicsObject():EnableMotion(false)
	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
end

function ENT:Think()
	if self:ValidateOwner() then
		self:CheckRent()
	end

	//This doesn't need to run every tick, and there will be quite a few signs.
	self:NextThink(CurTime() + 5)
	return true
end

function ENT:InvalidateDoors()
	self:SellProperty()
end

ENT.RentTime = 0

function ENT:ValidateOwner()
	if IsValid(self:GetPropertyOwner()) then return true end

	self:RemovePlayersFromDoors()
	self:SetPropertyOwner(nil)
	return false
end

function ENT:CheckRent()
	if !self:GetSaleType() or self.RentTime > CurTime() then return end

	local ply = self:GetPropertyOwner()
	if !IsValid(ply) then return end
	if ply:getDarkRPVar("money") <= 0 then
		self:SellProperty(false, true)
	else
		ply:addMoney(-self:GetPrice())
		DarkRP.notify(ply, 0, 5, "Spent " .. DarkRP.formatMoney(self:GetPrice()) .. " on property rent.")

		self.RentTime = CurTime() + LAWLYHOUSING.RentTime
	end
end

net.Receive("lawlyhousing_send_data_to_server", function(len, ply)
	local ent = net.ReadEntity()
	local name = net.ReadString()
	local price = net.ReadInt(32)
	local doorList = net.ReadTable()
	local typeval = net.ReadBool()
	if !IsValid( ent ) or !ent:CanPlyEdit(ply) then MsgN("[Lawlyhousing] Could not verify info!") return end
	if string.len(name) <= 0 then name = "Un-Named" end
	if price < 0 then price = 0 end

	if ( !IsValid(ent) or !ent.AssignVars ) then
		MsgN("[LAWLYHOUSING WARNING] WARNING! Recieved net comm from [" .. ply:Nick() .. "] but entity verification is not valid!")
		MsgN(ent:EntIndex(), " ", ent:GetClass())
		return
	end
	ent:AssignVars(doorList, name, price, typeval)
end )

net.Receive("lawlyhousing_update_sign_friends", function(len, ply)
	local ent = net.ReadEntity()
	local ls = net.ReadTable()
	if !IsValid( ent ) or !ent:CanPlyEdit(ply) then return end
	ent:UpdateCoOwners(ply, ls)
end)

ENT.LastPurchaseTime = 0

//Comes from the buyBtn in the client menu
net.Receive("lawlyhousing_purchase_house_from_menu", function(len, ply)
	local ent = net.ReadEntity()
	if !IsValid( ent ) then return end
	if ent.LastPurchaseTime > CurTime() then
		DarkRP.notify(ply, 0, 5, "Please wait " .. math.ceil(ent.LastPurchaseTime - CurTime()) .. " seconds to do that again.")
		return
	end
	ent.LastPurchaseTime = CurTime() + 5
	ent:MakePurchase(ply)
end)

//Comes from the nameBtn in the client menu
net.Receive("lawlyhousing_update_house_name", function(len, ply)
	local ent = net.ReadEntity()
	local name = net.ReadString()
	if !IsValid( ent ) or !ent:CanPlyEdit(ply) then return end
	if #name > 0 and ent:CanPlyEdit(ply) then
		ent:SetProperty(name)
		DarkRP.notify(ply, 0, 5, "Updated property name to \"" .. name .. "\"!")
	end
end)

net.Receive("lawlyhousing_remove_player_admin", function(len, ply)
	local ent = net.ReadEntity()
	if !IsValid( ent ) or !ent:CheckIfAdmin(ply) then return end
	DarkRP.notify(ply, 0, 5, "Removed owner from property.")
	ent:AdminRemovePlayer()
end)

function ENT:CanPlyEdit(ply)
	return ply == self:GetPropertyOwner() or self:CheckIfAdmin(ply)
end

function ENT:AssignVars(ls, name, price, typeval)
	self:Reset()
	if #name <= 0 then
		MsgN("[Lawlyhousing] Sign is missing name!")
		return
	end

	self:SetSaleType(typeval)
	self:SetProperty(name)
	self:SetOriginalName(name)
	self:SetPrice(price)

	if #ls > 0 then
		self:SetDoors(ls)
	end

	self:MakeDoorsUnownable(true)

	MsgN("[Lawlyhousing] Wrote values to \"", self:GetClass(), "\" [", self:EntIndex(), "]")
	MsgN("Name:  ", name)
	MsgN("Price: ", price)
	MsgN("Doors: ", #ls)
end

function ENT:SetDoors(list)
	self:SetDoorCount(#list)
	self.DoorList = table.Copy( list )
end

function ENT:GetDoors()
	return self.DoorList
end

function ENT:UpdateCoOwners(ply, ls)
	for _, door in ipairs(self.DoorList) do
		local ent = Entity( door )
		ent:removeAllKeysExtraOwners()
		for _, addply in ipairs(ls) do
			if !IsValid(addply) or !addply:IsPlayer() then continue end
			ent:addKeysDoorOwner(addply)
		end
	end
end
// @TODO :: Replace with a permission-friendly function
function ENT:CheckIfAdmin(ply)
	return ply:IsAdmin()
end

function ENT:CheckPurchase(ply)
	local OwnedProperties = 0
	for _, ent in ipairs(ents.GetAll()) do
		if !ent.IsSign then continue end
		if ent:GetPropertyOwner() == ply then
			OwnedProperties = OwnedProperties + 1
		end
	end

	if OwnedProperties >= LAWLYHOUSING.MaxOwnedProperies then
		DarkRP.notify(ply, 0, 5, "You already own the maximum number of properties!")
		return true
	elseif ply:getDarkRPVar("money") < self:GetPrice() then
		DarkRP.notify(ply, 0, 5, "You do not have enough money to purchase this property!")
		return true
	else
		return false
	end
	return false
end

function ENT:PurchaseProperty(ply)
	self.RentTime = CurTime() + LAWLYHOUSING.RentTime
	self:SetPropertyOwner(ply)

	for _, door in ipairs(self.DoorList) do
		Entity(door):keysOwn(ply)
		Entity(door):keysLock()
	end

	ply:addMoney(-self:GetPrice())
	local purchaseTypeName = "purchase"
	if self:GetSaleType() then
		purchaseTypeName = "rent"
	end
	DarkRP.notify(ply, 0, 5, "Spent " .. DarkRP.formatMoney(self:GetPrice()) .. " on property " .. purchaseTypeName .. ".")
end

function ENT:MakeDoorsUnownable(val)
	for _, door in ipairs(self.DoorList) do
		local ent = Entity ( door )
		ent:setKeysNonOwnable(val)
	end
end

function ENT:RemovePlayersFromDoors()
	for _, door in ipairs(self.DoorList) do
		local ent = Entity( door )
		ent:keysUnOwn(ent:getDoorOwner())
		ent:removeAllKeysExtraOwners()
		ent:removeAllKeysAllowedToOwn()
		ent:keysUnLock()
	end
end

function ENT:SellProperty(forced, rentNoMoney)
	local propOwner = self:GetPropertyOwner()
	local forced = forced or false
	local rentNoMoney = rentNoMoney or false
	if !IsValid(propOwner) then return end
	self:SetPropertyOwner(nil)
	self:SetProperty(self:GetOriginalName())

	self:RemovePlayersFromDoors()

	local saleAmount = math.floor(self:GetPrice()*LAWLYHOUSING.SellReturn)

	if !self:GetSaleType() then
		propOwner:addMoney(saleAmount)
	end

	if forced then
		DarkRP.notify(propOwner, 0, 5, "You were forcibly removed from a property by a staff member.")
	elseif rentNoMoney then
		DarkRP.notify(propOwner, 0, 5, "You did not have sufficient fund to pay for the next rent.")
	else
		if self:GetSaleType() then
			DarkRP.notify(propOwner, 0, 5, "Terminated Lease.")
		else
			DarkRP.notify(propOwner, 0, 5, "Sold Property for " .. DarkRP.formatMoney(saleAmount) .. ".")
		end
	end
end

function ENT:AdminRemovePlayer()
	self:SellProperty(true)
end

function ENT:MakePurchase(ply)
	if IsValid(self:GetPropertyOwner()) then
		if self:GetPropertyOwner() == ply then
			self:SellProperty()
			return
		end

		DarkRP.notify(ply, 0, 5, "You do not own this property!")
		return
	end

	if #self.DoorList <= 0 then
		DarkRP.notify(ply, 0, 5, "There are no doors on this property! Please notify a staff member.")
		return
	end

	if self:CheckPurchase(ply) then
		return
	end

	self:PurchaseProperty(ply)
	return
end

function ENT:Reset()
	self:RemovePlayersFromDoors()
	table.Empty(self.DoorList)
	self:SetPrice(0)
	self:SetProperty("Un-Named")
	self:SetPropertyOwner(nil)
end

function ENT:OnRemove()
	if !self.DoorList then return end
	self:MakeDoorsUnownable(false)
	self:Reset()
end


function ENT:OpenMenu(ply)
	net.Start("lawlyhousing_open_client_menu")
		net.WriteEntity(self)
		net.WriteBool(self:CheckIfAdmin(ply))
	net.Send(ply)
end

function ENT:Use(ply)
	if ( !IsValid(ply) or !ply:IsPlayer() ) then return end
	if ( team.GetName(ply:Team()) == "Hobo" ) then return end
	self:OpenMenu(ply)
end
