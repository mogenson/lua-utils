---@diagnostic disable unused-local

local a = require("async")
local objc = require("objc")
objc.loadFramework("Foundation")
objc.loadFramework("CoreBluetooth")

local ffi = require("ffi")
local C = ffi.C

ffi.cdef([[
void NSLog(id, ...);
]])

-- utilities
local function NSString(str)
    return objc.NSString:stringWithUTF8String(str)
end

local function NSInteger(int)
    return ffi.new("NSInteger", int)
end

local function BOOL(bool)
    return ffi.new("BOOL", bool and 1 or 0)
end

local function CBUUID(str)
    return objc.CBUUID:UUIDWithString(NSString(str))
end

local function NSData(bytes)
    return objc.NSData:dataWithBytes_length(objc.cast("const void*", ffi.new("uint8_t[?]", #bytes, bytes)),
        NSInteger(#bytes))
end

local function NSLog(str, ...)
    C.NSLog(NSString(str), ...)
end

-- constants
local NSDefaultRunLoopMode = NSString("kCFRunLoopDefaultMode")

-- CoreBluetooth constants from https://github.com/brettchien/PyBLEWrapper/blob/master/pyble/osx/IOBluetooth.py
local CBCentralManagerStateUnkown = NSInteger(0)
local CBCentralManagerStateResetting = NSInteger(1)
local CBCentralManagerStateUnsupported = NSInteger(2)
local CBCentralManagerStateUnauthorized = NSInteger(3)
local CBCentralManagerStatePoweredOff = NSInteger(4)
local CBCentralManagerStatePoweredOn = NSInteger(5)

local CBAdvertisementDataLocalNameKey = NSString("kCBAdvDataLocalName")
local CBAdvertisementDataManufacturerDataKey = NSString("kCBAdvDataManufacturerData")
local CBAdvertisementDataServiceDataKey = NSString("kCBAdvDataServiceData")
local CBAdvertisementDataServiceUUIDsKey = NSString("kCBAdvDataServiceUUIDs")
local CBAdvertisementDataOverflowServiceUUIDsKey = NSString("kCBAdvDataOverflowService")
local CBAdvertisementDataTxPowerLevelKey = NSString("kCBAdvDataTxPowerLevel")
local CBAdvertisementDataIsConnectable = NSString("kCBAdvDataIsConnectable")
local CBAdvertisementDataSolicitedServiceUUIDsKey = NSString("kCBAdvDataSolicitedServiceUUIDs")

local CBCharacteristicWriteWithResponse = NSInteger(0)
local CBCharacteristicWriteWithoutResponse = NSInteger(1)

local ServiceDataUuid = CBUUID("fd3d")
local CommandService = CBUUID("cba20d00-224d-11e6-9fb8-0002a5d5c51b")
local CommandCharacteristic = CBUUID("cba20002-224d-11e6-9fb8-0002a5d5c51b")
local ResponseCharacteristic = CBUUID("cba20003-224d-11e6-9fb8-0002a5d5c51b")
local ExpectedServiceData = NSData({ 0x48, 0x00, 0x64, 0x00 })
local ExpectedMfgData = NSData({ 0x69, 0x09, 0xd6, 0x34, 0xc5, 0x46, 0x61, 0x50, 0x05, 0x0c })
local PressCommand = NSData({ 0x57, 0x01, 0x00 })
local PressResponse = NSData({ 0x01, 0xFF, 0x00 })

local run = false -- main runloop flag

-- core bluetooth delegate methods

local function didUpdateState(cb)
    return function(id, sel, central)
        if (central.state == CBCentralManagerStatePoweredOn) then
            NSLog("Central manager powered on")
            return cb and cb(central:retain())
        end
    end
end

local function didDiscoverPeripheral(cb)
    return function(id, sel, central, peripheral,
                    advertisement_data, rssi)
        local service_data = advertisement_data:objectForKey(CBAdvertisementDataServiceDataKey)  -- NSDictionary<NSString *,id>
        local mfg_data = advertisement_data:objectForKey(CBAdvertisementDataManufacturerDataKey) -- NSData*
        if service_data and mfg_data then
            local data = service_data:objectForKey(ServiceDataUuid)                              -- NSDictionary<CBUUID *, NSData *>
            if data and data:isEqualToData(ExpectedServiceData) == BOOL(true) and mfg_data:isEqualToData(ExpectedMfgData) == BOOL(true) then
                NSLog("Discovered peripheral with service data: %@ and manufacturer data %@", data, mfg_data)
                central:stopScan()
                return cb and cb(peripheral:retain())
            end
        end
    end
end

local function didConnectPeripheral(cb)
    return function(id, sel, central, peripheral)
        NSLog("Connected to peripheral: %@", peripheral.name)
        return cb and cb(true)
    end
end

local function didFailToConnectPeripheral(cb)
    return function(id, sel, central, peripheral, error)
        NSLog("Failed to connect to peripheral: %@", error)
        return cb and cb(false)
    end
end

local function didDisconnectPeripheral(cb)
    return function(id, sel, central, peripheral, error)
        if objc.ptr(error) then
            NSLog("Error disconnecting from peripheral: %@", error)
            return cb and cb(false)
        else
            NSLog("Disconnected from peripheral")
            return cb and cb(true)
        end
        run = false -- stop run loop if no waiting callback
    end
end

local function didDiscoverServices(cb)
    return function(id, sel, peripheral, error)
        if objc.ptr(error) then
            NSLog("Error discovering services: %@", error)
            return cb and cb(nil)
        end

        local service = peripheral.services:objectAtIndex(0)
        NSLog("Discovered service: %@", service.UUID)
        return cb and cb(service:retain())
    end
end

local function didDiscoverCharacteristics(cb)
    return function(id, sel, peripheral, service, error)
        if objc.ptr(error) then
            NSLog("Error discovering characteristics: %@", error)
            return cb and cb(nil)
        end

        local characteristic = service.characteristics:objectAtIndex(0)
        NSLog("Discovered characteristic %@", characteristic.UUID)
        return cb and cb(characteristic:retain())
    end
end

local function didWriteValueForCharacteristic(cb)
    return function(id, sel, peripheral, characteristic, error)
        if objc.ptr(error) then
            NSLog("Write to characteristic: %@", error)
            return cb and cb(false)
        else
            NSLog("Wrote to characteristic")
            return cb and cb(true)
        end
    end
end

local function timerFired(cb)
    return function(id, sel, timer)
        return cb and cb()
    end
end

-- async methods
local Ble = {
    makeDelegate = function(self)
        local class = objc.newClass("CentralManagerDelegate")

        self.init_cb = objc.addMethod(class, "centralManagerDidUpdateState:", "v@:@",
            didUpdateState())

        self.scan_cb = objc.addMethod(class, "centralManager:didDiscoverPeripheral:advertisementData:RSSI:", "v@:@@@@",
            didDiscoverPeripheral())

        self.connect_cb = objc.addMethod(class, "centralManager:didConnectPeripheral:", "v@:@@",
            didConnectPeripheral())

        self.connect_fail_cb = objc.addMethod(class, "centralManager:didFailToConnectPeripheral:error:", "v@:@@@",
            didFailToConnectPeripheral())

        self.disconnect_cb = objc.addMethod(class, "centralManager:didDisconnectPeripheral:error:", "v@:@@@",
            didDisconnectPeripheral())

        self.discover_svc_cb = objc.addMethod(class, "peripheral:didDiscoverServices:", "v@:@@",
            didDiscoverServices())

        self.discover_char_cb = objc.addMethod(class, "peripheral:didDiscoverCharacteristicsForService:error:", "v@:@@@",
            didDiscoverCharacteristics())

        self.write_cb = objc.addMethod(class, "peripheral:didWriteValueForCharacteristic:error:", "v@:@@@",
            didWriteValueForCharacteristic())

        self.timer_cb = objc.addMethod(class, "timerFireMethod:", "v@:@",
            timerFired())

        return objc.CentralManagerDelegate:alloc():init()
    end,

    init = a.wrap(function(self, delegate, cb)
        self.init_cb:set(didUpdateState(cb))
        objc.CBCentralManager:alloc():initWithDelegate_queue(delegate, nil)
    end),

    scan = a.wrap(function(self, central, cb)
        self.scan_cb:set(didDiscoverPeripheral(cb))
        central:scanForPeripheralsWithServices_options(nil, nil)
    end),

    connect = a.wrap(function(self, central, peripheral, cb)
        self.connect_cb:set(didConnectPeripheral(cb))
        self.connect_fail_cb:set(didFailToConnectPeripheral(cb))
        central:connectPeripheral_options(peripheral, nil)
    end),

    discoverService = a.wrap(function(self, peripheral, uuid, cb)
        self.discover_svc_cb:set(didDiscoverServices(cb))
        peripheral:discoverServices(objc.NSArray:arrayWithObject(uuid))
    end),

    discoverCharacteristic = a.wrap(function(self, peripheral, service, uuid, cb)
        self.discover_char_cb:set(didDiscoverCharacteristics(cb))
        peripheral:discoverCharacteristics_forService(objc.NSArray:arrayWithObject(uuid), service)
    end),

    write = a.wrap(function(self, peripheral, characteristic, value, cb)
        self.write_cb:set(didWriteValueForCharacteristic(cb))
        peripheral:writeValue_forCharacteristic_type(value, characteristic, CBCharacteristicWriteWithResponse)
    end),

    disconnect = a.wrap(function(self, central, peripheral, cb)
        self.disconnect_cb:set(didDisconnectPeripheral(cb))
        central:cancelPeripheralConnection(peripheral)
    end),

    sleep = a.wrap(function(self, target, seconds, cb)
        self.timer_cb:set(timerFired(cb))
        seconds = ffi.new("double", seconds)
        local selector = objc.SEL("timerFireMethod:")
        objc.NSTimer:scheduledTimerWithTimeInterval_target_selector_userInfo_repeats(seconds, target, selector, nil,
            BOOL(false))
    end)
}

local main = a.sync(function()
    run = true

    -- init and scan
    local delegate = Ble:makeDelegate()

    local central = a.wait(Ble:init(delegate))
    local peripheral = a.wait(Ble:scan(central))
    peripheral.delegate = delegate -- register for peripheral callbacks

    -- connect and get characteristic
    a.wait(Ble:connect(central, peripheral))
    local service = a.wait(Ble:discoverService(peripheral, CommandService))
    local characteristic = a.wait(Ble:discoverCharacteristic(peripheral, service, CommandCharacteristic))

    -- write command and wait
    a.wait(Ble:sleep(delegate, 2.0)) -- wait for peripheral service discovery to finish
    a.wait(Ble:write(peripheral, characteristic, PressCommand))
    a.wait(Ble:sleep(delegate, 1.0)) -- wait for command to process

    -- disconnect and stop
    a.wait(Ble:disconnect(central, peripheral))
    run = false
end)

a.run(main())

local run_loop = objc.NSRunLoop:currentRunLoop()
local distant_future = objc.NSDate:distantFuture()
while run == true and run_loop:runMode_beforeDate(NSDefaultRunLoopMode, distant_future) == BOOL(true) do end

NSLog("Done")
