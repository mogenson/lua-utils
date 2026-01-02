local a = require("async")
local curl = require("libcurl")
local json = require("json")
local loop = require("libuv")

local seq = require("pl.seq")
local operator = require("pl.operator")

local Application = require("alf.application")
local Element = require("alf.element")
local Response = require("alf.response")
local Route = require("alf.route")
local Server = require("alf.server")

local Body = Element.Body
local Br = Element.Br
local Div = Element.Div
local Footer = Element.Footer
local H1 = Element.H1
local Head = Element.Head
local Header = Element.Header
local Hr = Element.Hr
local Html = Element.Html
local Input = Element.Input
local Ins = Element.Ins
local Link = Element.Link
local Main = Element.Main
local Mark = Element.Mark
local Meta = Element.Meta
local P = Element.P
local Pre = Element.Pre
local Script = Element.Script
local Title = Element.Title

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
    local html = Html(nil, {
        Head(nil, {
            Title(nil, "NextBus"),
            Meta()
                :addAttribute("name='viewport'")
                :addAttribute("content='width=device-width, initial-scale=1'"),
            Link()
                :addAttribute("rel='stylesheet'")
                :addAttribute("href='https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.fluid.classless.min.css'"),
            Script({ "src='https://cdn.jsdelivr.net/npm/htmx.org@2/dist/htmx.min.js'" }),
        }),
        Body(nil, {
            Header(nil, H1(nil, "Arrivals")),
            Main(nil, {
                Pre()
                    :addAttribute("id='arrivals'")
                    :addAttribute("hx-get='/arrivals'")
                    :addAttribute("hx-trigger='load'")
                    :setContent("Loading arrival times..."),
                P({ "id='last-update'" }, "Waiting for update..."),
                Br(),
                Input()
                    :addAttribute("type='button'")
                    :addAttribute("value='Refresh'")
                    :addAttribute("hx-get='/arrivals'")
                    :addAttribute("hx-target='#arrivals'")
                    :addAttribute("hx-swap='innerHTML'"),
                Input()
                    :addAttribute("type='button'")
                    :addAttribute("value='Close'")
                    :addAttribute("hx-post='/shutdown'")
                    :addAttribute("hx-on::after-request='window.close()'"),
            }),
            Hr(),
            Footer(nil, {
                P(nil, { "LibUV time: ", Ins(nil, function() return loop:now() end) }),
                P(nil, { "Using ", Mark(nil, function() return collectgarbage("count") end), "Kb" })
            }),
        }),
    })

    return Response(html)
end

---Return bus arrivals
---@param request Request
---@return Response
local function arrivals(request) ---@diagnostic disable-line:unused-local
    local times = table.pack(a.wait(a.gather({
        -- Teele Square
        eta("87", 2576),
        eta("88", 2576),
        -- Davis Square
        eta("87", 5104),
        eta("88", 5104),
        eta("Red", 70063),
        -- Kendall Square
        eta("Red", 70072)
    })))
    local date = os.date("*t")
    local now = (date.hour * 3600) + (date.min * 60) + date.sec
    local updated = Div()
        :addAttribute("id='last-update'")
        :addAttribute("hx-swap-oob='true'")
        :setContent(("Last updated: %2d:%02d:%02d"):format(date.hour, date.min, date.sec))

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
]]):format(table.unpack(seq(times)
            :map(json.decode)
            :map(function(data) return data.data[1].attributes.arrival_time or "" end)
            :map(to_seconds)
            :map(operator.sub, now)
            :map(operator.div, 60)
            :map(math.max, 0)
            :map(math.floor)
            :copy()))
        .. updated:render()
    )
end

---Shutdown the server
---@param request Request
---@return Response
local function shutdown(request) ---@diagnostic disable-line:unused-local
    local response = Response()
    local send = response.send
    response.send = function(self, sender)
        send(self, sender)
        print("goodbye")
        loop:shutdown()     -- shutdown after response is sent
    end
    return response
end

local routes = {
    Route("/", home),
    Route("/arrivals", arrivals),
    Route("/shutdown", shutdown, { "POST" }),
}
local app = Application(routes)
local server = Server(app)
local host = "127.0.0.1"
local port = 8000

-- open web browser
local command = jit.os == "OSX" and "open" or jit.os == "Linux" and "termux-open-url" or "echo"
os.execute(("%s http://%s:%d"):format(command, host, port))

-- run server
os.exit(server:serve(host, port) and 0 or 1)
