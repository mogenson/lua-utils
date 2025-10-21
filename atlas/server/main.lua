local utils = require("pl.utils")

local Server = require("atlas.server.server")

-- Load the app from the configuration.
local function load_app(config)
    local app_type = type(assert(config.app, "No app in config"))
    if app_type == "table" then
        return config.app
    elseif app_type == "string" then
        local app_module, app_name = utils.splitv(config.app, ":", false, 2)
        local module = require(app_module)

        local app = module[app_name]
        if not app then
            error(("No app named '%s' found in module '%s'"):format(app_name, app_module))
        end

        return app
    else
        error(("Invalid config.app type: %s"):format(app_type))
    end
end

-- Run the `serve` command.
local function run(config)
    local app = load_app(config)
    local server = Server(app)
    server:set_up(config)
    return server:run()
end

return { run = run }
