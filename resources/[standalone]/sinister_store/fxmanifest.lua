fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'power-scripts.com (configured for Sinister H-Town RP)'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua',
    'server/package_handler.lua',
    'server/database.lua',
}

client_scripts {
    'client/client.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/config.js',
}

dependencies {
    'oxmysql',
    'ox_lib',
}
