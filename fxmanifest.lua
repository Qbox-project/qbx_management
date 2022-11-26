fx_version 'cerulean'
game 'gta5'

description 'qb-management'
version '2.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@qb-core/shared/locale.lua',
	'locales/en.lua',
    'config.lua'
}

client_scripts {
    'client/cl_util.lua',
    'client/cl_boss.lua',
    'client/cl_gang.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/sv_util.lua',
    'server/sv_boss.lua',
    'server/sv_gang.lua'
}

lua54 'yes'