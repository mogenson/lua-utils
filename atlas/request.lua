local Request = {}
Request.__index = Request

setmetatable(Request, {
    -- An HTTP request
    --
    -- The request object is the primary input interface for controllers.
    --
    -- scope: An ASGI scope with connection information
    __call = function(_, scope)
        return setmetatable({
            scope = scope,
            path = scope.path
        }, Request)
    end
})

return Request
