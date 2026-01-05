local ffi = require("ffi")

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
    struct uv_fs_s {uint8_t _[%d];};
    struct uv_tcp_s {uint8_t _[%d];};
    struct uv_tty_s {uint8_t _[%d];};
    struct uv_pipe_s {uint8_t _[%d];};
    struct uv_timer_s {uint8_t _[%d];};
    struct uv_poll_s {uint8_t _[%d];};
    struct uv_signal_s {uint8_t _[%d];};
]],
    tonumber(libuv.uv_loop_size()),
    tonumber(libuv.uv_req_size(libuv.UV_CONNECT)),
    tonumber(libuv.uv_req_size(libuv.UV_WRITE)),
    tonumber(libuv.uv_req_size(libuv.UV_SHUTDOWN)),
    tonumber(libuv.uv_req_size(libuv.UV_GETADDRINFO)),
    tonumber(libuv.uv_req_size(libuv.UV_FS)),
    tonumber(libuv.uv_handle_size(libuv.UV_TCP)),
    tonumber(libuv.uv_handle_size(libuv.UV_TTY)),
    tonumber(libuv.uv_handle_size(libuv.UV_NAMED_PIPE)),
    tonumber(libuv.uv_handle_size(libuv.UV_TIMER)),
    tonumber(libuv.uv_handle_size(libuv.UV_POLL)),
    tonumber(libuv.uv_handle_size(libuv.UV_SIGNAL))
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
    typedef struct uv_signal_s uv_signal_t;
    typedef struct uv_fs_s uv_fs_t;

    const char* uv_err_name(int err);
    const char* uv_strerror(int err);
]])

---Return libuv error status as a formated Lua string
---@param status number
---@return string
local function get_error(status)
    local name = ffi.string(libuv.uv_err_name(status))
    local err = ffi.string(libuv.uv_strerror(status))
    return string.format("%s: %s", name, err)
end

---Checks the status of a libuv operation and returns an error if negative
---@param status number
---@return string? error
local function check(status)
    return status < 0 and get_error(status) or nil
end

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

---Convert a NULL pointer to nil
---@generic T
---@param p T
---@return T?
local function pointer(p)
    if p == nil then return nil else return p end
end

---Return the address of a pointer or cdata
---@param cdata ffi.cdata*
local function address(cdata)
    return assert(tonumber(cast("intptr_t", cast("void*", cdata))))
end

ffi.cdef([[
    typedef void (*uv_close_cb)(uv_handle_t *handle);

    const char *uv_handle_type_name(uv_handle_type type);
    int uv_is_closing(const uv_handle_t *handle);
    uv_handle_type uv_handle_get_type(const uv_handle_t *handle);
    void uv_close(uv_handle_t *handle, uv_close_cb close_cb);
    void* uv_handle_get_data(const uv_handle_t* handle);
    void uv_handle_set_data(uv_handle_t* handle, void* data);
]])

---@class Handle: ffi.cdata*
local Handle = {}
Handle.__index = Handle
ffi.metatype(ffi.typeof("uv_handle_t"), Handle)

---@type ffi.cb*
local close_cb = cast("uv_close_cb", function(handle)
    Handle.free_cache(handle)
end)

function Handle.__tostring(self)
    local id = libuv.uv_handle_get_type(cast("uv_handle_t*", self))
    return string.format("%s: %d", ffi.string(libuv.uv_handle_type_name(id)), address(self))
end

---Check if a libuv handle is closed
---@return boolean
function Handle:closed()
    return libuv.uv_is_closing(cast("uv_handle_t*", self)) ~= 0
end

---Close a libuv handle
function Handle:close()
    if not self:closed() then
        libuv.uv_close(cast("uv_handle_t*", self), close_cb)
    end
end

---This is the garbage collection metamethod for libuv handles.
function Handle:__gc()
    self:close()
end

