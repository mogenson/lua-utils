---@diagnostic disable undefined-field

local objc = require("objc")
local ffi = require("ffi")

describe("objc", function()
    it("should load a framework", function()
        objc.loadFramework("Foundation")
        assert.is_not_nil(objc.NSObject)
    end)

    it("should get a class", function()
        local NSObject = objc.Class("NSObject")
        assert.is_not_nil(NSObject)
        assert.are.equal("NSObject", tostring(NSObject))
    end)

    it("should get a selector", function()
        local description = objc.SEL("description")
        assert.is_not_nil(description)
        assert.are.equal("description", tostring(description))
    end)

    it("should send a message to a class", function()
        local NSObject = objc.Class("NSObject")
        local obj = objc.msgSend(NSObject, "alloc")
        assert.is_not_nil(obj)
    end)

    it("should send a message to an instance", function()
        local pool = objc.NSAutoreleasePool:alloc():init()
        local obj = objc.NSObject:alloc():init()
        local description = obj.description
        assert.is_not_nil(description)
        assert.is_not_nil(ffi.string(description:UTF8String()):match("^<NSObject: 0x[0-9a-f]+>$"))
        pool:drain()
    end)

    it("should create a new class and add a method", function()
        local MyClass = objc.newClass("MyClass", "NSObject")
        assert.is_not_nil(MyClass)
        assert.are.equal("MyClass", tostring(MyClass))

        local instance = MyClass:alloc():init()
        assert.is_not_nil(instance)

        local function myMethod(self, cmd)
            assert.are.equal(instance, self)
            assert.are.equal("myMethod", tostring(cmd))
            return 42
        end
        objc.addMethod(MyClass, "myMethod", "i@:", myMethod)

        local result = instance:myMethod()
        assert.are.equal(42, result)
    end)

    it("can swizzle class method", function()
        local MyOtherClass = objc.newClass("MyOtherClass", "NSObject")
        local instance = MyOtherClass:alloc():init()

        local MyOtherMethod = objc.addMethod(
            MyOtherClass, "myOtherMethod", "i@:",
            function() return 6 end)
        assert.are.equal(6, instance:myOtherMethod())

        MyOtherMethod:set(function() return 7 end)
        assert.are.equal(7, instance:myOtherMethod())
    end)

    it("should convert a null pointer to nil", function()
        local null_ptr = objc.ptr(ffi.cast("void*", 0))
        assert.is_nil(null_ptr)
    end)
end)
