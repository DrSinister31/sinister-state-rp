fx_version "cerulean"
game "gta5"
description "Lone Star Logistics — Texas-themed trucking job system"
version "1.0.0"
author "Sinister State"

shared_scripts {
    "@ox_lib/init.lua",
    "shared/config.lua",
}

client_scripts {
    "client/main.lua",
}

server_scripts {
    "server/main.lua",
}

lua54 "yes"
