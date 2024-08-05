fx_version "cerulean"
game "gta5"
lua54 "yes"
use_experimental_fxv2_oal "yes"

name "loaf_keysystem"
author "Loaf Scripts"
description "Keysystem for FiveM, works with ESX, QBCore or Standalone."
version "3.0.0"

shared_script {
    "config/*.lua",
    "shared/*.lua",
    "framework/shared.lua"
}

client_script {
    "framework/**/client.lua",
    "client/*.lua"
}

server_script {
    "@mysql-async/lib/MySQL.lua",
    "framework/**/server.lua",
    "server/*.lua"
}

escrow_ignore {
    "framework/**/*.lua",
    "config/**/*.lua"
}

dependency "loaf_lib" -- https://github.com/loaf-scripts/loaf_lib
