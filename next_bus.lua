#!/usr/bin/env luajit

local ffi = require("ffi")
ffi.cdef([[
typedef size_t (*write_function)(char*, size_t, size_t, void*);
void* curl_easy_init();
void curl_easy_cleanup(void*);
int curl_easy_setopt(void*, int, ...);
int curl_easy_perform(void*);
]])
local libcurl = ffi.load("curl")

CURLOPT_URL = 10002
CURLOPT_WRITEFUNCTION = 20011

local function http_get(url)
    local response = {}
    local curl = assert(libcurl.curl_easy_init())
    libcurl.curl_easy_setopt(curl, CURLOPT_URL, url)
    libcurl.curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION,
        ---@diagnostic disable-next-line:unused-local
        ffi.cast("write_function", function(buffer, size, nitems, context)
            table.insert(response, ffi.string(buffer, size * nitems))
            return nitems
        end))
    local ret = libcurl.curl_easy_perform(curl)
    libcurl.curl_easy_cleanup(curl)
    return table.concat(response), ret
end

local url = "https://api-v3.mbta.com/predictions?page[limit]=1&filter[route]=%s&filter[stop]=%d"
local pattern = '"departure_time":"%d%d%d%d%-%d%d%-%d%dT(%d%d:%d%d):%d%d%-%d%d:%d%d"'
for _, stop in ipairs({ { name = "Teele", id = 2576 }, { name = "Davis", id = 5104 } }) do
    print(stop.name .. " Square")
    for _, route in ipairs({ 87, 88 }) do
        local json, _ = http_get(string.format(url, route, stop.id))
        local _, _, departure_time = json:find(pattern)
        print(route, departure_time)
    end
end

local route = "Red"
local stop = 70063
local json, _ = http_get(string.format(url, route, stop))
local _, _, departure_time = json:find(pattern)
print(route, departure_time)

print("Kendall Square")
json, _ = http_get(string.format(url, route, 70072))
_, _, departure_time = json:find(pattern)
print(route, departure_time)
