ESX = nil

TriggerEvent("esx:getSharedObject", function(obj) 
    ESX = obj 
end)

local debugging = true
local debugprint = function(text)
    if debugging then
        print(string.format("^1[%s - DEBUG]^0: %s", GetCurrentResourceName(), text))
    end
end

GenerateId = function(length, disableCharacters, disableNumbers, disableUppercase)
    local id = ""

    for i = 1, length do
        local randomChar = ""

        if not disableCharacters then
            randomChar = string.char(math.random(122-97) + 97) -- random character a-z
        end

        if math.random(1, 2) == 1 and not disableNumbers or (disableCharacters and not disableNumbers) then
            randomChar = tostring(math.random(0, 9)) -- 50% chance that it is a number
        end

        if math.random(1, 2) == 1 and not disableUppercase then
            randomChar = randomChar:upper() -- 50% chance that it is uppercase
        end

        id = id .. randomChar
    end

    debugprint("Generated id: " .. id)

    return id
end

GenerateKey = function(source, key, name, eventtype, eventname)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer and xPlayer.identifier then
        local found, id = false, GenerateId(15)
        
        while not found do
            local doingQuery = true
            MySQL.Async.fetchScalar("SELECT `unique_id` FROM `loaf_keys` WHERE `unique_id` = @id", {
                ["@id"] = id
            }, function(result)
                if result == nil then
                    local key_data = {
                        name = name or key,
                        key_id = key,
                        unique_id = id,
                    }

                    if eventtype and eventname and type(eventtype) == "string" and type(eventname) == "string" then
                        key_data.eventtype = eventtype
                        key_data.eventname = eventname
                        debugprint("Generating with eventtype & eventname.")
                    else
                        debugprint("Generating without eventtype & eventname.")
                    end

                    MySQL.Async.execute("INSERT INTO `loaf_keys` (`unique_id`, `key_id`, `identifier`, `key_data`) VALUES (@id, @key_id, @identifier, @data)", {
                        ["@id"] = id,
                        ["@key_id"] = key,
                        ["@identifier"] = xPlayer.identifier,
                        ["@data"] = json.encode(key_data)
                    })

                    xPlayer.showNotification(Strings["recieved_key"])

                    found = true
                    debugprint("Inserted into the database with unique id: " .. id)
                end
                doingQuery = false
            end)

            while doingQuery do
                Wait(50)
            end

            Wait(50)
        end

        return id
    else
        return false
    end
end

RemoveKey = function(unique_id)
    MySQL.Async.execute("DELETE FROM `loaf_keys` WHERE `unique_id` = @id", {
        ["@id"] = unique_id,
    })
    return true
end

GetKeys = function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer and xPlayer.identifier then

        local doingQuery, toReturn = true, false
        MySQL.Async.fetchAll("SELECT `unique_id`, `key_id`, `key_data` FROM `loaf_keys` WHERE `identifier` = @identifier", {
            ["@identifier"] = xPlayer.identifier
        }, function(result)
            if result and type(result) == "table" then
                toReturn = result
            else
                toReturn = {}
            end
            doingQuery = false
        end)

        while doingQuery do
            Wait(50)
        end

        return toReturn
    else
        return {}
    end
end

TransferKey = function(old, new, unique_id)
    local oldPlayer, newPlayer = ESX.GetPlayerFromId(old), ESX.GetPlayerFromId(new)
    if oldPlayer and newPlayer and oldPlayer.identifier and newPlayer.identifier and unique_id and type(unique_id) == "string" then
        local toReturn, doingQuery = false, true

        MySQL.Async.fetchScalar("SELECT `identifier` FROM `loaf_keys` WHERE `unique_id` = @id", {
            ["@id"] = unique_id
        }, function(result)
            if result and result == oldPlayer.identifier then
                MySQL.Sync.execute("UPDATE `loaf_keys` set `identifier`=@new_identifier WHERE `identifier`=@old_identifier AND `unique_id`=@unique_id", {
                    ["@new_identifier"] = newPlayer.identifier,
                    ["@old_identifier"] = oldPlayer.identifier,
                    ["@unique_id"] = unique_id
                })
                toReturn = true
            end
            
            doingQuery = false
        end)

        while doingQuery do 
            Wait(50) 
        end

        return toReturn
    else
        return false
    end
end

RegisterNetEvent("generateKey")
AddEventHandler("generateKey", function(playerid, key, name, eventtype, eventname, cb)
    local src = source
    
    if type(src) == "string" then -- if it was triggered by the server
        if playerid and type(playerid) == "number" and key and type(key) == "string" then
            GenerateKey(playerid, key, name, eventtype, eventname)
            if cb then cb(GetKeys(playerid)) end
        end
    end
end)

RegisterNetEvent("getKeys")
AddEventHandler("getKeys", function(playerid, cb)
    local src = source
    
    if type(src) == "string" then -- if it was triggered by the server
        if playerid and type(playerid) == "number" then
            if cb then cb(GetKeys(playerid)) end
        end
    end
end)

RegisterNetEvent("removeKey")
AddEventHandler("removeKey", function(playerid, key, cb)
    local src = source
    if type(src) == "string" then -- if it was triggered by the server
        if playerid and type(playerid) == "number" and key and type(key) == "string" then
            RemoveKey(playerid, key)
            if cb then cb(GetKeys(playerid)) end
        end
    end
end)

RegisterNetEvent("removeAllKeys")
AddEventHandler("removeAllKeys", function(key)
    local src = source
    if type(src) == "string" then -- if it was triggered by the server
        if key and type(key) == "string" then
            MySQL.Async.execute("DELETE FROM `loaf_keys` WHERE `key_id` = @key", {
                ["@key"] = key
            })
        end
    end
end)

ESX.RegisterServerCallback("loaf_keysystem:removeKey", function(src, cb, unique_id)
    local xPlayer = ESX.GetPlayerFromId(src)

    if xPlayer and xPlayer.identifier and unique_id and type(unique_id) == "string" then

        local toReturn, doingQuery = false, true

        MySQL.Async.fetchScalar("SELECT `identifier` FROM `loaf_keys` WHERE `unique_id` = @id", {
            ["@id"] = unique_id
        }, function(result)
            if result and result == xPlayer.identifier then
                RemoveKey(unique_id)
                toReturn = true
            end
            
            doingQuery = false
        end)

        while doingQuery == true do
            Wait(50)
        end
        
        cb(toReturn)
    end
end)

ESX.RegisterServerCallback("loaf_keysystem:getKeys", function(src, cb)
    cb(GetKeys(src))
end)

ESX.RegisterServerCallback("loaf_keysystem:getRpName", function(src, cb, player)
    local xPlayer = ESX.GetPlayerFromId(player)
    if xPlayer then
        if Config.EnableESXIdentity then
            cb(xPlayer.get('firstName') .. " " .. xPlayer.get('lastName'))
        else
            cb(false)
        end
    else
        cb(false)
    end
end)

ESX.RegisterServerCallback("loaf_keysystem:transferKey", function(src, cb, playerid, unique_id)
    if playerid and unique_id then
        cb(TransferKey(src, playerid, unique_id))
    else
        cb(false)
    end
end)
