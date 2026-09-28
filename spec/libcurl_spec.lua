---@diagnostic disable:redefined-local

local a = require("async")
local curl = require("libcurl")
local loop = require("libuv")

describe("libcurl", function()
    it("multi", function()
        local url = "http://httpbin.org/get"
        local fetch = a.wrap(function(url, cb)
            curl.GET(url, cb)
        end)

        local get = a.sync(function(url)
            return a.wait(fetch(url))
        end)

        local main = a.sync(function()
            return a.wait(a.gather({
                get(url),
                get(url),
                get(url),
                get(url),
                get(url),
                get(url),
            }))
        end)

        local responses ---@type string[]
        a.run(main(), function(...)
            responses = { ... }
        end)
        loop:run()

        local expected = string.format('"url": "%s"\n}\n', url)
        assert.are.same(6, #responses)
        for _, resp in ipairs(responses) do
            assert.are.same("string", type(resp))
            assert.are.same(expected, assert(resp):sub(- #expected))
        end
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

        local response ---@type string?
        a.run(main(), function(...)
            response = ... ---@type string?
        end)
        loop:run()

        assert.are.same("string", type(response))
        assert.is_not_nil(assert(response):find(content))
    end)
end)
