Config = {}

Config.Debug = true

Config.Framework = "auto" --[[
    Supported:
    -   qb-core
    -   esx
    -   standalone
    -   auto
]]

Config.Language = "en" -- see config/locales.lua

Config.MenuSystem = "framework" --[[
    Supported:
    -   framework (will use esx_menu_default or qb-menu)
    -   esx_context (esx context menu)
    -   ox_lib (https://overextended.dev/ox_lib/Modules/Interface/Client/menu)
]]

Config.MenuAlign = "top-left"

Config.TransferDistance = 3.0

Config.Command = "keys" -- false to disable
Config.Keybind = "PAGEUP" -- false to disable (requires command)

Config.UseRPName = true -- use the in-game name when giving keys instead of fivem name + id?
