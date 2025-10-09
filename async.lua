---Converts a function into a future. This function can await other futures
---internally. The returned future is completed when this function finished.
---@param fn function A function that is not run until the future is polled
---@return function A future with a poll function that calls cb when finished
local function async(fn)
    return function(...)
        local params = table.pack(...)
        local thread = coroutine.create(function()
            return fn(table.unpack(params, 1, params.n))
        end)

        return function(cb)
            local poll = nil
            poll = function(...)
                local result = table.pack(coroutine.resume(thread, ...))
                if coroutine.status(thread) == "dead" then
                    return cb and cb(table.unpack(result, 2, result.n))
                else
                    return result[2](poll)
                end
            end
            return poll()
        end
    end
end

---Converts a function into a future that completes when a cb is called. The
---function needs a callback as the last param and must call it to complete.
---@param fn function A function that registers a callback for a future event
---@return function A future that completes when the callback is called
local function wrap(fn)
    return function(...)
        local params = table.pack(...)
        return function(cb)
            table.insert(params, params.n + 1, cb)
            return fn(table.unpack(params, 1, params.n + 1))
        end
    end
end

---Return one future that completes when all provided futures are done.
---@param futures function[] A list of futures
---@return function A future that runs all provided futures to completion.
local function gather(futures)
    local total = #futures
    local finished = 0
    local results = {}

    return function(cb)
        if total == 0 then return cb and cb() end

        for i, future in ipairs(futures) do
            future(function(...)
                local params = table.pack(...)
                results[i] = params.n <= 1 and params[1] or params
                finished = finished + 1
                if finished == total then
                    return cb and cb(table.unpack(results))
                end
            end)
        end
    end
end

---Return one future that completes when the first of provided futures are done
---@param futures function[] A list of futures
---@return function A future that runs only one provided future to completion
local function select(futures)
    local finished = false
    return function(cb)
        if #futures == 0 then return cb and cb() end

        for i, future in ipairs(futures) do
            future(function(...)
                if finished then return end
                finished = true
                local results = {}
                local params = table.pack(...)
                results[i] = params.n <= 1 and params[1] or params
                return cb and cb(results)
            end)
        end
    end
end

---Yield to a provided future and return when it completes
---@param future function A future
---@return any The results from the future completion callback
local function await(future)
    return coroutine.yield(future)
end

---Start the execution of a future. This function does not block.
---@param future function A future to run
---@param cb function|nil An optional callback to be called on completion
local function run(future, cb)
    future(cb)
end

---Returns an async queue.
-- It has regular put method and an async get method that can be awaited.
---@return table
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

---Returns a linked async channel sender and receiver.
---The channel transfers a single value at a time. The sender will await until
---the receiver reads and the receiver will await until the sender writes.
---@return table sender
---@return table receiver
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

    gather = gather,
    select = select,
    run = run,

    queue = queue,
    channel = channel,
}
