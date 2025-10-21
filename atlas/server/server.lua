local a = require("async")
local loop = require("libuv")
local Parser = require("atlas.server.http_11_parser")
local ParserErrors = require("atlas.server.parser_errors")
local http_statuses = require("atlas.server.statuses")

local Server = {}
Server.__index = Server

local function _init(_, app)
    local self = setmetatable({}, Server)
    self._server = nil
    self._app = app

    return self
end
setmetatable(Server, { __call = _init })

local ASGI_VERSION = { version = "3.0", spec_version = "2.3" }

--[[
local function on_connection(client, app)
    client:read_start(function(data)
        -- TODO: Pass along any request body data.
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

        if data then
            local parser = Parser()
            local scope, _, parser_err = parser:parse(data) -- meta, body, parser_err

            if parser_err then
                if parser_err == ParserErrors.INVALID_REQUEST_LINE then
                    client:write("HTTP/1.1 400 Bad Request\r\n\r\n")
                elseif parser_err == ParserErrors.METHOD_NOT_IMPLEMENTED then
                    client:write("HTTP/1.1 501 Not Implemented\r\n\r\n")
                elseif parser_err == ParserErrors.VERSION_NOT_SUPPORTED then
                    client:write("HTTP/1.1 505 HTTP Version Not Supported\r\n\r\n")
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

            app(scope, receive, send)

            local wire_response = {
                "HTTP/1.1 ", http_statuses[response.status], "\r\n",
                "content-length: " .. #response.body .. "\r\n",
            }

            for _, header in ipairs(response.headers) do
                table.insert(wire_response, header[1] .. ": " .. header[2] .. "\r\n")
            end

            table.insert(wire_response, "\r\n")
            table.insert(wire_response, response.body)

            client:write(table.concat(wire_response))
        else
            client:close()
        end
    end)
end
]] --

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
    if not data then
        client:close()
        return
    end

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
        "HTTP/1.1 ", http_statuses[response.status], "\r\n",
        "content-length: " .. #response.body .. "\r\n",
    }

    for _, header in ipairs(response.headers) do
        table.insert(wire_response, header[1] .. ": " .. header[2] .. "\r\n")
    end

    table.insert(wire_response, "\r\n")
    table.insert(wire_response, response.body)

    a.wait(write(client, table.concat(wire_response)))
    client:close()
    print("on connection done")
end)


function Server.on_sigint(_)
    loop:stop()
end

-- Set sigint handler.
--
-- Clean up immediately.
-- When the main loop is running in the default usage,
-- SIGINT doesn't respond unless it happens twice.
-- This handler ensures that the clean up happens right away.
function Server._set_sigint(_)
    -- MIKE TODO set signal handler
end

-- Set up the server to handle requests.
function Server.set_up(self, config)
    self._server = loop:new_tcp()
    self._server:bind(config.host, config.port)

    print("Listening for requests on http://" .. config.host .. ":" .. config.port)

    self._server:listen(1, function()
        local client = loop:new_tcp()
        self._server:accept(client)
        a.run(on_connection(client, self._app))
        print("after a.run on connection")
    end)

    self:_set_sigint()
end

-- Run the uv loop.
---@return boolean true if there are no active handles on stop
function Server.run() return loop:run() == 0 end

return Server
