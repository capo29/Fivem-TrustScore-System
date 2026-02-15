fx_version 'cerulean'
game 'gta5'

author 'Kites'
description 'Staff System by Kites (ACE perms + MySQL + Trustscore)'
version '1.0.0'

shared_script 'config.lua'

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server.lua'
}

client_script 'client.lua'
