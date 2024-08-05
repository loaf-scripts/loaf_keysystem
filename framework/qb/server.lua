if Config.Framework ~= "qb-core" then
    return
end

local QB = exports["qb-core"]:GetCoreObject()

function GetIdentifier(source)
    return QB.Functions.GetPlayer(source)?.PlayerData.citizenid
end

function GetSourceFromIdentifier(identifier)
    return QB.Functions.GetPlayerByCitizenId(identifier)?.PlayerData.source
end

function GetIngameName(source)
    local charinfo = QB.Functions.GetPlayer(source)?.PlayerData.charinfo
    if not charinfo then
        return GetPlayerName(source) .. " | " .. source
    end

    return charinfo.firstname .. " " .. charinfo.lastname
end
