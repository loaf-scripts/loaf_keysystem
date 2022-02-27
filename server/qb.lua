CreateThread(function()
    if Config.Framework ~= "qb" then return end
    local QBCore = exports["qb-core"]:GetCoreObject()

    function Notify(source, message)
        TriggerClientEvent("QBCore:Notify", source, message)
    end

    function GetIdentifier(source)
        local qPlayer = QBCore.Functions.GetPlayer(source)
        if not qPlayer then return false end
        return qPlayer.PlayerData.citizenid
    end

    function GetIngameName(source)
        local qPlayer = QBCore.Functions.GetPlayer(source)
        return qPlayer.PlayerData.charinfo.firstname  .. " " .. qPlayer.PlayerData.charinfo.lastname
    end

    function GetSourceByIdentifier(identifier)
        local qPlayer = QBCore.Functions.GetPlayerByCitizenId(identifier)
        if qPlayer then return 
            qPlayer.PlayerData.source
        end
        return false
    end

    loaded = true
end)