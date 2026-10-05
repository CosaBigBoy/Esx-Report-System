fx_version 'cerulean'
game 'gta5'

author 'COSA'
description ''
version '1.1.0'

lua54 'yes'

shared_script 'config.lua'

client_script 'client.lua'
server_script 'server.lua'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

dependencies {
    'es_extended'
}
