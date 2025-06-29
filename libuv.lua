local ffi = require("ffi")
local bit = require("bit")

local libuv = ffi.load("libuv")

ffi.cdef([[
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

local function uv_assert(status)
    if status < 0 then
        local name = ffi.string(libuv.uv_err_name(status))
        local err = ffi.string(libuv.uv_strerror(status))
        error(string.format("%: %", name, err))
    end
    return status
end

ffi.cdef([[
    typedef void (*uv_close_cb)(uv_handle_t *handle);

    uv_handle_type uv_handle_get_type(const uv_handle_t *handle);
    const char *uv_handle_type_name(uv_handle_type type);
    void uv_close(uv_handle_t *handle, uv_close_cb close_cb);
]])

local Handle = {}
Handle.__index = Handle

function Handle.__tostring(self)
    local id = libuv.uv_handle_get_type(ffi.cast("uv_handle_t*", self))
    return ffi.string(libuv.uv_handle_type_name(id))
end

function Handle.__gc(self)
    print(string.format("handle %s closing in __gc", tostring(self)));
    libuv.uv_close(ffi.cast("uv_handle_t*", self), nil)
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

local Loop = setmetatable({}, { __index = libuv })
Loop.__index = Loop
ffi.metatype(ffi.typeof("uv_loop_t"), Loop)

function Loop:now()
    return tonumber(libuv.uv_loop_now(self))
end

function Loop:update_time()
    libuv.uv_update_time(self)
end

function Loop:stop()
    libuv.uv_stop(self)
end

function Loop:run(mode)
    return tonumber(uv_assert(libuv.uv_run(self, mode or libuv.UV_RUN_DEFAULT)))
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

function Loop:new_timer()
    local timer = ffi.new("uv_timer_t")
    uv_assert(libuv.uv_timer_init(self, timer))
    return timer
end

function Timer:start(timeout, callback)
    uv_assert(libuv.uv_timer_start(self, ffi.cast("uv_timer_cb", callback), timeout, 0))
end

function Timer:recurring(interval, callback)
    uv_assert(libuv.uv_timer_start(self, ffi.cast("uv_timer_cb", callback), interval, interval))
end

function Timer:stop()
    uv_assert(libuv.uv_timer_stop(self))
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

function Loop:new_poll(fd)
    local poll = ffi.new("uv_poll_t")
    uv_assert(libuv.uv_poll_init(self, poll, fd))
    return poll
end

function Poll:start(events, callback)
    uv_assert(libuv.uv_poll_start(self, events, ffi.cast("uv_poll_cb", callback)))
end

function Poll:stop()
    uv_assert(libuv.uv_poll_stop(self))
end

return libuv.uv_default_loop()
