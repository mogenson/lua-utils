local a = require("async")
local Request = require("alf.request")
local Response = require("alf.response")
local Router = require("alf.router")

---@class Application
---@field router Router
local Application = {}
Application.__index = Application

setmetatable(Application, {
    ---An ASGI application
    ---@param routes Route[]
    ---@return Application
    __call = function(_, routes)
        return setmetatable({ router = Router(routes) }, Application)
    end
})

---An async entrypoint into the Application
---@param self Application
---@param scope table
---@param receive function
---@param send function
Application.__call = a.sync(function(self, scope, receive, send)
    -- read the rest of the body, if needed
    local content_length = tonumber(scope.headers["Content-Length"] or 0)
    while #scope.body < content_length do
        scope.body = scope.body .. a.wait(receive())
    end

    local match, route = self.router:route(scope.method, scope.path)

    local response = (function()
        if match == true then      -- good match
            return assert(route):run(Request(scope))
        elseif match == false then -- bad match
            return Response("Method Not Allowed", "text/plain", 405)
        else                       -- no match
            return Response("Not Found", "text/plain", 404)
        end
    end)()

    response(send)
end)


return Application
