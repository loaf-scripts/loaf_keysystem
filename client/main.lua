OpenKeyMenu = function()
    print("ESX not loaded")
end

local key_usages = {}

CreateThread(function()
    while not NetworkIsSessionStarted() do -- wait for the client to load the game
        Wait(250)
    end

    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(esx) -- get esx object
            ESX = esx 
        end)
        Wait(50)
    end
    
    while ESX.GetPlayerData().job == nil do -- wait until the character has a job (kashacters support)
        Wait(50)
    end

    OpenKeyMenu = function()
        ESX.TriggerServerCallback("loaf_keysystem:getKeys", function(keys)
            local elements = {}
            if keys then
                for k, v in pairs(keys) do
                    table.insert(elements, {label = v.name or v.key_id, id = v.key_id, unique_id = v.unique_id})
                end
            else
                table.insert(elements, {label = Strings["no_keys"]})
            end

            ESX.UI.Menu.Open("default", GetCurrentResourceName(), "keymenu", {
                title = Strings["main_menu"],
                align = "top-left",
                elements = elements
            }, function(data, menu)
                local currentKey, currentUnique = data.current.id, data.current.unique_id

                ESX.UI.Menu.Open("default", GetCurrentResourceName(), "individualkeymenu", {
                    title = data.current.label,
                    align = "top-left",
                    elements = {
                        {label = Strings["transfer_nearby"], value = "transfer"},
                        {label = Strings["use"], value = "use"},
                    }
                }, function(data2, menu2)
                    local currentValue = data2.current.value
    
                    if currentValue == "transfer" then
                        elements = {}

                        for k, v in pairs(GetActivePlayers()) do
                            if v ~= PlayerId() then
                                local ped = GetPlayerPed(v)
                                if #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(ped)) <= 3.0 then
                                    local foundName, startedSearch, name = false, GetGameTimer(), GetPlayerName(v) .. " | " .. GetPlayerServerId(v)
                                    
                                    ESX.TriggerServerCallback("loaf_keysystem:getRpName", function(n)
                                        if n then
                                            name = n
                                        end
                                        foundName = true
                                    end, GetPlayerServerId(v))

                                    while not foundName do
                                        if GetGameTimer() - startedSearch > 3000 then
                                            break
                                        end

                                        Wait(50)
                                    end

                                    table.insert(elements, {
                                        label = name,
                                        value = v,
                                    })
                                end
                            end
                        end

                        if #elements == 0 then
                            table.insert(elements, {label = Strings["none_nearby"], value = "none"})
                        end

                        ESX.UI.Menu.Open("default", GetCurrentResourceName(), "transferkeymenu", {
                            title = Strings["transfer"] .. " - " .. data.current.label,
                            align = "top-left",
                            elements = elements
                        }, function(data3, menu3)
                            local currentPlayer = data3.current.value
                            if currentPlayer ~= "none" then
                                local ped = GetPlayerPed(currentPlayer)
                                if #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(ped)) <= 4.0 then
                                    ESX.TriggerServerCallback("loaf_keysystem:transferKey", function(success)
                                        if success then
                                            ESX.UI.Menu.CloseAll()
                                            ESX.ShowNotification(string.format(Strings["gave_key"], data3.current.label))
                                            OpenKeyMenu()
                                        else
                                            ESX.ShowNotification(Strings["couldnt_give"])
                                        end
                                    end, GetPlayerServerId(currentPlayer), currentUnique)
                                else
                                    ESX.ShowNotification(Strings["no_longer_nearby"])
                                end
                            end
                        end, function(data3, menu3)
                            menu3.close()
                        end)
                    elseif currentValue == "use" then
                        if key_usages[currentKey] then
                            key_usages[currentKey](currentKey)
                        end
                    end
    
                end, function(data2, menu2)
                    menu2.close()
                end)

            end, function(data, menu)
                menu.close()
            end)
        end)
    end
end)

RegisterNetEvent("loaf_keysystem:setUsage")
AddEventHandler("loaf_keysystem:setUsage", function(key_id, cb)
    if key_id and type(key_id) == "string" and cb then
        key_usages[key_id] = cb
        print(cb)
    end
end)

RegisterCommand("keys", function()
    OpenKeyMenu()
end)