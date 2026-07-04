fx_version "cerulean"
game "gta5"
description "Sinister CAD — Police MDT, plate scanner, speed radar for NPWD"
version "1.0.0"

client_script "client/client.lua"
server_script "server/server.lua"
ui_page "web/dist/index.html"

files { "web/dist/**/*" }
lua54 "yes"
use_experimental_fxv2_oal "yes"
