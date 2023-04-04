CreateThread(function()
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

    function Notify(source, message)
        TriggerClientEvent("esx:showNotification", source, message)
    end

    function GetIdentifier(source)
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return false end
        return xPlayer.identifier
    end

    function GetIngameName(source)
        local xPlayer = ESX.GetPlayerFromId(source)
        local firstName, lastName
        if xPlayer.get and xPlayer.get("firstName") and xPlayer.get("lastName") then
            firstName = xPlayer.get("firstName")
            lastName = xPlayer.get("lastName")
        else
            local name = MySQL.Sync.fetchAll("SELECT `firstname`, `lastname` FROM `users` WHERE `identifier`=@identifier", {["@identifier"] = GetIdentifier(source)})
            firstName, lastName = name[1]?.firstname or GetPlayerName(source), name[1]?.lastname or ""
        end

        return ("%s %s"):format(firstName, lastName)
    end

    function GetSourceByIdentifier(identifier)
        local xPlayer = ESX.GetPlayerFromIdentifier(identifier)
        if xPlayer then return 
            xPlayer.source
        end
        return false
    end

    -- BACKWARDS COMPATIBILITY
    -- PLEASE DO NOT USE
    ESX.RegisterServerCallback("loaf_keysystem:getKeys", function(source, cb)
        cb(GetKeys(source))
    end)

    loaded = true
end)