ffi.cdef([[
    typedef enum uv_run_mode_e {
        UV_RUN_DEFAULT = 0,
        UV_RUN_ONCE,
        UV_RUN_NOWAIT
    } uv_run_mode;

    typedef void (*uv_walk_cb)(uv_handle_t *handle, void *arg);

    uv_loop_t* uv_default_loop();
    void uv_stop(uv_loop_t* loop);
    uint64_t uv_now(const uv_loop_t* loop);
    void uv_update_time(uv_loop_t *loop);
    int uv_run(uv_loop_t* loop, uv_run_mode mode);
    void uv_walk(uv_loop_t *loop, uv_walk_cb walk_cb, void *arg);
]])

---@class Loop: ffi.cdata*
---@field UV_RUN_DEFAULT number
---@field UV_RUN_ONCE number
---@field UV_RUN_NOWAI number
---@field UV_READABLE number
---@field UV_WRITABLE number
---@field UV_DISCONNECT number
---@field UV_PRIORITIZED number
---@field UV_DIRENT_UNKNOWN number
---@field UV_DIRENT_FILE number
---@field UV_DIRENT_DIR number
---@field UV_DIRENT_LINK number
local Loop = setmetatable({}, { __index = libuv })
ffi.metatype(ffi.typeof("uv_loop_t"), { __index = Loop })

---Returns the current time in milliseconds.
---@return number
function Loop:now()
    return assert(tonumber(libuv.uv_now(self)))
end

---Updates the event loop's concept of "now".
function Loop:update_time()
    libuv.uv_update_time(self)
end

---Stops the event loop.
function Loop:stop()
    libuv.uv_stop(self)
end

---Stops the event loop and closes all handles
function Loop:shutdown()
    libuv.uv_stop(self)
    libuv.uv_walk(self, cast("uv_walk_cb",
        function(handle, arg) ---@diagnostic disable-line:unused-local
            Handle.close(handle)
        end), nil)
    libuv.uv_run(self, libuv.UV_RUN_ONCE)
end

---Start the event loop.
---@param mode number? a member of the uv_run_mode enum
---@return string? error
function Loop:run(mode)
    return check(libuv.uv_run(self, mode or libuv.UV_RUN_DEFAULT))
end

ffi.cdef([[
    typedef void (*uv_timer_cb)(uv_timer_t* handle);

    int uv_timer_init(uv_loop_t* loop, uv_timer_t* handle);
    int uv_timer_start(uv_timer_t* handle, uv_timer_cb cb, uint64_t timeout, uint64_t repeat);
    int uv_timer_stop(uv_timer_t* handle);
]])

---@class Timer: Handle
local Timer = setmetatable({}, Handle)
ffi.metatype(ffi.typeof("uv_timer_t"), { __index = Timer, __tostring = Handle.__tostring, __gc = Handle.__gc })

---Creates a new timer.
---@return Timer?
---@return string? error
function Loop:timer()
    local timer = ffi.new("uv_timer_t") ---@cast timer Timer
    local err   = check(libuv.uv_timer_init(self, timer))
    return not err and timer or nil, err
end

---Starts a timer.
---@param timeout number
---@param callback fun()
---@return string? error
function Timer:start(timeout, callback)
    local cb = nil ---@type ffi.cb*
    cb = cast("uv_timer_cb", function(_)
        cb:free()
        return callback and callback()
    end)
    return check(libuv.uv_timer_start(self, cb, timeout, 0))
end

---Starts a recurring timer.
---@param interval number
---@param callback fun()
---@return string? error
function Timer:recurring(interval, callback)
    local function timer_cb(_) return callback and callback() end
    local cb = self:cache_callback("timer_cb", timer_cb)
    return check(libuv.uv_timer_start(self, cb, interval, interval))
end

---Stops a timer.
---@return string? error
function Timer:stop()
    self:cache_callback("timer_cb", nil)
    return check(libuv.uv_timer_stop(self))
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

---@class Poll: Handle
local Poll = setmetatable({}, Handle)
ffi.metatype(ffi.typeof("uv_poll_t"), { __index = Poll, __tostring = Handle.__tostring, __gc = Handle.__gc })

