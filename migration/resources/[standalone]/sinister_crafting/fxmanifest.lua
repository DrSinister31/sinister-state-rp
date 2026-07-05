fx_version "cerulean"
game "gta5"
description "Sinister Crafting — Texas-rethemed advanced crafting | Bluebonnet Batch, Hill Country Still, Third Ward Lab, Lone Star Forge"
version "1.0.0"

shared_scripts {
	"@ox_lib/init.lua",
	"config.lua"
}

client_scripts { "client/main.lua" }
server_scripts { "server/main.lua" }

lua54 "yes"
dependencies { "ox_lib", "ox_inventory" }
