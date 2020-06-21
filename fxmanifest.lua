fx_version 'bodacious'
game 'gta5'

author 'InZidiuZ'
description 'Legacy Fuel'
version '1.3'

-- What to run
client_scripts {
	'config.lua',
	'functions/functions_client.lua',
	'source/fuel_client.lua'
}

server_scripts {
	'config.lua',
	'source/fuel_server.lua'
}

exports {
	'GetFuel',
	'SetFuel'
}
