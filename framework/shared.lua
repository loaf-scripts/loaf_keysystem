if Config.Framework == "auto" then
    if GetResourceState("es_extended") ~= "missing" then
        Config.Framework = "esx"
    elseif GetResourceState("qb-core") ~= "missing" then
        Config.Framework = "qb-core"
    else
        print("^3[WARNING]^7: Failed to automatically set framework. Please set it manually in loaf_keysystem/config/config.lua.")
        Config.Framework = "standalone"
    end
end
