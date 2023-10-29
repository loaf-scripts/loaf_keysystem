local playerKeys = {}

local function findKey(t, k, v)
    if not t then
        return
    end

    for i = 1, #t do
        if t[i][k] == v then
            return i
        end
    end
end

lib.RegisterCallback("loaf_keysystem:fetch_keys", function(source, cb)
    local sSrc = tostring(source)

    local identifier = GetIdentifier(source)
    if not identifier then
        playerKeys[sSrc] = {}
        return cb({})
    end

    local keys = MySQL.Sync.fetchAll("SELECT `unique_id`, `key_id`, `key_data` FROM `loaf_keys` WHERE `identifier`=@identifier", {
        ["@identifier"] = identifier
    })

    for i = 1, #keys do
        local key = keys[i]
        if key.key_data then
            key.key_data = json.decode(key.key_data)
        else
            key.key_data = {}
        end
    end

    playerKeys[sSrc] = keys

    cb(keys)
end)

lib.RegisterCallback("loaf_keysystem:remove_key", function(source, cb, uniqueId)
    local sSrc = tostring(source)

    local index = findKey(playerKeys[sSrc], "unique_id", uniqueId)
    if not index then
        printf("remove_key: key %s not found", uniqueId)
        return cb(false)
    end

    table.remove(playerKeys[sSrc], index)

    MySQL.Async.execute("DELETE FROM `loaf_keys` WHERE `unique_id`=@unique_id", {
        ["@unique_id"] = uniqueId
    }, function(rows)
        if rows > 0 then
            printf("removed key %s", uniqueId)
        else
            printf("remove_key: key %s not found in db", uniqueId)
        end

        cb(rows > 0)
    end)
end)

