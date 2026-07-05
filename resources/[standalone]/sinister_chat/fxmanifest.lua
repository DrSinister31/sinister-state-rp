fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Sinister H-Town RP'
description 'Sinister Chat — Full chat replacement for Sinister H-Town RP'
version '1.0.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'config.lua',
    'client/client.lua'
}

server_scripts {
    'config.lua',
    'server/server.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/emoji.json',
    'locales/en.lua'
}

dependencies {}

exports {
    'getOnlineCount'
}