---Creates a new poll handle.
---@param fd number
---@return Poll?
---@return string? error
function Loop:poll(fd)
    local poll = ffi.new("uv_poll_t") ---@cast poll Poll
    local err = check(libuv.uv_poll_init(self, poll, fd))
    return not err and poll or nil, err
end

---Starts polling a file descriptor.
---@param events number a member of the uv_poll_event enum
---@param callback fun(events: number?, err: string?)
---@return string? error
function Poll:start(events, callback)
    local function poll_cb(_, status, events)
        local err = check(status)
        return callback and callback(not err and events or nil, err)
    end

    local cb = self:cache_callback("poll_cb", poll_cb)
    return check(libuv.uv_poll_start(self, events, cb))
end

---Stops polling a file descriptor.
---@return string? error
function Poll:stop()
    self:cache_callback("poll_cb", nil)
    return check(libuv.uv_poll_stop(self))
end

ffi.cdef([[
    typedef void (*uv_signal_cb)(uv_signal_t* handle, int signum);

    int uv_signal_init(uv_loop_t* loop, uv_signal_t* signal);
    int uv_signal_start_oneshot(uv_signal_t* signal, uv_signal_cb cb, int signum);
]])

---@class Signal: Handle
local Signal = setmetatable({}, Handle)
ffi.metatype(ffi.typeof("uv_signal_t"), { __index = Signal, __tostring = Handle.__tostring, __gc = Handle.__gc })

---Creates a new signal.
---@return Signal?
---@return string? error
function Loop:signal()
    local signal = ffi.new("uv_signal_t") ---@cast signal Signal
    local err = check(libuv.uv_signal_init(self, signal))
    return not err and signal or nil, err
end

---Starts a signal.
---@param signum number
---@param callback fun(signum: number)
---@return string? error
function Signal:start(signum, callback)
    local cb = nil ---@type ffi.cb*
    cb = cast("uv_signal_cb", function(_, _)
        cb:free()
        return callback and callback(signum)
    end)
    return check(libuv.uv_signal_start_oneshot(self, cb, signum))
end

ffi.cdef([[
    int uv_cancel(uv_req_t *req);
    uv_req_type uv_req_get_type(const uv_req_t* req);
    const char* uv_req_type_name(uv_req_type type);
]])

---@class Request: ffi.cdata*
local Request = {}
Request.__index = Request
ffi.metatype(ffi.typeof("uv_connect_t"), Request)
ffi.metatype(ffi.typeof("uv_write_t"), Request)
ffi.metatype(ffi.typeof("uv_shutdown_t"), Request)
ffi.metatype(ffi.typeof("uv_getaddrinfo_t"), Request)
ffi.metatype(ffi.typeof("uv_fs_t"), Request)

---Cancel a request
---@return string? error
function Request:cancel()
    return check(libuv.uv_cancel(cast("uv_req_t*", self)))
end

---Return the request type as a string
---@return string
function Request.__tostring(self)
    local id = libuv.uv_req_get_type(cast("uv_req_t*", self))
    return ffi.string(libuv.uv_req_type_name(id))
end

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

---@class Buffer: ffi.cdata*
---@field base ffi.cdata*
---@field len number

---@class Stream: Handle
local Stream = setmetatable({
    ---@type ffi.cb*
    alloc_cb = cast("uv_alloc_cb",
        ---Allocate a receive buffer based on suggested size
        ---@param handle Handle
        ---@param suggested_size number
        ---@param buf Buffer
        function(handle, suggested_size, buf)
            local cache = handle:get_cache()
            if not cache then cache = handle:make_cache() end
            if cache.read_buf.base == nil then
                cache.read_buf.base = assert(pointer(cast("char*", ffi.C.malloc(suggested_size))))
                cache.read_buf.len = suggested_size
            end
            buf.base = cache.read_buf.base
            buf.len = cache.read_buf.len
        end)
}, Handle)
Stream.__index = Stream
ffi.metatype(ffi.typeof("uv_stream_t"), { __index = Stream, __tostring = Handle.__tostring, __gc = Handle.__gc })

