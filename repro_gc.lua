local loop = require("libuv")
local a = require("async")

-- Force aggressive GC
local function hammer_gc()
    for i = 1, 10 do
        collectgarbage("collect")
    end
end

print("Starting GC stress test...")

local counter = 0
local total = 1000

local function next_step()
    if counter >= total then
        print("Done!")
        return
    end
    counter = counter + 1
    
    -- Test fs_stat (Request struct + callback)
    loop:fs_stat(".", function(mode, err)
        if err then
            print("Error:", err)
        end
        -- If we get here without crashing, that's one success
    end)
    
    -- Test timer (Callback)
    loop:timer():start(1, function()
        -- Timer fired
    end)

    hammer_gc()
    
    -- Schedule next
    local t = assert(loop:timer())
    t:start(2, next_step)
end

next_step()

print("Running loop...")
loop:run()
