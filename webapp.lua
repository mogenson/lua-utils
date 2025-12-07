local a = require("async")
local curl = require("libcurl")
local json = require("json")
local loop = require("libuv")

local List = require("pl.List")
local operator = require("pl.operator")

local Application = require("alf.application")
local Response = require("alf.response")
local Route = require("alf.route")
local Server = require("alf.server")

---Sleep current async task until time has elapsed
---@param ms number duration in milliseconds
---@param cb fun()
local sleep = a.wrap(function(ms, cb) ---@diagnostic disable-line:unused-local
    loop:timer():start(ms, cb)
end)

---Perform an HTTP GET request for remote URL
---@param url string
---@param cb fun(data: string|nil, err: string|nil)
local fetch = a.wrap(function(url, cb)
    curl.GET(url, cb)
end)

---Fetch next arrival time
---@param route string name of the mbta route
---@param stop number id of mbta stop
---@return string arrival time
local eta = a.sync(function(route, stop)
    local url = "https://api-v3.mbta.com/predictions?page[limit]=1&filter[route]=%s&filter[stop]=%d"
    return a.wait(fetch(url:format(route, stop)))
end)

---Convert a timestamp string to number of seconds since midnight
---@param timestamp string
---@return number
local function to_seconds(timestamp)
    local h, m, s = timestamp:match("T(%d%d):(%d%d):(%d%d)")
    h, m, s = tonumber(h), tonumber(m), tonumber(s)
    if not (h and m and s) then return math.huge end
    return (h * 3600) + (m * 60) + s
end

---Generate HTML home page
---@param request Request
---@return Response
local function home(request) ---@diagnostic disable-line:unused-local
    local html = { [[
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.5">
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

---Return bus arrivals
---@param request Request
---@return Response
local function arrivals(request) ---@diagnostic disable-line:unused-local
    local date = os.date("*t")
    local now = (date.hour * 3600) + (date.min * 60) + date.sec

    return Response(([[
Teele Square
    87 bus: %s min
    88 bus: %s min
Davis Square
    87 bus: %s min
    88 bus: %s min
    Red line: %s min
Kendall Square
    Red line: %s min

As of: %2d:%02d]]):format(table.unpack(
        List(table.pack(a.wait(a.gather({
            -- Teele Square
            eta("87", 2576),
            eta("88", 2576),
            -- Davis Square
            eta("87", 5104),
            eta("88", 5104),
            eta("Red", 70063),
            -- Kendall Square
            eta("Red", 70072)
        }))))
        :map(json.decode)
        :map(function(data) return data.data[1].attributes.arrival_time or "" end)
        :map(to_seconds)
        :map(operator.sub, now)
        :map(operator.div, 60)
        :map(math.max, 0)
        :map(math.floor)
        :append(date.hour)
        :append(date.min))))
end

---Shutdown the server
---@param request Request
---@return Response
local function shutdown(request) ---@diagnostic disable-line:unused-local
    return setmetatable({ response = Response(), }, {
        __call = function(self, send)
            self.response(send)
            print("goodbye")
            loop:shutdown() -- shutdown after response is sent
        end
    })
end

local routes = {
    Route("/", home),
    Route("/arrivals", arrivals),
    Route("/shutdown", shutdown),
}
local app = Application(routes)
local server = Server(app)
local host = "127.0.0.1"
local port = 8000

-- open web browser
local command = jit.os == "OSX" and "open" or jit.os == "Linux" and "termux-open-url" or "echo"
os.execute(("%s http://%s:%d"):format(command, host, port))

-- run server
os.exit(server(host, port) and 0 or 1)
