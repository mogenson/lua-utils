local a = require("async")
local curl = require("libcurl")
local loop = require("libuv")

describe("libcurl", function()
    it("multi", function()
        local url = "http://httpbin.org/get"
        local q1 = a.queue()
        local q2 = a.queue()

        curl:get(url,
            function(str) q1:put(str) end,
            function(result)
                assert(result == 0)
                q1:put(nil)
            end
        )

        curl:get(url,
            function(str) q2:put(str) end,
            function(result)
                assert(result == 0)
                q2:put(nil)
            end
        )

        local collector = a.sync(function(q)
            local vals, val = {}, nil
            repeat
                val = a.wait(q:get())
                table.insert(vals, val)
            until not val
            print() -- force jit off
            return table.concat(vals)
        end)

        local main = a.sync(function()
            return a.wait(a.gather({ collector(q1), collector(q2) }))
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
end)