---Shutdown and close a stream
---@param callback fun(err: string?)?
---@return string? error
function Stream:shutdown(callback)
    local handle = cast("uv_stream_t*", self)
    local req, cb = ffi.new("uv_shutdown_t"), nil ---@cast cb ffi.cb*
    cb = cast("uv_shutdown_cb", function(_, status)
        cb:free()
        return callback and callback(check(status))
    end)
    return check(libuv.uv_shutdown(req, handle, cb))
end

---Listen for a client to connect to a stream
---@param backlog number
---@param callback fun(err: string?)
---@return string? error
function Stream:listen(backlog, callback)
    local function connection_cb(_, status)
        return callback and callback(check(status))
    end
    local stream = cast("uv_stream_t*", self)
    local cb = self:cache_callback("connection_cb", connection_cb)
    return check(libuv.uv_listen(stream, backlog, cb))
end

---Accept a connecting client
---@param client Stream
---@return string? error
function Stream:accept(client)
    local server = cast("uv_stream_t*", self)
    local client = cast("uv_stream_t*", client) ---@diagnostic disable-line:redefined-local
    return check(libuv.uv_accept(server, client))
end

---Start reading from a stream
---@param callback fun(data: string?, err: string?)
---@return string? error
function Stream:read_start(callback)
    local stream = cast("uv_stream_t*", self)

    ---Process internal read callback
    ---@param nread number
    ---@param buf Buffer
    local function read_cb(_, nread, buf)
        if nread == 0 then
            return
        elseif nread == libuv.UV_EOF then
            return callback and callback(nil, nil)
        elseif nread < 0 then
            return callback and callback(nil, get_error(nread))
        else
            return callback and callback(ffi.string(buf.base, nread), nil)
        end
    end

    local cb = self:cache_callback("read_cb", read_cb)
    return check(libuv.uv_read_start(stream, Stream.alloc_cb, cb))
end

---Stop reading from a stream
---@return string? error
function Stream:read_stop()
    self:cache_callback("read_cb", nil)
    return check(libuv.uv_read_stop(cast("uv_stream_t*", self)))
end

---Write data to a stream
---@param data string
---@param callback fun(err: string?)?
---@return string? error
function Stream:write(data, callback)
    local handle = cast("uv_stream_t*", self)
    local buf = ffi.new("uv_buf_t") ---@cast buf Buffer
    buf.base = cast("char*", data)
    buf.len = #data
    local req, cb = ffi.new("uv_write_t"), nil ---@cast cb ffi.cb*
    cb = cast("uv_write_cb", function(_, status)
        cb:free()
        return callback and callback(check(status))
    end)
    return check(libuv.uv_write(req, handle, buf, 1, cb))
end

ffi.cdef([[
    int uv_ip4_addr(const char *ip, int port, struct sockaddr_in *addr);

    int uv_tcp_init(uv_loop_t* loop, uv_tcp_t* handle);
    int uv_tcp_bind(uv_tcp_t* handle, const struct sockaddr* addr, unsigned int flags);
    int uv_tcp_connect(uv_connect_t* req, uv_tcp_t* handle, const struct sockaddr_in* addr, uv_connect_cb cb);
]])

---@class Tcp: Stream
local Tcp = setmetatable({}, Stream)
ffi.metatype(ffi.typeof("uv_tcp_t"), { __index = Tcp, __tostring = Handle.__tostring, __gc = Handle.__gc })

---Creates a new Tcp socket
---@return Tcp?
---@return string? error
function Loop:tcp()
    local tcp = ffi.new("uv_tcp_t") ---@cast tcp Tcp
    local err = check(libuv.uv_tcp_init(self, tcp))
    return not err and tcp or nil, err
end

---Bind socket to an IP address and port
---@param host string
---@param port number
---@return string? error
function Tcp:bind(host, port)
    local addr = ffi.new("struct sockaddr_in")
    local err = check(libuv.uv_ip4_addr(host, port, addr))
    if err then return err end
    return check(libuv.uv_tcp_bind(self, cast("const struct sockaddr*", addr), 0))
