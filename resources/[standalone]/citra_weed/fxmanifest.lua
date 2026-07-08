fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'
author 'citRa'
description 'Simple weed planting / growing script for FiveM'
version '0.0.2'

dependencies {
    '/server:6666',
    '/gameBuild:3095',
    '/onesync',
    'oxmysql',
    'ox_lib',
}

shared_scripts {
    '@ox_lib/init.lua',
    '@citra_bridge/main.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

files {
    'shared/config.lua',
    'client/menus.lua',
}
