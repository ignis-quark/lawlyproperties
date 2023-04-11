local savelocation = "lawlyhousing/" .. game.GetMap() .. "/"
local savefilename = "signinfo.txt"

local saveTable = {}

util.AddNetworkString("lawlyhousing_save_signs")
util.AddNetworkString("lawlyhousing_reload_signs")

local function SaveAllSigns()
    local signcount = 0
    local doorcount = 0
    for _, sign in ipairs(ents.GetAll()) do
        if !IsValid(sign) or !sign.IsSign then continue end
        if #sign:GetDoors() <= 0 then continue end
        doorcount = #sign:GetDoors() + doorcount
        local name = sign:GetOriginalName()
        local class = sign:GetClass()
        local pos = sign:GetPos()
        local ang = sign:GetAngles()
        local doors = {}
        for _, i in ipairs(sign:GetDoors()) do
            local doorEnt = Entity(i)
            if !IsValid(doorEnt) or !doorEnt:CreatedByMap() then continue end
            table.insert(doors, doorEnt:MapCreationID())
        end
        local price = sign:GetPrice()
        local signtype = sign:GetSaleType()

        local signtable = {name, class, pos, ang, doors, price, signtype}
        table.insert(saveTable, signtable)
        sign:SetIsSaved(true)
        signcount = signcount + 1
    end

    MsgN("[Lawlyhousing] Saving data for ", signcount, " signs, and ", doorcount, " doors...")
    local jsontable = util.TableToJSON(saveTable, true)
    if !file.Exists(savelocation, "DATA") then file.CreateDir(savelocation, "DATA") end
    file.Write(savelocation .. savefilename, jsontable)
    MsgN("Done!")
    table.Empty(saveTable)
end

local function LoadSignsFromFile()
    if !file.Exists(savelocation .. savefilename, "DATA") then
        MsgN("[Lawlyhousing] No save file present, skipping.")
        return
    end
    local jsontable = file.Read(savelocation .. savefilename)
    local signtable = util.JSONToTable(jsontable)
    for _, sign in ipairs(signtable) do
        local name = sign[1]
        local class = sign[2]
        local pos = sign[3]
        local ang = sign[4]
        local doors = sign[5]
        local price = sign[6]
        local signtype = sign[7]

        local doorIndex = {}
        for _, i in ipairs(doors) do
            local ent = ents.GetMapCreatedEntity(i)
            if !IsValid(ent) then continue end
            table.insert(doorIndex, ent:EntIndex())
        end

        if sign[7] == nil then
            signType = false
        end
        local newsign = ents.Create(class)
        newsign:SetPos(pos)
        newsign:SetAngles(ang)
        newsign:Spawn()
        newsign:AssignVars(doorIndex, name, price, signtype)
        newsign:SetIsSaved(true)
    end
    MsgN("[Lawlyhousing] Successfuly loaded ", #signtable, " signs.")
end

local function ReloadAllSigns()
    for _, sign in ipairs(ents.GetAll()) do
        if !IsValid(sign) or !sign.IsSign or !sign:GetIsSaved() then continue end
        if #sign:GetDoors() <= 0 then continue end
        sign:Remove()
    end
    timer.Simple(1, function()
        LoadSignsFromFile()
    end)
end

net.Receive("lawlyhousing_save_signs", function(len, ply)
    if !IsValid(ply) or !ply:IsAdmin() then return end
    MsgN("[Lawlyhousing] Player ", ply:Nick(), " is saving sign data...")
    SaveAllSigns()
    DarkRP.notify(ply, 0, 5, "Saved sign data.")
end)

net.Receive("lawlyhousing_reload_signs", function(len, ply)
    if !IsValid(ply) or !ply:IsAdmin() then return end
    MsgN("[Lawlyhousing] Player ", ply:Nick(), " is reloading all sign data...")
    ReloadAllSigns()
    DarkRP.notify(ply, 0, 5, "Re-Loaded sign data.")
end)

hook.Add("InitPostEntity", "lawlhousing_generate_signs_postentity", LoadSignsFromFile)

hook.Add("PostCleanupMap", "lawlhousing_generate_signs_postmapcleanup", LoadSignsFromFile)
