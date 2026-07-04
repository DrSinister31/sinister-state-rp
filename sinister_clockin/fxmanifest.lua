fx_version "cerulean"
game "gta5"
description "Sinister Clock-In — GPS-zoned employee shift tracking"
version "1.0.0"

shared_scripts { "@ox_lib/init.lua" }
client_scripts { "client/main.lua" }
server_scripts { "server/main.lua" }

lua54 "yes"
