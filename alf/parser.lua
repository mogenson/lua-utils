local a = require("async")
local class = require("pl.class")
local tablex = require("pl.tablex")

local Scope = require("alf.scope")

--  request-line = method SP request-target SP HTTP-version CRLF
local REQUEST_LINE_PATTERN = "^(%u+) ([^ ]+) HTTP/([%d.]+)\r\n"

-- Currrently unsupported: CONNECT, OPTIONS, TRACE
-- PATCH is defined in RFC 5789
local SUPPORTED_METHODS = { "GET", "POST", "HEAD", "DELETE", "PUT", "PATCH" }

-- These are the versions supported by ASGI HTTP 2.3.
local SUPPORTED_VERSIONS = { "1.0", "1.1", "2" }

---@class Parser An HTTP 1.1 Parser
---@field INVALID_REQUEST_LINE number
---@field METHOD_NOT_IMPLEMENTED number
---@field VERSION_NOT_SUPPORTED number
local Parser = class()

-- Errors

-- A request line can parse to something invalid.
Parser.INVALID_REQUEST_LINE = 1
-- HTTP method is not implemented.
Parser.METHOD_NOT_IMPLEMENTED = 2
-- HTTP version is not supported.
Parser.VERSION_NOT_SUPPORTED = 3

---Parse an HTTP requst string
---@param self Parser
---@param receive function an async function that returns data
---@return Scope request metadata
---@return number|nil parsing error
Parser.__call = a.sync(function(self, receive)
    local scope = Scope()
    local data = a.wait(receive())

    local _, finish, method, path, version = data:find(REQUEST_LINE_PATTERN)
    if not method then return scope, self.INVALID_REQUEST_LINE end

    scope.method = method
    if not tablex.find(SUPPORTED_METHODS, method) then
        return scope, self.METHOD_NOT_IMPLEMENTED
    end

    scope.path = path
    scope.version = version
    if not tablex.find(SUPPORTED_VERSIONS, version) then
        return scope, self.VERSION_NOT_SUPPORTED
    end

    local index, line = finish + 1, nil
    repeat
        if finish then index = finish + 1 end
        _, finish, line = data:find("(.-)\r\n", index) -- parse line by line
        if line then
            local key, value = line:match("^(.-):%s*(.*)$")
            if key and value then scope.headers[key] = value end
        else
            data = data .. a.wait(receive()) -- read more data
        end
    until line == ""                         -- end of metadata

    scope.body = data:sub(finish + 1)        -- anything after the break is the body

    return scope, nil
end)

return Parser
