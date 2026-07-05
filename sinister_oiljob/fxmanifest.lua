fx_version "cerulean"
game "gta5"
description "Texas Crude Co. — Multiplayer oil rig job system"
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
