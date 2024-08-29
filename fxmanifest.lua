fx_version 'cerulean'
lua54 'yes'
game 'gta5'

name 'pan-containers'
author 'Panzo'
version '1.0.0'
license 'LGPL-3.0-or-later'
repository 'https://github.com/simsonas86/pan-containers.git'
description 'A resource to create and manage storage containers'

dependencies {
  'ox_lib',
  'ox_inventory',
  'ox_target'
}

client_script {
  'client/*.lua',
}

server_script {
  '@oxmysql/lib/MySQL.lua',
  'server/*.lua',
}

shared_script {
  '@ox_lib/init.lua',
  'shared/*.lua',
}

files {
  'locales/*.json'
}

ox_lib 'locale'