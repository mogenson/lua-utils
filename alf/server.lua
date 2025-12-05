local a = require("async")
local loop = require("libuv")
local Parser = require("alf.parser")
local utils = require("pl.utils")

---Helper utility to load Lua module from path
---@param app string|Application path to require app or Application
---@return Application
local function load_app(app)
    local app_type = type(app)
    if app_type == "table" then
        return app
    elseif app_type == "string" then
        local app_module, app_name = utils.splitv(app, ":", false, 2)
        local module = require(app_module)
        app = module[app_name]
        if not app then
            error(("No app named '%s' found in module '%s'"):format(app_name, app_module))
        end
        return app
    else
        error(("Invalid app type: %s"):format(app_type))
    end
end

---@class Server
---@field app Application
---@field tcp Tcp
local Server = {}
Server.__index = Server

setmetatable(Server, {
    ---Create an HTTP web server
    ---@param app string|Application
    ---@return Server
    __call = function(_, app)
        return setmetatable({
            app = load_app(app),
            tcp = nil
        }, Server)
    end
})

local on_connection = a.sync(function(client, app)
    local q = a.queue()
    client:read_start(function(data) q:put(data) end)

    local send = a.wrap(function(data, cb) client:write(data, cb) end)
    local receive = a.sync(function() return a.wait(q:get()) end)

    local parser = Parser()
    local scope, err = a.wait(parser(receive))

    if err then
        if err == Parser.INVALID_REQUEST_LINE then
            a.wait(send("HTTP/1.1 400 Bad Request\r\n\r\n"))
        elseif err == Parser.METHOD_NOT_IMPLEMENTED then
            a.wait(send("HTTP/1.1 501 Not Implemented\r\n\r\n"))
        elseif err == Parser.VERSION_NOT_SUPPORTED then
            a.wait(send("HTTP/1.1 505 HTTP Version Not Supported\r\n\r\n"))
        end
    else
        a.wait(app(scope, receive, send))
    end

    client:close()
end)

---Start the server and run the libuv loop
---@param self Server
---@param host string
---@param port number
---@return boolean true if there are no active handles on stop
function Server.__call(self, host, port)
    self.tcp = loop:tcp()
    self.tcp:bind(host, port)

    self.tcp:listen(1, function()
        local client = loop:tcp()
        self.tcp:accept(client)
        a.run(on_connection(client, self.app))
    end)

    -- register SIGINT / Ctrl-C handler
    loop:signal():start(2, function(signum) ---@diagnostic disable-line:unused-local
        loop:shutdown()
    end)

    print(("Listening for requests on http://%s:%d"):format(host, port))

    return loop:run() == 0
end

return Server
