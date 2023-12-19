#!/usr/bin/env luajit

local ffi = require("ffi")
local bit = require("bit")

ffi.cdef([[
typedef signed char   BOOL;
typedef double        CGFloat;
typedef long          NSInteger;
typedef unsigned long NSUInteger;

typedef struct objc_class    *Class;
typedef struct objc_object   *id;
typedef struct objc_selector *SEL;
typedef struct objc_method   *Method;
typedef id                   (*IMP) (id, SEL, ...);
typedef struct Protocol      Protocol;

// runtime API
void objc_msgSend(void);

// classes
Class objc_getClass(const char*);
Class objc_allocateClassPair(Class, const char*, size_t);
void objc_registerClassPair(Class);

// selectors
SEL sel_registerName(const char*);

// methods
BOOL class_addMethod(Class, SEL, IMP, const char*);
Method class_getInstanceMethod(Class, SEL);

// protocols
Protocol* objc_getProtocol(const char*);
BOOL class_addProtocol(Class, Protocol*);

// core graphics
typedef struct CGPoint { CGFloat x; CGFloat y; } CGPoint;
typedef struct CGSize { CGFloat width; CGFloat height; } CGSize;
typedef struct CGRect { CGPoint origin; CGSize size; } CGRect;
]])

ffi.load("/System/Library/Frameworks/AppKit.framework/AppKit", true)

local cast = ffi.cast
local class_addMethod = ffi.C.class_addMethod
local class_addProtocol = ffi.C.class_addProtocol
local class_getInstanceMethod = ffi.C.class_getInstanceMethod
local objc_allocateClassPair = ffi.C.objc_allocateClassPair
local objc_getClass = ffi.C.objc_getClass
local objc_getProtocol = ffi.C.objc_getProtocol
local objc_msgSend = ffi.C.objc_msgSend
local sel_registerName = ffi.C.sel_registerName

-- constants
local NSBackingStoreBuffered = ffi.new("NSUInteger", 2)
local NSWindowStyleMaskTitled = ffi.new("NSUInteger", bit.lshift(1, 0))
local NSWindowStyleMaskClosable = ffi.new("NSUInteger", bit.lshift(1, 1))
local NSWindowStyleMaskMiniaturizable = ffi.new("NSUInteger", bit.lshift(1, 2))
local NSWindowStyleMaskResizable = ffi.new("NSUInteger", bit.lshift(1, 3))

-- callbacks
local function applicationShouldTerminate(self, cmd, sender)
    print("terminating app")
    return 1
end

local function windowWillClose(self, cmd, notification)
    print("window will close")
end

local allocSel = sel_registerName("alloc")
local initSel = sel_registerName("init")
local autoreleaseSel = sel_registerName("autorelease")

local NSAutoreleasePoolClass = objc_getClass("NSAutoreleasePool")
local poolAlloc = cast("id(*)(Class, SEL)", objc_msgSend)(NSAutoreleasePoolClass, allocSel)
local pool = cast("id(*)(id, SEL)", objc_msgSend)(poolAlloc, initSel)

local NSApplicationClass = objc_getClass("NSApplication")
local sharedApplicationSel = sel_registerName("sharedApplication")
local NSApp = cast("id(*)(Class, SEL)", objc_msgSend)(NSApplicationClass, sharedApplicationSel)

local setActivationPolicySel = sel_registerName("setActivationPolicy:")
cast("void(*)(id, SEL, NSInteger)", objc_msgSend)(NSApp, setActivationPolicySel, 0)

local NSObjectClass = objc_getClass("NSObject")
local AppDelegateClass = objc_allocateClassPair(NSObjectClass, "AppDelegate", 0)
--local NSApplicationDelegateProtocol = objc_getProtocol("NSApplicationDelegate")
--assert(class_addProtocol(AppDelegateClass, NSApplicationDelegateProtocol) == 1)
local applicationShouldTerminateSel = sel_registerName("applicationShouldTerminate:")

local imp = cast("IMP", cast("unsigned long (*)()", applicationShouldTerminate))
assert(class_addMethod(AppDelegateClass, applicationShouldTerminateSel, imp, "L@:@"))
local dgAlloc = cast("id(*)(Class, SEL)", objc_msgSend)(AppDelegateClass, allocSel)
local dg = cast("id(*)(id, SEL)", objc_msgSend)(dgAlloc, initSel)
cast("id(*)(id, SEL)", objc_msgSend)(dg, autoreleaseSel)

local setDelegateSel = sel_registerName("setDelegate:")
cast("void(*)(id, SEL, id)", objc_msgSend)(NSApp, setDelegateSel, dg);

local NSMenuClass = objc_getClass("NSMenu")
local menubarAlloc = cast("id(*)(Class, SEL)", objc_msgSend)(NSMenuClass, allocSel)
local menubar = cast("id(*)(id, SEL)", objc_msgSend)(menubarAlloc, initSel)
cast("void(*)(id, SEL)", objc_msgSend)(menubar, autoreleaseSel)

