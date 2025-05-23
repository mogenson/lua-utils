local uv = require('luv')

-- This will be the second task, which has its own timer.
-- It needs to know which coroutine to resume when it's done.
local function task2_logic(task1_co_to_resume)
    local task2_co_self = coroutine.running()
    print("Task 2: Starting")

    local timer2 = uv.new_timer()
    print("Task 2: Starting timer for 2 seconds")

    timer2:start(2000, 0, function() -- 2000 ms delay, 0 repeat
        print("Timer 2: Callback fired!")
        timer2:close()             -- Clean up timer2
        if coroutine.status(task2_co_self) == "suspended" then
            print("Timer 2: Resuming Task 2 coroutine")
            coroutine.resume(task2_co_self)
        end
    end)

    print("Task 2: Yielding, waiting for Timer 2")
    coroutine.yield() -- Wait for Timer 2 callback to resume this coroutine

    print("Task 2: Resumed after its timer.")
    print("Task 2: Completed. Resuming Task 1.")
    if task1_co_to_resume and coroutine.status(task1_co_to_resume) == "suspended" then
        coroutine.resume(task1_co_to_resume)
    else
        if not task1_co_to_resume then print(
            "Task 2: Error - task1_co_to_resume is nil") end
        if task1_co_to_resume and coroutine.status(task1_co_to_resume) ~= "suspended" then
            print(
            "Task 2: Warning - Task 1 coroutine was not in a suspended state (" ..
            coroutine.status(task1_co_to_resume) .. ")")
        end
    end
end

-- This is the first task. It will wait for its own timer,
-- then start task2 and wait for task2 to complete.
local function task1_logic()
    local task1_co_self = coroutine.running()
    print("Task 1: Starting")

    local timer1 = uv.new_timer()
    print("Task 1: Starting timer for 1 second")

    timer1:start(1000, 0, function() -- 1000 ms delay, 0 repeat
        print("Timer 1: Callback fired!")
        timer1:close()             -- Clean up timer1
        if coroutine.status(task1_co_self) == "suspended" then
            print("Timer 1: Resuming Task 1 coroutine")
            coroutine.resume(task1_co_self)
        end
    end)

    print("Task 1: Yielding, waiting for Timer 1")
    coroutine.yield() -- Wait for Timer 1 callback to resume this coroutine

    print("Task 1: Resumed after its timer.")
    print("Task 1: Now starting Task 2 and will wait for it.")

    -- Create and start task2, passing our own coroutine so task2 can resume us
    local task2_co = coroutine.create(task2_logic)
    local ok, err_or_val = coroutine.resume(task2_co, task1_co_self) -- Pass task1_co_self to task2_logic

    if not ok then
        print("Task 1: Error starting Task 2 -", err_or_val)
        -- Potentially handle error, maybe try to finish Task 1 or propagate error
        return
    end

    -- If task2_co yielded (it will, for its timer), task1_co_self needs to yield
    -- to wait for task2_co to explicitly resume it upon task2's completion.
    if coroutine.status(task2_co) == "suspended" then
        print("Task 1: Yielding, waiting for Task 2 to complete.")
        coroutine.yield() -- Wait for task2_logic to resume task1_co_self
    else
        -- This case (task2 completed synchronously without yielding) is unlikely with timers
        -- but good to acknowledge.
        print(
        "Task 1: Task 2 completed synchronously (or errored before yielding).")
    end

    print("Task 1: Resumed after Task 2 completed.")
    print("Task 1: All tasks finished.")
end

-- Main execution
print("Main: Creating Task 1 coroutine")
local main_task1_co = coroutine.create(task1_logic)

print("Main: Starting Task 1")
local status, err = coroutine.resume(main_task1_co)
if not status then
    print("Main: Coroutine 1 initial error:", err)
end

print(
"Main: Task 1 has yielded or completed its first part. Starting luv event loop...")
-- Start the luv event loop. This will block until all handles are closed
-- (or uv.stop() is called) and callbacks are processed.
uv.run()

print("Main: Luv loop finished. Script ending.")
