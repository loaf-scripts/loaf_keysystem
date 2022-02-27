CreateThread(function()
    if Config.Framework ~= "qb" then return end
    while not NetworkIsSessionStarted() do
        Wait(500)
    end

    local QBCore
    while not QBCore do
        Wait(500)
        QBCore = exports["qb-core"]:GetCoreObject()
        print("waiting for qb to load")
    end
    while not QBCore.Functions.GetPlayerData() or not QBCore.Functions.GetPlayerData().job do
        Wait(500)
        print("waiting for qb to load")
    end

    lib = exports["loaf_lib"]:GetLib()

    local keys = lib.TriggerCallbackSync("loaf_keysystem:fetch_keys")
    printf("fetched all keys: %s", json.encode(keys, {indent=true}))
    for i, v in pairs(keys) do
        if type(v.key_data) == "string" then 
            v.key_data = json.decode(v.key_data) 
        end
    end
    cache.keys = keys

    function Notify(msg)
        QBCore.Functions.Notify(msg)
    end

    RegisterNetEvent("loaf_keysystem:menu:use_key")
    AddEventHandler("loaf_keysystem:menu:use_key", function(uniqueId)
        local key = GetKey(uniqueId)
        if not key then return end

        local keyData = key.key_data
        if keyData.eventname and keyData.eventtype then
            if keyData.eventtype == "server" then
                TriggerServerEvent(keyData.eventname, keyData)
            elseif keyData.eventtype == "client" then
                TriggerEvent(keyData.eventname, keyData)
            end
        end

        if cache.keyUsages[key.key_id] then 
            cache.keyUsages[key.key_id](key) 
        end
    end)

    RegisterNetEvent("loaf_keysystem:menu:confirm_transfer")
    AddEventHandler("loaf_keysystem:menu:confirm_transfer", function(data)
        local playerName, serverId, uniqueId = table.unpack(data)
        local key = GetKey(uniqueId)
        if not key then return end

        exports["qb-menu"]:openMenu({
            {
                header = Strings["confirm_give"]:format(playerName),
                txt = key.key_data.name,
                isMenuHeader = true
            },
            {
                header = Strings["yes"],
                params = {
                    event = function()
                        lib.TriggerCallback("loaf_keysystem:transfer_key", function(success)
                            if not success then
                                Notify(Strings["couldnt_transfer"])
                            else
                                Notify(Strings["transferred"]:format(key.key_data.name, playerName))
                            end
                        end, uniqueId, serverId)
                    end,
                    isAction = true
                },
            },
            {
                header = Strings["no"]
            }
        })
    end)
    RegisterNetEvent("loaf_keysystem:menu:transfer_key")
    AddEventHandler("loaf_keysystem:menu:transfer_key", function(uniqueId)
        local key = GetKey(uniqueId)
        if not key then return end

        local elements, nearbyPlayers = {
            {
                header = Strings["transfer_nearby"],
                txt = key.key_data.name,
                isMenuHeader = true
            }
        }, GetPlayers()
        for i, v in pairs(nearbyPlayers) do
            elements[i+1] = {
                header = Strings["give_to"]:format(v.name, v.serverId),
                params = {
                    event = "loaf_keysystem:menu:confirm_transfer",
                    args = {
                        v.name,
                        v.serverId,
                        uniqueId
                    }
                }
            }
        end
        exports["qb-menu"]:openMenu(elements)
    end)
    
    RegisterNetEvent("loaf_keysystem:menu:delete_key")
    AddEventHandler("loaf_keysystem:menu:delete_key", function(uniqueId)
        local key = GetKey(uniqueId)
        if not key then return end

        exports["qb-menu"]:openMenu({
            {
                header = Strings["confirm_delete"]:format(key.key_data.name),
                txt = key.key_data.name,
                isMenuHeader = true
            },
            {
                header = Strings["yes"],
                params = {
                    event = function()
                        lib.TriggerCallback("loaf_keysystem:remove_key", function(success)
                            if not success then 
                                Notify(Strings["couldnt_delete"]) 
                            else
                                Notify(Strings["deleted"]:format(key.key_data.name))
                            end
                        end, uniqueId)
                    end,
                    isAction = true
                },
            },
            {
                header = Strings["no"]
            }
        })
    end)

    RegisterNetEvent("loaf_keysystem:menu:specific_keymenu")
    AddEventHandler("loaf_keysystem:menu:specific_keymenu", function(uniqueId)
        local key = GetKey(uniqueId)
        if not key then return end

        local keyData = key.key_data
        local elements = {
            {
                header = keyData.name,
                isMenuHeader = true
            }
        }

        if keyData.eventname or cache.keyUsages[key.key_id] then
            table.insert(elements, {
                header = Strings["use_key"],
                params = {
                    event = "loaf_keysystem:menu:use_key",
                    args = uniqueId
                }
            })
        end
        table.insert(elements, {
            header = Strings["transfer_nearby"],
            params = {
                event = "loaf_keysystem:menu:transfer_key",
                args = uniqueId
            }
        })
        table.insert(elements, {
            header = Strings["delete_key"],
            params = {
                event = "loaf_keysystem:menu:delete_key",
                args = uniqueId
            }
        })

        exports["qb-menu"]:openMenu(elements)
    end)

    function OpenKeyMenu()
        if #cache.keys == 0 then
            return Notify(Strings["no_keys"])
        end
        local elements = {
            {
                header = Strings["main_menu"],
                isMenuHeader = true
            }
        }
        for i, v in pairs(cache.keys) do
            elements[i+1] = {
                header = v.key_data.name,
                txt = v.key_id,
                params = {
                    event = "loaf_keysystem:menu:specific_keymenu",
                    args = v.unique_id
                }
            }
        end
        exports["qb-menu"]:openMenu(elements)
    end

    cache.loaded = true
end)