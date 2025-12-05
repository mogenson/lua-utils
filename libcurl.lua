local ffi = require("ffi")
local loop = require("libuv")

local libcurl = ffi.load("curl")
ffi.cdef([[
    typedef void* curl;
    typedef void* curlm;

    typedef struct {
        enum {
            CURLMSG_NONE,
            CURLMSG_DONE,
            CURLMSG_LAST
        } msg;
        curl handle;
        int result;
    } curl_msg;

    typedef enum {
        CURL_GLOBAL_ALL = 2,
    } curl_global_option;

    typedef enum {
        CURLMOPT_SOCKETDATA     = 10002,
        CURLMOPT_SOCKETFUNCTION = 20001,
        CURLMOPT_TIMERFUNCTION  = 20004
    } curl_multi_option;

    typedef enum {
        CURL_SOCKET_TIMEOUT = -1
    } curl_socket_option;

    typedef enum {
        CURL_POLL_IN     = 1,
        CURL_POLL_OUT    = 2,
        CURL_POLL_REMOVE = 4
    } curl_poll_option;

    typedef enum {
        CURLOPT_POSTFIELDSIZE = 60,
        CURLOPT_WRITEDATA     = 10001,
        CURLOPT_URL           = 10002,
        CURLOPT_POSTFIELDS    = 10015,
        CURLOPT_WRITEFUNCTION = 20011
    } curl_option;

    typedef enum {
        CURL_CSELECT_IN  = 1,
        CURL_CSELECT_OUT = 2
    } curl_cselect_option;

    int curl_global_init(curl_global_option option);

    curl  curl_easy_init();
    int   curl_easy_setopt(curl handle, curl_option option, ...);
    void  curl_easy_cleanup(curl handle);
    char* curl_easy_strerror(int code);

    curlm     curl_multi_init();
    int       curl_multi_setopt(curlm multi, curl_multi_option option, ...);
    int       curl_multi_add_handle(curlm multi, curl handle);
    int       curl_multi_socket_action(curlm multi, int fd, int event, int *handles);
    int       curl_multi_remove_handle(curlm multi, curl handle);
    curl_msg* curl_multi_info_read(curlm multi, int* msgs);

    typedef int    (*socket_callback)(curl handle, int fd, int what, void* clientp, void* socketp);
    typedef int    (*timer_callback)(curlm multi, long ms, void* clientp);
    typedef size_t (*write_callback)(char* ptr, size_t size, size_t nmemb, void* userdata);
]])

---@alias curl cdata
---@alias curlm cdata
---@alias callback fun(data: string|nil, err: string|nil)

---@class poll
---@field start fun(self: poll, events: number, callback: fun(events: number))
---@field stop fun(self: poll)

---@class timer
---@field start fun(self: timer, ms: number, callback: fun())
---@field stop fun(self: timer)
---@field closed fun(self: timer): boolean

---@class cache
---@field data string[]
---@field callback callback

local int = ffi.typeof("int[1]")
libcurl.curl_global_init(libcurl.CURL_GLOBAL_ALL)

local cast = setmetatable({}, {
    ---cast an object to C type using cached type
    ---@param self table
    ---@param typedef string C type definition
    ---@param object any object to cast
    ---@return cdata c
    __call = function(self, typedef, object)
        local typeobj = self[typedef]
        if not typeobj then
            typeobj = ffi.typeof(typedef)
            self[typedef] = typeobj
        end
        return ffi.cast(typeobj, object)
    end
})

--- Converts a cdata object to its memory address.
---@param cdata ffi.cdata*
---@return number
local function address(cdata)
    return assert(tonumber(cast("intptr_t", cdata)))
end

local curl = {
    multi = assert(libcurl.curl_multi_init()), ---@type curlm
    polls = {}, ---@type { [number]: poll }
    timer = loop:timer(), ---@type timer
    handles = {} ---@type { [number]: cache }
}

--- This is the callback function for curl's CURLOPT_WRITEFUNCTION option.
---@param ptr ffi.cdata*
---@param size number
---@param nmemb number
---@param handle curl
---@return number
local write_callback = cast("write_callback", function(ptr, size, nmemb, handle)
    local len = size * nmemb
    table.insert(curl.handles[address(handle)].data, ffi.string(ptr, len))
    return len
end)

