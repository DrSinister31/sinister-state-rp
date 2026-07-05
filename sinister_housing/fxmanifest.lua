fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Sinister H-Town'
description 'Texas apartment & housing system — door teleport, ownership, rentals'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/doors.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/ownership.lua',
}

dependencies {
    'ox_lib',
    'oxmysql',
    'ox_target',
    'qbx_core',
    'bob74_ipl',
}
