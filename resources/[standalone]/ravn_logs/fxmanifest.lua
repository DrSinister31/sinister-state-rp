fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Ravn-dev (configured for Sinister H-Town RP)'
description 'Ravn Logs - Player action logging to Discord webhooks and NDJSON files'
version '1.0.0'
repository 'https://github.com/Ravn-dev/ravn-logs'

server_scripts {
    'config.lua',
    'server/utils.lua',
    'server/webhook.lua',
    'server/server.lua',
}

client_scripts {
    'config.lua',
    'client/client.lua',
}

dependencies {
    '/server:7290',
    '/onesync',
}
