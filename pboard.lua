#!/usr/bin/env luajit

local ffi = require("ffi")
local C = ffi.C

ffi.cdef([[
typedef struct objc_object *id;
typedef struct objc_selector *SEL;
id objc_getClass(const char*);
SEL sel_registerName(const char*);
id objc_msgSend(id,SEL);
id NSPasteboardTypeString;
]])

assert(ffi.load("/System/Library/Frameworks/AppKit.framework/AppKit", true))

local input = ffi.cast("char*", arg[1] or io.read())

local pboard = C.objc_msgSend(C.objc_getClass("NSPasteboard"),
    C.sel_registerName("generalPasteboard"))

C.objc_msgSend(pboard, C.sel_registerName("clearContents"))

local str = ffi.cast("id(*)(id,SEL,char*)", C.objc_msgSend)(
    C.objc_getClass("NSString"),
    C.sel_registerName("stringWithUTF8String:"),
    input)

local ret = ffi.cast("bool(*)(id,SEL,id,id)", C.objc_msgSend)(pboard,
    C.sel_registerName("setString:forType:"),
    str,
    C.NSPasteboardTypeString)

os.exit(ret)
