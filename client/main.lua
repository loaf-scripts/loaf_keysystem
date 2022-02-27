cache = {
    keyUsages = {}
}

CreateThread(function()
    cache.menuAlign = Config.Align or "top-right"
    while not cache.loaded do 
        Wait(500)
    end

    function GetPlayers()
        local found = {}
        for _, player in pairs(GetActivePlayers()) do
            if player ~= PlayerId() then
                local playerPed = GetPlayerPed(player)
                if #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(playerPed)) <= 5.0 then
                    local foundName, startedSearch, name = false, GetGameTimer(), GetPlayerName(player) .. " | " .. GetPlayerServerId(player)
                    
                    if Config.UseRPName then 
                        name = lib.TriggerCallbackSync("loaf_keysystem:get_name", GetPlayerServerId(player)) or name 
                    end

                    found[#found+1] = {
                        serverId = GetPlayerServerId(player),
                        name = name
                    }
                end
            end
        end
        return found
    end

    if Config.Command then
        if Config.Keybind then
            RegisterKeyMapping(Config.Command, Strings["keybind"], "keyboard", Config.Keybind)
        end
        RegisterCommand(Config.Command, OpenKeyMenu)
        TriggerEvent("chat:addSuggestion", "/"..Config.Command, Strings["keybind"], {})
    end
end)

RegisterNetEvent("loaf_keysystem:remove_key")
AddEventHandler("loaf_keysystem:remove_key", function(uniqueId)
    if not cache.keys then return print("keys have not loaded yet.") end
    for i, v in pairs(cache.keys) do
        if v.unique_id == uniqueId then
            printf("removed key %s from cache.keys, index %i", uniqueId, i)
            table.remove(cache.keys, i)
            break
        end
    end
end)

RegisterNetEvent("loaf_keysystem:add_key")
AddEventHandler("loaf_keysystem:add_key", function(keyId, uniqueId, keyData)
    if not cache.keys then return print("keys have not loaded yet.") end
    Notify(Strings["received_key"])
    printf("received key %s (%s) with data %s", keyId, uniqueId, json.encode({keyData}))
    table.insert(cache.keys, {
        key_id = keyId,
        unique_id = uniqueId,
        key_data = keyData
    })
end)

RegisterNetEvent("loaf_keysystem:openMenu")
AddEventHandler("loaf_keysystem:openMenu", function()
    OpenKeyMenu()
end)

function SetKeyUsage(keyId, cb)
    cache.keyUsages[keyId] = cb
end
exports("SetKeyUsage", SetKeyUsage)

SetKeyUsage("Test2t4", function()
    print("used key ", "Test2t4")
end)

function HasKey(keyId)
    for i, v in pairs(cache.keys) do
        if v.key_id == keyId then
            return true
        end
    end

    return false
end
exports("HasKey", HasKey)

function GetKeys()
    return cache.keys
end
exports("GetKeys", GetKeys)

function GetKey(uniqueId)
    for i, v in pairs(cache.keys) do
        if v.unique_id == uniqueId then
            return v
        end
    end
    return false
end
exports("GetKey", GetKey)

-- backwards compatibility, please do not use this event.
RegisterNetEvent("loaf_keysystem:setUsage")
AddEventHandler("loaf_keysystem:setUsage", function(keyId, cb)
    SetKeyUsage(keyId, cb)
end)

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end

    if Config.Command then
        TriggerEvent("chat:removeSuggestion", "/command")
    end
end)