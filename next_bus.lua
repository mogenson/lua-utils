#!/usr/bin/env luajit

ffi = require("ffi")
ffi.cdef([[
typedef size_t (*write_function)(char*, size_t, size_t, void*);
void* curl_easy_init();
void curl_easy_cleanup(void*);
int curl_easy_setopt(void*, int, ...);
int curl_easy_perform(void*);
]])
libcurl = ffi.load("curl")

CURLOPT_URL = 10002
CURLOPT_WRITEFUNCTION = 20011

function http_get(url)
    response = {}
    curl = assert(libcurl.curl_easy_init())
    libcurl.curl_easy_setopt(curl, CURLOPT_URL, url)
    libcurl.curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION,
        ffi.cast("write_function", function(buffer, size, nitems, context)
            table.insert(response, ffi.string(buffer, size * nitems))
            return nitems
        end))
    ret = libcurl.curl_easy_perform(curl)
    libcurl.curl_easy_cleanup(curl)
    return table.concat(response), ret
end

url = "https://api-v3.mbta.com/predictions?page[limit]=1&filter[route]=%d&filter[stop]=%d"
pattern = '"departure_time":"%d%d%d%d%-%d%d%-%d%dT(%d%d:%d%d):%d%d%-%d%d:%d%d"'
for name, stop in pairs({ Teele = 2576, Davis = 5104 }) do
    print(name .. " Square")
    for _, route in ipairs({ 87, 88 }) do
        json, err = http_get(string.format(url, route, stop))
        start, finish, departure_time = json:find(pattern)
        --print(json, start, finish)
        print(route, departure_time)
    end
end
