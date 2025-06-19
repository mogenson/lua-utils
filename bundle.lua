#!/usr/bin/env lua

local package_preload = 'package.preload["%s"] = function()\n%s\nend\n'
local require_pattern = [[require%s*%(?%s*(['"])(.-)%1%s*%)?]]

if not arg[1] or arg[1]:match("^-+h") then
    print(string.format("Usage: %s main.lua", arg[0]))
    print("  Bundles all required Lua modules into one file")
    print("  Outputs 'bundled_main.lua'")
    print("  Does not support C modules")
    os.exit()
end

local main_file = arg[1]
local main_content = assert(io.open(main_file, "r")):read("*a")
local output_name = "bundled_" .. main_file
local output_file = assert(io.open(output_name, "w"))

local preload_modules = {}
local skipped_modules = {}

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
    output_file:write(package_preload:format(module_name, module_content))
end

output_file:write(main_content)

print("bundled into file: ", output_name)