end

---Connect to an IP address and port
---@param host string
---@param port number
---@param callback fun(err: string?)
---@return string? error
function Tcp:connect(host, port, callback)
    local addr = ffi.new("struct sockaddr_in")
    check(libuv.uv_ip4_addr(host, port, addr))
    local req, cb = ffi.new("uv_connect_t"), nil ---@cast cb ffi.cb*
    cb = cast("uv_connect_cb", function(_, status)
        cb:free()
        return callback and callback(check(status))
    end)
    return check(libuv.uv_tcp_connect(req, self, addr, cb))
end

ffi.cdef([[
    int uv_pipe_init(uv_loop_t *loop, uv_pipe_t *handle, int ipc);
    int uv_pipe_bind(uv_pipe_t *handle, const char *name);
    void uv_pipe_connect(uv_connect_t *req, uv_pipe_t *handle, const char *name, uv_connect_cb cb);
]])

---@class Pipe: Stream
local Pipe = setmetatable({}, Stream)
ffi.metatype(ffi.typeof("uv_pipe_t"), { __index = Pipe, __tostring = Handle.__tostring, __gc = Handle.__gc })

---Creates a new Pipe
---@param ipc boolean?
---@return Pipe?
---@return string? error
function Loop:pipe(ipc)
    local pipe = ffi.new("uv_pipe_t") ---@cast pipe Pipe
    local err = check(libuv.uv_pipe_init(self, pipe, ipc and 1 or 0))
    return not err and pipe or nil, err
end

---Bind pipe to a local path
---@param name string
---@return string? error
function Pipe:bind(name)
    return check(libuv.uv_pipe_bind(self, name))
end

---Connect pipe to a local path
---@param name string
---@param callback fun(err: string?)
function Pipe:connect(name, callback)
    local req, cb = ffi.new("uv_connect_t"), nil ---@cast cb ffi.cb*
    cb = cast("uv_connect_cb", function(_, status)
        cb:free()
        return callback and callback(check(status))
    end)
    libuv.uv_pipe_connect(req, self, name, cb)
end

ffi.cdef([[
    typedef enum {
        UV_DIRENT_UNKNOWN,
        UV_DIRENT_FILE,
        UV_DIRENT_DIR,
        UV_DIRENT_LINK,
        UV_DIRENT_FIFO,
        UV_DIRENT_SOCKET,
        UV_DIRENT_CHAR,
        UV_DIRENT_BLOCK
    } uv_dirent_type_t;

    typedef struct uv_dirent_s {
        const char* name;
        uv_dirent_type_t type;
    } uv_dirent_t;

    typedef struct {
        long tv_sec;
        long tv_nsec;
    } uv_timespec_t;

    typedef struct {
        uint64_t st_dev;
        uint64_t st_mode;
        uint64_t st_nlink;
        uint64_t st_uid;
        uint64_t st_gid;
        uint64_t st_rdev;
        uint64_t st_ino;
        uint64_t st_size;
        uint64_t st_blksize;
        uint64_t st_blocks;
        uint64_t st_flags;
        uint64_t st_gen;
        uv_timespec_t st_atim;
        uv_timespec_t st_mtim;
        uv_timespec_t st_ctim;
        uv_timespec_t st_birthtim;
    } uv_stat_t;

    enum {
        S_IFMT  = 0xF000,
        S_IFDIR = 0x4000,
        S_IFREG = 0x8000
    };

    enum {
        O_RDONLY = 0x0000,
        O_WRONLY = 0x0001,
        O_RDWR   = 0x0002
    };

    typedef int uv_file;

    typedef void (*uv_fs_cb)(uv_fs_t *req);

    int uv_fs_scandir(uv_loop_t *loop, uv_fs_t *req, const char *path, int flags, uv_fs_cb cb);
    int uv_fs_scandir_next(uv_fs_t *req, uv_dirent_t *ent);
    int uv_fs_stat(uv_loop_t *loop, uv_fs_t *req, const char *path, uv_fs_cb cb);
    int uv_fs_open(uv_loop_t *loop, uv_fs_t *req, const char *path, int flags, int mode, uv_fs_cb cb);
    int uv_fs_close(uv_loop_t *loop, uv_fs_t *req, uv_file file, uv_fs_cb cb);
    int uv_fs_read(uv_loop_t *loop, uv_fs_t *req, uv_file file, const uv_buf_t bufs[], unsigned int nbufs, int64_t offset, uv_fs_cb cb);
    int uv_fs_write(uv_loop_t *loop, uv_fs_t *req, uv_file file, const uv_buf_t bufs[], unsigned int nbufs, int64_t offset, uv_fs_cb cb);
    void uv_fs_req_cleanup(uv_fs_t *req);
    ssize_t uv_fs_get_result(const uv_fs_t *req);
    uv_stat_t *uv_fs_get_statbuf(uv_fs_t *req);
]])

