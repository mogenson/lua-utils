local a = require("async")
local Application = require("alf.application")
local curl = require("libcurl")
local loop = require("libuv")
local Parser = require("alf.parser")
local Response = require("alf.response")
local Route = require("alf.route")
local Router = require("alf.router")
local Server = require("alf.server")


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

        app:run(scope, receive, send)
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

        app:run(scope, receive, send)
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

        app:run(scope, receive, send)
    end)
end)

describe("Parser", function()
    it("should parse a request in chunks", function()
        local chunks = {
            "POST /test HTTP/1.1\r\nHost: localhost\r\n",
            "Content-Type: text/plain\r\nContent-Length: 13",
            "\r\n\r\nHello, world!",
        }

        local read = a.sync(function()
            return table.remove(chunks, 1)
        end)

        local parser = Parser()
        local scope, err = a.block(parser:parse(read))

        assert.is_nil(err)
        assert.are.equal("POST", scope.method)
        assert.are.equal("/test", scope.path)
        assert.are.equal("1.1", scope.version)
        assert.are.equal("localhost", scope.headers["Host"])
        assert.are.equal("text/plain", scope.headers["Content-Type"])
        assert.are.equal("13", scope.headers["Content-Length"])
        assert.are.equal("Hello, world!", scope.body)
    end)
end)

describe("E2E", function()
    it("should start a webapp and fetch content from it", function()
        local function test()
            return Response("test content")
        end

        local routes = { Route("/test", test) }
        local app = Application(routes)
        local host = "127.0.0.1"
        local port = 8000
        local server = Server(app)

        -- fetch content
        local content = {}
        curl.GET(("http://%s:%d/test"):format(host, port),
            function(data, err)
                assert(not err)
                table.insert(content, data)
                loop:shutdown()
            end
        )

        server:serve(host, port)

        assert.are.equal("test content", table.concat(content))
    end)

    it("should start a webapp and post content to it", function()
        local function echo(request)
            return Response(request.scope.body)
        end

        local routes = { Route("/echo", echo, { "POST" }) }
        local app = Application(routes)
        local host = "127.0.0.1"
        local port = 8000
        local server = Server(app)

        -- fetch content
        local request_content = "Hello, World"
        local response_content = {}
        curl.POST(("http://%s:%d/echo"):format(host, port), request_content,
            function(data, err)
                assert(not err)
                table.insert(response_content, data)
                loop:shutdown()
            end
        )

        server:serve(host, port)

        assert.are.equal(request_content, table.concat(response_content))
    end)
end)
