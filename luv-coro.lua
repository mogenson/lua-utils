local uv = require('luv')

-- Function that will run in a coroutine
local function my_task()
    print("Coroutine: Starting task")

    -- Create a new timer
    local timer = uv.new_timer()
    local current_co = coroutine.running() -- Get the current coroutine

    print("Coroutine: Starting timer for 2 seconds")

    -- Start the timer. The callback will resume the coroutine.
    timer:start(2000, 0, function() -- 2000 ms delay, 0 repeat
        print("Timer: Callback fired!")
        timer:close()             -- Clean up the timer
        if coroutine.status(current_co) == "suspended" then
            coroutine.resume(current_co)
        end
    end)

    -- Yield the coroutine, waiting for the timer callback
    coroutine.yield()

    print("Coroutine: Resumed after timer")
    print("Coroutine: Task finished")
end

-- Create the coroutine
local co = coroutine.create(my_task)

-- Start the coroutine
print("Main: Starting coroutine")
local status, err = coroutine.resume(co)
if not status then
    print("Main: Coroutine error:", err)
end

print("Main: Coroutine yielded, waiting for luv events...")

-- Start the luv event loop
-- This will block until all handles are closed (or uv.stop() is called)
uv.run()

print("Main: Luv loop finished")
