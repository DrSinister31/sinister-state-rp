fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'Sinister State'
description 'Phone apps — Business Banking, Texas Browser, syntok'
version '1.0.0'

ui_page 'html/index.html'

server_scripts { 'server/main.lua' }
client_scripts { 'client/main.lua' }

files {
    'html/index.html',
    'html/banking.html',
    'html/browser.html',
    'html/syntok.html',
    'html/style.css',
    'html/script.js',
}
