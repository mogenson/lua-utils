#!/usr/bin/env lua

local package_preload = 'package.preload["%s"] = function()\n%s\nend\n'
local require_pattern = [[require%s*%(?%s*(['"])(.-)%1%s*%)?]]
local loader_script = '#!/bin/sh\ntail -n +4 "$0" | %s - "$@"\nexit\n'

if not arg[1] or arg[1]:match("^-+h") then
    print(string.format("Usage: %s main.lua", arg[0]))
    print("  Bundles all Lua dependencies into one source by following required module paths.")
    print("  Bundled source is then compiled to bytecode using the same Lua interpreter running this script.")
    print("  A shell script loader and shebang are prepended to the bytecode so the file can be executed in place.")
    print("  Outputs 'main.luac' or 'main.jlbc' depending on if this script is run with Lua or LuaJIT.")
    print("  Supports Lua modules, no C modules, and Unix only.")
    os.exit()
end

local main_file = arg[1]
local main_content = assert(io.open(main_file, "r")):read("*a")
local output_name = main_file:gsub("%.[^.]*$", "") .. (jit and ".ljbc" or ".luac")
local output_file = assert(io.open(output_name, "w"))

local preload_modules = {}
local skipped_modules = {}
local bundled_sources = {}

local function process_modules(content)
    for _, module_name in content:gmatch(require_pattern) do
        local module_file = package.searchpath(module_name, package.path)
        if module_file then
            if not preload_modules[module_name] then
                print("preloading module: ", module_name)
                local module_content = assert(io.open(module_file, "r")):read("*a")
                preload_modules[module_name] = module_content
                process_modules(module_content)
            end
        else
            if not skipped_modules[module_name] then
                print("can't find module: ", module_name)
                skipped_modules[module_name] = true
            end
        end
    end
end

process_modules(main_content)

for module_name, module_content in pairs(preload_modules) do
    table.insert(bundled_sources, package_preload:format(module_name, module_content))
end
table.insert(bundled_sources, main_content)

output_file:write(loader_script:format(jit and "luajit" or "lua"))
output_file:write(string.dump(assert(load(table.concat(bundled_sources, "\n"))), true))
output_file:close()

os.execute("chmod +x " .. output_name)
print("bundled into file: ", output_name)
