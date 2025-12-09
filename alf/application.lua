local a = require("async")
local class = require("pl.class")

local Request = require("alf.request")
local Response = require("alf.response")
local Router = require("alf.router")

---@class Application
---@field router Router
local Application = class()

---An ASGI application
---@param routes Route[]
function Application:_init(routes)
    self.router = Router(routes)
end

---An async entrypoint into the Application
---@param self Application
---@param scope Scope
---@param receive function async ASGI callable
---@param send function async ASGI callable
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
