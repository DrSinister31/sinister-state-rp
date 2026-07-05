fx_version "cerulean"
game "gta5"
description "H-Town Midnight Runs — Texas underground street racing | Wager races, muscle cars, police alerts, leaderboards"
version "1.0.0"

shared_scripts {
	"@ox_lib/init.lua",
	"config.lua"
}

client_scripts { "client/main.lua" }
server_scripts { "server/main.lua" }

lua54 "yes"
dependencies { "ox_lib" }
