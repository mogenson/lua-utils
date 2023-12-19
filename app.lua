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

-- callbacks
local function applicationShouldTerminate(self, cmd, sender)
    print("terminating app")
    return 1
end

objc.loadFramework("AppKit")

local pool = objc.NSAutoreleasePool:alloc():init()

local NSApp = objc.NSApplication:sharedApplication()
assert(NSApp:setActivationPolicy(NSApplicationActivationPolicyRegular) == YES)

local AppDelegateClass = objc.newClass("AppDelegate")
objc.addMethod(AppDelegateClass, "applicationShouldTerminate:", "L@:@",
    function(self, cmd, sender)
        print("terminating app")
        return NSTerminateNow
    end)
local appDelegate = objc.AppDelegate:alloc():init()
appDelegate:autorelease()
NSApp:setDelegate(appDelegate)

local menubar = objc.NSMenu:alloc():init()
local appMenuItem = objc.NSMenuItem:alloc():init()
menubar:addItem(appMenuItem)
NSApp:setMainMenu(menubar)
local appMenu = objc.NSMenu:alloc():init()
local quitTitle = objc.NSString:stringWithUTF8String("Quit")
local quitMenuItemKey = objc.NSString:stringWithUTF8String("q")
local quitMenuItem = objc.NSMenuItem:alloc():initWithTitle_action_keyEquivalent(quitTitle, "terminate:",
    quitMenuItemKey)
quitMenuItem:autorelease()
appMenu:addItem(quitMenuItem)
appMenuItem:setSubmenu(appMenu)

local rect = ffi.new("CGRect", { origin = { x = 0, y = 0 }, size = { width = 200, height = 300 } })
local styleMask = bit.bor(NSWindowStyleMaskTitled, NSWindowStyleMaskClosable, NSWindowStyleMaskMiniaturizable,
    NSWindowStyleMaskResizable)
local window = objc.NSWindow:alloc():initWithContentRect_styleMask_backing_defer(rect, styleMask,
    NSBackingStoreBuffered, NO)

local WindowDelegateClass = objc.newClass("WindowDelegate")
objc.addMethod(WindowDelegateClass, "windowWillClose:", "v@:@",
    function(self, cmd, notification)
        print("window will close")
    end)
local windowDelegate = objc.WindowDelegate:alloc():init()
window:setDelegate(windowDelegate)

local windowTitle = objc.NSString:stringWithUTF8String("LuaREPL")
window:setTitle(windowTitle)
window:makeKeyAndOrderFront(window)

print("starting runloop")
NSApp:run()
print("gracefully terminated")
