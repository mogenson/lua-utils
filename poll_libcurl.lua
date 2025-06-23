-- FFI example for libcurl integration into the libuv event loop
local ffi = require('ffi')
local bit = require('bit')
local uv = require('luv')

local libcurl = ffi.load('libcurl')
ffi.cdef [[
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
]]

local Multi = {}

function Multi:new(...)
    return setmetatable({ ... }, { __index = self }):init()
end

function Multi:init()
    self.polls = {}
    self.timer = uv.new_timer()
    self.multi = libcurl.curl_multi_init()
    self.socketWrapper = ffi.cast('curlm_socketfunction_ptr_t', function(...) return Multi._onSocket(self, ...) end)
    self.timerWrapper = ffi.cast('curlm_timeoutfunction_ptr_t', function(...) return Multi._onTimer(self, ...) end)
    libcurl.curl_multi_setopt(self.multi, ffi.C.CURLMOPT_SOCKETFUNCTION, self.socketWrapper)
    libcurl.curl_multi_setopt(self.multi, ffi.C.CURLMOPT_TIMERFUNCTION, self.timerWrapper)
    return self
end

function Multi:add(url)
    print("add ", url)
    local handle = libcurl.curl_easy_init()
    local dataCallback = ffi.cast('curl_datafunction_ptr_t', function(...) return Multi._onData(self, ...) end)
    libcurl.curl_easy_setopt(handle,
        ffi.C.CURLOPT_URL,
        url)
    libcurl.curl_easy_setopt(handle,
        ffi.C.CURLOPT_WRITEFUNCTION,
        dataCallback)
    libcurl.curl_multi_add_handle(self.multi, handle);
end

function Multi:_onData(ptr, size, nmemb, userdata)
    print(ffi.string(ptr))
    return size
end

function Multi:_onSocket(handle, fd, action)
    print("on socket")
    self.timer:stop()

    local function perform(err, events)
        assert(not err, err)

        local flags = bit.tobit(0)
        if events == 'r' then
            flags = bit.bor(flags, ffi.C.CURL_CSELECT_IN)
        elseif events == 'w' then
            flags = bit.bor(flags, ffi.C.CURL_CSELECT_OUT)
        end

        local running_handles = ffi.new('int[1]')
        libcurl.curl_multi_socket_action(self.multi, fd, flags, running_handles)

        local msg = nil
        local pending = ffi.new('int[1]')
        repeat
            msg = libcurl.curl_multi_info_read(self.multi, pending)
            if msg ~= nil and msg.msg == ffi.C.CURLMSG_DONE then
                libcurl.curl_multi_remove_handle(self.multi, msg.easy_handle)
                libcurl.curl_easy_cleanup(handle)
            end
        until msg == nil
    end

    local poll = self.polls[fd]
    if not poll then
        poll = uv.new_poll(fd)
        self.polls[fd] = poll
    end

    if action == ffi.C.CURL_POLL_IN then
        poll:start('r', perform)
    elseif action == ffi.C.CURL_POLL_OUT then
        poll:start('w', perform)
    elseif action == ffi.C.CURL_POLL_REMOVE then
        poll:stop()
        poll:close()
        self.polls[fd] = nil
    end

    return 0
end

function Multi:_onTimer(curlm, ms)
    print("on timer")
    ms = tonumber(ms)
    self.timer:stop()
    if ms < 0 then return 0 end
    local function action()
        local running_handles = ffi.new('int[1]')
        libcurl.curl_multi_socket_action(curlm, ffi.C.CURL_SOCKET_TIMEOUT, 0, running_handles)
    end
    self.timer:start(ms, 0, action)
    return 0
end

libcurl.curl_global_init(ffi.C.CURL_GLOBAL_ALL)
local m = Multi:new()
for i = 1, 2 do
    m:add('http://httpbin.org/get')
end

print("uv run start")
uv.run()
print("uv run stop")
