if Config.Framework ~= "custom" then
    return
end

function GetIdentifier(source)
    return GetPlayerIdentifierByType(source, "license")
end

function GetSourceFromIdentifier(identifier)
    local players = GetPlayers()
    for i = 1, #players do
        local source = players[i]
        if GetIdentifier(source) == identifier then
            return source
        end
    end
end

function GetIngameName(source)
    return GetPlayerName(source) .. " | " .. source
end