---@class Dirent: ffi.cdata*
---@field type number|ffi.cdata*
---@field name string|ffi.cdata*

---Scan directory and collect list of contents
---@param path string path to directory
---@param callback fun(entries: { type: number, name: string }[]?, err: string?)
---@return string? error
function Loop:fs_scandir(path, callback)
    local req, cb = ffi.new("uv_fs_t"), nil ---@cast cb ffi.cb*
    cb = cast("uv_fs_cb", function(_)
        local entries = nil
        local err = check(libuv.uv_fs_get_result(req))
        if not err then
            local dirent = ffi.new("uv_dirent_t") ---@cast dirent Dirent
            entries = {}
            while libuv.uv_fs_scandir_next(req, dirent) ~= libuv.UV_EOF do
                table.insert(entries, {
                    type = tonumber(dirent.type),
                    name = dirent.name == nil and "" or ffi.string(dirent.name)
                })
            end
        end
        libuv.uv_fs_req_cleanup(req);
        cb:free()
        return callback and callback(entries, err)
    end)
    return check(libuv.uv_fs_scandir(self, req, path, 0, cb))
end

---Check if fs_stat st_mode is a directory
---@param mode number fs_stat st_mode
---@return boolean
function Loop.S_ISDIR(mode) ---@diagnostic disable-next-line:param-type-mismatch
    return bit.band(mode, libuv.S_IFMT) == libuv.S_IFDIR
end

---Check if fs_stat st_mode is a regular file
---@param mode number fs_stat st_mode
---@return boolean
function Loop.S_ISREG(mode) ---@diagnostic disable-next-line:param-type-mismatch
    return bit.band(mode, libuv.S_IFMT) == libuv.S_IFREG
end

---Query file system stats for path
---@param path string path to file or directory
---@param callback fun(mode: number?, err: string?)
---@return string? error
function Loop:fs_stat(path, callback)
    local req, cb = ffi.new("uv_fs_t"), nil ---@cast cb ffi.cb*
    cb = cast("uv_fs_cb", function(_)
        local mode = nil
        local err = check(libuv.uv_fs_get_result(req))
        if not err then
            local stat = libuv.uv_fs_get_statbuf(req);
            mode = tonumber(stat.st_mode)
        end
        libuv.uv_fs_req_cleanup(req);
        cb:free()
        return callback and callback(mode, err)
    end)
    return check(libuv.uv_fs_stat(self, req, path, cb))
end

---Open a file
---@param path string path to file
---@param callback fun(fd: number?, err: string?)
---@return string? error
function Loop:fs_open(path, callback)
    local req, cb = ffi.new("uv_fs_t"), nil ---@cast cb ffi.cb*
    cb = cast("uv_fs_cb", function(_)
        local result = libuv.uv_fs_get_result(req)
        local err = check(result)
        libuv.uv_fs_req_cleanup(req);
        cb:free()
        return callback and callback(not err and tonumber(result) or nil, err)
    end)
    return check(libuv.uv_fs_open(self, req, path, libuv.O_RDWR, 0, cb))
