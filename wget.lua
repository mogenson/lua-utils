local loop = require("libuv")
local multi = require("libcurl")


for i, url in ipairs(arg) do
    local name = i .. ".download"
    print(string.format("Downloading %s as %s", url, name))
    local file = assert(io.open(i .. ".download", "w"))
    multi:add(url,
        function(data)
            file:write(data)
        end,
        function(result)
            print(string.format("%s finished with status: %d", name, result))
            file:close()
        end
    )
end

loop:run()
