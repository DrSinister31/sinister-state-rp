fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Sinister State'
description 'Ambient AI system — police, EMS, criminal, civilian NPCs with identity markers'
version '1.0.0'

server_scripts {
    'server/identity.lua',
    'server/police_ai.lua',
    'server/criminal_ai.lua',
    'server/civilian_ai.lua',
}

client_scripts {
    'client/state_listener.lua',
}
