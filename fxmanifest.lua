fx_version "cerulean"
game "gta5"
lua54 "yes"

author "Prodigy Studios"
description "prp-bridge - A framework bridge for Prodigy Studios resources"
version "1.0.1"

ui_page "ui/index.html"

shared_scripts {
    "@ox_lib/init.lua",
    "config.lua",
    "vehicleConfig.lua",
    "import.lua",
    "shared.lua"
}

client_scripts {
    "groups/client.lua",
    "cooldowns/client.lua",
    "attachobject/client.lua",
    "attachobject/clientVeh.lua",
    "allowlist/client.lua",
    "pedinteractions/client.lua",
    "propplacer/client.lua",
    "main/client.lua",
    "utils/vehicleData.lua",
    "utils/tpToCoords.lua",
    "caseopening/client.lua"
}

server_scripts {
    "@oxmysql/lib/MySQL.lua",
    "groups/server.lua",
    "cooldowns/server.lua",
    "main/server.lua",
    "utils/versionCheck.lua",
    "utils/lootGenerator.lua",
    "utils/spawnVehicle.lua",
    "utils/vehicleData.lua",
    "uniqueue/classes/*.lua",
    "uniqueue/*.lua",
    "attachobject/server.lua",
    "allowlist/server.lua",
    "sellshops/server.lua",
    "caseopening/server.lua"
}

escrow_ignore {
    "*.lua",
    "*/**.lua",
}

files {
    "modules/**/client.lua",
    "locales/*.json",
    "ui/**/*",
    "sounds/*.ogg",
}
