local objc = require("objc")
local ffi = require("ffi")
local bit = require("bit")

-- AppKit constants
local NSApplicationActivationPolicyRegular = ffi.new("NSInteger", 0)
local NSBackingStoreBuffered = ffi.new("NSUInteger", 2)
local NSTerminateNow = ffi.new("NSInteger", 1)

local NSWindowStyleMaskTitled = ffi.new("NSUInteger", bit.lshift(1, 0))
local NSWindowStyleMaskClosable = ffi.new("NSUInteger", bit.lshift(1, 1))
local NSWindowStyleMaskMiniaturizable = ffi.new("NSUInteger", bit.lshift(1, 2))
local NSWindowStyleMaskResizable = ffi.new("NSUInteger", bit.lshift(1, 3))

local NO = ffi.new("BOOL", 0)
local YES = ffi.new("BOOL", 1)

local function NSStr(str)
    return objc.NSString:stringWithUTF8String(str)
end

objc.loadFramework("AppKit")

local pool = objc.NSAutoreleasePool:alloc():init()

local NSApp = objc.NSApplication:sharedApplication()
assert(NSApp:setActivationPolicy(NSApplicationActivationPolicyRegular) == YES)

local AppDelegateClass = objc.newClass("AppDelegate")
objc.addMethod(AppDelegateClass, "applicationShouldTerminateAfterLastWindowClosed:", "B@:",
    function(self, cmd)
        print("last window closed")
        return ffi.new("BOOL", 1)
    end)

objc.addMethod(AppDelegateClass, "myClicked:", "v@:@",
    function(self, cmd, sender)
        print("button clicked")
    end)

local appDelegate = objc.AppDelegate:alloc():init()
appDelegate:autorelease()
NSApp:setDelegate(appDelegate)

local menubar = objc.NSMenu:alloc():init()
local appMenuItem = objc.NSMenuItem:alloc():init()
menubar:addItem(appMenuItem)
NSApp:setMainMenu(menubar)
local appMenu = objc.NSMenu:alloc():init()

local quitMenuItem = objc.NSMenuItem:alloc():initWithTitle_action_keyEquivalent(NSStr("Quit"), "terminate:",
    NSStr("q"))
quitMenuItem:autorelease()
appMenu:addItem(quitMenuItem)

local closeMenuItem = objc.NSMenuItem:alloc():initWithTitle_action_keyEquivalent(NSStr("Close"), "performClose:",
    NSStr("w"))
closeMenuItem:autorelease()
appMenu:addItem(closeMenuItem)

appMenuItem:setSubmenu(appMenu)

local rect = ffi.new("CGRect", { origin = { x = 0, y = 0 }, size = { width = 200, height = 300 } })
local styleMask = bit.bor(NSWindowStyleMaskTitled, NSWindowStyleMaskClosable, NSWindowStyleMaskMiniaturizable,
    NSWindowStyleMaskResizable)
local window = objc.NSWindow:alloc():initWithContentRect_styleMask_backing_defer(rect, styleMask,
    NSBackingStoreBuffered, NO)

local button = objc.NSButton:alloc():initWithFrame(rect)
button:setTitle(NSStr("Hello World"))


button.target = appDelegate
button.action = "myClicked:"
window.contentView = button

window:setTitle(NSStr("LuaREPL"))
window:makeKeyAndOrderFront(window)

print("starting runloop")
NSApp:run()
print("gracefully terminated")
