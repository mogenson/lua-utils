local class = require("pl.class")

---@class Scope: pl.Class
---@field method string
---@field version string
---@field path string
---@field headers { [string]:string }
---@field body string
---@operator call(...): Scope
local Scope = class()

---An ASGI scope
---@param method string?
---@param version string?
---@param path string?
---@param headers { [string]:string }?
---@param body string?
function Scope:_init(method, version, path, headers, body)
    self.method = method or ""
    self.version = version or ""
    self.path = path or ""
    self.headers = headers or {}
    self.body = body or ""
end

return Scope
