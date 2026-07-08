fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Baguscodestudio'
description 'Ownable gunstore using ox_inventory shops'
version '1.0.0'

dependencies {
    'ox_lib',
    'ox_inventory',
    'oxmysql',
}

files {
    'locales/*.json'
}

shared_scripts {
    '@ox_lib/init.lua',
    'config/config.lua',
    'init.lua',
}

client_scripts {
    'client/main.lua',
    'bridge/esx/client.lua',
    'bridge/qb/client.lua',
    'bridge/qbx/client.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'bridge/esx/server.lua',
    'bridge/qb/server.lua',
    'bridge/qbx/server.lua',
}
