fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'EasyAdmin (configured for Sinister H-Town RP)'
description 'EasyAdmin v6 — Full admin suite for Sinister H-Town RP. Replaces qbx_adminmenu.'
version '1.0.0'

shared_scripts {
    'config.lua'
}

server_scripts {
    'config.lua',
    'server/server.lua',
    'server/commands.lua',
    'server/ban_system.lua',
    'server/report_system.lua'
}

client_scripts {
    'config.lua',
    'client/client.lua',
    'client/nui.lua',
    'client/commands.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/media/*'
}

dependencies {
    'oxmysql'
}
