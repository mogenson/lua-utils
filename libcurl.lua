-- FFI example for libcurl integration into the libuv event loop
local ffi = require('ffi')
local bit = require('bit')

-- CURL FFI ------------------------------------------------------------------
local libcurl = ffi.load('curl')
ffi.cdef([[
    enum CURLMSG {
        CURLMSG_NONE,
        CURLMSG_DONE,
        CURLMSG_LAST
    };

    struct CURLMsg {
        enum CURLMSG msg;
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
        CURLOPT_WRITEFUNCTION  = 20011
    };

    enum curl_cselect_option
    {
        CURL_CSELECT_IN  = 1,
        CURL_CSELECT_OUT = 2
    };

    int curl_global_init(enum curl_global_option option);

    typedef void* CURL;

    CURL  curl_easy_init();
    int   curl_easy_setopt(CURL curl, enum curl_option option, ...);
    int   curl_easy_perform(CURL curl);
    void  curl_easy_cleanup(CURL curl);
    char* curl_easy_strerror(int code);

    typedef void* CURLM;

    CURLM   curl_multi_init();
    int     curl_multi_setopt(CURLM curlm, enum curl_multi_option option, ...);
    int     curl_multi_add_handle(CURLM curlm, CURL curl_handle);
    int     curl_multi_socket_action(CURLM curlm, int s, int ev_bitmask, int *running_handles);
    int     curl_multi_assign(CURLM curlm, int sockfd, void *sockp);
    int     curl_multi_remove_handle(CURLM curlm, CURL curl_handle);
    struct CURLMsg *curl_multi_info_read(CURLM curlm, int *msgs_in_queue);

    typedef int (*curlm_socketfunction)(CURLM curlm, int sockfd, int ev_bitmask, int *running_handles);
    typedef int (*curlm_timerfunction)(CURLM curlm, long timeout_ms, int *userp);
    typedef size_t (*curl_datafunction)(char *ptr, size_t size, size_t nmemb, void *userdata);
]])

-- UV FFI --------------------------------------------------------------------
local loop = require("libuv")

-- cURL Multi with uv --------------------------------------------------------
local Multi = {}
Multi.__index = Multi

function Multi.new()
    local self = { multi = libcurl.curl_multi_init(), polls = {}, timer = loop:new_timer() }
    libcurl.curl_multi_setopt(self.multi, libcurl.CURLMOPT_SOCKETFUNCTION,
        ffi.cast("curlm_socketfunction", function(handle, fd, action)
            return Multi.socket_function(self, handle, fd, action)
        end))
    libcurl.curl_multi_setopt(self.multi, libcurl.CURLMOPT_TIMERFUNCTION,
        ffi.cast("curlm_timerfunction", function(curlm, ms)
            return Multi.timer_function(self, curlm, ms)
        end))
    return setmetatable(self, Multi)
end

function Multi:add(url)
    print("add ", url)
    local handle = libcurl.curl_easy_init()
    libcurl.curl_easy_setopt(handle,
        libcurl.CURLOPT_URL,
        url)
    libcurl.curl_easy_setopt(handle,
        libcurl.CURLOPT_WRITEFUNCTION,
        ffi.cast('curl_datafunction', function(...) return Multi.data_function(self, ...) end))
    libcurl.curl_multi_add_handle(self.multi, handle);
end

function Multi:data_function(ptr, size, nmemb, userdata)
    print(ffi.string(ptr))
    return size
end

function Multi:socket_function(handle, fd, action)
    print("on socket")
    self.timer:stop()

    local function perform(handle, status, events)
        assert(status >= 0)

        local running_handles = ffi.new('int[1]')
        if events == loop.UV_READABLE then
            libcurl.curl_multi_socket_action(self.multi, fd, libcurl.CURL_CSELECT_IN, running_handles)
        elseif events == loop.UV_WRITABLE then
            libcurl.curl_multi_socket_action(self.multi, fd, libcurl.CURL_CSELECT_OUT, running_handles)
        end

        local pending, msg = ffi.new('int[1]'), nil
        repeat
            msg = libcurl.curl_multi_info_read(self.multi, pending)
            if msg ~= nil and msg.msg == libcurl.CURLMSG_DONE then
                libcurl.curl_multi_remove_handle(self.multi, handle)
                libcurl.curl_easy_cleanup(handle)
            end
        until msg == nil
    end

    local poll = self.polls[fd]
    if not poll then
        poll = loop:new_poll(fd)
        self.polls[fd] = poll
    end

    if action == libcurl.CURL_POLL_IN then
        poll:start(loop.UV_READABLE, perform)
    elseif action == libcurl.CURL_POLL_OUT then
        poll:start(loop.UV_WRITABLE, perform)
    elseif action == libcurl.CURL_POLL_REMOVE then
        poll:stop()
        self.polls[fd] = nil
    end

    return 0
end

function Multi:timer_function(curlm, ms)
    print("on timer")
    ms = tonumber(ms)
    self.timer:stop()
    if ms < 0 then return 0 end
    local function action(timer)
        local running_handles = ffi.new('int[1]')
        libcurl.curl_multi_socket_action(self.multi, libcurl.CURL_SOCKET_TIMEOUT, 0, running_handles)
    end
    self.timer:start(ms, action)
    return 0
end

libcurl.curl_global_init(libcurl.CURL_GLOBAL_ALL)
return Multi.new()
