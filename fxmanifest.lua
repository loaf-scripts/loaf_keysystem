fx_version "cerulean"
game "gta5"
description "Keysystem for FiveM, works with ESX & QBCore."
lua54 "yes"
version "2.0.1"
author "Loaf Scripts#7785"

shared_script "config.lua"
server_script {
    "@mysql-async/lib/MySQL.lua",
    "@oxmysql/lib/MySQL.lua",
    "logs.lua",
    "server/*.lua"
}
client_script "client/*.lua"

dependency "loaf_lib" -- https://github.com/loaf-scripts/loaf_lib
