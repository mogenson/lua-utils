local class = require("pl.class")
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
    local converters = {} ---@type string[]

    local pattern = "^"
    local index, path_length = 1, path:len()
    while index <= path_length do
        local parameter_start, parameter_end = path:find(PARAMETER_PATTERN, index)
        if parameter_start then
            -- Include any literal characters before the parameter.
            pattern = pattern .. path:sub(index, parameter_start - 1)

            ---@type number?, string?
            local _, converter = path:match(PARAMETER_PATTERN, parameter_start)
            local converter_type = assert(converter):sub(2) -- strip off the colon

            local converter_pattern = CONVERTER_PATTERNS[converter_type]
            if not converter_pattern then
                error("Unknown converter type: " .. converter_type)
            end

            pattern = pattern .. converter_pattern ---@type string
            table.insert(converters, converter_type)
            index = parameter_end + 1
        else
            -- No parameters. Capture any remaining portion.
            pattern = pattern .. path:sub(index)
            break
        end
    end
    return pattern .. "$", converters
end

---@class Route: pl.Class
---@field path string An HTTP request path
---@field path_pattern string
---@field controller function
---@field methods string[] list of supported HTTP methods
---@field converters string[]
---@operator call(...): Route
local Route = class()

---A route to an individual controller
---A route is used to connect an incoming request to the responsible controller.
---@param path string A path template
---@param controller function A controller function
---@param methods string[] A list of methods that the controller can handle (default: {"GET"})
function Route:_init(path, controller, methods)
    self.path = path
    self.path_pattern, self.converters = make_path_matcher(path)
    self.controller = controller
    self.methods = methods or { "GET" }
end

---Check if the route matches the method and path
---@param method string An HTTP method, uppercased
---@param path string An HTTP request path
---@return boolean|nil true if path and method match, false if only path matches, nil for no match
function Route:matches(method, path)
    if not path:match(self.path_pattern) then return nil end -- no match

    for _, allowed_method in ipairs(self.methods) do
        if method == allowed_method then return true end -- good match
    end

    return false -- bad match
end

---Route a request to a controller.
---@param request Request
---@return Response
function Route:run(request)
    local raw_parameters = table.pack(string.match(request.path, self.path_pattern)) ---@type string[]

    local parameters = {} ---@type any[]
    for i, converter_type in ipairs(self.converters) do
        local transformer = CONVERTER_TRANSFORMS[converter_type] ---@type function?
        table.insert(parameters, transformer and transformer(raw_parameters[i]) or raw_parameters[i])
    end

    return self.controller(request, table.unpack(parameters))
end

return Route
