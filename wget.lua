local ffi = require('ffi')
local bit = require('bit')
local loop = require("libuv")
local multi = require("libcurl")


for i = 1, 2 do
    multi:add('http://httpbin.org/get')
end

print("uv run start")
loop:run()
print("uv run stop")
