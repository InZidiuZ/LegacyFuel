fx_version "adamant"
game "gta5"

ui_page 'html/ui.html'

server_scripts {
	"@mysql-async/lib/MySQL.lua",
	"config.lua",
	"server.lua"
}

client_scripts {
	"config.lua",
	"client.lua"
}

dependency 'renzu_popui'
files {
  'html/ui.html',
  'html/ui.css', 
  'html/ui.js',
  'html/logo.png'
}              