fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Sinister H-Town'
description 'Texas interaction wheel — job-smart quick actions, /me, /do, /anim, carry, GPS'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

dependencies {
    'ox_lib',
    'qbx_core',
}
