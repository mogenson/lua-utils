local objc = require("objc")
local ffi = require("ffi")
local bit = require("bit")

-- Foundation types
ffi.cdef([[
typedef struct NSEdgeInsets {
    CGFloat top;
    CGFloat left;
    CGFloat bottom;
    CGFloat right;
} NSEdgeInsets;
typedef struct NSRange {
    NSUInteger location;
    NSUInteger length;
} NSRange;
]])

-- AppKit constants
local NSApplicationActivationPolicyRegular = ffi.new("NSInteger", 0)
local NSBackingStoreBuffered = ffi.new("NSUInteger", 2)
local NSTerminateNow = ffi.new("NSInteger", 1)

local NSWindowStyleMaskTitled = ffi.new("NSUInteger", bit.lshift(1, 0))
local NSWindowStyleMaskClosable = ffi.new("NSUInteger", bit.lshift(1, 1))
local NSWindowStyleMaskMiniaturizable = ffi.new("NSUInteger", bit.lshift(1, 2))
local NSWindowStyleMaskResizable = ffi.new("NSUInteger", bit.lshift(1, 3))

local NSStackViewGravityTop = ffi.new("NSInteger", 1)
local NSStackViewGravityLeading = ffi.new("NSInteger", 1)
local NSStackViewGravityCenter = ffi.new("NSInteger", 2)
local NSStackViewGravityBottom = ffi.new("NSInteger", 3)
local NSStackViewGravityTrailing = ffi.new("NSInteger", 3)

local NSUserInterfaceLayoutOrientationHorizontal = ffi.new("NSInteger", 0)
local NSUserInterfaceLayoutOrientationVertical = ffi.new("NSInteger", 1)

local NO = ffi.new("BOOL", 0)
local YES = ffi.new("BOOL", 1)

local button_action_selector = "buttonClicked:"

local function NSStr(str)
    return objc.NSString:stringWithUTF8String(str)
end

local scrollView = nil -- forward declaration

local function appendString(str)
    local textView = scrollView.documentView
    local contents = textView.string
    textView.string = contents:stringByAppendingString(NSStr("\n" .. str))
    textView:scrollToEndOfDocument(textView)
end

objc.loadFramework("AppKit")

local pool = objc.NSAutoreleasePool:alloc():init()

local NSApp = objc.NSApplication:sharedApplication()
assert(NSApp:setActivationPolicy(NSApplicationActivationPolicyRegular) == YES)

local AppDelegateClass = objc.newClass("AppDelegate")
objc.addMethod(AppDelegateClass, "applicationShouldTerminateAfterLastWindowClosed:", "B@:",
    function(self, cmd)
        print("last window closed")
        return YES
    end)

local i = 1
objc.addMethod(AppDelegateClass, button_action_selector, "v@:@",
    function(self, cmd, sender)
        local title = ffi.string(sender.title:UTF8String())
        print(title .. " clicked")
        appendString("line " .. tostring(i))
        i = i + 1
    end)

local appDelegate = objc.AppDelegate:alloc():init()
appDelegate:autorelease()
NSApp:setDelegate(appDelegate)

local menubar = objc.NSMenu:alloc():init()
menubar:autorelease()
local appMenuItem = objc.NSMenuItem:alloc():init()
appMenuItem:autorelease()
menubar:addItem(appMenuItem)
NSApp:setMainMenu(menubar)
local appMenu = objc.NSMenu:alloc():init()
appMenu:autorelease()

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
window:autorelease()

local textField = objc.NSTextField:alloc():init()
textField.placeholderString = NSStr("Enter Lua Code...")
local button = objc.NSButton:buttonWithTitle_target_action(NSStr("Eval"), appDelegate, button_action_selector)

local hStack = objc.NSStackView:alloc():init()
hStack:autorelease()
hStack:addView_inGravity(textField, NSStackViewGravityLeading)
hStack:addView_inGravity(button, NSStackViewGravityTrailing)

scrollView = objc.NSTextView:scrollableTextView()
scrollView.documentView.editable = NO
scrollView:autorelease()

local vStack = objc.NSStackView:alloc():init()
vStack:autorelease()
vStack.orientation = NSUserInterfaceLayoutOrientationVertical
vStack.edgeInsets = ffi.new("NSEdgeInsets", { top = 10, left = 10, bottom = 10, right = 10 })
vStack:addView_inGravity(scrollView, NSStackViewGravityTop)
vStack:addView_inGravity(hStack, NSStackViewGravityBottom)

window.contentView = vStack

window:setTitle(NSStr("LuaREPL"))
window:makeKeyAndOrderFront(window)

print("starting runloop")
NSApp:run()
print("gracefully terminated")
