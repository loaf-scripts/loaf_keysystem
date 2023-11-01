function GetNearbyPlayers()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local players = GetActivePlayers()
    local selfPlayer = PlayerId()

    local nearbyPlayers = {}
    for i = 1, #players do
        local player = players[i]
        local distance = #(GetEntityCoords(GetPlayerPed(player)) - playerCoords)

        if selfPlayer == player or distance > (Config.TransferDistance or 3.0) then
            goto continue
        end

        local id = GetPlayerServerId(player)
        local name = GetPlayerName(player)
        if Config.UseRPName then
            name = lib.TriggerCallbackSync("loaf_keysystem:get_name", id)
        else
            name = GetPlayerName(player) .. " | " .. id
        end

        nearbyPlayers[#nearbyPlayers+1] = {
            id = id,
            name = name,
            distance = distance
        }

        ::continue::
    end

    table.sort(nearbyPlayers, function(a, b)
        return a.distance < b.distance
    end)

    return nearbyPlayers
end

if Config.MenuSystem == "ox_lib" then
    local function confirmDeleteKey(key)
        exports.ox_lib:registerMenu({
            id = "confirm_delete_key_menu",
            title = L("confirm_delete", { key_name = key.key_data.name }),
            position = Config.MenuAlign,
            options = {
                {
                    label = L("yes"),
                    args = true
                },
                {
                    label = L("no")
                }
            },
            onClose = function()
                exports.ox_lib:showMenu("individual_key_menu")
            end
        }, function(_, _, confirmed)
            if not confirmed then
                exports.ox_lib:showMenu("individual_key_menu")
                return
            end

            local success = DeleteKey(key.unique_id)
            if success then
                Notify(L("deleted", {
                    key_name = key.key_data.name
                }))
            else
                Notify(L("failed_delete"))
            end

            TriggerEvent("loaf_keysystem:openMenu")
        end)

        exports.ox_lib:showMenu("confirm_delete_key_menu")
    end

    local function confirmTransferKey(key, player)
        exports.ox_lib:registerMenu({
            id = "confirm_transfer_key_menu",
            title = L("confirm_transfer", { name = player.name }),
            position = Config.MenuAlign,
            options = {
                {
                    label = L("yes"),
                    args = true
                },
                {
                    label = L("no")
                }
            },
            onClose = function()
                exports.ox_lib:showMenu("individual_key_menu")
            end
        }, function(_, _, confirmed)
            if not confirmed then
                exports.ox_lib:showMenu("individual_key_menu")
                return
            end

            local success = TransferKey(key.unique_id, player.id)
            if success then
                Notify(L("transferred", {
                    key_name = key.key_data.name,
                    player_name = player.name
                }))
            else
                Notify(L("failed_transfer"))
            end

            TriggerEvent("loaf_keysystem:openMenu")
        end)

        exports.ox_lib:showMenu("confirm_transfer_key_menu")
    end

    local function selectNearbyPlayer(key)
        local players = GetNearbyPlayers()
        if #players == 0 then
            Notify(L("no_one_nearby"))
            exports.ox_lib:showMenu("individual_key_menu")
            return
        end

        local options = {}
        for i = 1, #players do
            local player = players[i]
            options[#options+1] = {
                label = player.name,
                args = player
            }
        end

        exports.ox_lib:registerMenu({
            id = "select_nearby_player_menu",
            title = key.key_data.name,
            position = Config.MenuAlign,
            options = options,
            onClose = function()
                exports.ox_lib:showMenu("individual_key_menu")
            end
        }, function(_, _, player)
            confirmTransferKey(key, player)
        end)

        exports.ox_lib:showMenu("select_nearby_player_menu")
    end

    local function individualKeyMenu(key)
        local options = {
            {
                label = L("transfer_nearby"),
                args = "transfer"
            },
            {
                label = L("delete_key"),
                args = "delete"
            }
        }

        if key.key_data.eventname or KeyUsages[key.key_id] then
            table.insert(options, 1, {
                label = L("use_key"),
                args = "use",
                close = false
            })
        end

        exports.ox_lib:registerMenu({
            id = "individual_key_menu",
            title = key.key_data.name,
            position = Config.MenuAlign,
            options = options,
            onClose = function()
                exports.ox_lib:showMenu("keys_main_menu")
            end
        }, function(_, _, action)
            if action == "use" then
                UseKey(key.unique_id)
            elseif action == "transfer" then
                selectNearbyPlayer(key)
            elseif action == "delete" then
                confirmDeleteKey(key)
            end
        end)

        exports.ox_lib:showMenu("individual_key_menu")
    end

    function OpenKeyMenu(keys)
        if #keys == 0 then
            Notify(L("no_keys"))
            return
        end

        local options = {}
        for i = 1, #keys do
            local key = keys[i]
            options[#options+1] = {
                label = key.key_data.name,
                args = key
            }
        end

        exports.ox_lib:registerMenu({
            id = "keys_main_menu",
            title = L("main_menu"),
            position = Config.MenuAlign,
            options = options
        }, function(_, _, key)
            individualKeyMenu(key)
        end)

        exports.ox_lib:showMenu("keys_main_menu")
    end
end