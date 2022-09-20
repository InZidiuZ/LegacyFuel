fx_version 'cerulean'
game 'gta5'

author 'InZidiuZ'
description 'Legacy Fuel'
version '1.3'

shared_script 'config.lua'

client_scripts {
	'functions/functions_client.lua',
	'source/fuel_client.lua'
}

server_scripts {
	'source/fuel_server.lua'
}

lua54 'yes'
