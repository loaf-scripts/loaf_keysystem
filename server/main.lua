lib = exports["loaf_lib"]:GetLib()

lib.RegisterCallback("loaf_keysystem:fetch_keys", function(source, cb)
    cb(GetKeys(source))
end)

lib.RegisterCallback("loaf_keysystem:remove_key", function(source, cb, uniqueId)
    local key = GetKey(uniqueId)
    if key and key.identifier == GetIdentifier(source) then
        RemoveKey(uniqueId, true)
        cb(true)

        if Logs.LogDelete then
            lib.Log({
                webhook = Logs.Webhook,
                source = source,
                category = "Keysystem",
                type = "error",

                title = "Remove key",
                text = Strings["LOG_removed_key"]:format(key.key_id, key.unique_id)
            })
        end
    else
        Notify(source, Strings["not_your_key"])
        cb(false)
    end
end)

lib.RegisterCallback("loaf_keysystem:get_name", function(source, cb, player)
    if not Config.UseRPName then return cb(false) end
    cb(GetIngameName(player))
end)

lib.RegisterCallback("loaf_keysystem:transfer_key", function(source, cb, uniqueId, player)
    local key = GetKey(uniqueId) 
    if key and key.identifier == GetIdentifier(source) then
        local success = TransferKey(uniqueId, player)
        if success then
            TriggerClientEvent("loaf_keysystem:remove_key", source, uniqueId)
            TriggerClientEvent("loaf_keysystem:add_key", player, key.key_id, uniqueId, json.decode(key.key_data))

            if Logs.LogTransfer then
                lib.Log({
                    webhook = Logs.Webhook,
                    source = source,
                    category = "Keysystem",
                    type = "error",

                    title = "Transfer key",
                    text = Strings["LOG_transferred_key"]:format(key.key_id, key.unique_id, GetPlayerName(player), player)
                })

                lib.Log({
                    webhook = Logs.Webhook,
                    source = player,
                    category = "Keysystem",
                    type = "success",

                    title = "Transfer key",
                    text = Strings["LOG_received_key"]:format(key.key_id, key.unique_id, GetPlayerName(source), source)
                })
            end
        end
        cb(success)
    else
        Notify(source, Strings["not_your_key"])
        cb(false)
    end
end)

