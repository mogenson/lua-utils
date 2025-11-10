---@class Router
---@field routes Route[]
local Router = {}
Router.__index = Router

setmetatable(Router, {
    ---A collection of ordered routes
    ---The router is responsible for finding a route that matches a URL path.
    ---@param routes string[] A list of routes to check against
    ---@return Router
    __call = function(_, routes)
        return setmetatable({ routes = routes }, Router)
    end
})

---Find a route that maches an HTTP method and path
---@param method string An HTTP method
---@param path string An HTTP request path
---@return boolean|nil, Route|nil
function Router:route(method, path)
    for _, route in ipairs(self.routes) do
        local match = route:matches(method, path)
        if match then return match, route end
    end
    return nil, nil
end

return Router
