local a    = require("async")
local loop = require("libuv")

describe("timer", function()
    it("sleep", function()
        local sleep = a.wrap(function(ms, cb)
            loop:new_timer():start(ms, function() cb(ms) end)
        end)

        local result = nil
        sleep(123)(function(val) result = val end)
        loop:run()
        assert.are.equal(result, 123)

        local main = a.sync(function()
            local start = loop:now()
            a.wait(sleep(1000))
            return loop:now() - start
        end)

        result = nil
        main()(function(val) result = val end)
        loop:run()
        assert(result >= 1000)
    end)
end)

describe("pipe", function()
    it("echo", function()
        local name = "/tmp/test.sock"
        local count = 100

        local listen = a.wrap(function(pipe, backlog, cb)
            pipe:listen(backlog, cb)
        end)
        local connect = a.wrap(function(pipe, host, port, cb)
            pipe:connect(host, port, cb)
        end)
        local write = a.wrap(function(pipe, data, cb)
            pipe:write(data, cb)
        end)
        local read = a.wrap(function(pipe, cb)
            pipe:read_start(function(data)
                pipe:read_stop()
                return cb(data)
            end)
        end)

        local server = a.sync(function()
            local server_pipe = loop:new_pipe()
            server_pipe:bind(name)
            a.wait(listen(server_pipe, 1))
            local echo_pipe = loop:new_pipe()
            server_pipe:accept(echo_pipe)

            while true do
                local data = a.wait(read(echo_pipe))
                if data then
                    a.wait(write(echo_pipe, data))
                else
                    echo_pipe:close()
                    break
                end
            end
            server_pipe:close()
        end)

        local client = a.sync(function()
            local client_pipe = loop:new_pipe()
            a.wait(connect(client_pipe, name))

            local number = 1
            a.wait(write(client_pipe, string.char(number)))

            while true do
                number = assert(string.byte(a.wait(read(client_pipe))))
                if number == count then
                    break
                else
                    number = number + 1
                end
                a.wait(write(client_pipe, string.char(number)))
            end

            client_pipe:close()
            return number
        end)

        os.execute(string.format("rm -f %s", name))

        local main = a.sync(function()
            return a.wait_race(server(), client())
        end)

        local result = nil
        main()(function(...) result = ... end)
        loop:run()

        assert.are.equal(count, result[2])
    end)
end)

describe("socket", function()
    it("echo", function()
        local host = "127.0.0.1"
        local port = 8080
        local count = 100

        local listen = a.wrap(function(socket, backlog, cb)
            socket:listen(backlog, cb)
        end)
        local connect = a.wrap(function(socket, host, port, cb)
            socket:connect(host, port, cb)
        end)
        local write = a.wrap(function(socket, data, cb)
            socket:write(data, cb)
        end)
        local read = a.wrap(function(socket, cb)
            socket:read_start(function(data)
                socket:read_stop()
                return cb(data or false)
            end)
        end)

        local server = a.sync(function()
            local server_socket = loop:new_tcp()
            server_socket:bind(host, port)
            a.wait(listen(server_socket, 1))
            local echo_socket = loop:new_tcp()
            server_socket:accept(echo_socket)

            while true do
                local data = a.wait(read(echo_socket))
                if data then
                    a.wait(write(echo_socket, data))
                else
                    echo_socket:close()
                    break
                end
            end
            server_socket:close()
        end)

        local client = a.sync(function()
            local client_socket = loop:new_tcp()
            a.wait(connect(client_socket, host, port))

            local number = 1
            a.wait(write(client_socket, string.char(number)))

            while true do
                number = assert(string.byte(a.wait(read(client_socket))))
                if number == count then
                    break
                else
                    number = number + 1
                end
                a.wait(write(client_socket, string.char(number)))
            end

            client_socket:close()
            return number
        end)

        local main = a.sync(function()
            return a.wait_race(server(), client())
        end)

        local result = nil
        main()(function(...) result = ... end)
        loop:run()

        assert.are.equal(count, result[2])
    end)
end)