libcurl.curl_multi_setopt(curl.multi, libcurl.CURLMOPT_SOCKETFUNCTION,
    --- This is the callback function for curl's CURLMOPT_SOCKETFUNCTION option.
    ---@param handle curl
    ---@param fd number
    ---@param action number
    ---@return number
    cast("socket_callback", function(handle, fd, action)
        curl.timer:stop()

        --- This function is called by libuv when a socket is ready for reading or writing.
        ---@param events number
        local function perform(events)
            if events == loop.UV_READABLE then
                libcurl.curl_multi_socket_action(curl.multi, fd, libcurl.CURL_CSELECT_IN, int())
            elseif events == loop.UV_WRITABLE then
                libcurl.curl_multi_socket_action(curl.multi, fd, libcurl.CURL_CSELECT_OUT, int())
            end

            local msg = nil
            repeat
                msg = libcurl.curl_multi_info_read(curl.multi, int())
                if msg ~= nil and msg.msg == libcurl.CURLMSG_DONE then
                    libcurl.curl_multi_remove_handle(curl.multi, msg.handle)
                    libcurl.curl_easy_cleanup(msg.handle)

                    local cache = assert(curl.handles[address(msg.handle)])
                    curl.handles[address(msg.handle)] = nil
                    if msg.result ~= 0 then
                        cache.callback(nil, ffi.string(libcurl.curl_easy_strerror(msg.result)))
                    else
                        cache.callback(table.concat(cache.data))
                    end
                end
            until msg == nil
        end

        local poll = curl.polls[fd]
        if not poll then
            poll = loop:poll(fd)
            curl.polls[fd] = poll
        end

        if action == libcurl.CURL_POLL_IN then
            poll:start(loop.UV_READABLE, perform)
        elseif action == libcurl.CURL_POLL_OUT then
            poll:start(loop.UV_WRITABLE, perform)
        elseif action == libcurl.CURL_POLL_REMOVE then
            poll:stop()
            curl.polls[fd] = nil
        end

        return 0
    end))

--- This function is called by libuv when the timer expires.
local function timeout()
    libcurl.curl_multi_socket_action(curl.multi, libcurl.CURL_SOCKET_TIMEOUT, 0, int())
end

libcurl.curl_multi_setopt(curl.multi, libcurl.CURLMOPT_TIMERFUNCTION, cast("timer_callback",
    --- This is the callback function for curl's CURLMOPT_TIMERFUNCTION option.
    ---@param multi curlm
    ---@param ms number
    ---@return number
    function(multi, ms) ---@diagnostic disable-line:unused-local
        ms = assert(tonumber(ms))
        curl.timer:stop()
        if ms >= 0 then curl.timer:start(ms, timeout) end
        return 0
    end))


---Add a new request to the curl multi instance
---@param handle curl
---@param url string
---@param callback callback
local function add(handle, url, callback)
    libcurl.curl_easy_setopt(handle, libcurl.CURLOPT_URL, url)
    libcurl.curl_easy_setopt(handle, libcurl.CURLOPT_WRITEFUNCTION, write_callback)
    libcurl.curl_easy_setopt(handle, libcurl.CURLOPT_WRITEDATA, handle);

    -- in case loop was shutdown between calls
    if curl.timer:closed() then
        curl.timer = loop:timer()
    end

    curl.handles[address(handle)] = {
        data = {},
        callback = callback or function() end
    }

    libcurl.curl_multi_add_handle(curl.multi, handle);
end

---Perform an HTTP GET request
---@param url string
---@param callback callback
local function get(url, callback)
    local handle = assert(libcurl.curl_easy_init())
    add(handle, url, callback)
end

---Perform an HTTP POST request
---@param url string
---@param data string
---@param callback callback
local function post(url, data, callback)
    local handle = libcurl.curl_easy_init()
    libcurl.curl_easy_setopt(handle, libcurl.CURLOPT_POSTFIELDS, cast("char *", data))
    libcurl.curl_easy_setopt(handle, libcurl.CURLOPT_POSTFIELDSIZE, cast("long", #data))
    add(handle, url, callback)
end

return {
    GET = get,
    POST = post,
}
