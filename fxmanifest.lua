fx_version 'cerulean'
game 'gta5'

description 'qbx_management'
repository 'https://github.com/Qbox-project/qbx_management'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/utils.lua',
    '@qbx_core/shared/locale.lua',
	'locales/en.lua',
	'locales/*.lua',
}

client_scripts {
    '@qbx_core/modules/playerdata.lua',
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/storage.lua'
}

files {
    'config/shared.lua',
    'config/client.lua',
    'config/server.lua'
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'
