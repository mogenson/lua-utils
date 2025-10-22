local a = require("async")
local loop = require("libuv")
local main = require("atlas.server.main")
local Server = require("atlas.server.server")
local Application = require("atlas.application")
local Route = require("atlas.route")
local Response = require("atlas.response")

local sleep = a.wrap(function(ms, cb)
    loop:timer():start(ms, cb)
end)

local function home(request)
    local html = { [[
<html>
<head>
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/water.css@2/out/water.css">
</head>
<body>]] }

    print("before sleep")
    table.insert(html, "<p>LibUV time before sleep: " .. loop:now() .. "</p>")

    a.wait(sleep(1000))

    table.insert(html, "<p>LibUV time after sleep: " .. loop:now() .. "</p>")
    print("after sleep")

    table.insert(html, "<p>Using " .. collectgarbage("count") .. " Kb</p>")

    table.insert(html, "</body>\r\n</html>")

    return Response(table.concat(html, "\r\n"))
end

local controllers = { home = home }
local routes = { Route("/", controllers.home) }
local config = { app = Application(routes), host = "127.0.0.1", port = 8080 }

os.exit(main.run(config) and 0 or -1)
