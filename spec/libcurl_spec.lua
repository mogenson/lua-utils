local a = require("async")
local curl = require("libcurl")
local loop = require("libuv")

describe("libcurl", function()
    it("multi", function()
        local url = "http://httpbin.org/get"
        local fetch = a.wrap(function(url, cb)
            curl.GET(url, cb)
        end)

        local get1 = a.sync(function(url)
            return a.wait(fetch(url))
        end)

        local get2 = a.sync(function(url)
            return a.wait(fetch(url))
        end)

        local main = a.sync(function()
            return a.wait(a.gather({ get1(url), get1(url) }))
        end)

        local response1, response2 = "", ""
        a.run(main(), function(...) response1, response2 = ... end)
        loop:run()

        local expected = string.format('"url": "%s"\n}\n', url)
        assert.are.same("string", type(response1))
        assert.are.same(expected, response1:sub(- #expected))

        assert.are.same("string", type(response2))
        assert.are.same(expected, response2:sub(- #expected))
    end)

    it("post", function()
        local url = "http://httpbin.org/post"
        local post = a.wrap(function(url, data, cb)
            curl.POST(url, data, cb)
        end)

        local content = "Hello World"
        local main = a.sync(function()
            return a.wait(post(url, content))
        end)

        local response
        a.run(main(), function(...) response = ... end)
        loop:run()

        assert.are.same("string", type(response))
        assert.is_not_nil(response:find(content))
    end)
end)
