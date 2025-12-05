local loop = require("libuv")
local curl = require("libcurl")

for i, url in ipairs(arg) do
    local name = i .. ".download"
    print(("Downloading %s as %s"):format(url, name))
    curl.GET(url,
        function(data, err)
            if data then
                assert(io.open(i .. ".download", "w")):write(data):close()
                print(("%s finished"):format(name))
            elseif err then
                print(("Error: %s"):format(err))
            end
        end
    )
end

loop:run()
