local ffi = require("ffi")
local cast = ffi.cast
local C = ffi.C

ffi.cdef([[
    struct sockaddr {
      unsigned short    sa_family;
      char              sa_data[14];
    };

    struct in_addr {
        unsigned long s_addr;
    };

    struct sockaddr_in {
        short            sin_family;
        unsigned short   sin_port;
        struct in_addr   sin_addr;
        char             sin_zero[8];
    };

void *malloc(size_t size);
void free(void *ptr);
]])

local libuv = ffi.load("libuv")

ffi.cdef([[
    typedef enum {
        UV_EOF = -4095
    } uv_errno_t;

    typedef enum {
        UV_UNKNOWN_HANDLE = 0,
        UV_ASYNC,
        UV_CHECK,
        UV_FS_EVENT,
        UV_FS_POLL,
        UV_HANDLE,
        UV_IDLE,
        UV_NAMED_PIPE,
        UV_POLL,
        UV_PREPARE,
        UV_PROCESS,
        UV_STREAM,
        UV_TCP,
        UV_TIMER,
        UV_TTY,
        UV_UDP,
        UV_SIGNAL,
        UV_FILE,
        UV_HANDLE_TYPE_MAX
    } uv_handle_type;

    typedef enum {
        UV_UNKNOWN_REQ = 0,
        UV_REQ,
        UV_CONNECT,
        UV_WRITE,
        UV_SHUTDOWN,
        UV_UDP_SEND,
        UV_FS,
        UV_WORK,
        UV_GETADDRINFO,
        UV_GETNAMEINFO,
        UV_REQ_TYPE_MAX,
    } uv_req_type;

    size_t uv_loop_size(void);
    size_t uv_req_size(uv_req_type type);
    size_t uv_handle_size(uv_handle_type type);
]])

ffi.cdef(string.format([[
    struct uv_loop_s {uint8_t _[%d];};
    struct uv_connect_s {uint8_t _[%d];};
    struct uv_write_s {uint8_t _[%d];};
    struct uv_shutdown_s {uint8_t _[%d];};
    struct uv_getaddrinfo_s {uint8_t _[%d];};
    struct uv_tcp_s {uint8_t _[%d];};
    struct uv_tty_s {uint8_t _[%d];};
    struct uv_pipe_s {uint8_t _[%d];};
    struct uv_timer_s {uint8_t _[%d];};
    struct uv_poll_s {uint8_t _[%d];};
]],
    tonumber(libuv.uv_loop_size()),
    tonumber(libuv.uv_req_size(libuv.UV_CONNECT)),
    tonumber(libuv.uv_req_size(libuv.UV_WRITE)),
    tonumber(libuv.uv_req_size(libuv.UV_SHUTDOWN)),
    tonumber(libuv.uv_req_size(libuv.UV_GETADDRINFO)),
    tonumber(libuv.uv_handle_size(libuv.UV_TCP)),
    tonumber(libuv.uv_handle_size(libuv.UV_TTY)),
    tonumber(libuv.uv_handle_size(libuv.UV_NAMED_PIPE)),
    tonumber(libuv.uv_handle_size(libuv.UV_TIMER)),
    tonumber(libuv.uv_handle_size(libuv.UV_POLL))
))

ffi.cdef([[
    typedef struct uv_loop_s uv_loop_t;
    typedef struct uv_req_s uv_req_t;
    typedef struct uv_write_s uv_write_t;
    typedef struct uv_connect_s uv_connect_t;
    typedef struct uv_shutdown_s uv_shutdown_t;
    typedef struct uv_getaddrinfo_s uv_getaddrinfo_t;
    typedef struct uv_handle_s uv_handle_t;
    typedef struct uv_stream_s uv_stream_t;
    typedef struct uv_tcp_s uv_tcp_t;
    typedef struct uv_tty_s uv_tty_t;
    typedef struct uv_pipe_s uv_pipe_t;
    typedef struct uv_timer_s uv_timer_t;
    typedef struct uv_poll_s uv_poll_t;

    const char* uv_err_name(int err);
    const char* uv_strerror(int err);
]])

local function get_error(status)
    local name = ffi.string(libuv.uv_err_name(status))
    local err = ffi.string(libuv.uv_strerror(status))
    return string.format("%: %", name, err)
