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

RegisterNetEvent("esx:playerLoaded", function(playerData)
    ESX.PlayerData = playerData
    ESX.PlayerLoaded = true
end)

function Notify(text, errType)
    ESX.ShowNotification(text, errType)
end

while not ESX.PlayerLoaded do
    Wait(500)
end

Loaded = true

if Config.MenuSystem == "framework" then
    local function closeMenuHandler(data, menu)
        menu.close()
    end

    local function confirmDeleteKey(key)
        ESX.UI.Menu.Open("default", GetCurrentResourceName(), "confirm_delete", {
            title = L("confirm_delete", {
                key_name = key.key_data.name
            }),
            align = Config.MenuAlign,
            elements = {
                {
                    label = L("no"),
                    value = "no"
                },
                {
                    label = L("yes"),
                    value = "yes"
                }
            }
        }, function(data, menu)
            if data.current.value ~= "yes" then
                return menu.close()
            end

            ESX.UI.Menu.CloseAll()

            local success = DeleteKey(key.unique_id)
            if success then
                Notify(L("deleted", {
                    key_name = key.key_data.name
                }))
            else
                Notify(L("failed_delete"))
            end

            TriggerEvent("loaf_keysystem:openMenu")
        end, closeMenuHandler)
    end

    local function confirmTransferKey(key, player)
        ESX.UI.Menu.Open("default", GetCurrentResourceName(), "confirm_transfer", {
            title = L("confirm_transfer", {
                name = player.name
            }),
            align = Config.MenuAlign,
            elements = {
                {
                    label = L("no"),
                    value = "no"
                },
                {
                    label = L("yes"),
                    value = "yes"
                }
            }
        }, function(data, menu)
            if data.current.value ~= "yes" then
                return menu.close()
            end

            ESX.UI.Menu.CloseAll()

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
        end, closeMenuHandler)
    end

    local function selectNearbyPlayer(key)
        local players = GetNearbyPlayers()

        if #players == 0 then
            Notify(L("no_one_nearby"))
            return
        end

        local elements = {}
        for i = 1, #players do
            local player = players[i]
            elements[#elements+1] = {
                label = player.name,
                player = player
            }
        end

        ESX.UI.Menu.Open("default", GetCurrentResourceName(), "transfer_key", {
            title = key.key_data.name,
            align = Config.MenuAlign,
            elements = elements
        }, function(data, menu)
            confirmTransferKey(key, data.current.player)
        end, closeMenuHandler)
    end

    local function individualKeyMenu(key)
        local elements = {}
        if key.key_data.eventname or KeyUsages[key.key_id] then
            elements[#elements+1] = {
                label = L("use_key"),
                value = "use"
            }
        end

        elements[#elements+1] = {
            label = L("transfer_nearby"),
            value = "transfer"
        }

        elements[#elements+1] = {
            label = L("delete_key"),
            value = "delete"
        }

        ESX.UI.Menu.Open("default", GetCurrentResourceName(), "individual_key", {
            title = key.key_data.name,
            align = Config.MenuAlign,
            elements = elements
        }, function(data, menu)
            local action = data.current.value
            if action == "use" then
                UseKey(key.unique_id)
            elseif action == "transfer" then
                selectNearbyPlayer(key)
            elseif action == "delete" then
                confirmDeleteKey(key)
            end
        end, closeMenuHandler)
    end

    function OpenKeyMenu(keys)
        local elements = {}
        for i = 1, #keys do
            local key = keys[i]
            elements[#elements+1] = {
                label = key.key_data.name,
                key = key
            }
        end

        if #elements == 0 then
            Notify(L("no_keys"))
            return
        end

        if not ESX?.UI?.Menu then
            print("ESX.UI.Menu not found, did you set up ESX correctly?")
            return
        end

        ESX.UI.Menu.CloseAll()

        ESX.UI.Menu.Open("default", GetCurrentResourceName(), "key_menu", {
            title = L("main_menu"),
            align = Config.MenuAlign,
            elements = elements
        }, function(data, menu)
            individualKeyMenu(data.current.key)
        end, closeMenuHandler)
    end
