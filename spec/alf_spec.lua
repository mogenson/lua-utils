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

    it("should extract int path parameter", function()
        local user_id
        local function user_details(_, id)
            user_id = id
            return Response()
        end

        local route = Route("/users/{id:int}", user_details)
        local router = Router({ route })
        local match, found_route = router:route("GET", "/users/123")
        assert.is_true(match)
        assert.are.equal(route, found_route)

        found_route:run({ path = "/users/123" })
        assert.are.equal(123, user_id)
    end)

    it("should extract number path parameter", function()
        local number
        local function controller(_, param)
            number = param
            return Response()
        end

        local route = Route("/test/{param:number}", controller)
        local router = Router({ route })
        local match, found_route = router:route("GET", "/test/-3.14")
        assert.is_true(match)
        assert.are.equal(route, found_route)

        found_route:run({ path = "/test/-3.14" })
        assert.are.equal(-3.14, number)
    end)

    it("should extract string path parameter", function()
        local name
        local function controller(_, str)
            name = str
            return Response()
        end

        local route = Route("/test/{name:string}", controller)
        local router = Router({ route })
        local match, found_route = router:route("GET", "/test/John")
        assert.is_true(match)
        assert.are.equal(route, found_route)

        found_route:run({ path = "/test/John" })
        assert.are.equal("John", name)
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

    --[[
    it("should handle a request with a body", function()
        local route = Route("/echo", function(req)
            return Response(req.body)
        end, { "POST" })
        local app = Application({ route })

        local scope = { method = "POST", path = "/echo" }

        local request_body = "hello from body"
        local body_sent = false
        local receive = function()
            print("Test receive: called, body_sent", body_sent)
            if not body_sent then
                body_sent = true
                print("Test receive: returning body", request_body)
                return { body = request_body, more_body = false }
            else
                print("Test receive: returning no more body")
                return { more_body = false }
            end
        end

        local response_body = ""
        local send = function(event)
            print("Test send: event type", event.type)
            if event.type == "http.response.start" then
                assert.are.equal(200, event.status)
            elseif event.type == "http.response.body" then
                print("Test send: response body chunk", event.body)
                response_body = response_body .. (event.body or "")
            end
        end

        app(scope, receive, send)

        assert.are.equal(request_body, response_body)
    end)
    ]] --
end)

describe("Parser", function()
    it("should parse a request in chunks", function()
        local a = require("async")
        local Parser = require("alf.parser")

        local function block(future)
            local results = {}
            future(function(...) results = table.pack(...) end)
            return table.unpack(results, 1, results.n)
        end

        local chunks = {
            "POST /test HTTP/1.1\r\nHost: localhost\r\n",
            "Content-Type: text/plain\r\nContent-Length: 13",
            "\r\n\r\nHello, world!",
        }

        local read = a.sync(function()
            return table.remove(chunks, 1)
        end)

        local parser = Parser()
        local meta, err = block(parser(read))

        assert.is_nil(err)
        assert.are.equal("POST", meta.method)
        assert.are.equal("/test", meta.path)
        assert.are.equal("1.1", meta.version)
        assert.are.equal("localhost", meta.headers["Host"])
        assert.are.equal("text/plain", meta.headers["Content-Type"])
        assert.are.equal("13", meta.headers["Content-Length"])
        assert.are.equal("Hello, world!", meta.body)
    end)
end)

describe("E2E", function()
    it("should start a webapp and fetch content from it", function()
        local a = require("async")
        local curl = require("libcurl")
        local loop = require("libuv")
        local Server = require("alf.server")

        local function test_route()
            return Response("test content")
        end

        local routes = { Route("/test", test_route) }
        local app = Application(routes)
        local host = "127.0.0.1"
        local port = 8000
        local server = Server(app)

        -- fetch content
        local content = {}
        curl:get(("http://%s:%d/test"):format(host, port),
            function(data) table.insert(content, data) end,
            function(_) loop:shutdown() end
        )

        server(host, port)

        assert.are.equal("test content", table.concat(content))
    end)
end)
