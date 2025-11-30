local Response = require("alf.response")
local Route = require("alf.route")
local Router = require("alf.router")
local Application = require("alf.application")

describe("Router", function()
    it("should match a simple route", function()
        local route = Route("/", function() end)
        local router = Router({ route })
        local match, found_route = router:route("GET", "/")
        assert.is_true(match)
        assert.are.equal(route, found_route)
    end)

    it("should not match a different path", function()
        local route = Route("/", function() end)
        local router = Router({ route })
        local match, found_route = router:route("GET", "/other")
        assert.is_nil(match)
        assert.is_nil(found_route)
    end)

    it("should not match a different method", function()
        local route = Route("/", function() end, { "GET" })
        local router = Router({ route })
        local match, found_route = router:route("POST", "/")
        assert.is_false(match)
        assert.are.equal(route, found_route)
    end)

    it("should extract path parameters", function()
        local user_id
        local function user_details(_, id)
            user_id = id
            return Response("test")
        end

        local route = Route("/users/{id:int}", user_details)
        local router = Router({ route })
        local match, found_route = router:route("GET", "/users/123")
        assert.is_true(match)
        assert.are.equal(route, found_route)

        found_route:run({ path = "/users/123" })
        assert.are.equal(123, user_id)
    end)
end)

describe("Application", function()
    it("should return 200 OK for a valid route", function()
        local route = Route("/", function()
            return Response("Hello")
        end)
        local app = Application({ route })

        local scope = { method = "GET", path = "/" }
        local receive = function() return {} end
        local send = function(event)
            if event.type == "http.response.start" then
                assert.are.equal(200, event.status)
            end
        end

        app(scope, receive, send)
    end)

    it("should return 404 Not Found for an invalid route", function()
        local app = Application({})

        local scope = { method = "GET", path = "/invalid" }
        local receive = function() return {} end
        local send = function(event)
            if event.type == "http.response.start" then
                assert.are.equal(404, event.status)
            end
        end

        app(scope, receive, send)
    end)

    it("should return 405 Method Not Allowed for a mismatched method", function()
        local route = Route("/", function() return Response("Hello") end, { "GET" })
        local app = Application({ route })

        local scope = { method = "POST", path = "/" }
        local receive = function() return {} end
        local send = function(event)
            if event.type == "http.response.start" then
                assert.are.equal(405, event.status)
            end
        end

        app(scope, receive, send)
    end)
end)

describe("E2E", function()
    it("should start a webapp and fetch content from it", function()
        local a = require("async")
        local curl = require("libcurl")
        local loop = require("libuv")
        local Server = require("alf.server.server")

        local function test_route()
            return Response("test content")
        end

        local routes = { Route("/test", test_route), }
        local config = { app = Application(routes), host = "127.0.0.1", port = 8080 }
        local server = Server(config.app)
        server:set_up(config)

        -- fetch content
        local content = {}
        curl:get(("http://%s:%d/test"):format(config.host, config.port),
            function(data) table.insert(content, data) end,
            function(_) loop:shutdown() end
        )

        loop:run()

        assert.are.equal("test content", table.concat(content))
    end)
end)
