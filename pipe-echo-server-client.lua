local loop = require("libuv")

local name = "/tmp/mike-pipe"
os.execute("rm -f " .. name)

-- server
local server = loop:pipe()
server:bind(name)
print("server listening")
server:listen(16, function()
    print("new client connected")
    local client = loop:pipe()
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
local client = loop:pipe()
client:connect(name, function()
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
