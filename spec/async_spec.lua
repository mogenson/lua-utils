local a = require("async")

describe("a", function()
    it("example from the readme", function()
        local greet = a.sync(function()
            return "Hello"
        end)

        local separator = a.wrap(function(cb)
            cb(", ")
        end)

        local main = a.sync(function(name)
            local g = a.wait(greet())
            local s = a.wait(separator())
            return g .. s .. name
        end)

        local result = a.block(main("World"))
        assert.are.equal("Hello, World", result)
    end)

    it("queue", function()
        local q = a.queue()

        local putter = a.sync(function(queue)
            for i = 1, 10 do
                queue:put(i)
            end
            queue:put(nil)
            return true
        end)

        local getter = a.sync(function(queue)
            local vals, val = {}, nil
            repeat
                val = a.wait(queue:get())
                table.insert(vals, val)
            until not val
            return vals
        end)

        local main = a.sync(function()
            return a.wait(a.gather({ getter(q), putter(q) }))
        end)

        local getter_vals, putter_vals = a.block(main())
        assert.are.same({ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }, getter_vals)
        assert.is_true(putter_vals)
    end)

    it("iter", function()
        local q = a.queue()

        local putter = a.sync(function(queue)
            for i = 1, 10 do
                queue:put(i)
            end
            queue:put(nil)
            return true
        end)

        local getter = a.sync(function(queue)
            local vals = {}
            for val in queue:iter() do
                table.insert(vals, val)
            end
            return vals
        end)

        local main = a.sync(function()
            return a.wait(a.gather({ getter(q), putter(q) }))
        end)

        local getter_vals, putter_vals = a.block(main())
        assert.are.same({ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }, getter_vals)
        assert.is_true(putter_vals)
    end)


    it("channel", function()
        local tx, rx = a.channel()

        local sender = a.sync(function(tx)
            for i = 1, 10 do
                a.wait(tx:send(i))
            end
            a.wait(tx:send(nil))
            return true
        end)

        local receiver = a.sync(function(rx)
            local vals, val = {}, nil
            while true do
                val = a.wait(rx:recv())
                if val == nil then break end
                table.insert(vals, val)
            end
            return vals
        end)

        local main = a.sync(function()
            return a.wait(a.gather({ sender(tx), receiver(rx) }))
        end)

        local tx_vals, rx_vals = a.block(main())
        assert.is_true(tx_vals)
        assert.are.same({ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }, rx_vals)
    end)

    it("channel-reverse", function()
        local tx, rx = a.channel()

        local sender = a.sync(function(tx)
            for i = 1, 10 do
                a.wait(tx:send(i))
            end
            a.wait(tx:send(false))
            return true
        end)

        local receiver = a.sync(function(rx)
            local vals, val = {}, nil
            repeat
                val = a.wait(rx:recv())
                table.insert(vals, val or nil)
            until not val
            return vals
        end)

        local main = a.sync(function()
            return a.wait(a.gather({ receiver(rx), sender(tx) }))
        end)

        local rx_vals, tx_vals = a.block(main())
        assert.are.same({ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }, rx_vals)
        assert.is_true(tx_vals)
    end)

    it("calls the callback with the return of the function", function()
        local f = a.sync(function()
            return 42
        end)

        local result = a.block(f())
        assert.are.equal(42, result)
    end)

    it("passes argument to the function", function()
        local f = a.sync(function(n)
            return n + 1
        end)

        local result = a.block(f(41))
        assert.are.equal(42, result)
    end)

    it("passes nil to the function", function()
        local f = a.sync(function(a, b, c)
            assert.are.equal(a, 1)
            assert.are.equal(b, nil)
            assert.are.equal(c, 3)
        end)

        f(1, nil, 3)()
    end)

    it("returns nil from the function", function()
        local f = a.sync(function()
            return 1, nil, 3
        end)

        f()(function(a, b, c)
            assert.are.equal(a, 1)
            assert.are.equal(b, nil)
            assert.are.equal(c, 3)
        end)
    end)

    it("wrap provides callback to function", function()
        local f = a.wrap(function(n, cb)
            cb(n + 1)
        end)

        local result = a.block(f(41))
        assert.are.equal(42, result)
    end)

    it("wrap passes nil to function", function()
        local f = a.wrap(function(a, b, c, cb)
            assert.are.equal(a, 1)
            assert.are.equal(b, nil)
            assert.are.equal(c, 3)
            cb()
        end)

        f(1, nil, 3)(function() end)
    end)

    it("await returns result of function", function()
        local foo = a.sync(function(n)
            return n + 1
        end)

        local bar = a.sync(function()
            local from_foo = a.wait(foo(41))
            return from_foo + 1
        end)

        local result = a.block(bar(41))
        assert.are.equal(43, result)
    end)

    it("does not call immediately", function()
        local continue = nil
        local foo = a.wrap(function(cb)
            continue = cb
        end)

        local bar = a.sync(function()
            return a.wait(foo())
        end)

        local calledWith = nil
        bar()(function(n)
            calledWith = n
        end)

        assert.are.equal(nil, calledWith)

        assert(continue)(42)

        assert.are.equal(42, calledWith)
    end)

    it("joins multiple results", function()
        local continueFoo = nil
        local foo = a.wrap(function(cb)
            continueFoo = cb
        end)

        local continueBar = nil
        local bar = a.wrap(function(cb)
            continueBar = cb
        end)

        local baz = a.sync(function()
            return a.wait(a.gather({ foo(), bar() }))
        end)

        local calledWith = nil
        baz()(function(...)
            calledWith = { ... }
        end)

        assert.are.same(nil, calledWith)

        assert(continueFoo)(42)
        assert.are.same(nil, calledWith)

        assert(continueBar)(43)
        assert.are.same({ 42, 43 }, calledWith)
    end)

    it("joins multiple results in another order", function()
        local continueFoo = nil
        local foo = a.wrap(function(cb)
            continueFoo = cb
        end)

        local continueBar = nil
        local bar = a.wrap(function(cb)
            continueBar = cb
        end)

        local baz = a.sync(function()
            return a.wait(a.gather({ foo(), bar() }))
        end)

        local calledWith = nil
        baz()(function(...)
            calledWith = { ... }
        end)

        assert.are.same(nil, calledWith)

        assert(continueBar)(43)
        assert.are.same(nil, calledWith)

        assert(continueFoo)(42)
        assert.are.same({ 42, 43 }, calledWith)
    end)

    it("races two futures", function()
        local continueFoo = nil
        local foo = a.wrap(function(cb)
            continueFoo = cb
        end)

        local continueBar = nil
        local bar = a.wrap(function(cb)
            continueBar = cb
        end)

        local baz = a.sync(function()
            return a.wait(a.select({ foo(), bar() }))
        end)

        local calledWith = nil
        baz()(function(...)
            calledWith = ...
        end)

        assert.are.same(nil, calledWith)

        assert(continueBar)(43)
        assert.are.same({ nil, 43 }, calledWith)
    end)
end)
