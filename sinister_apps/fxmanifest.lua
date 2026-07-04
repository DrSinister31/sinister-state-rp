fx_version("cerulean")
game("gta5")
description("Sinister Apps — Business Banking, TX Browser, syntok for NPWD")

server_script("dist/server/server.js")
client_script("dist/client/client.js")

files({ "dist/web/app.js" })

dependency({ "npwd" })
