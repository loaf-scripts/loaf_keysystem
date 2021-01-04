ESX = nil

TriggerEvent("esx:getSharedObject", function(obj) 
    ESX = obj 
end)

local debugging = true
local debugprint = function(text)
    print(string.format("^1[%s - DEBUG]^0: %s", GetCurrentResourceName(), text))
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

GenerateKey = function(source, key, name)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer and xPlayer.identifier then
        local found, id = false, GenerateId(15)
        
        while not found do
            local doingQuery = true
            MySQL.Async.fetchScalar("SELECT `unique_id` FROM `unique_keys` WHERE `unique_id` = @id", {
                ["@id"] = id
            }, function(result)
                if result == nil then
                    MySQL.Async.execute("INSERT INTO `unique_keys` (`unique_id`) VALUES (@id)", {
                        ["@id"] = id
                    })

                    found = true
                    debugprint("Found a unique id: " .. id)
                else
                    debugprint("Id was taken: " .. id)
                end
                doingQuery = false
            end)

            while doingQuery do
                Wait(50)
            end

            Wait(50)
        end

        local doingQuery = true

        MySQL.Async.fetchScalar("SELECT `keys` FROM `loaf_keys` WHERE `identifier` = @id", {
            ["@id"] = xPlayer.identifier
        }, function(result)
            local keys, hadKey = {}
            if result ~= nil then
                keys = json.decode(result)
                debugprint("Had keys: " .. result)
                hadKey = true
            end

            local toadd = {
                unique_id = id,
                key_id = key
            }

            if name and type(name) == "string" then
                toadd.name = name
            end

            table.insert(keys, toadd)

            if not hadKey then
                MySQL.Async.execute("INSERT INTO `loaf_keys` (`identifier`, `keys`) VALUES (@identifier, @key)", {
                    ["@identifier"] = xPlayer.identifier, 
                    ["@key"] = json.encode(keys)
                })
                debugprint("Inserted inte keys for '" .. xPlayer.identifier .. "': " .. json.encode(keys))
            else
                MySQL.Async.execute("UPDATE `loaf_keys` SET `keys`=@key WHERE `identifier`=@identifier", {
                    ["@identifier"] = xPlayer.identifier, 
                    ["@key"] = json.encode(keys)
                })
                debugprint("Updated keys to: " .. json.encode(keys))
            end
            doingQuery = false
        end)

        while doingQuery do
            Wait(50)
        end

        -- MySQL.Async.execute("INSERT INTO `loaf_keys` (`identifier`, `keys`) VALUES (@identifier, @timeleft)",{['@identifier'] = identifier, ['timeleft'] = 0})

        return id
    else
        return false
    end
end

RemoveKey = function(source, unique_id)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer and xPlayer.identifier and unique_id and type(unique_id) == "string" then

        local doingQuery, toReturn = true, false
        MySQL.Async.fetchScalar("SELECT `keys` FROM `loaf_keys` WHERE `identifier` = @id", {
            ["@id"] = xPlayer.identifier
        }, function(result)
            if result then
                local keys = json.decode(result)
                if keys then
                    local new_keys = {}
                    for k, v in pairs(keys) do
                        if v.unique_id ~= unique_id then
                            table.insert(new_keys, v)
                        end
                    end

                    MySQL.Async.execute("UPDATE `loaf_keys` SET `keys`=@key WHERE `identifier`=@identifier", {
                        ["@identifier"] = xPlayer.identifier, 
                        ["@key"] = json.encode(new_keys)
                    }, function()
                        debugprint("Removed key for user: " .. unique_id)
                        MySQL.Async.execute("DELETE FROM `unique_keys` WHERE `unique_id`=@id", {
                            ["@id"] = unique_id
                        }, function()
                            debugprint("Deleted from unique_keys: " .. unique_id)
                            doingQuery = false
                            toReturn = true
                        end)
                    end)
                else
                    doingQuery = false
                end
            else
                ddoingQuery = false
            end
        end)

        while doingQuery do
            Wait(50)
        end

        return toReturn
    else
        return false
    end
end

