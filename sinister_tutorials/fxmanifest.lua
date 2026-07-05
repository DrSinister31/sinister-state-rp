fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Sinister H-Town'
description 'In-game tutorial missions — per-job walkthroughs with NPC mentors, waypoints, and rewards'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
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
