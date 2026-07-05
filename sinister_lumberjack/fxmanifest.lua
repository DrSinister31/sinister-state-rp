fx_version "cerulean"
game "gta5"
description "Piney Woods Logging Co. — Texas-themed multiplayer lumberjack job"
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

ui_page "html/index.html"

files {
    "html/index.html",
    "html/style.css",
    "html/script.js",
}

lua54 "yes"
