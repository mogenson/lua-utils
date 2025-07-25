local ffi = require("ffi")
local uv = require("libuv")

local libcurl = ffi.load('curl')
ffi.cdef([[
    enum CURLMSG {
        CURLMSG_NONE,
        CURLMSG_DONE,
        CURLMSG_LAST
    };

    struct CURLMsg {
        enum CURLMSG msg;
        void* handle;
        union {
            void* whatever;
            int result;
        } data;
    };

    enum curl_global_option
    {
        CURL_GLOBAL_ALL = 2,
    };

    enum curl_multi_option
    {
        CURLMOPT_SOCKETFUNCTION = 20000 + 1,
        CURLMOPT_TIMERFUNCTION  = 20000 + 4
    };

    enum curl_socket_option
    {
        CURL_SOCKET_TIMEOUT = -1
    };

    enum curl_poll_option
    {
        CURL_POLL_IN     = 1,
        CURL_POLL_OUT    = 2,
        CURL_POLL_REMOVE = 4
    };

    enum curl_option
    {
        CURLOPT_CAINFO         = 10065,
        CURLOPT_CONNECTTIMEOUT = 78,
        CURLOPT_COOKIE         = 10022,
        CURLOPT_FOLLOWLOCATION = 52,
        CURLOPT_HEADER         = 42,
        CURLOPT_HTTPHEADER     = 10023,
        CURLOPT_INTERFACE      = 10062,
        CURLOPT_POST           = 47,
        CURLOPT_POSTFIELDS     = 10015,
        CURLOPT_REFERER        = 10016,
        CURLOPT_SSL_VERIFYPEER = 64,
        CURLOPT_URL            = 10002,
        CURLOPT_USERAGENT      = 10018,
        CURLOPT_WRITEFUNCTION  = 20011,
        CURLOPT_WRITEDATA      = 10001,
    };

    enum curl_cselect_option
    {
        CURL_CSELECT_IN  = 1,
        CURL_CSELECT_OUT = 2
    };

    int curl_global_init(enum curl_global_option option);

    void* curl_easy_init();
    int   curl_easy_setopt(void* curl, enum curl_option option, ...);
    int   curl_easy_perform(void* curl);
    void  curl_easy_cleanup(void* curl);
    char* curl_easy_strerror(int code);

    void*   curl_multi_init();
    int     curl_multi_setopt(void* curlm, enum curl_multi_option option, ...);
    int     curl_multi_add_handle(void* curlm, void* curl_handle);
    int     curl_multi_socket_action(void* curlm, int s, int ev_bitmask, int *running_handles);
    int     curl_multi_assign(void* curlm, int sockfd, void *sockp);
    int     curl_multi_remove_handle(void* curlm, void* curl_handle);
    struct CURLMsg *curl_multi_info_read(void* curlm, int *msgs_in_queue);

    typedef int (*curlm_socketfunction)(void* curlm, int sockfd, int ev_bitmask, int *running_handles);
    typedef int (*curlm_timerfunction)(void* curlm, long timeout_ms, int *userp);
    typedef size_t (*curl_datafunction)(char *ptr, size_t size, size_t nmemb, void *userdata);
]])

libcurl.curl_global_init(libcurl.CURL_GLOBAL_ALL)

--- Converts a cdata object to its memory address.
---@param cdata ffi.cdata*
---@return number
local function address(cdata)
    return assert(tonumber(ffi.cast("intptr_t", cdata)))
end

local Multi = {
    multi = libcurl.curl_multi_init(),
    polls = {},
    handles = {},
    timer = uv:new_timer(),
}

--- Adds a new network request to the curl multi instance.
---@param self table
---@param url string
---@param data_callback fun(data: string)
---@param finished_callback fun(result: number)
function Multi:add(url, data_callback, finished_callback)
    local handle = libcurl.curl_easy_init()
    libcurl.curl_easy_setopt(handle,
        libcurl.CURLOPT_URL,
        url)
    libcurl.curl_easy_setopt(handle,
        libcurl.CURLOPT_WRITEFUNCTION,
        ffi.cast('curl_datafunction', function(...) return Multi.data_function(self, ...) end))
    libcurl.curl_easy_setopt(handle, libcurl.CURLOPT_WRITEDATA, handle);
    libcurl.curl_multi_add_handle(self.multi, handle);
    self.handles[address(handle)] = {
        data_callback = data_callback,
        finished_callback = finished_callback,
    }
