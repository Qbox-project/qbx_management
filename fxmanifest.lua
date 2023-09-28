fx_version 'cerulean'
game 'gta5'

name 'qbx_management'
description 'Business and gang management menu for stashes, wardrobes and shared money'
version '1.0.0'
repository 'https://github.com/Qbox-project/qbx_management'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/import.lua',
    'config.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

modules {
    'qbx_core:playerdata'
}

lua54 'yes'
