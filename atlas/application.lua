local a = require("async")
local Match = require("atlas.match")
local Request = require("atlas.request")
local Response = require("atlas.response")
local Router = require("atlas.router")
local FULL, PARTIAL = Match.FULL, Match.PARTIAL

-- Atlas application
local Application = {}
Application.__index = Application

setmetatable(Application, {
    __call = function(_, routes)
        return setmetatable({ router = Router(routes) }, Application)
    end
})

-- Act as a LASGI callable interface.
Application.__call = a.sync(function(self, scope, receive, send)
    -- TODO: When is this supposed to be called?
    -- What happens on a request with no body?
    local _ = receive() -- event

    local response = Response("Not Found", "text/html", 404)
    local match, route = self.router:route(scope.method, scope.path)
    if match == FULL then
        response = route:run(Request(scope))
    elseif match == PARTIAL then
        response = Response("Method Not Allowed", "text/html", 405)
    end

    response(send)
end)


return Application
