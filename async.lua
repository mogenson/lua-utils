local function async(f)
    return function(...)
        local params = table.pack(...)
        local thread = coroutine.create(function()
            return f(table.unpack(params, 1, params.n))
        end)

        return function(cb)
            local step = nil
            step = function(...)
                local result = table.pack(coroutine.resume(thread, ...))

                if coroutine.status(thread) == "dead" then
                    return (cb or function() end)(table.unpack(result, 2, result.n))
                else
                    return result[2](step)
                end
            end
            return step()
        end
    end
end

local function wrap(f)
    return function(...)
        local params = table.pack(...)
        return function(cb)
            table.insert(params, params.n + 1, cb)
            return f(table.unpack(params, 1, params.n + 1))
        end
    end
end

local function join(thunks)
    local total = #thunks

    local finished = 0
    local result = {}

    return function(cb)
        if total == 0 then
            return (cb or function() end)()
        end

        for i, thunk in ipairs(thunks) do
            thunk(function(...)
                local args = { ... }
                if #args <= 1 then
                    result[i] = args[1]
                else
                    result[i] = args
                end

                finished = finished + 1
                if finished == total then
                    return (cb or function() end)(table.unpack(result))
                end
            end)
        end
    end
end

local function race(thunks)
    local finished = false
    return function(cb)
        if #thunks == 0 then
            return (cb or function() end)()
        end

        for i, thunk in ipairs(thunks) do
            thunk(function(...)
                if finished then
                    return
                end
                finished = true

                local result = {}
                local args = { ... }
                if #args <= 1 then
                    result[i] = args[1]
                else
                    result[i] = args
                end

                return (cb or function() end)(result)
            end)
        end
    end
end

local function await(thunk)
    return coroutine.yield(thunk)
end

local function await_all(...)
    return coroutine.yield(join({ ... }))
end

local function await_race(...)
    return coroutine.yield(race({ ... }))
end

local function block(thunk)
    local results = {}
    thunk(function(...) results = table.pack(...) end)
    return table.unpack(results, 1, results.n)
end

local function queue()
    return {
        cb = nil,
        q = {},
        NIL = {},
        get = wrap(function(self, cb)
            local value = table.remove(self.q)
            if value then
                if value == self.NIL then value = nil end
                return cb(value)
            else
                self.cb = cb
            end
        end),
        put = function(self, value)
            local cb = self.cb
            if cb then
                self.cb = nil
                return cb(value)
            else
                if value == nil then value = self.NIL end
                table.insert(self.q, value)
            end
        end,
    }
end

local function channel()
    local tx = {
        send = wrap(function(self, value, send_cb)
            self.rx.recv = wrap(function(self, recv_cb)
                self.recv = self.default
                send_cb()
                return recv_cb(value)
            end)
        end)
    }
    local rx = {
        recv = wrap(function(self, recv_cb)
            self.tx.send = wrap(function(self, value, send_cb)
                self.send = self.default
                recv_cb(value)
                return send_cb()
            end)
        end)
    }
    tx.default, rx.default = tx.send, rx.recv
    tx.rx, rx.tx = rx, tx
    return tx, rx
end

return {
    sync = async,
    wait = await,
    wrap = wrap,

    wait_all = await_all,
    wait_race = await_race,
    block = block,

    queue = queue,
    channel = channel,
}
