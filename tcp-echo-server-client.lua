local loop = require("libuv")

local host = "127.0.0.1"
local port = 8000

-- server
local server = loop:tcp()
server:bind(host, port)
print("server listening")
server:listen(16, function()
    print("new client connected")
    local client = loop:tcp()
    server:accept(client)
    client:read_start(function(data)
        print("server received: ", data)
        if data then
            client:write(data)
        else
            client:close()
        end
    end)
end)

-- client
local client = loop:tcp()
client:connect(host, port, function()
    client:read_start(function(data)
        print("client received: ", data)
        if data then
            client:shutdown()
        else
            client:close()
            server:close()
        end
    end)
    print("writing from client")
    client:write("hello")
    client:write("world")
end)

loop:run()
