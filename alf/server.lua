local a = require("async")
local loop = require("libuv")
local Parser = require("alf.parser")
local utils = require("pl.utils")

local http_status = {
    -- 1xx - https://httpwg.org/specs/rfc7231.html#status.1xx
    [100] = "100 Continue",
    [101] = "101 Switching Protocols",
    -- 2xx - https://httpwg.org/specs/rfc7231.html#status.2xx
    [200] = "200 OK",
    [201] = "201 Created",
    [202] = "202 Accepted",
    [203] = "203 Non-Authoritative Information",
    [204] = "204 No Content",
    [205] = "205 Reset Content",
    [206] = "206 Partial Content", -- RFC7233
    -- 3xx - https://httpwg.org/specs/rfc7231.html#status.3xx
    [300] = "300 Multiple Choices",
    [301] = "301 Moved Permanently",
    [302] = "302 Found",
    [303] = "303 See Other",
    [304] = "304 Not Modified", -- RFC7232
    [305] = "305 Use Proxy",
    [306] = "306 (Unused)",
    [307] = "307 Temporary Redirect",
    -- 4xx - https://httpwg.org/specs/rfc7231.html#status.4xx
    [400] = "400 Bad Request",
    [401] = "401 Unauthorized", -- RFC7235
    [402] = "402 Payment Required",
    [403] = "403 Forbidden",
    [404] = "404 Not Found",
    [405] = "405 Method Not Allowed",
    [406] = "406 Not Acceptable",
    [407] = "407 Proxy Authentication Required", -- RFC7235
    [408] = "408 Request Timeout",
    [409] = "409 Conflict",
    [410] = "410 Gone",
    [411] = "411 Length Required",
    [412] = "412 Precondition Failed", -- RFC7232
    [413] = "413 Payload Too Large",
    [414] = "414 URI Too Long",
    [415] = "415 Unsupported Media Type",
    [416] = "416 Range Not Satisfiable", -- RFC7233
    [417] = "417 Expectation Failed",
    [426] = "426 Upgrade Required",
    -- 5xx - https://httpwg.org/specs/rfc7231.html#status.5xx
    [500] = "500 Internal Server Error",
    [501] = "501 Not Implemented",
    [502] = "502 Bad Gateway",
    [503] = "503 Service Unavailable",
    [504] = "504 Gateway Timeout",
    [505] = "505 HTTP Version Not Supported",
}

---Helper utility to load Lua module from path
---@param app string|Application path to require app or Application
---@return Application
local function load_app(app)
    local app_type = type(app)
    if app_type == "table" then
        return app
    elseif app_type == "string" then
        local app_module, app_name = utils.splitv(app, ":", false, 2)
        local module = require(app_module)
        app = module[app_name]
        if not app then
            error(("No app named '%s' found in module '%s'"):format(app_name, app_module))
        end
        return app
    else
        error(("Invalid app type: %s"):format(app_type))
    end
end

---@class Server
---@field app Application
---@field server ffi.cdata*
local Server = {}
Server.__index = Server

setmetatable(Server, {
    ---Create an HTTP web server
    ---@param app string|Application
    ---@return Server
    __call = function(_, app)
        return setmetatable({
            app = load_app(app),
            server = nil
        }, Server)
    end
})

local write = a.wrap(function(socket, data, cb)
    socket:write(data, cb)
end)

local on_connection = a.sync(function(client, app)
    local q = a.queue()
    client:read_start(function(data) q:put(data) end)

    local parser = Parser()
    local read = a.sync(function() return a.wait(q:get()) end)
    local scope, body, err = a.wait(parser(read))

    if err then
        if err == Parser.INVALID_REQUEST_LINE then
            a.wait(write(client, "HTTP/1.1 400 Bad Request\r\n\r\n"))
        elseif err == Parser.METHOD_NOT_IMPLEMENTED then
            a.wait(write(client, "HTTP/1.1 501 Not Implemented\r\n\r\n"))
        elseif err == Parser.VERSION_NOT_SUPPORTED then
            a.wait(write(client, "HTTP/1.1 505 HTTP Version Not Supported\r\n\r\n"))
        end
        client:close()
        return
    end

    local receive = function()
        return {
            type = "http.request",
            body = body or "",
            more_body = false,
        }
    end

    local response = {}
    local send = function(event)
        if event.type == "http.response.start" then
            response.status = event.status
            response.headers = event.headers
        elseif event.type == "http.response.body" then
            response.body = event.body
        end
    end

    a.wait(app(scope, receive, send))

    local wire_response = {
        "HTTP/1.1 ", http_status[response.status or 204], "\r\n",
        "content-length: " .. #(response.body or {}) .. "\r\n",
    }

    for _, header in ipairs(response.headers or {}) do
        table.insert(wire_response, header[1] .. ": " .. header[2] .. "\r\n")
    end

    table.insert(wire_response, "\r\n")
    table.insert(wire_response, response.body)

    a.wait(write(client, table.concat(wire_response)))

    client:close()
end)

---Start the server and run the libuv loop
---@param self Server
---@param host string
---@param port number
---@return boolean true if there are no active handles on stop
function Server.__call(self, host, port)
    self.server = loop:tcp()
    self.server:bind(host, port)

    self.server:listen(1, function()
        local client = loop:tcp()
        self.server:accept(client)
        a.run(on_connection(client, self.app))
    end)

    -- register SIGINT / Ctrl-C handler
    loop:signal():start(2, function(signum)
        loop:shutdown()
    end)

    print(("Listening for requests on http://%s:%d"):format(host, port))

    return loop:run() == 0
end

return Server
