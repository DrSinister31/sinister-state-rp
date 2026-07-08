fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'attano_pawnshop'
description 'Attano Pawnshop System (ox_inventory + NUI)'
version '1.0.0'

ui_page 'html/index.html'

files {
    'html/*'
}

shared_scripts {
    'middleware/latest_utils.js',
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

dependencies {
    'ox_lib',
    'ox_target',
    'ox_inventory'
}
