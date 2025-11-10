---@class Request
---@field path string
---@field scope table
local Request = {}
Request.__index = Request

setmetatable(Request, {
    ---An HTTP request
    ---The request object is the primary input interface for controllers.
    ---@param scope table An ASGI scope with connection information
    ---@return Request
    __call = function(_, scope)
        return setmetatable({
            scope = scope,
            path = scope.path
        }, Request)
    end
})

return Request
