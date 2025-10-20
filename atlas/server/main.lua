local utils = require("pl.utils")

local Server = require("atlas.server.server")

-- Load the app from the configuration.
local function load_app(config)
    local app_module, app_name = utils.splitv(config.app, ":", false, 2)
    local module = require(app_module)

    local app = module[app_name]
    if not app then
        error(string.format("No app named '%s' found in module '%s'", app_name, app_module))
    end

    return app
end

-- Run the `serve` command.
--
-- server: A dependency injected server for testing modes
--    app: A dependency injected app for testing modes
local function run(config, server, app)
    if app == nil then app = load_app(config) end
    if server == nil then server = Server(app) end

    server:set_up(config)

    return server:run()
end

return { run = run }
