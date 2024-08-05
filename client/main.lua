local keys = {}
KeyUsages = {}

local function findKey(k, v)
    for i = 1, #keys do
        if keys[i][k] == v then
            return i
        end
    end
end

RegisterNetEvent("loaf_keysystem:add_key", function(keyId, uniqueId, keyData)
    Notify(L("received_key"))
    printf("received key %s (%s) with data %s", keyId, uniqueId, json.encode(keyData, { indent = true }))

    keys[#keys+1] = {
        key_id = keyId,
        unique_id = uniqueId,
        key_data = keyData
    }
end)

local function removeFromCache(uniqueId)
    local index = findKey("unique_id", uniqueId)
    if not index then
        printf("remove_key: key %s not found", uniqueId)
        return
    end

    printf("removed key %s", uniqueId)

    table.remove(keys, index)
end

RegisterNetEvent("loaf_keysystem:remove_key", removeFromCache)

RegisterNetEvent("loaf_keysystem:remove_all_keys", function(keyId)
    for i = 1, #keys do
        if keys[i].key_id == keyId then
            printf("removed key %s", keys[i].unique_id)
            table.remove(keys, i)
        end
    end
end)

function RefreshKeys()
    keys = lib.TriggerCallbackSync("loaf_keysystem:fetch_keys")
end

CreateThread(function()
    while not Loaded do
        Wait(250)
    end

    RefreshKeys()
end)

function DeleteKey(uniqueId)
    local success = lib.TriggerCallbackSync("loaf_keysystem:remove_key", uniqueId)

    if success then
        removeFromCache(uniqueId)
    end

    return success
end

function TransferKey(uniqueId, transferTo)
    local success = lib.TriggerCallbackSync("loaf_keysystem:transfer_key", uniqueId, transferTo)

    if success then
        removeFromCache(uniqueId)
    end

    return success
end

-- Exports
local function setKeyUsage(keyId, cb)
    KeyUsages[keyId] = cb
end

local function hasKey(keyId)
    return findKey("key_id", keyId) ~= nil
end

local function getKeys()
    return keys
end

local function getKey(uniqueId)
    local index = findKey("unique_id", uniqueId)
    if not index then
        return false
    end

    return keys[index]
end

function UseKey(uniqueId)
    local key = getKey(uniqueId)
    if not key then
        return false
    end

    local keyData = key.key_data
    if keyData.eventname then
        if keyData.eventtype == "server" then
            TriggerServerEvent(keyData.eventname, keyData)
        elseif keyData.eventtype == "client" then
            TriggerEvent(keyData.eventname, keyData)
        else
            print("invalid eventtype: " .. keyData.eventtype)
        end
    end

    if KeyUsages[key.key_id] then
        KeyUsages[key.key_id](key)
    end
end

exports("SetKeyUsage", setKeyUsage)
exports("HasKey", hasKey)
exports("GetKeys", getKeys)
exports("GetKey", getKey)
exports("UseKey", UseKey)

RegisterNetEvent("loaf_keysystem:setUsage", setKeyUsage)

RegisterNetEvent("loaf_keysystem:openMenu", function()
    if OpenKeyMenu then
        OpenKeyMenu(keys)
    else
        print("OpenKeyMenu is not defined")
    end
end)

-- Command
if Config.Command then
    if Config.Keybind then
        RegisterKeyMapping(Config.Command, L("keybind"), "keyboard", Config.Keybind)
    end

    RegisterCommand(Config.Command, function()
        TriggerEvent("loaf_keysystem:openMenu")
    end, false)
    TriggerEvent("chat:addSuggestion", "/" .. Config.Command, L("keybind"), {})
end

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    if Config.Command then
        TriggerEvent("chat:removeSuggestion", "/" .. Config.Command)
    end
end)