local NSMenuItemClass = objc_getClass("NSMenuItem")
local appMenuItemAlloc = cast("id(*)(Class, SEL)", objc_msgSend)(NSMenuItemClass, allocSel)
local appMenuItem = cast("id(*)(id, SEL)", objc_msgSend)(appMenuItemAlloc, initSel)
cast("void(*)(id, SEL)", objc_msgSend)(appMenuItem, autoreleaseSel)

local addItemSel = sel_registerName("addItem:")
cast("void(*)(id, SEL, id)", objc_msgSend)(menubar, addItemSel, appMenuItem)

local setMainMenuSel = sel_registerName("setMainMenu:")
cast("id(*)(id, SEL, id)", objc_msgSend)(NSApp, setMainMenuSel, menubar)

local appMenuAlloc = cast("id(*)(Class, SEL)", objc_msgSend)(NSMenuClass, allocSel)
local appMenu = cast("id(*)(id, SEL)", objc_msgSend)(appMenuAlloc, initSel)
cast("void(*)(id, SEL)", objc_msgSend)(appMenu, autoreleaseSel)

local NSStringClass = objc_getClass("NSString")
local stringWithUTF8StringSel = sel_registerName("stringWithUTF8String:")
local quitTitle = cast("id(*)(Class, SEL, const char*)", objc_msgSend)(NSStringClass, stringWithUTF8StringSel,
    "Quit")

local quitMenuItemKey = cast("id(*)(Class, SEL, const char*)", objc_msgSend)(NSStringClass, stringWithUTF8StringSel, "q")
local quitMenuItemAlloc = cast("id(*)(Class, SEL)", objc_msgSend)(NSMenuItemClass, allocSel)
local initWithTitelSel = sel_registerName("initWithTitle:action:keyEquivalent:")
local terminateSel = sel_registerName("terminate:")
local quitMenuItem = cast("id(*)(id, SEL, id, SEL, id)", objc_msgSend)(quitMenuItemAlloc, initWithTitelSel, quitTitle,
    terminateSel, quitMenuItemKey)
cast("void(*)(id, SEL)", objc_msgSend)(quitMenuItem, autoreleaseSel)

cast("void(*)(id, SEL, id)", objc_msgSend)(appMenu, addItemSel, quitMenuItem)
local setSubmenuSel = sel_registerName("setSubmenu:")
cast("void(*)(id, SEL, id)", objc_msgSend)(appMenuItem, setSubmenuSel, appMenu)

local rect = ffi.new("CGRect", { origin = { x = 0, y = 0 }, size = { width = 200, height = 300 } })
local NSWindowClass = objc_getClass("NSWindow")
local windowAlloc = cast("id(*)(Class, SEL)", objc_msgSend)(NSWindowClass, allocSel)
local initWithContentRectSel = sel_registerName("initWithContentRect:styleMask:backing:defer:")
local styleMask = bit.bor(NSWindowStyleMaskTitled, NSWindowStyleMaskClosable, NSWindowStyleMaskMiniaturizable,
    NSWindowStyleMaskResizable)
assert(styleMask == 15)
local window = cast("id(*)(id, SEL, CGRect, NSUInteger, NSUInteger, BOOL)", objc_msgSend)(windowAlloc,
    initWithContentRectSel, rect, styleMask, NSBackingStoreBuffered, false)

local WindowDelegateClass = objc_allocateClassPair(NSObjectClass, "WindowDelegate", 0)
--local NSWindowDelegateProtocol = objc_getProtocol("NSWindowDelegate")
--assert(class_addProtocol(WindowDelegateClass, NSWindowDelegateProtocol) == 1)
local windowWillCloseSel = sel_registerName("windowWillClose:")
local imp = cast("void (*)()", windowWillClose)
local cb = cast("IMP", imp)
assert(class_addMethod(WindowDelegateClass, windowWillCloseSel, cb, "v@:@"))

local wdgAlloc = cast("id(*)(Class, SEL)", objc_msgSend)(WindowDelegateClass, allocSel)
local wdg = cast("id(*)(id, SEL)", objc_msgSend)(wdgAlloc, initSel)
cast("id(*)(id, SEL)", objc_msgSend)(wdg, autoreleaseSel)
cast("void(*)(id, SEL, id)", objc_msgSend)(window, setDelegateSel, wdg)

-- TODO set window title

local makeKeyAndOrderFrontSel = sel_registerName("makeKeyAndOrderFront:")
cast("void(*)(id, SEL, id)", objc_msgSend)(window, makeKeyAndOrderFrontSel, window)

print("starting runloop")

local runSel = sel_registerName("run")
cast("void(*)(id, SEL)", objc_msgSend)(NSApp, runSel)

print("gracefully terminated")

local drainSel = sel_registerName("drain")
cast("void(*)(id, SEL)", objc_msgSend)(pool, drainSel)

-- TODO projectwise
-- 1) lookup method function for selector instead of calling objc_msgSend
-- 2) try making combined NSApp and NSWin
