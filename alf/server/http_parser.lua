local a = require("async")
local tablex = require("pl.tablex")

---@class Parser
local Parser = {}
Parser.__index = Parser

--  request-line = method SP request-target SP HTTP-version CRLF
local REQUEST_LINE_PATTERN = "^(%u+) ([^ ]+) HTTP/([%d.]+)\r\n"

-- Currrently unsupported: CONNECT, OPTIONS, TRACE
-- PATCH is defined in RFC 5789
local SUPPORTED_METHODS = { "GET", "POST", "HEAD", "DELETE", "PUT", "PATCH" }

-- These are the versions supported by ASGI HTTP 2.3.
local SUPPORTED_VERSIONS = { "1.0", "1.1", "2" }

setmetatable(Parser, {
    ---An HTTP 1.1 parser
    ---@return Parser
    __call = function(_)
        return setmetatable({}, Parser)
    end
})

-- Errors

-- A request line can parse to something invalid.
Parser.INVALID_REQUEST_LINE = 1
-- HTTP method is not implemented.
Parser.METHOD_NOT_IMPLEMENTED = 2
-- HTTP version is not supported.
Parser.VERSION_NOT_SUPPORTED = 3

---Parse an HTTP requst string
---@param self Parser
---@param read function an async function that returns data
---@return table request metadata
---@return string|nil body data
---@return number|nil parsing error
Parser.__call = a.sync(function(self, read)
    local meta = { headers = {} }
    local data = a.wait(read())

    local start, finish, method, path, version = data:find(REQUEST_LINE_PATTERN)
    if not method then return meta, nil, self.INVALID_REQUEST_LINE end

    meta.method = method
    if not tablex.find(SUPPORTED_METHODS, method) then
        return meta, nil, self.METHOD_NOT_IMPLEMENTED
    end

    meta.path = path
    meta.version = version
    if not tablex.find(SUPPORTED_VERSIONS, version) then
        return meta, nil, self.VERSION_NOT_SUPPORTED
    end

    local index, line = finish + 1, nil
    repeat
        if finish then index = finish + 1 end
        start, finish, line = data:find("(.-)\r\n", index) -- parse line by line
        if line then
            local key, value = line:match("^(.-):%s*(.*)$")
            if key and value then meta.headers[key] = value end
        else
            data = data .. a.wait(read()) -- read more data
        end
    until line == ""                      -- end of metadata

    local body = data:sub(finish + 1)     -- everything after the break is the body

    return meta, body, nil
end)

return Parser
