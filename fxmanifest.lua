fx_version 'cerulean'
game 'gta5'

name 'qb-management'
description 'Business and gang management menu for stashes, wardrobes and shared money'
version '1.0.0'
repository 'https://github.com/Qbox-project/qb-management'

shared_scripts {
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

lua54 'yes'
