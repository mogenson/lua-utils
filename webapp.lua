local a = require("async")
local loop = require("libuv")
local main = require("alf.server.main")
local Server = require("alf.server.server")
local Application = require("alf.application")
local Route = require("alf.route")
local Response = require("alf.response")
local curl = require("libcurl")

---Sleep current async task until time has elapsed
---@param ms number duration in milliseconds
---@param cb function completion callback
local sleep = a.wrap(function(ms, cb)
    loop:timer():start(ms, cb)
end)

---Perform an HTTP GET request for remote URL
---@param url string
---@return string content
local fetch = a.sync(function(url)
    local q = a.queue()
    curl:add(url,
        function(str) q:put(str) end,
        function(result) q:put(nil) end)
    local content, chunk = {}, nil
    repeat
        chunk = a.wait(q:get())
        table.insert(content, chunk)
    until not chunk
    return table.concat(content)
end)

local function home(request)
    local html = { [[
<html>
<head>
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/water.css@2/out/water.css">
</head>
<body>]] }

    table.insert(html, "<p>LibUV time: " .. loop:now() .. "</p>")

    table.insert(html, "<p>Using " .. collectgarbage("count") .. " Kb</p>")

    table.insert(html, "</body>\r\n</html>")

    return Response(table.concat(html, "\r\n"))
end

local function arrivals(request)
    local content = a.wait(fetch("https://httpbin.org/json"))
    print(content)
    return Response(content, "text/plain")
end

local controllers = { home = home, arrivals = arrivals }
local routes = { Route("/", controllers.home), Route("/arrivals", controllers.arrivals) }
local config = { app = Application(routes), host = "127.0.0.1", port = 8080 }

-- open web browser
local command = jit.os == "OSX" and "open" or jit.os == "Linux" and "termux-open-url" or "echo"
os.execute(("%s http://%s:%d"):format(command, config.host, config.port))

-- run server
os.exit(main.run(config) and 0 or -1)
