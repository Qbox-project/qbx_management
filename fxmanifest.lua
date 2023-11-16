fx_version 'cerulean'
game 'gta5'

name 'QBX_Management'
description 'Business and gang management menu for stashes, wardrobes and shared money'
version '1.0.0'
repository 'https://github.com/Qbox-project/qbx_management'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    '@qbx_core/modules/playerdata.lua',
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'