GetKeys = function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer and xPlayer.identifier then

        local doingQuery, toReturn = true, false
        MySQL.Async.fetchScalar("SELECT `keys` FROM `loaf_keys` WHERE `identifier` = @id", {
            ["@id"] = xPlayer.identifier
        }, function(result)
            if result then
                local keys = json.decode(result)
                if keys then
                    toReturn = keys
                else
                    toReturn = {}
                end
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

TransferKey = function(old, new, unique_id)
    local oldPlayer, newPlayer = ESX.GetPlayerFromId(old), ESX.GetPlayerFromId(new)
    if oldPlayer and newPlayer and oldPlayer.identifier and newPlayer.identifier and unique_id and type(unique_id) == "string" then
        local toReturn, doingQuery = false, true

        MySQL.Async.fetchScalar("SELECT `keys` FROM `loaf_keys` WHERE `identifier` = @id", {
            ["@id"] = oldPlayer.identifier
        }, function(result)
            if result then
                local keys = json.decode(result)
                local oldkeydata = false
                if keys then
                    for k, v in pairs(keys) do
                        if v.unique_id == unique_id then
                            oldkeydata = v
                            break
                        end
                    end
                end

                if keys and oldkeydata then

                    local new_keys_previous = {} -- new table for previous owner
                    for k, v in pairs(keys) do
                        if v.unique_id ~= unique_id then
                            table.insert(new_keys_previous, v)
                        end
                    end
                    
                    MySQL.Async.fetchScalar("SELECT `keys` FROM `loaf_keys` WHERE `identifier` = @id", {
                        ["@id"] = newPlayer.identifier
                    }, function(result)
                        new_keys_new = {}

                        if result then
                            local keys1 = json.decode(result)
                            for k, v in pairs(keys1) do
                                table.insert(new_keys_new, v)
                            end
                        end

                        table.insert(new_keys_new, oldkeydata)

                        MySQL.Async.execute("UPDATE `loaf_keys` SET `keys`=@key WHERE `identifier`=@identifier", {
                            ["@identifier"] = oldPlayer.identifier, 
                            ["@key"] = json.encode(new_keys_previous)
                        }, function()
                            debugprint("Removed key from old owner.")

                            if result then
                                MySQL.Async.execute("UPDATE `loaf_keys` SET `keys`=@key WHERE `identifier`=@identifier", {
                                    ["@identifier"] = newPlayer.identifier, 
                                    ["@key"] = json.encode(new_keys_new)
                                }, function()
                                    debugprint("Added key to new owner.")
                                    toReturn = true
                                    doingQuery = false
                                end)
                            else
                                MySQL.Async.execute("INSERT INTO `loaf_keys` (`identifier`, `keys`) VALUES (@identifier, @key)", {
                                    ["@identifier"] = newPlayer.identifier, 
                                    ["@key"] = json.encode(new_keys_new)
                                }, function()
                                    debugprint("Inserted key to new owner.")
                                    toReturn = true
                                    doingQuery = false
                                end)
                            end
                        end)
                    end)

                else
                    debugprint("Didn't have key with id: " .. unique_id)
                    doingQuery = false
                end
            else
                debugprint("No keys.")
                doingQuery = false
            end
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
AddEventHandler("generateKey", function(playerid, key, name, cb)
    local src = source
    
    if type(src) == "string" then -- if it was triggered by the server
        if playerid and type(playerid) == "number" and key and type(key) == "string" then
            GenerateKey(playerid, key, name)
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

ESX.RegisterServerCallback('loaf_keysystem:transferKey', function(src, cb, playerid, unique_id)
    if playerid and unique_id then
        cb(TransferKey(src, playerid, unique_id))
    else
        cb(false)
    end
end)

-- TriggerEvent("generateKey", 1, "house_2", "Husnyckel 2 :)", function()
--     TriggerEvent("getKeys", 1, function(keys)
--         if keys then
--             for k, v in pairs(keys) do
--                 local doing = true
--                 TriggerEvent("removeKey", 1, k, function()
--                     doing = false
--                 end)
--                 while doing do Wait(50) end
--             end
--         end
--     end)
-- end)

-- print(GenerateId(10))

-- print(GenerateKey(1, "test"))
