fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author 'myth1caldev'
description 'Simple Taxi Job'
version '1.0.0'

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'shared/locales.lua'
}

dependencies {
    'ox_lib',
    'ox_target',
    'ox_inventory'
}
