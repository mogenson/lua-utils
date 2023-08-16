#!/usr/bin/env luajit

ffi = require("ffi")
C = ffi.C

ffi.cdef([[
typedef struct objc_object *id;
typedef struct objc_selector *SEL;
id objc_getClass(const char*);
SEL sel_registerName(const char*);
id objc_msgSend(id,SEL);
id NSPasteboardTypeString;
]])

ffi.load("/System/Library/Frameworks/AppKit.framework/AppKit")

input = ffi.cast("char*", arg[1] or io.read())

pboard = C.objc_msgSend(C.objc_getClass("NSPasteboard"),
    C.sel_registerName("generalPasteboard"))

C.objc_msgSend(pboard, C.sel_registerName("clearContents"))

str = ffi.cast("id(*)(id,SEL,char*)", C.objc_msgSend)(
    C.objc_getClass("NSString"),
    C.sel_registerName("stringWithUTF8String:"),
    input)

ret = ffi.cast("bool(*)(id,SEL,id,id)", C.objc_msgSend)(pboard,
    C.sel_registerName("setString:forType:"),
    str,
    C.NSPasteboardTypeString)
os.exit(ret)
