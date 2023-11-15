local ffi = require("ffi")
ffi.cdef([[
typedef size_t (*write_function)(char*, size_t, size_t, void*);
void* curl_easy_init();
void curl_easy_cleanup(void*);
int curl_easy_setopt(void*, int, ...);
int curl_easy_perform(void*);
]])
local libcurl = ffi.load("curl")

local CURLOPT_URL = 10002
local CURLOPT_WRITEFUNCTION = 20011

local curl = {}

function curl.http_get(url)
    local response = {}
    local session = assert(libcurl.curl_easy_init())
    libcurl.curl_easy_setopt(session, CURLOPT_URL, url)
    libcurl.curl_easy_setopt(session, CURLOPT_WRITEFUNCTION,
        ffi.cast("write_function", function(buffer, size, nitems, context)
            table.insert(response, ffi.string(buffer, size * nitems))
            return nitems
        end))
    local ret = libcurl.curl_easy_perform(session)
    libcurl.curl_easy_cleanup(session)
    return table.concat(response), ret
end

return curl
