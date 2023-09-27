fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'qbx-management'
description 'Business and gang management menu for stashes, wardrobes and shared money'
version '1.0.0'
repository 'https://github.com/Qbox-project/qbx-management'

shared_scripts {
    '@qbx_core/import.lua',
    '@ox_lib/init.lua',
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
    'qbx_core:utils',
    'qbx_core:core',
    'qbx_core:playerdata',
}
