fx_version 'adamant'
game 'gta5'
description 'ESX Key system'
version '0.2.0'

server_script '@mysql-async/lib/MySQL.lua'
server_script 'server/*.lua'
client_script 'client/*.lua'
shared_script 'config.lua'

dependency 'es_extended'