---@meta

-- The class name can be anything, but "json" is standard.
-- If you use multiple JSON libraries, consider renaming this to "rxi.json".
---@class json
---@field _version string The version of the module (e.g. "0.1.2")
local json = {}

---
--- Encodes a Lua value to a JSON string.
---
--- This function will throw an error if a table contains mixed key types
--- (e.g. numbers and strings) or if a sparse array is detected.
---
--- @param val any The value to encode.
--- @return string json_string The resulting JSON string.
function json.encode(val) end

---
--- Decodes a JSON string to a Lua value.
---
--- @param str string The JSON string to decode.
--- @return any result The decoded Lua table, string, number, or boolean.
function json.decode(str) end

return json
