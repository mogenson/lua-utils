#!/usr/bin/env lua

local uv = require("luv")

local port = arg[1] or "/dev/ttyUSB0"
local baud = arg[2] or 115200

local read_fd = assert(uv.fs_open(port, "r", tonumber("666", 8)))
local write_fd = assert(uv.fs_open(port, "w", tonumber("666", 8)))
os.execute("stty -F " .. port .. " " .. baud .. " raw -echo -echoe -echok")

local stdin = assert(uv.new_tty(0, true))
assert(stdin:set_mode(1))
local stdout = assert(uv.new_tty(1, false))

local serial_in = uv.new_pipe()
assert(serial_in:open(read_fd))
local serial_out = uv.new_pipe()
serial_out:open(write_fd)

function quit()
    print("quitting...")
    stdin:set_mode(0)
    serial_in:close()
    serial_out:close()
    stdin:close()
    stdout:close()
    uv.fs_close(read_fd)
    uv.fs_close(write_fd)
    uv.stop()
end

stdin:read_start(function(err, data)
    assert(not err, err)
    if data then
        if string.sub(data, -1) == "\003" then quit() end
        serial_out:write(data)
    else
        quit()
    end
end)

serial_in:read_start(function(err, data)
    assert(not err, err)
    if data then
        stdout:write(data)
    else
        quit()
    end
end)

uv.run()
