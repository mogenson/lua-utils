-- FFI example for libcurl integration into the libuv event loop
local ffi = require('ffi')
local bit = require('bit')

-- CURL FFI ------------------------------------------------------------------
local libcurl = ffi.load('curl')
ffi.cdef([[
  enum CURLMSG {
    CURLMSG_NONE, /* first, not used */
    CURLMSG_DONE, /* This easy handle has completed. 'result' contains the CURLcode of the transfer */
    CURLMSG_LAST /* last, not used */
  };

  struct CURLMsg {
    enum CURLMSG msg;       /* what this message means */
    void *easy_handle; /* the handle it concerns */
    union {
      void *whatever;    /* message-specific data */
      int result;   /* return code for transfer */
    } data;
  };

  enum curl_global_option
  {
    CURL_GLOBAL_ALL = 2,
  };

  enum curl_multi_option
  {
    CURLMOPT_SOCKETFUNCTION = 20000 + 1,
    CURLMOPT_TIMERFUNCTION = 20000 + 4
  };

  enum curl_socket_option
  {
    CURL_SOCKET_TIMEOUT = -1
  };

  enum curl_poll_option
  {
    CURL_POLL_IN = 1,
    CURL_POLL_OUT = 2,
    CURL_POLL_REMOVE = 4
  };

  enum curl_option
  {
    CURLOPT_CAINFO    = 10065,
    CURLOPT_CONNECTTIMEOUT  = 78,
    CURLOPT_COOKIE    = 10022,
    CURLOPT_FOLLOWLOCATION  = 52,
    CURLOPT_HEADER    = 42,
    CURLOPT_HTTPHEADER  = 10023,
    CURLOPT_INTERFACE   = 10062,
    CURLOPT_POST    = 47,
    CURLOPT_POSTFIELDS  = 10015,
    CURLOPT_REFERER   = 10016,
    CURLOPT_SSL_VERIFYPEER  = 64,
    CURLOPT_URL   = 10002,
    CURLOPT_USERAGENT   = 10018,
    CURLOPT_WRITEFUNCTION = 20011
  };

  enum curl_cselect_option
  {
    CURL_CSELECT_IN = 0x01,
    CURL_CSELECT_OUT = 0x02
  };

  /*
  #define CURLOPTTYPE_LONG          0
  #define CURLOPTTYPE_OBJECTPOINT   10000
  #define CURLOPTTYPE_FUNCTIONPOINT 20000
  #define CURLOPTTYPE_OFF_T         30000
  */

  void *curl_easy_init();
  int   curl_easy_setopt(void *curl, enum curl_option option, ...);
  int   curl_easy_perform(void *curl);
  void  curl_easy_cleanup(void *curl);
  char *curl_easy_strerror(int code);

  int   curl_global_init(enum curl_global_option option);

  void *curl_multi_init();
  int   curl_multi_setopt(void *curlm, enum curl_multi_option option, ...);
  int   curl_multi_add_handle(void *curlm, void *curl_handle);
  int   curl_multi_socket_action(void *curlm, int s, int ev_bitmask, int *running_handles);
  int   curl_multi_assign(void *curlm, int sockfd, void *sockp);
  int   curl_multi_remove_handle(void *curlm, void *curl_handle);
  struct CURLMsg *curl_multi_info_read(void *culm, int *msgs_in_queue);

  typedef int (*curlm_socketfunction_ptr_t)(void *curlm, int sockfd, int ev_bitmask, int *running_handles);
  typedef int (*curlm_timeoutfunction_ptr_t)(void *curlm, long timeout_ms, int *userp);
  typedef size_t (*curl_datafunction_ptr_t)(char *ptr, size_t size, size_t nmemb, void *userdata);
]])

-- UV FFI --------------------------------------------------------------------
local libuv = ffi.load('libuv')
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

  typedef enum uv_run_mode_e {
    UV_RUN_DEFAULT = 0,
    UV_RUN_ONCE,
    UV_RUN_NOWAIT
  } uv_run_mode;

  const char* uv_err_name(int err);
  const char* uv_strerror(int err);
]])

ffi.cdef([[
  uv_loop_t* uv_default_loop();
  void uv_stop(uv_loop_t* loop);
  uint64_t uv_now(const uv_loop_t* loop);
  int uv_run(uv_loop_t* loop, uv_run_mode mode);
]])


ffi.cdef([[
  typedef void (*uv_timer_cb)(uv_timer_t* handle);

  int uv_timer_init(uv_loop_t* loop, uv_timer_t* handle);
  int uv_timer_start(uv_timer_t* handle, uv_timer_cb cb, uint64_t timeout, uint64_t repeat);
  int uv_timer_stop(uv_timer_t* handle);
  int uv_timer_again(uv_timer_t* handle);
  void uv_timer_set_repeat(uv_timer_t* handle, uint64_t repeat);
  uint64_t uv_timer_get_repeat(const uv_timer_t* handle);
]])

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