end

---Close a file
---@param fd number
---@param callback fun(err: string?)
---@return string? error
function Loop:fs_close(fd, callback)
    local req, cb = ffi.new("uv_fs_t"), nil ---@cast cb ffi.cb*
    cb = cast("uv_fs_cb", function(_)
        local err = check(libuv.uv_fs_get_result(req))
        libuv.uv_fs_req_cleanup(req);
        cb:free()
        return callback and callback(err)
    end)
    return check(libuv.uv_fs_close(self, req, fd, cb))
end

---Read the entire contents of a file
---@param fd number
---@param callback fun(contents: string?, err: string?)
---@return string? error
function Loop:fs_read(fd, callback)
    local offset, contents = 0, {}
    local buf = ffi.new("uv_buf_t") ---@cast buf Buffer
    buf.len = 1024
    buf.base = ffi.new("char[?]", buf.len)
    local req, cb = ffi.new("uv_fs_t"), nil ---@cast cb ffi.cb*
    cb = cast("uv_fs_cb", function(_)
        local result = libuv.uv_fs_get_result(req)
        libuv.uv_fs_req_cleanup(req);
        if result > 0 then
            table.insert(contents, ffi.string(buf.base, result))
            offset = offset + result
            libuv.uv_fs_read(self, req, fd, buf, 1, offset, cb)
            return -- keep reading
        end
        cb:free()
        local err = check(result)
        return callback and callback(not err and table.concat(contents) or nil, err)
    end)
    return check(libuv.uv_fs_read(self, req, fd, buf, 1, offset, cb))
end

ffi.cdef([[
    typedef struct cache_t {
        uv_buf_t read_buf;
        uv_connection_cb connection_cb;
        uv_poll_cb poll_cb;
        uv_read_cb read_cb;
        uv_timer_cb timer_cb;
    } cache_t;
]])

---@class Cache
---@field read_buf Buffer
---@field connection_cb ffi.cb*
---@field poll_cb ffi.cb*
---@field read_cb ffi.cb*
---@field timer_cb ffi.cb*

---Return cache for handle
---@return Cache?
function Handle:get_cache()
    return pointer(cast("cache_t*", libuv.uv_handle_get_data(cast("const uv_handle_t*", self))))
end

---Set cache for handle
---@param cache Cache?
function Handle:set_cache(cache)
    libuv.uv_handle_set_data(cast("uv_handle_t*", self), cache)
end

---Allocate a new cache for handle
---@return Cache
function Handle:make_cache()
    assert(self:get_cache() == nil)
    local cache = assert(pointer(cast("cache_t*", ffi.C.malloc(ffi.sizeof("cache_t")))))
    self:set_cache(cache)
    return cache
end

---Cache a function as a FFI callback
---@param name string cache_t struct member
---@param callback function? function to save or delete
---@return ffi.cb*?
function Handle:cache_callback(name, callback)
    local cache = self:get_cache()
    if callback then
        if not cache then cache = self:make_cache() end
        if cache[name] == nil then
            cache[name] = cast(("uv_%s"):format(name), callback)
        else
            cache[name]:set(callback)
        end
        return cache[name]
    elseif cache and cache[name] then
        cache[name]:free()
        cache[name] = nil
    end
end

---Free the cache for a handle
function Handle:free_cache()
    local cache = self:get_cache()
    if not cache then return end
    if cache.read_buf.base ~= nil then ffi.C.free(cache.read_buf.base) end
    if cache.connection_cb ~= nil then cache.connection_cb:free() end
    if cache.poll_cb ~= nil then cache.poll_cb:free() end
    if cache.read_cb ~= nil then cache.read_cb:free() end
    if cache.timer_cb ~= nil then cache.timer_cb:free() end
    ffi.C.free(cache)
    self:set_cache(nil)
end

local loop = libuv.uv_default_loop() ---@type Loop
return loop
