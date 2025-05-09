--[[ FX Information ]]--
fx_version   'cerulean'
use_experimental_fxv2_oal 'yes'
lua54        'yes'
game         'gta5'

--[[ Resource Information ]]--
name         'bub-multichar'
version      '1.0.0'
author       'Bubble - Edited by Cartier'
description  'ESX Multicharacter System'

--[[ Dependencies ]]--
dependencies {
	'es_extended',
	'oxmysql',
	'ox_lib',
	'illenium-appearance'
}

--[[ Manifest ]]--
shared_scripts {
	'@es_extended/imports.lua',
	'@ox_lib/init.lua',
	'config/*.lua'
}

client_scripts {
	'client/main.lua',
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'server/main.lua',
}

ui_page 'web/build/index.html'

files {
	'web/build/index.html',
	'web/build/**/*',
	'config/client.lua',
	'config/shared.lua',
}