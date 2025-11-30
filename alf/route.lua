local stringx = require("pl.stringx")

-- Converter is not optional!
local PARAMETER_PATTERN = "{([a-zA-Z_][a-zA-Z0-9_]*)(:[a-zA-Z_][a-zA-Z0-9_]*)}"

local CONVERTER_PATTERNS = {
    -- string should include any character except a slash.
    string = "([^/]*)",
    int = "(%-?%d*)",
    number = "(%-?%d*%.?%d*)"
}
local CONVERTER_TRANSFORMS = {
    int = math.floor,
    number = tonumber,
}

---Make a pattern that matches the path template
---@param path string a path template
---@return string, string[] regex pattern for path matching, list of type conversions
local function make_path_matcher(path)
    assert(stringx.startswith(path, "/"), "A route path must start with a slash `/`.")

    -- Capture which converters are used. There will be one converter for each parameter.
    local converters = {}

    local pattern = "^"
    local index, path_length = 1, string.len(path)
    local parameter_start, parameter_end
    while index <= path_length do
        parameter_start, parameter_end = string.find(path, PARAMETER_PATTERN, index)
        if parameter_start then
            -- Include any literal characters before the parameter.
            pattern = pattern .. string.sub(path, index, parameter_start - 1)

            local _, converter = string.match(path, PARAMETER_PATTERN, parameter_start)
            local converter_type = string.sub(converter, 2) -- strip off the colon

            local converter_pattern = CONVERTER_PATTERNS[converter_type]
            if not converter_pattern then
                error("Unknown converter type: " .. converter_type)
            end

            pattern = pattern .. converter_pattern
            table.insert(converters, converter_type)
            index = parameter_end + 1
        else
            -- No parameters. Capture any remaining portion.
            pattern = pattern .. string.sub(path, index)
            break
        end
    end
    return pattern .. "$", converters
end

---@class Route
---@field path string An HTTP request path
---@field path_pattern string
---@field controller function
---@field methods string[] list of supported HTTP methods
---@field converters string[]
local Route = {}
Route.__index = Route

setmetatable(Route, {
    ---A route to an individual controller
    ---A route is used to connect an incoming request to the responsible controller.
    ---@param path string A path template
    ---@param controller function A controller function
    ---@param methods string[] A list of methods that the controller can handle (default: {"GET"})
    ---@return Route
    __call = function(_, path, controller, methods)
        local self = setmetatable({}, Route)

        self.path = path
        self.path_pattern, self.converters = make_path_matcher(path)
        self.controller = controller
        self.methods = methods or { "GET" }

        return self
    end
})

---Check if the route matches the method and path
---@param self Route
---@param method string An HTTP method, uppercased
---@param path string An HTTP request path
---@return boolean|nil true if path and method match, false if only path matches, nil for no match
function Route.matches(self, method, path)
    if not string.match(path, self.path_pattern) then return nil end -- no match

    for _, allowed_method in ipairs(self.methods) do
        if method == allowed_method then return true end -- good match
    end

    return false -- bad match
end

---Route a request to a controller.
---@param self Route
---@param request Request
---@return Response
function Route.run(self, request)
    local raw_parameters = table.pack(string.match(request.path, self.path_pattern))

    local transformer
    local parameters = {}
    for i, converter_type in ipairs(self.converters) do
        transformer = CONVERTER_TRANSFORMS[converter_type]
        if transformer then
            table.insert(parameters, transformer(raw_parameters[i]))
        else
            table.insert(parameters, raw_parameters[i])
        end
    end

    return self.controller(request, table.unpack(parameters))
end

return Route
