--[[ FX Information ]]--
fx_version   'cerulean'
use_experimental_fxv2_oal 'yes'
lua54        'yes'
game         'gta5'

--[[ Resource Information ]]--
name         'bzzz_chess'
version      '1.1.0'
description  'Chess'
author       'BzZz'

this_is_a_map 'yes'


--[[ Manifest ]]--
shared_scripts {
}

client_scripts {
}

server_scripts {
}

escrow_ignore {
	'stream/*.ydr',	
	'data/*.lua'		
}

dependencies {

}



data_file 'DLC_ITYP_REQUEST' 'stream/*.ytyp'

files {
    'stream/*.ytyp',
}




dependency '/assetpacks'