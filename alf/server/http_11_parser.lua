--  HTTP-message   = start-line
--                   *( header-field CRLF )
--                   CRLF
--                   [ message-body ]
--
--  start-line     = request-line / status-line
--
--  request-target = origin-form
--                 / absolute-form
--                 / authority-form
--                 / asterisk-form
--
--  request-target too long, response with 414 URI Too Long
--
--  > Various ad hoc limitations on request-line length are found in practice.
--  > It is RECOMMENDED that all HTTP senders and recipients support, at a minimum,
--  > request-line lengths of 8000 octets.
local ParserErrors = require("alf.server.parser_errors")
local tablex = require("pl.tablex")

local Parser = {}
Parser.__index = Parser

--  request-line = method SP request-target SP HTTP-version CRLF
local REQUEST_LINE_PATTERN = "^(%u+) ([^ ]+) HTTP/([%d.]+)\r\n(.*)"

-- Currrently unsupported: CONNECT, OPTIONS, TRACE
-- PATCH is defined in RFC 5789
local SUPPORTED_METHODS = { "GET", "POST", "HEAD", "DELETE", "PUT", "PATCH" }

-- These are the versions supported by ASGI HTTP 2.3.
local SUPPORTED_VERSIONS = { "1.0", "1.1", "2" }

setmetatable(Parser, {
    -- An HTTP 1.1 parser
    --
    -- This parser focuses on HTTP *request* parsing.
    __call = function(_)
        -- TODO MIKE hold state and allow calling multiple times with more data until parse is complete
        return setmetatable({}, Parser)
    end
})

-- Parse the request data.
--
-- data: Raw network data
--
-- Returns:
-- meta: The non-body portion of the request (a strict subset of an ASGI scope)
-- body: The body data
--  err: Non-nil if an error exists
function Parser:parse(data) -- self, data
    local meta = { type = "http" }
    local method, path, version, body = string.match(data, REQUEST_LINE_PATTERN)
    if not method then return nil, nil, ParserErrors.INVALID_REQUEST_LINE end

    meta.method = method
    if not tablex.find(SUPPORTED_METHODS, method) then
        return meta, nil, ParserErrors.METHOD_NOT_IMPLEMENTED
    end

    meta.path = path
    meta.version = version
    if not tablex.find(SUPPORTED_VERSIONS, version) then
        return meta, nil, ParserErrors.VERSION_NOT_SUPPORTED
    end

    return meta, body, nil
end

return Parser
