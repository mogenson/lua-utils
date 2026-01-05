local a = require("async")
local loop = require("libuv")

local Application = require("alf.application")
local Response = require("alf.response")
local Route = require("alf.route")
local Server = require("alf.server")

local A = require("alf.elements.a")
local Body = require("alf.elements.body")
local H1 = require("alf.elements.h1")
local Head = require("alf.elements.head")
local Header = require("alf.elements.header")
local Html = require("alf.elements.html")
local Li = require("alf.elements.li")
local Link = require("alf.elements.link")
local Main = require("alf.elements.main")
local Meta = require("alf.elements.meta")
local Title = require("alf.elements.title")
local Ul = require("alf.elements.ul")

local stat = a.wrap(function(path, cb) return loop:fs_stat(path, cb) end)
local scandir = a.wrap(function(path, cb) return loop:fs_scandir(path, cb) end)
local open = a.wrap(function(path, cb) return loop:fs_open(path, cb) end)
local close = a.wrap(function(fd, cb) return loop:fs_close(fd, cb) end)
local read = a.wrap(function(fd, cb) return loop:fs_read(fd, cb) end)

local function list_dir(local_path, request_path)
    local entries, err = a.wait(scandir(local_path))
    if not entries and err then
        return Response(err, "text/plain", 500)
    end

    local items = {}
    if request_path ~= "/" then
        local parent_path = request_path:match("(.*)/[^/]+/?$")
        if parent_path == "" then parent_path = "/" end
        table.insert(items, Li(nil, { A({ href = parent_path }, "..") }))
    end

    for _, entry in ipairs(entries) do
        local link_path = request_path .. (request_path:sub(-1) == "/" and "" or "/") .. entry.name
        local link_name = entry.name .. (entry.type == loop.UV_DIRENT_DIR and "/" or "")
        table.insert(items, Li(nil, { A({ href = link_path }, link_name) }))
    end

    local title = "Index of " .. request_path

    local html = Html(nil, {
        Head(nil, {
            Title(nil, title),
            Meta({
                name = "viewport",
                content = "width=device-width, initial-scale=1"
            }),
            Link({
                rel = "stylesheet",
                href = "https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.fluid.classless.min.css",
            }),
        }),
        Body(nil, {
            Header(nil, H1(nil, title)),
            Main(nil,
                Ul(nil, items)
            )
        })
    })

    return Response(html)
end

local function read_file(local_path, request_path)
    local fd, err = a.wait(open(local_path))
    if not fd and err then
        return Response(err, "text/plain", 500)
    end

    local contents, err = a.wait(read(fd))
    if not contents and err then
        return Response(err, "text/plain", 500)
    end

    err = a.wait(close(fd))
    if err then
        return Response(err, "text/plain", 500)
    end

    return Response(contents, "text/plain")
end

local function browser(request)
    local request_path = request.path
    local local_path = "." .. request_path
    local mode, err = a.wait(stat(local_path))
    if not mode and err then
        return Response(err, "text/plain", 500)
    end

    if loop.S_ISDIR(mode) then
        return list_dir(local_path, request_path)
    elseif loop.S_ISREG(mode) then
        return read_file(local_path, request_path)
    else
        return Response("Unknown file type", "text/plain", 500)
    end
end

local routes = {
    Route("/(.*)", browser)
}

local app = Application(routes)
local server = Server(app)
local host = "127.0.0.1"
local port = 8080

os.exit(server:serve(host, port) and 0 or 1)
