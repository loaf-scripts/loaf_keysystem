CreateThread(function()
    if Config.Framework ~= "esx" then
        return
    end

    local export, ESX = pcall(function()
        return exports.es_extended:getSharedObject()
    end)
    if not export then
        while not ESX do
            TriggerEvent("esx:getSharedObject", function(obj)
                ESX = obj
            end)
            Wait(500)
        end
    end

    while not ESX.GetPlayerData()?.job do
        Wait(500)
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

    local function CloseMenuHandler(_, menu)
        menu.close()
    end

    function Notify(msg)
        ESX.ShowNotification(msg)
    end

    local KeyActions = {}
    function KeyActions.use(uniqueId)
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
    end

    function KeyActions.transfer(uniqueId)
        local key = GetKey(uniqueId)
        if not key then return end

        local elements, nearbyPlayers = {}, GetPlayers()
        for _, v in pairs(nearbyPlayers) do
            elements[#elements+1] = {
                label = Strings["give_to"]:format(v.name, v.serverId),
                name = v.name,
                id = v.serverId
            }
        end
        if #elements == 0 then 
            elements = {{label = Strings["noone_nearby"]}}
        end
        ESX.UI.Menu.Open("default", GetCurrentResourceName(), "transfer_key", {
            title = Strings["transfer_nearby"],
            align = cache.menuAlign,
            elements = elements
        }, function(data, menu)
            if not data.current.id then return end
            ESX.UI.Menu.Open("default", GetCurrentResourceName(), "confirm_transfer", {
                title = Strings["confirm_give"]:format(data.current.name),
                align = cache.menuAlign,
                elements = {
                    {label = Strings["no"], value = "no"},
                    {label = Strings["yes"], value = "yes"}
                }
            }, function(data2, menu2)
                if data2.current.value == "no" then 
                    return menu2.close()
                end
                ESX.UI.Menu.CloseAll()
                lib.TriggerCallback("loaf_keysystem:transfer_key", function(success)
                    if not success then
                        Notify(Strings["couldnt_transfer"])
                    else
                        Notify(Strings["transferred"]:format(key.key_data.name, data.current.name))
                    end
                end, uniqueId, data.current.id)
            end, CloseMenuHandler)
        end, CloseMenuHandler)
    end

    function KeyActions.delete(uniqueId)
        local key = GetKey(uniqueId)
        if not key then return end

        ESX.UI.Menu.Open("default", GetCurrentResourceName(), "confirm_deletion", {
            title = Strings["confirm_delete"]:format(key.key_data.name),
            align = cache.menuAlign,
            elements = {
                {label = Strings["no"], value = "no"},
                {label = Strings["yes"], value = "yes"},
            }
        }, function(data, menu)
            if data.current.value == "yes" then
                ESX.UI.Menu.CloseAll()
                lib.TriggerCallback("loaf_keysystem:remove_key", function(success)
                    if not success then 
                        Notify(Strings["couldnt_delete"]) 
                    else
                        Notify(Strings["deleted"]:format(key.key_data.name))
                        Wait(250)
                    end
                    OpenKeyMenu()
                end, uniqueId)
            else
                menu.close()
            end
        end, CloseMenuHandler)
    end

    function OpenKeyMenu()
        ESX.UI.Menu.CloseAll()

        local elements = {}
        for i, v in pairs(cache.keys) do
            elements[i] = {label = v.key_data.name, key = v}
        end
        if #elements == 0 then elements = {{label = Strings["no_keys"]}} end

        ESX.UI.Menu.Open("default", GetCurrentResourceName(), "key_menu", {
            title = Strings["main_menu"],
            align = cache.menuAlign,
            elements = elements
        }, function(data, menu)
            if not data.current.key then return end

            local elements = {}
            if data.current.key.key_data.eventname or cache.keyUsages[data.current.key.key_id] then
                table.insert(elements, {label = Strings["use_key"], value = "use"})
            end
            table.insert(elements, {label = Strings["transfer_nearby"], value = "transfer"})
            table.insert(elements, {label = Strings["delete_key"], value = "delete"})

            ESX.UI.Menu.Open("default", GetCurrentResourceName(), "specific_key", {
                title = data.current.label,
                align = cache.menuAlign,
                elements = elements
            }, function(data2, menu2)
                KeyActions[data2.current.value](data.current.key.unique_id)
            end, CloseMenuHandler)
        end, CloseMenuHandler)
    end

    cache.loaded = true
end)