lib.RegisterCallback("loaf_keysystem:transfer_key", function(source, cb, uniqueId, player)
    if player == source then
        print("transfer_key: cannot transfer key to self")
        return cb(false)
    end

    local transferToKeys = playerKeys[tostring(player)]
    if not transferToKeys then
        printf("transfer_key: player %s not found", player)
        return cb(false)
    end

    local ownedKeys = playerKeys[tostring(source)]
    local index = findKey(ownedKeys, "unique_id", uniqueId)
    if not index then
        printf("transfer_key: person transferring does not own key %s", uniqueId)
        return cb(false)
    end

    local key = ownedKeys[index]
    table.remove(ownedKeys, index)
    transferToKeys[#transferToKeys+1] = key

    MySQL.Async.execute("UPDATE `loaf_keys` SET `identifier`=@identifier WHERE `unique_id`=@unique_id", {
        ["@identifier"] = GetIdentifier(player),
        ["@unique_id"] = uniqueId
    }, function(rows)
        if rows > 0 then
            printf("transferred key %s to %s", uniqueId, player)

            TriggerClientEvent("loaf_keysystem:add_key", player, key.key_id, key.unique_id, key.key_data)
            TriggerClientEvent("loaf_keysystem:remove_key", source, uniqueId)
        else
            printf("transfer_key: key %s not found in db", uniqueId)
        end

        cb(rows > 0)
    end)
end)

lib.RegisterCallback("loaf_keysystem:get_name", function(source, cb, player)
    if not Config.UseRPName then
        return cb("")
    end

    cb(GetIngameName(player))
end)

-- Exports & events
local function findUniqueKey(uniqueId)
    for src, keys in pairs(playerKeys) do
        local index = findKey(keys, "unique_id", uniqueId)
        if index then
            return src, index
        end
    end

    return false
end

local function transferKey(uniqueId, toSrc)
    local identifier = GetIdentifier(toSrc)
    if not identifier then
        return false
    end

    local success = MySQL.Sync.execute("UPDATE loaf_keys SET identifier=@identifier WHERE unique_id=@uniqueId", {
        ["@identifier"] = identifier,
        ["@uniqueId"] = uniqueId
    }) > 0

    if not success then
        return false
    end

    local fromSrc, index = findUniqueKey(uniqueId)
    if fromSrc then
        table.remove(playerKeys[fromSrc], index)
        TriggerClientEvent("loaf_keysystem:remove_key", fromSrc, uniqueId)
    end

    local sSrc = tostring(toSrc)
    if not playerKeys[sSrc] then
        playerKeys[sSrc] = {}
    end

    local key = MySQL.Sync.fetchScalar("SELECT `unique_id`, `key_id`, `key_data` FROM `loaf_keys` WHERE unique_id=@uniqueId", { ["@uniqueId"] = uniqueId })

    if key.key_data then
        key.key_data = json.decode(key.key_data)
    else
        key.key_data = {}
    end

    local keys = playerKeys[sSrc]
    keys[#keys+1] = key

    TriggerClientEvent("loaf_keysystem:add_key", toSrc, key.key_id, key.unique_id, key.key_data)

    return true
end

local function generateKey(source, keyId, name, eventtype, eventname)
    local identifier = GetIdentifier(source)

    if not identifier or not keyId then
        return false
    end

    local found, uniqueId
    while not found do
        Wait(0)
        uniqueId = lib.GenerateString()
        found = MySQL.Sync.fetchScalar("SELECT unique_id FROM loaf_keys WHERE unique_id=@uniqueId", {
            ["@uniqueId"] = uniqueId
        }) == nil
    end

    local keyData = {
        name = name or keyId,
        key_id = keyId,
        unique_id = uniqueId,
        eventtype = eventtype,
        eventname = eventname
    }

    MySQL.Async.execute("INSERT INTO loaf_keys (unique_id, key_id, identifier, key_data) VALUES (@uniqueId, @keyId, @identifier, @keyData)", {
        ["@uniqueId"] = uniqueId,
        ["@keyId"] = keyId,
        ["@identifier"] = identifier,
        ["@keyData"] = json.encode(keyData)
    })

    playerKeys[tostring(source)] = playerKeys[tostring(source)] or {}
    local keys = playerKeys[tostring(source)]
    keys[#keys+1] = {
        unique_id = uniqueId,
        key_id = keyId,
        key_data = keyData
    }

    TriggerClientEvent("loaf_keysystem:add_key", source, keyId, uniqueId, keyData)
end

local function removeAllKeys(keyId)
    for src, keys in pairs(playerKeys) do
        for i = #keys, 1, -1 do
            if keys[i].key_id == keyId then
                table.remove(keys, i)
            end
        end
    end

    MySQL.Async.execute("DELETE FROM loaf_keys WHERE key_id=@keyId", {
        ["@keyId"] = keyId
    })

    TriggerClientEvent("loaf_keysystem:remove_all_keys", -1, keyId)
end

local function removeKey(uniqueId)
    local src, index = findUniqueKey(uniqueId)
    if src then
        table.remove(playerKeys[src], index)
        TriggerClientEvent("loaf_keysystem:remove_key", src, uniqueId)
    end

    MySQL.Async.execute("DELETE FROM loaf_keys WHERE unique_id=@uniqueId", {
        ["@uniqueId"] = uniqueId
    })
end

local function hasKey(source, keyId)
    local index = findKey(playerKeys[tostring(source)], "key_id", keyId)
    return index ~= nil
end

local function getKey(uniqueId)
    return MySQL.Sync.fetchAll("SELECT unique_id, key_id, identifier, key_data FROM loaf_keys WHERE unique_id=@uniqueId", {
        ["@uniqueId"] = uniqueId
    })[1]
end

local function getKeys(source)
    return playerKeys[tostring(source)]
end

exports("TransferKey", transferKey)
exports("GenerateKey", generateKey)
exports("RemoveAllKeys", removeAllKeys)
exports("RemoveKey", removeKey)
exports("HasKey", hasKey)
exports("GetKey", getKey)
exports("GetKeys", getKeys)

AddEventHandler("generateKey", function(playerSrc, keyId, name, eventtype, eventname, cb)
    generateKey(playerSrc, keyId, name, eventtype, eventname)
    if cb then
        cb(getKeys(playerSrc))
    end
end)

AddEventHandler("removeAllKeys", function(keyId)
    removeAllKeys(keyId)
end)

AddEventHandler("removeKey", function(uniqueId)
    removeKey(uniqueId)
end)

AddEventHandler("getKeys", function(playerSrc, cb)
    if cb then
        cb(getKeys(playerSrc))
    end
end)

-- Free up memory on player leave
AddEventHandler("playerDropped", function()
    local src = source
    local sSrc = tostring(src)

    playerKeys[sSrc] = nil
end)
