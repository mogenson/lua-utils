local main = require("atlas.server.main")

local Server = require("atlas.server.server")
local Application = require("atlas.application")
local Route = require("atlas.route")
local Response = require("atlas.response")
local luv = luv or require("luv")

local function home()
    local uname = luv.os_uname()

    local hello = "Hello from " .. uname.sysname .. " " .. uname.release
    local mem = "Using " .. collectgarbage("count") .. " Kb"

    local html = [[
    <html>
    <head>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/water.css@2/out/water.css">
    </head>
    <body>]]

    for _, content in ipairs({ hello, mem }) do
        html = html .. "<p>" .. content .. "</p>"
    end

    return html .. "</body></html>"
end

local controllers = {
    home = function(request) return Response(home()) end
}

local routes = {
    Route("/", controllers.home)
}

local app = Application(routes)

coroutine.wrap(function()
    local config = { host = "127.0.0.1", port = 8080 }
    local server = Server(app)
    local status = main.run(config, server, app)
    os.exit(status)
end)()