-- cURL Multi with uv --------------------------------------------------------
local Multi = {}

function Multi:new(...)
    libcurl.curl_global_init(libcurl.CURL_GLOBAL_ALL)
    return setmetatable({ ... }, { __index = self }):init()
end

function Multi:init()
    self.loop = libuv.uv_default_loop()
    self.polls = {}
    self.timer = ffi.new("uv_timer_t")
    self.multi = libcurl.curl_multi_init()
    self.socketWrapper = ffi.cast('curlm_socketfunction_ptr_t', function(...) return Multi._onSocket(self, ...) end)
    self.timerWrapper = ffi.cast('curlm_timeoutfunction_ptr_t', function(...) return Multi._onTimer(self, ...) end)
    libcurl.curl_multi_setopt(self.multi, libcurl.CURLMOPT_SOCKETFUNCTION, self.socketWrapper)
    libcurl.curl_multi_setopt(self.multi, libcurl.CURLMOPT_TIMERFUNCTION, self.timerWrapper)
    assert(libuv.uv_timer_init(self.loop, self.timer) >= 0)
    return self
end

function Multi:deinit()
    libuv.uv_loop_close(self.loop);
end

function Multi:add(url)
    print("add ", url)
    local handle = libcurl.curl_easy_init()
    local dataCallback = ffi.cast('curl_datafunction_ptr_t', function(...) return Multi._onData(self, ...) end)
    libcurl.curl_easy_setopt(handle,
        libcurl.CURLOPT_URL,
        url)
    libcurl.curl_easy_setopt(handle,
        libcurl.CURLOPT_WRITEFUNCTION,
        dataCallback)
    libcurl.curl_multi_add_handle(self.multi, handle);
end

function Multi:_onData(ptr, size, nmemb, userdata)
    print(ffi.string(ptr))
    return size
end

function Multi:_onSocket(handle, fd, action)
    print("on socket")
    assert(libuv.uv_timer_stop(self.timer) >= 0)

    local function perform(_handle, status, events)
        assert(status >= 0)

        local flags = bit.tobit(0)
        if events == libuv.UV_READABLE then
            flags = bit.bor(flags, libcurl.CURL_CSELECT_IN)
        elseif events == libuv.UV_WRITABLE then
            flags = bit.bor(flags, libcurl.CURL_CSELECT_OUT)
        end

        local running_handles = ffi.new('int[1]')
        libcurl.curl_multi_socket_action(self.multi, fd, flags, running_handles)

        local msg = nil
        local pending = ffi.new('int[1]')
        repeat
            msg = libcurl.curl_multi_info_read(self.multi, pending)
            if msg ~= nil and msg.msg == libcurl.CURLMSG_DONE then
                libcurl.curl_multi_remove_handle(self.multi, msg.easy_handle)
                libcurl.curl_easy_cleanup(handle)
            end
        until msg == nil
    end

    local poll = self.polls[fd]
    if not poll then
        poll = ffi.new("uv_poll_t")
        assert(libuv.uv_poll_init(self.loop, poll, fd) >= 0)
        self.polls[fd] = poll
    end

    local cb = ffi.cast("uv_poll_cb", perform)
    local events = bit.tobit(0)
    if action == libcurl.CURL_POLL_IN then
        events = bit.bor(events, libuv.UV_READABLE)
        assert(libuv.uv_poll_start(poll, events, cb) >= 0)
    elseif action == libcurl.CURL_POLL_OUT then
        events = bit.bor(events, libuv.UV_WRITABLE)
        assert(libuv.uv_poll_start(poll, events, cb) >= 0)
    elseif action == libcurl.CURL_POLL_REMOVE then
        assert(libuv.uv_poll_stop(poll) >= 0)
        -- libuv.uv_close(poll)
        self.polls[fd] = nil
    end

    return 0
end

function Multi:_onTimer(curlm, ms)
    print("on timer")
    ms = tonumber(ms)
    assert(libuv.uv_timer_stop(self.timer) >= 0)
    if ms < 0 then return 0 end
    local function action(_timer)
        local running_handles = ffi.new('int[1]')
        libcurl.curl_multi_socket_action(curlm, libcurl.CURL_SOCKET_TIMEOUT, 0, running_handles)
    end
    libuv.uv_timer_start(self.timer, ffi.cast("uv_timer_cb", action), ms, 0)
    return 0
end

function Multi:run()
    libuv.uv_run(self.loop, libuv.UV_RUN_DEFAULT)
end

local m = Multi:new()
for i = 1, 2 do
    m:add('http://httpbin.org/get')
end

print("uv run start")
m:run()
print("uv run stop")