end

--- This is the callback function for curl's CURLOPT_WRITEFUNCTION option.
---@param self table
---@param ptr ffi.cdata*
---@param size number
---@param nmemb number
---@param handle ffi.cdata*
---@return number
function Multi:data_function(ptr, size, nmemb, handle)
    local len = size * nmemb
    local callback = (self.handles[address(handle)] or {}).data_callback
    if callback then
        callback(ffi.string(ptr, len))
    end
    return len
end

--- This is the callback function for curl's CURLMOPT_SOCKETFUNCTION option.
---@param self table
---@param handle ffi.cdata*
---@param fd number
---@param action number
---@return number
---@diagnostic disable-next-line: unused-local
function Multi:socket_function(handle, fd, action)
    self.timer:stop()

    --- This function is called by libuv when a socket is ready for reading or writing.
    ---@param events number
    local function perform(events)
        local running_handles = ffi.new('int[1]')
        if events == uv.UV_READABLE then
            libcurl.curl_multi_socket_action(self.multi, fd, libcurl.CURL_CSELECT_IN, running_handles)
        elseif events == uv.UV_WRITABLE then
            libcurl.curl_multi_socket_action(self.multi, fd, libcurl.CURL_CSELECT_OUT, running_handles)
        end

        local pending, msg = ffi.new('int[1]'), nil
        repeat
            msg = libcurl.curl_multi_info_read(self.multi, pending)
            if msg ~= nil and msg.msg == libcurl.CURLMSG_DONE then
                libcurl.curl_multi_remove_handle(self.multi, msg.handle)
                libcurl.curl_easy_cleanup(msg.handle)
                local callback = (self.handles[address(msg.handle)] or {}).finished_callback
                self.handles[address(msg.handle)] = nil
                if callback then
                    callback(tonumber(msg.data.result))
                end
            end
        until msg == nil
    end

    local poll = self.polls[fd]
    if not poll then
        poll = uv:new_poll(fd)
        self.polls[fd] = poll
    end

    if action == libcurl.CURL_POLL_IN then
        poll:start(uv.UV_READABLE, perform)
    elseif action == libcurl.CURL_POLL_OUT then
        poll:start(uv.UV_WRITABLE, perform)
    elseif action == libcurl.CURL_POLL_REMOVE then
        poll:stop()
        self.polls[fd] = nil
    end

    return 0
end

--- This is the callback function for curl's CURLMOPT_TIMERFUNCTION option.
---@param self table
---@param curlm ffi.cdata*
---@param ms number
---@return number
---@diagnostic disable-next-line: unused-local
function Multi:timer_function(curlm, ms)
    ms = assert(tonumber(ms))
    self.timer:stop()
    if ms < 0 then return 0 end

    --- This function is called by libuv when the timer expires.
    ---@param timer ffi.cdata*
    ---@diagnostic disable-next-line: unused-local
    local function action(timer)
        local running_handles = ffi.new('int[1]')
        libcurl.curl_multi_socket_action(self.multi, libcurl.CURL_SOCKET_TIMEOUT, 0, running_handles)
    end

    self.timer:start(ms, action)
    return 0
end

libcurl.curl_multi_setopt(Multi.multi, libcurl.CURLMOPT_SOCKETFUNCTION,
    ffi.cast("curlm_socketfunction", function(handle, fd, action)
        return Multi.socket_function(Multi, handle, fd, action)
    end))

libcurl.curl_multi_setopt(Multi.multi, libcurl.CURLMOPT_TIMERFUNCTION,
    ffi.cast("curlm_timerfunction", function(curlm, ms)
        return Multi.timer_function(Multi, curlm, ms)
    end))

return Multi
