local a = require("async")
local curl = require("libcurl")
local json = require("json")
local loop = require("libuv")
local dbg = require("debugger")

local main = require("alf.server.main")
local Application = require("alf.application")
local Response = require("alf.response")
local Route = require("alf.route")
local Server = require("alf.server.server")

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

---Fetch next arrival time
---@param route string name of the mbta route
---@param stop number id of mbta stop
---@return string arrival time
local nextbus = a.sync(function(route, stop)
    local url = "https://api-v3.mbta.com/predictions?page[limit]=1&filter[route]=%s&filter[stop]=%d"
    local encoded = a.wait(fetch(url:format(route, stop)))
    local decoded = json.decode(encoded)
    return decoded.data[1].attributes.arrival_time:match("T(%d%d:%d%d)")
end)

local function home(request)
    local html = { [[
<html>
<head>
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/water.css@2/out/water.css">
</head>
<body>
<h1>Arrivals</h1>
<pre id="arrivals">
  Click "Refresh" to load arrival times.
</pre>
<button id="refresh_button">Refresh</button>
<button id="close_button">Close</button>
<script>
  document.getElementById('refresh_button').addEventListener('click', function() {
    fetch('/arrivals')
      .then(response => response.text())
      .then(data => {
        document.getElementById('arrivals').innerHTML = data;
      });
  });
  document.getElementById('close_button').addEventListener('click', function() {
    fetch('/shutdown')
      .then(response => {
        window.close();
      });
  });
document.getElementById('refresh_button').click()
</script>
]] }

    table.insert(html, "<p>LibUV time: " .. loop:now() .. "</p>")
    table.insert(html, "<p>Using " .. collectgarbage("count") .. " Kb</p>")
    table.insert(html, "</body>\r\n</html>")

    return Response(table.concat(html, "\r\n"))
end

local function arrivals(request)
    local content = ([[
Teele Square
    87 bus: %s
    88 bus: %s
Davis Square
    87 bus: %s
    88 bus: %s
    Red line: %s
Kendall Square
    Red line: %s
    ]]):format(
        a.wait(a.gather({
            -- Teele Square
            nextbus("87", 2576),
            nextbus("88", 2576),
            -- Davis Square
            nextbus("87", 5104),
            nextbus("88", 5104),
            nextbus("Red", 70063),
            -- Kendall Square
            nextbus("Red", 70072)
        }))

    )
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
