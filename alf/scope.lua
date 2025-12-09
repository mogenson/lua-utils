local class = require("pl.class")

---@class Scope
---@field method string
---@field version string
---@field path string
---@field headers { [string]:string }
---@field body string
local Scope = class()

---An ASGI scope
function Scope:_init()
    self.method = ""
    self.version = ""
    self.path = ""
    self.headers = {}
    self.body = ""
end

return Scope
