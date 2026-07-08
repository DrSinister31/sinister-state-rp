fx_version 'cerulean'
game 'gta5'
lua54 'yes'

shared_scripts {
    'shared/*.lua',
}

client_scripts {
    '@PolyZone/client.lua',
    '@PolyZone/BoxZone.lua',
    '@ox_lib/init.lua', -- Remove if not using ox_lib
    'client/*.lua',
}

server_scripts {
    'server/*.lua'
}