end

---Checks the status of a libuv operation and throws an error if it's negative.
---@param status number
---@return number
local function check(status)
    return status < 0 and error(get_error(status)) or assert(tonumber(status))
end

ffi.cdef([[
    typedef void (*uv_close_cb)(uv_handle_t *handle);

    const char *uv_handle_type_name(uv_handle_type type);
    int uv_is_closing(const uv_handle_t *handle);
    uv_handle_type uv_handle_get_type(const uv_handle_t *handle);
    void uv_close(uv_handle_t *handle, uv_close_cb close_cb);
    void* uv_handle_get_data(const uv_handle_t* handle);
    void* uv_handle_set_data(uv_handle_t* handle, void* data);
]])

local Handle = {}
Handle.__index = Handle

---Returns a string representation of a libuv handle.
---@param self ffi.cdata*
---@return string
function Handle:__tostring()
    local id = libuv.uv_handle_get_type(cast("uv_handle_t*", self))
    return ffi.string(libuv.uv_handle_type_name(id))
end

---Close a libuv handle
---@param self ffi.cdata*
function Handle:close()
    libuv.uv_close(cast("uv_handle_t*", self), nil)
    local cached = cast("uv_buf_t*", libuv.uv_handle_get_data(cast("const uv_handle_t*", self)))
    if cached ~= nil then
        C.free(cached.base)
        C.free(cached)
    end
end

---This is the garbage collection metamethod for libuv handles.
---@param self ffi.cdata*
function Handle:__gc()
    if libuv.uv_is_closing(cast("uv_handle_t*", self)) ~= 0 then
        libuv.uv_close(cast("uv_handle_t*", self), nil)
    end
end

ffi.cdef([[
    typedef enum uv_run_mode_e {
        UV_RUN_DEFAULT = 0,
        UV_RUN_ONCE,
        UV_RUN_NOWAIT
    } uv_run_mode;

    uv_loop_t* uv_default_loop();
    void uv_stop(uv_loop_t* loop);
    uint64_t uv_now(const uv_loop_t* loop);
    void uv_update_time(uv_loop_t *loop);
    int uv_run(uv_loop_t* loop, uv_run_mode mode);
]])

local Loop = {}
Loop.__index = Loop
setmetatable(Loop, { __index = libuv })
ffi.metatype(ffi.typeof("uv_loop_t"), Loop)

---Returns the current time in milliseconds.
---@param self ffi.cdata*
---@return number
function Loop:now()
    return assert(tonumber(libuv.uv_loop_now(self)))
end

---Updates the event loop's concept of "now".
---@param self ffi.cdata*
function Loop:update_time()
    libuv.uv_update_time(self)
end

---Stops the event loop.
---@param self ffi.cdata*
function Loop:stop()
    libuv.uv_stop(self)
end

---Start the event loop.
---@param self ffi.cdata*
---@param mode number a member of the uv_run_mode enum
-- @return number
function Loop:run(mode)
    return check(libuv.uv_run(self, mode or libuv.UV_RUN_DEFAULT))
end

ffi.cdef([[
    typedef void (*uv_timer_cb)(uv_timer_t* handle);

    int uv_timer_init(uv_loop_t* loop, uv_timer_t* handle);
    int uv_timer_start(uv_timer_t* handle, uv_timer_cb cb, uint64_t timeout, uint64_t repeat);
    int uv_timer_stop(uv_timer_t* handle);
]])

local Timer = setmetatable({}, Handle)
Timer.__index = Timer
ffi.metatype(ffi.typeof("uv_timer_t"), Timer)

---Creates a new timer.
---@param self ffi.cdata*
---@return ffi.cdata*
function Loop:new_timer()
    local timer = ffi.new("uv_timer_t")
    check(libuv.uv_timer_init(self, timer))
    return timer
end

---Starts a timer.
---@param self ffi.cdata*
---@param timeout number
---@param callback function
function Timer:start(timeout, callback)
    check(libuv.uv_timer_start(self, cast("uv_timer_cb", callback), timeout, 0))
end

