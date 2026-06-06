local ffi = require("ffi")
local old_load = ffi.load

---@type string[]
local search_paths = {}
local ld_path = os.getenv("LD_LIBRARY_PATH")
if ld_path then
    for path in ld_path:gmatch("[^:]+") do
        table.insert(search_paths, path)
    end
end

ffi.load = function(name, global)
    local ok, lib = pcall(old_load, name, global)
    if ok then return lib end

    if ffi.os == "OSX" then
        local names = { name }
        if not name:find("^lib") then table.insert(names, "lib" .. name) end
        
        for _, n in ipairs(names) do
            local filename = n
            if not n:find("%.dylib$") then filename = n .. ".dylib" end
            
            for _, path in ipairs(search_paths) do
                local full_path = path .. "/" .. filename
                local ok2, lib2 = pcall(old_load, full_path, global)
                if ok2 then return lib2 end
            end
        end
    end

    error(lib)
end
