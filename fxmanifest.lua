fx_version  "cerulean"
use_experimental_fxv2_oal   "yes"
lua54       "yes"
game        "gta5"

name        "x-vehicleremote"
version     "0.0.0"
repository  "https://github.com/XProject/x-vehicleremote"
description "Project-X Vehicle Remote: Synced Vehicle Remote & Engine System"

ui_page "web/index.html"

files {
    "web/**"
}

shared_scripts {
    "shared/*.lua",
}

server_scripts {
    "server/*.lua"
}

client_scripts {
    "client/*.lua",
}