---Starts a recurring timer.
---@param self ffi.cdata*
---@param interval number
---@param callback function
function Timer:recurring(interval, callback)
    check(libuv.uv_timer_start(self, cast("uv_timer_cb", callback), interval, interval))
end

---Stops a timer.
---@param self ffi.cdata*
function Timer:stop()
    check(libuv.uv_timer_stop(self))
end

ffi.cdef([[
    enum uv_poll_event {
        UV_READABLE = 1,
        UV_WRITABLE = 2,
        UV_DISCONNECT = 4,
        UV_PRIORITIZED = 8
    };
    typedef void (*uv_poll_cb)(uv_poll_t *handle, int status, int events);
    int uv_poll_init(uv_loop_t *loop, uv_poll_t *handle, int fd);
    int uv_poll_start(uv_poll_t *handle, int events, uv_poll_cb cb);
    int uv_poll_stop(uv_poll_t *poll);
]])

local Poll = setmetatable({}, Handle)
Poll.__index = Poll
ffi.metatype(ffi.typeof("uv_poll_t"), Poll)

---Creates a new poll handle.
---@param self ffi.cdata*
---@param fd number
---@return ffi.cdata*
function Loop:new_poll(fd)
    local poll = ffi.new("uv_poll_t")
    check(libuv.uv_poll_init(self, poll, fd))
    return poll
end

---Starts polling a file descriptor.
---@param self ffi.cdata*
---@param events number a member of the uv_poll_event enum
---@param callback function
function Poll:start(events, callback)
    check(libuv.uv_poll_start(self, events, cast("uv_poll_cb", callback)))
end

---Stops polling a file descriptor.
---@param self ffi.cdata*
function Poll:stop()
    check(libuv.uv_poll_stop(self))
end

ffi.cdef([[
    int uv_cancel(uv_req_t *req);
    uv_req_type uv_req_get_type(const uv_req_t* req);
    const char* uv_req_type_name(uv_req_type type);
]])

local Request = {}
Request.__index = Request

function Request:cancel()
    check(libuv.uv_cancel(cast("uv_req_t*", self)))
end

function Request:__tostring()
    local id = libuv.uv_req_get_type(cast("uv_req_t*", self))
    return ffi.string(libuv.uv_req_type_name(id))
end

local Connect = setmetatable({}, Request)
Connect.__index = Connect
ffi.metatype(ffi.typeof("uv_connect_t"), Connect)

local Write = setmetatable({}, Request)
Write.__index = Write
ffi.metatype(ffi.typeof("uv_write_t"), Write)

local Shutdown = setmetatable({}, Request)
Shutdown.__index = Shutdown
ffi.metatype(ffi.typeof("uv_shutdown_t"), Shutdown)

ffi.cdef([[
    typedef struct uv_buf_t {
        char* base;
        size_t len;
    } uv_buf_t;

    typedef void (*uv_alloc_cb)(uv_handle_t *handle, size_t suggested_size, uv_buf_t *buf);
    typedef void (*uv_connect_cb)(uv_connect_t *req, int status);
    typedef void (*uv_connection_cb)(uv_stream_t *server, int status);
    typedef void (*uv_read_cb)(uv_stream_t *stream, ssize_t nread, const uv_buf_t *buf);
    typedef void (*uv_shutdown_cb)(uv_shutdown_t *req, int status);
    typedef void (*uv_write_cb)(uv_write_t *req, int status);

    int uv_accept(uv_stream_t *server, uv_stream_t *client);
    int uv_listen(uv_stream_t *stream, int backlog, uv_connection_cb cb);
    int uv_read_start(uv_stream_t *stream, uv_alloc_cb alloc_cb, uv_read_cb read_cb);
    int uv_read_stop(uv_stream_t*);
    int uv_shutdown(uv_shutdown_t *req, uv_stream_t *handle, uv_shutdown_cb cb);
    int uv_write(uv_write_t *req, uv_stream_t *handle, const uv_buf_t bufs[], unsigned int nbufs, uv_write_cb cb);
]])

local Stream = setmetatable({}, Handle)
Stream.__index = Stream
ffi.metatype(ffi.typeof("uv_stream_t"), Stream)

