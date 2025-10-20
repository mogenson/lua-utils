local main = require("atlas.server.main")

local Server = require("atlas.server.server")
local Application = require("atlas.application")
local Route = require("atlas.route")
local Response = require("atlas.response")

local function home()
    local html = { [[
    <html>
    <head>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/water.css@2/out/water.css">
    </head>
    <body>]] }

    table.insert(html, "<p>Hello from " .. io.popen("uname"):read() .. "</p>")
    table.insert(html, "<p>Using " .. collectgarbage("count") .. " Kb</p>")

    table.insert(html, "</body></html>")

    return table.concat(html)
end

local controllers = {
    home = function(request) return Response(home()) end
}

local routes = {
    Route("/", controllers.home)
}

local app = Application(routes)
local config = { host = "127.0.0.1", port = 8080 }
local server = Server(app)

if not main.run(config, server, app) then os.exit(-1) end
