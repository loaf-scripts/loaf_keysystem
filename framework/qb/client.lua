if Config.Framework ~= "qb-core" then
    return
end

local QB = exports["qb-core"]:GetCoreObject()

function Notify(text, errType)
    QB.Functions.Notify(text, errType)
end

CreateThread(function()
    while not LocalPlayer.state.isLoggedIn do
        Wait(500)
    end

    Loaded = true
end)

if Config.MenuSystem == "framework" then
    local selectNearbyPlayer, individualKeyMenu, confirmTransferKey

    local function confirmDeleteKey(keys, key)
        exports["qb-menu"]:openMenu({
            {
                header = L("confirm_delete", {
                    key_name = key.key_data.name
                }),
                isMenuHeader = true
            },
            {
                header = L("yes"),
                params = {
                    event = function()
                        local success = DeleteKey(key.unique_id)
                        if success then
                            Notify(L("deleted", {
                                key_name = key.key_data.name
                            }))
                        else
                            Notify(L("failed_delete"))
                        end

                        TriggerEvent("loaf_keysystem:openMenu")
                    end,
                    isAction = true
                }
            },
            {
                header = L("no"),
                params = {
                    event = function()
                        individualKeyMenu(keys, key)
                    end,
                    isAction = true
                }
            }
        })
    end

    function confirmTransferKey(keys, key, player)
        exports["qb-menu"]:openMenu({
            {
                header = L("confirm_transfer", {
                    name = player.name
                }),
                isMenuHeader = true
            },
            {
                header = L("yes"),
                params = {
                    event = function()
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
                    end,
                    isAction = true
                }
            },
            {
                header = L("no"),
                params = {
                    event = function()
                        individualKeyMenu(keys, key)
                    end,
                    isAction = true
                }
            }
        })
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
                header = L("transfer_nearby"),
                isMenuHeader = true
            }
        }

        for i = 1, #players do
            local player = players[i]
            elements[#elements+1] = {
                header = player.name,
                params = {
                    event = function()
                        confirmTransferKey(keys, key, player)
                    end,
                    isAction = true
                }
            }
        end

        elements[#elements+1] = {
            header = L("back"),
            params = {
                event = function()
                    individualKeyMenu(keys, key)
                end,
                isAction = true
            }
        }

        exports["qb-menu"]:openMenu(elements)
    end

    function individualKeyMenu(keys, key)
        local elements = {
            {
                header = key.key_data.name,
                isMenuHeader = true
            },
            {
                header = L("transfer_nearby"),
                params = {
                    event = function()
                        selectNearbyPlayer(keys, key)
                    end,
                    isAction = true
                }
            },
            {
                header = L("delete_key"),
                params = {
                    event = function()
                        confirmDeleteKey(keys, key)
                    end,
                    isAction = true
                }
            },
            {
                header = L("back"),
                params = {
                    event = OpenKeyMenu,
                    args = keys,
                    isAction = true
                }
            }
        }

        if key.key_data.eventname or KeyUsages[key.key_id] then
            table.insert(elements, 2, {
                header = L("use_key"),
                params = {
                    event = UseKey,
                    args = key.unique_id,
                    isAction = true
                }
            })
        end

        exports["qb-menu"]:openMenu(elements)
    end

    function OpenKeyMenu(keys)
        if #keys == 0 then
            Notify(L("no_keys"))
            return
        end

        local elements = {
            {
                header = L("main_menu"),
                isMenuHeader = true
            }
        }

        for i = 1, #keys do
            local key = keys[i]
            elements[#elements+1] = {
                header = key.key_data.name,
                params = {
                    event = function()
                        individualKeyMenu(keys, key)
                    end,
                    isAction  = true
                }
            }
        end

        exports["qb-menu"]:openMenu(elements)
    end
end