fx_version 'cerulean'
use_experimental_fxv2_oal 'yes'
lua54 'yes'
game 'gta5'
name 'pure_inventory'
author 'ma3iich (fork of ox_inventory by Overextended / TheOrderFivem)'
version '1.0.0'
repository 'https://github.com/ma3iich/pure_inventory'
description 'Slot-based inventory with a 3D character, clothing slots and a customisable look. Standalone or QBCore.'

provide 'ox_inventory'

dependencies {
    '/server:6116',
    '/onesync',
    'oxmysql',
    'ox_lib',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

ox_libs {
    'locale',
    'table',
    'math',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'init.lua',
    'server/version.lua',
}

client_script 'init.lua'

ui_page 'web/build/index.html'

files {
    'client.lua',
    'server.lua',
    'locales/*.json',
    'web/build/index.html',
    'web/build/assets/**',
    'web/images/*.png',
    'modules/**/shared.lua',
    'modules/**/client.lua',
    'modules/bridge/**/client.lua',
    'data/*.lua',
}
