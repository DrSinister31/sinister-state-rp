fx_version "cerulean"
game "gta5"
description "Sinister Robberies — Texas-rethemed robbery creator | Hold-ups, heists, stick-ups with heat system & police alerts"
version "1.0.0"

shared_scripts {
	"@ox_lib/init.lua",
	"config.lua"
}

client_scripts { "client/main.lua" }
server_scripts { "server/main.lua" }

lua54 "yes"
dependencies { "ox_lib" }
