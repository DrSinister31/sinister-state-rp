author "Debux Workshop"
description 'debux.tebex.io'
fx_version 'adamant'

game 'gta5'

version '2.0.0'

ui_page 'html/ui.html'

client_scripts {
	'functions/shared_functions.lua',
	'shared/config.lua',
	'client.lua',
	'shared/client.lua',
}

server_scripts {
	'@mysql-async/lib/MySQL.lua',
	'shared/config.lua',
	'server.lua',
	'shared/server.lua',
}

files {
	'html/ui.html',
	'html/*.css',
	'html/*.js',
	'html/img/*.png',
	'html/img/*.jpg',
	'html/font/*.ttf',
	'html/font/*.woff',
	'html/img/*.svg',
}

lua54 'yes'

escrow_ignore {
	'shared/*.lua',
	'server.lua',
	'client.lua',
}