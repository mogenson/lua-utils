---Converts a function into a task. This task can await other futures
---internally. The returned task is a future that can be awaited.
---@param fn function A function that is not run until the task is polled
---@return function A task with a poll function that calls cb when finished
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

---Converts a function into a future that completes when cb is called. The
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
    local results = {} ---@type any[]

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
                local results = {} ---@type any[]
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

---Execute of a future and collect the results. This function will block.
---@param future function a future to run
---@return ... a variadic list of results
local function block(future)
    local results = {}
    run(future, function(...) results = table.pack(...) end)
    return table.unpack(results, 1, results.n)
end

---@class Queue
---@field cb function?
---@field q any[]
---@field NIL table
---@field get function(self: Queue, cb: function?)
---@field put function(self: Queue, value: any)
---@field iter function(self: Queue): fun(): any

---Returns an async queue.
---It has regular put method and an async get method that can be awaited.
---@return Queue
local function queue()
    return { ---@type Queue
        cb = nil,
        q = {},
        NIL = {},
        ---Get a value from the queue async
        ---@param self Queue
        ---@param cb function?
        get = wrap(function(self, cb)
            local value = table.remove(self.q)
            if value then
                if value == self.NIL then value = nil end
                return cb and cb(value)
            else
                self.cb = cb
            end
        end),
        ---Put a value into the queue sync
        ---@param self Queue
        ---@param value any
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
        ---Iterate over values in the queue
        ---@param self Queue
        iter = function(self)
            return function()
                return await(self:get())
            end
        end
    }
end

---@class Sender
---@field send fun(self: Sender, value: any, send_cb: function?)
---@field rx Receiver?
---@field default function?

---@class Receiver
---@field recv fun(self: Receiver, recv_cb: function?)
---@field tx Sender?
---@field default function?

---Returns a linked async channel sender and receiver.
---The channel transfers a single value at a time. The sender will await until
---the receiver reads and the receiver will await until the sender writes.
---@return Sender
---@return Receiver
local function channel()
    local tx = { ---@type Sender
        ---Send a value to the receiver async
        ---@param self Sender
        ---@param value any
        ---@param send_cb function?
        send = wrap(function(self, value, send_cb)
            ---Set the receivers recv function
            ---@param self Receiver
            ---@param recv_cb function?
            ---@diagnostic disable-next-line: redefined-local
            self.rx.recv = wrap(function(self, recv_cb)
                self.recv = self.default
                if send_cb then send_cb() end
                return recv_cb and recv_cb(value)
            end)
        end)
    }
    local rx = { ---@type Receiver
        ---Receive a value from the Sender async
        ---@param self Receiver
        ---@param recv_cb function?
        recv = wrap(function(self, recv_cb)
            ---Set the senders send function
            ---@param self Sender
            ---@param value any
            ---@param send_cb function?
            ---@diagnostic disable-next-line: redefined-local
            self.tx.send = wrap(function(self, value, send_cb)
                self.send = self.default
                if recv_cb then recv_cb(value) end
                return send_cb and send_cb()
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
    block = block,

    queue = queue,
    channel = channel,
}
