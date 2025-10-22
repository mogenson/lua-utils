local a = require("async")
local loop = require("libuv")
local Parser = require("atlas.server.http_11_parser")
local ParserErrors = require("atlas.server.parser_errors")
local http_statuses = require("atlas.server.statuses")

local Server = {}
Server.__index = Server

setmetatable(Server, {
    __call = function(_, app)
        return setmetatable({
            app = app,
            server = nil
        }, Server)
    end
})

local ASGI_VERSION = { version = "3.0", spec_version = "2.3" }

local write = a.wrap(function(socket, data, cb)
    socket:write(data, cb)
end)

local read = a.wrap(function(socket, cb)
    socket:read_start(function(data)
        socket:read_stop()
        return cb(data)
    end)
end)

local on_connection = a.sync(function(client, app)
    local receive = function()
        return {
            type = "http.request",
            body = "",
            -- Don't bother with more_body.
            -- Make the server join the body together rather than pushing
            -- that responsibility to the app.
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

    local data = a.wait(read(client))
    if data then
        local parser = Parser()
        local scope, _, parser_err = parser:parse(data) -- meta, body, parser_err

        if parser_err then
            if parser_err == ParserErrors.INVALID_REQUEST_LINE then
                a.wait(write(client, "HTTP/1.1 400 Bad Request\r\n\r\n"))
            elseif parser_err == ParserErrors.METHOD_NOT_IMPLEMENTED then
                a.wait(write(client, "HTTP/1.1 501 Not Implemented\r\n\r\n"))
            elseif parser_err == ParserErrors.VERSION_NOT_SUPPORTED then
                a.wait(write(client, "HTTP/1.1 505 HTTP Version Not Supported\r\n\r\n"))
            end
            return
        end

        scope.asgi = ASGI_VERSION
        scope.http_version = "1.1"
        -- Constant until the server supports TLS.
        scope.scheme = "http"
        scope.query_string = ""
        scope.root_path = "" -- Not supporting applications mounted at some subpath
        scope.headers = {}
        scope.client = { "127.0.0.1", 8000 }
        scope.server = { "127.0.0.1", 8000 }

        a.wait(app(scope, receive, send))

        local wire_response = {
            "HTTP/1.1 ", http_statuses[response.status or 204], "\r\n",
            "content-length: " .. #(response.body or {}) .. "\r\n",
        }

        for _, header in ipairs(response.headers or {}) do
            table.insert(wire_response, header[1] .. ": " .. header[2] .. "\r\n")
        end

        table.insert(wire_response, "\r\n")
        table.insert(wire_response, response.body)

        a.wait(write(client, table.concat(wire_response)))
    end

    client:close()
end)

-- Set up the server to handle requests.
function Server.set_up(self, config)
    self.server = loop:new_tcp()
    self.server:bind(config.host, config.port)

    print("Listening for requests on http://" .. config.host .. ":" .. config.port)

    self.server:listen(1, function()
        local client = loop:new_tcp()
        self.server:accept(client)
        a.run(on_connection(client, self.app))
    end)

    -- register SIGINT / Ctrl-C handler
    loop:new_signal():start(2, function(signum)
        loop:stop()
    end)
end

-- Run the uv loop.
---@return boolean true if there are no active handles on stop
function Server.run() return loop:run() == 0 end

return Server
