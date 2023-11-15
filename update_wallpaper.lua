#!/usr/bin/env luajit
package.path = package.path .. ";" .. os.getenv("HOME") .. "/?.lua"
local curl = require("curl")

local json, ret = curl.http_get("http://bing.com/HPImageArchive.aspx?format=js&idx=0&n=1")
if (ret ~= 0) then
    error("http get failed")
    os.exit(ret)
end

local pattern = '"url":"(.+)_1920x1080.jpg&rf'
local start, finish, path = json:find(pattern)
local url = "https://bing.com" .. path .. "_UHD.jpg"
print("setting wallpaper to: " .. url)

os.execute("echo $(date) >> $HOME/wallpaper.log")
os.execute("echo " .. url .. " >> $HOME/wallpaper.log")
os.execute("termux-wallpaper -u " .. url .. " >> $HOME/wallpaper.log")
os.execute("termux-wallpaper -l -u " .. url .. " >> $HOME/wallpaper.log")
