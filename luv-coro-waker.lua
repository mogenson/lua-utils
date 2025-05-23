local uv = require('luv')

local ready_tasks = {}
local pending_tasks = {}

local function schedule(fn)
    table.insert(ready_tasks, coroutine.create(fn))
end

local function run()
    repeat
        while true do
            local thread = table.remove(ready_tasks, 1)
            if not thread then break end
            local status, err = coroutine.resume(thread)
            if not status then
                error("coroutine.resume() error, thread: " ..
                    tostring(thread) .. " error: " .. err)
            end
            if coroutine.status(thread) ~= "dead" then
                table.insert(pending_tasks, thread)
            end
        end

        uv.run("once")
    until not uv.loop_alive()
end

local function wake(thread)
    for i, pending in ipairs(pending_tasks) do
        if pending == thread then
            table.remove(pending_tasks, i)
            table.insert(ready_tasks, pending)
            return
        end
    end
    error("wake: pending task not found")
end

local function make_waker()
    local thread = coroutine.running()
    return function() wake(thread) end
end

local function make_queue(recv_thread)
    local send = function(value)
        coroutine.resume(recv_thread, value)
    end
    local recv = function()
        return coroutine.yield()
    end
    return send, recv
end

local function reader()
    print("reader start")

    for i = 1, 10 do
        local timer = uv.new_timer()
        local waker = make_waker()

        timer:start(100, 0, function()
            print("timer callback " .. i)
            timer:close()
            waker()
        end)

        local val = coroutine.yield()
        --print("reader send: " .. val)
        -- send(result)
    end

    -- send(nil) -- nil closes the queue

    print("reader stop")
end

local function writer()
    print("writer start")
    local send, recv = make_queue(coroutine.running())
    run(reader, send)
    local val = true
    repeat
        val = recv()
        print("writer recv: " .. val)
    until val == nil
    print("writer stop")
end

schedule(reader)

print("uv start")
run()
print("uv stop")
