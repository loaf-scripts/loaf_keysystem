if Config.Framework ~= "esx" then
    return
end

local export, ESX = pcall(function()
    return exports.es_extended:getSharedObject()
end)

if not export then
    TriggerEvent("esx:getSharedObject", function(obj)
        ESX = obj
    end)
end

function GetIdentifier(source)
    return ESX.GetPlayerFromId(source)?.identifier
end

function GetSourceFromIdentifier(identifier)
    return ESX.GetPlayerFromIdentifier(identifier)?.source
end

function GetIngameName(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    local firstName, lastName
    if xPlayer?.get and xPlayer.get("firstName") and xPlayer.get("lastName") then
        firstName = xPlayer.get("firstName")
        lastName = xPlayer.get("lastName")
    else
        local name = MySQL.Sync.fetchAll("SELECT `firstname`, `lastname` FROM `users` WHERE `identifier`=@identifier", {
            ["@identifier"] = GetIdentifier(source)
        })
        firstName, lastName = name[1]?.firstname or GetPlayerName(source), name[1]?.lastname or ""
    end

    return ("%s %s"):format(firstName, lastName)
end