CreateThread(function()
    while not loaded do 
        Wait(500)
        print("waiting for framework to load")
    end

    function TransferKey(uniqueId, player)
        local identifier = GetIdentifier(player)
        if not identifier then return false end
        return MySQL.Sync.execute("UPDATE `loaf_keys` SET `identifier`=@identifier WHERE `unique_id`=@unique_id", {
            ["@identifier"] = identifier,
            ["@unique_id"] = uniqueId
        }) ~= 0
    end

    function GenerateKey(source, key, name, eventtype, eventname)
        local invoking = GetInvokingResource() or "unknown"
        local identifier = GetIdentifier(source)
        if not identifier then return false end
        if not key then return false end

        local found, id
        while not found do
            Wait(50)
            id = lib.GenerateString()
            found = MySQL.Sync.fetchScalar("SELECT `unique_id` FROM `loaf_keys` WHERE `unique_id`=@id", {["@id"] = id}) == nil
        end

        local keyData = {
            name = name or key,
            key_id = key,
            unique_id = id
        }
        if eventtype and eventname then
            keyData.eventtype = eventtype
            keyData.eventname = eventname
        end

        MySQL.Async.execute("INSERT INTO `loaf_keys` (`unique_id`, `key_id`, `identifier`, `key_data`) VALUES (@id, @key_id, @identifier, @data)",{
            ["@id"] = id,
            ["@key_id"] = key,
            ["@identifier"] = identifier,
            ["@data"] = json.encode(keyData)
        })

        TriggerClientEvent("loaf_keysystem:add_key", source, key, id, keyData)

        if Logs.LogCreate then
            lib.Log({
                webhook = Logs.Webhook,
                source = source,
                category = "Keysystem",
                type = "success",

                title = "Generate key",
                text = Strings["LOG_create_key"]:format(invoking, name, key, id)
            })
        end
    end

    function RemoveAllKeys(keyId)
        local invoking = GetInvokingResource() or "unknown"
        MySQL.Async.fetchAll("SELECT `identifier`, `unique_id` FROM `loaf_keys` WHERE `key_id`=@key_id", {
            ["@key_id"] = keyId
        }, function(keys)
            if not keys then return end
            MySQL.Async.execute("DELETE FROM `loaf_keys` WHERE `key_id`=@key_id", {["@key_id"] = keyId})
            
            for _, v in pairs(keys) do
                local ownerSource = GetSourceByIdentifier(v.identifier)
                if ownerSource then
                    TriggerClientEvent("loaf_keysystem:remove_key", ownerSource, v.unique_id)
                end
            end

            if Logs.LogDeleteAll then
                lib.Log({
                    webhook = Logs.Webhook,
                    category = "Keysystem",
                    type = "error",
    
                    title = "Delete all keys",
                    text = Strings["LOG_delete_all"]:format(keyId, invoking)
                })
            end
        end)
    end

    function RemoveKey(uniqueId, ignoreLog)
        local invoking = GetInvokingResource() or "unknown"
        local data = GetKey(uniqueId)
        if not data then return false end
    
        MySQL.Async.execute("DELETE FROM `loaf_keys` WHERE `unique_id`=@unique_id", {["@unique_id"] = uniqueId})

        local ownerSource = GetSourceByIdentifier(data.identifier)
        if ownerSource then
            TriggerClientEvent("loaf_keysystem:remove_key", ownerSource, uniqueId)
            if Logs.LogDeleteUnique and not ignoreLog then
                lib.Log({
                    webhook = Logs.Webhook,
                    source = ownerSource,
                    category = "Keysystem",
                    type = "error",
    
                    title = "Deleted key",
                    text = Strings["LOG_delete_key"]:format(data.key_id, uniqueId, invoking)
                })
            end
        elseif Logs.LogDeleteUnique and not ignoreLog then
            lib.Log({
                webhook = Logs.Webhook,
                category = "Keysystem",
                type = "error",

                title = "Deleted key",
                text = Strings["LOG_delete_specific"]:format(invoking, uniqueId)
            })
        end
        return true
    end

    function HasKey(source, keyId)
        local identifier = GetIdentifier(source)
        if not identifier then return false end
        return MySQL.Sync.fetchScalar("SELECT `identifier` FROM `loaf_keys` WHERE `key_id`=@key_id AND `identifier`=@identifier", {
            ["@key_id"] = keyId,
            ["@identifier"] = identifier
        }) == identifier
    end

    function GetKey(uniqueId)
        return MySQL.Sync.fetchAll("SELECT `unique_id`, `key_id`, `identifier`, `key_data` FROM `loaf_keys` WHERE `unique_id`=@unique_id", {["@unique_id"] = uniqueId})[1]
    end

    function GetKeys(source)
        local identifier = GetIdentifier(source)
        if not identifier then return {} end
        return MySQL.Sync.fetchAll("SELECT `unique_id`, `key_id`, `key_data` FROM `loaf_keys` WHERE `identifier`=@identifier", {["@identifier"] = identifier}) or {}
    end

    exports("GetKeys", GetKeys) -- params: source
    exports("GetKey", GetKey) -- params: uniqueId
    exports("HasKey", HasKey) -- params: source, keyId
    exports("RemoveKey", RemoveKey) -- params: uniqueId
    exports("RemoveAllKeys", RemoveAllKeys) -- params: keyId
    exports("TransferKey", TransferKey) -- params: uniqueId, player
    exports("GenerateKey", GenerateKey) -- params: source, key, name, eventtype, eventname

    local function OldWarning()
        _print("^3[WARNING] ^0The events are outdated. Please use the exports instead. (this is just a warning, if you are not a script developer please do ignore)")
    end

    -- BACKWARDS COMPATIBILITY
    -- PLEASE DO NOT USE
    RegisterNetEvent("generateKey")
    AddEventHandler("generateKey", function(playerid, key, name, eventtype, eventname, cb)
        if type(source) ~= "string" then return end -- not triggered by server
        OldWarning()
        GenerateKey(playerid, key, name, eventtype, eventname)
        if cb then cb(GetKeys(playerid)) end
    end)

    RegisterNetEvent("getKeys")
    AddEventHandler("getKeys", function(playerid, cb)
        if type(source) ~= "string" then return end -- not triggered by server
        OldWarning()
        if cb then cb(GetKeys(playerid)) end
    end)

    RegisterNetEvent("removeAllKeys")
    AddEventHandler("removeAllKeys", function(keyId)
        if type(source) ~= "string" then return end -- not triggered by server
        OldWarning()
        RemoveAllKeys(keyId)
    end)

    RegisterNetEvent("removeKey")
    AddEventHandler("removeKey", function(uniqueId)
        if type(source) ~= "string" then return end -- not triggered by server
        OldWarning()
        RemoveKey(uniqueId)
    end)
end)