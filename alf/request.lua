local class = require("pl.class")

---@class Request
---@field path string
---@field scope table
local Request = class()

---An HTTP request
---The request object is the primary input interface for controllers.
---@param scope table An ASGI scope with connection information
function Request:_init(scope)
    self.scope = scope
    self.path = scope.path
end

return Request
