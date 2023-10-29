if Config.Framework ~= "qb-core" then
    return
end

local QB = exports["qb-core"]:GetCoreObject()

CreateThread(function()
    while not LocalPlayer.state.isLoggedIn do
        Wait(500)
    end

    Loaded = true
end)