function Stream:shutdown(callback)
    local req = cast("uv_shutdown_t*", C.malloc(ffi.sizeof("uv_shutdown_t")))
    local handle = cast("uv_stream_t*", self)
    local cb = cast("uv_shutdown_cb", function(req, status)
        C.free(req)
        check(status)
        if callback then callback() end
    end)
    check(libuv.uv_shutdown(req, handle, cb))
end

function Stream:listen(backlog, callback)
    local stream = cast("uv_stream_t*", self)
    local cb = cast("uv_connection_cb", function(server, status)
        check(status)
        callback()
    end)
    check(libuv.uv_listen(stream, backlog, cb))
end

function Stream:accept(client)
    local server = cast("uv_stream_t*", self)
    local client = cast("uv_stream_t*", client)
    check(libuv.uv_accept(server, client))
end

function Stream:read_start(callback)
    local stream = cast("uv_stream_t*", self)

    local alloc_cb = cast("uv_alloc_cb", function(handle, suggested_size, buf)
        local cached = cast("uv_buf_t*", libuv.uv_handle_get_data(handle))
        if cached ~= nil then
            buf.base = cached.base
            buf.len = cached.len
        else
            local base = C.malloc(suggested_size)
            buf.base = base
            buf.len = suggested_size
            local data = cast("uv_buf_t*", C.malloc(ffi.sizeof("uv_buf_t")))
            data.base = base
            data.len = suggested_size
            libuv.uv_handle_set_data(handle, data)
        end
    end)

    local read_cb = cast("uv_read_cb", function(stream, nread, buf)
        if nread == 0 then
            return
        elseif nread == libuv.UV_EOF then
            callback(nil)
        else
            check(nread) -- shoud be > 0
            callback(ffi.string(buf.base, nread))
        end
    end)

    check(libuv.uv_read_start(stream, alloc_cb, read_cb))
end

function Stream:read_stop()
    check(libuv.uv_read_stop(cast("uv_stream_t*", self)))
end

function Stream:write(data, callback)
    local req = cast("uv_write_t*", C.malloc(ffi.sizeof("uv_write_t")))
    local handle = cast("uv_stream_t*", self)
    local bufs = ffi.new("uv_buf_t[1]")
    bufs[0].base = cast("char*", data)
    bufs[0].len = #data
    local nbufs = 1
    local cb = cast("uv_write_cb", function(req, status)
        C.free(req)
        check(status)
        if callback then callback() end
    end)
    check(libuv.uv_write(req, handle, bufs, nbufs, cb))
end

ffi.cdef([[
    int uv_ip4_addr(const char *ip, int port, struct sockaddr_in *addr);

    int uv_tcp_init(uv_loop_t* loop, uv_tcp_t* handle);
    int uv_tcp_bind(uv_tcp_t* handle, const struct sockaddr* addr, unsigned int flags);
    int uv_tcp_connect(uv_connect_t* req, uv_tcp_t* handle, const struct sockaddr_in* addr, uv_connect_cb cb);
]])

local Tcp = setmetatable({}, Stream)
Tcp.__index = Tcp
ffi.metatype(ffi.typeof("uv_tcp_t"), Tcp)

---Creates a new Tcp socket
---@param self ffi.cdata*
---@return ffi.cdata*
function Loop:new_tcp()
    local tcp = ffi.new("uv_tcp_t")
    check(libuv.uv_tcp_init(self, tcp))
    return tcp
end

---Bind socket to an IP address and port
---@param host string
---@param port number
function Tcp:bind(host, port)
    local addr = ffi.new("struct sockaddr_in")
    check(libuv.uv_ip4_addr(host, port, addr))
    check(libuv.uv_tcp_bind(self, cast("const struct sockaddr*", addr), 0))
end

---Connect to an IP address and port
---@param host string
---@param port number
---@param callback function
function Tcp:connect(host, port, callback)
    local addr = ffi.new("struct sockaddr_in")
    check(libuv.uv_ip4_addr(host, port, addr))
    local req = cast("uv_connect_t*", C.malloc(ffi.sizeof("uv_connect_t")))
    local cb = cast("uv_connect_cb", function(req, status)
        C.free(req)
        check(status)
        callback()
    end)
    check(libuv.uv_tcp_connect(req, self, addr, cb))
end

return libuv.uv_default_loop()
