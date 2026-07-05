fx_version 'cerulean'
game 'gta5'
lua54 'yes'

client_scripts {
    'client/client.lua',
}

server_scripts {
    'server/server.lua',
}

files {
    'web/dist/index.html',
    'web/dist/**/*',
}

server_exports {
    'getCurrentWeather',
}

ui_page 'web/dist/index.html'