elseif Config.MenuSystem == "esx_context" then
    local selectNearbyPlayer, individualKeyMenu, confirmTransferKey

    local function confirmDeleteKey(keys, key)
        ESX.OpenContext("right", {
            {
                unselectable = true,
                title = L("confirm_delete", {
                    key_name = key.key_data.name
                })
            },
            {
                title = L("yes"),
                value = "yes",
                icon = "fa-solid fa-check"
            },
            {
                title = L("no"),
                value = "no",
                icon = "fa-solid fa-xmark"
            },
        }, function(menu, element)
            if element.value == "yes" then
                ESX.CloseContext()

                local success = DeleteKey(key.unique_id)
                if success then
                    Notify(L("deleted", {
                        key_name = key.key_data.name
                    }))
                else
                    Notify(L("failed_delete"))
                end
            else
                individualKeyMenu(keys, key)
            end
        end)
    end

    function confirmTransferKey(keys, key, player)
        ESX.OpenContext("right", {
            {
                unselectable = true,
                title = L("confirm_transfer", {
                    name = player.name
                })
            },
            {
                title = L("yes"),
                value = "yes",
                icon = "fa-solid fa-check"
            },
            {
                title = L("no"),
                value = "no",
                icon = "fa-solid fa-xmark"
            },
        }, function(menu, element)
            if element.value == "yes" then
                ESX.CloseContext()

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
            else
                selectNearbyPlayer(keys, key)
            end
        end)
    end

    function selectNearbyPlayer(keys, key)
        local players = GetNearbyPlayers()
        if #players == 0 then
            Notify(L("no_one_nearby"))
            individualKeyMenu(keys, key)
            return
        end

        local elements = {
            {
                unselectable = true,
                title = key.key_data.name,
            }
        }

        for i = 1, #players do
            local player = players[i]
            elements[#elements+1] = {
                title = player.name,
                player = player,
                icon = "fas fa-user"
            }
        end

        elements[#elements+1] = {
            title = L("back"),
            value = "back",
            icon = "fa-solid fa-arrow-left"
        }

        ESX.OpenContext("right", elements, function(menu, element)
            if element.value == "back" then
                individualKeyMenu(keys, key)
            else
                confirmTransferKey(keys, key, element.player)
            end
        end)
    end

    function individualKeyMenu(keys, key)
        local elements = {
            {
                unselectable = true,
                title = key.key_data.name,
            },
            {
                title = L("transfer_nearby"),
                value = "transfer",
                icon = "fas fa-exchange-alt"
            },
            {
                title = L("delete_key"),
                value = "delete",
                icon = "fas fa-trash"
            },
            {
                title = L("back"),
                value = "back",
                icon = "fa-solid fa-arrow-left"
            }
        }

        if key.key_data.eventname or KeyUsages[key.key_id] then
            table.insert(elements, 2, {
                title = L("use_key"),
                value = "use",
                icon = "fas fa-key"
            })
        end

        ESX.OpenContext("right", elements, function(menu, element)
            local action = element.value
            print(action)
            if action == "use" then
                UseKey(key.unique_id)
            elseif action == "transfer" then
                selectNearbyPlayer(keys, key)
            elseif action == "delete" then
                confirmDeleteKey(keys, key)
            elseif action == "back" then
                OpenKeyMenu(keys)
            end
        end)
    end

    function OpenKeyMenu(keys)
        if #keys == 0 then
            Notify(L("no_keys"))
            return
        end

        if not ESX.OpenContext then
            print("ESX.OpenContext not found, did you set up ESX correctly?")
            return
        end

        ESX.CloseContext()

        local elements = {
            {
                unselectable = true,
                title = L("main_menu")
            }
        }

        for i = 1, #keys do
            local key = keys[i]
            elements[#elements+1] = {
                title = key.key_data.name,
                key = key,
                icon = "fas fa-key"
            }
        end

        elements[#elements+1] = {
            title = L("close"),
            value = "close",
            icon = "fa-solid fa-xmark"
        }

        ESX.OpenContext("right", elements, function(menu, element)
            if not element.key then
                ESX.CloseContext()
                return
            end

            individualKeyMenu(keys, element.key)
        end)
    end
end