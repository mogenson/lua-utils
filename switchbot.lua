#!/usr/bin/env luajit

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

local function NSLog(str, ...)
    C.NSLog(NSString(str), ...)
end

-- constants
local NSDefaultRunLoopMode = NSString("kCFRunLoopDefaultMode")
local CBAdvertisementDataServiceDataKey = NSString("kCBAdvDataServiceData")
local CBCharacteristicWriteWithoutResponse = ffi.new("NSInteger", 1)
local CBCharacteristicWriteWithResponse = ffi.new("NSInteger", 0)
local CBManagerStatePoweredOn = ffi.new("NSInteger", 5)
local YES = ffi.new("BOOL", 1)
local ServiceDataUuid = objc.CBUUID:UUIDWithString(NSString("fd3d"))
local ServiceUuid = objc.CBUUID:UUIDWithString(NSString("cba20d00-224d-11e6-9fb8-0002a5d5c51b"))
local CommandCharacteristic = objc.CBUUID:UUIDWithString(NSString("cba20002-224d-11e6-9fb8-0002a5d5c51b"))
local ResponseCharacteristic = objc.CBUUID:UUIDWithString(NSString("cba20003-224d-11e6-9fb8-0002a5d5c51b"))
local ExpectedServiceData = objc.NSData:dataWithBytes_length(
    ffi.cast("const void*", ffi.new("uint8_t[4]", { 0x48, 0x00, 0x64, 0x00 })),
    ffi.new("NSInteger", 4)
)
local PressCommand = objc.NSData:dataWithBytes_length(
    ffi.cast("const void*", ffi.new("uint8_t[3]", { 0x57, 0x01, 0x00 })),
    ffi.new("NSInteger", 3)
)
local PressResponse = objc.NSData:dataWithBytes_length(
    ffi.cast("const void*", ffi.new("uint8_t[3]", { 0x01, 0xFF, 0x00 })),
    ffi.new("NSInteger", 3)
)


-- globals
local App = {
    run = false,
    central = nil,
    delegate = nil,
    peripheral = nil,
    characteristic = nil,
}

local function didUpdateState(self, cmd, central)
    if (central.state == CBManagerStatePoweredOn) then
        NSLog("Central manager powered on, starting scan")
        central:scanForPeripheralsWithServices_options(nil, nil)
    end
end

local function didDiscoverPeripheral(self, cmd, central, peripheral,
                                     advertisement_data, rssi)
    local service_data = advertisement_data:objectForKey(CBAdvertisementDataServiceDataKey) -- NSDictionary<NSString *,id>
    if service_data then
        local data = service_data:objectForKey(ServiceDataUuid)                             -- NSDictionary<CBUUID *, NSData *>
        if data and data:isEqualToData(ExpectedServiceData) == YES then
            App.peripheral = peripheral:retain()                                            -- connect will not succeed if peripheral is dropped
            NSLog("Discovered peripheral with service data: %@", data)
            central:stopScan()
            NSLog("Connecting to: %@", peripheral.name)
            central:connectPeripheral_options(peripheral, nil)
        end
    end
end

local function didConnectPeripheral(self, cmd, central, peripheral)
    NSLog("Connected to peripheral")
    peripheral.delegate = App.delegate
    local uuids = objc.NSArray:arrayWithObject(ServiceUuid)
    peripheral:discoverServices(uuids)
end

local function didFailToConnectPeripheral(self, cmd, central, peripheral, error)
    NSLog("Failed to connect to peripheral: %@", error)
end

local function didDisconnectPeripheral(self, cmd, central, peripheral, error)
    if objc.ptr(error) then
        NSLog("Error disconnecting from peripheral: %@", error)
    else
        NSLog("Disconnected from peripheral")
    end
    App.run = false
end

local function didDiscoverServices(self, cmd, peripheral, error)
    if objc.ptr(error) then
        NSLog("Error discovering services: %@", error)
        return
    end

    local service = peripheral.services:objectAtIndex(0)
    NSLog("Discovered service: %@", service.UUID)
    local uuids = objc.NSArray:arrayWithObject(CommandCharacteristic)
    peripheral:discoverCharacteristics_forService(uuids, service)
end

local function didDiscoverCharacteristics(self, cmd, peripheral, service, error)
    if objc.ptr(error) then
        NSLog("Error discovering characteristics: %@", error)
        return
    end

    local characteristic = service.characteristics:objectAtIndex(0)
    NSLog("Discovered characteristic %@", characteristic.UUID)
    App.characteristic = characteristic:retain()
    NSLog("Write press command")
    App.peripheral:writeValue_forCharacteristic_type(PressCommand, App.characteristic,
        CBCharacteristicWriteWithResponse)
end

local function didWriteValueForCharacteristic(self, cmd, peripheral, characteristic, error)
    if objc.ptr(error) then
        NSLog("Write to characteristic: %@", error)
    else
        NSLog("Wrote to characteristic")
    end
    App.central:cancelPeripheralConnection(peripheral)
end

local function makeDelegate()
    local delegate_class = objc.newClass("CentralManagerDelegate")
    delegate_class:addMethod("centralManagerDidUpdateState:", "v@:@", didUpdateState)
    delegate_class:addMethod("centralManager:didDiscoverPeripheral:advertisementData:RSSI:", "v@:@@@@",
        didDiscoverPeripheral)
    delegate_class:addMethod("centralManager:didConnectPeripheral:", "v@:@@", didConnectPeripheral)
    delegate_class:addMethod("centralManager:didFailToConnectPeripheral:error:", "v@:@@@", didFailToConnectPeripheral)
    delegate_class:addMethod("centralManager:didDisconnectPeripheral:error:", "v@:@@@", didDisconnectPeripheral)
    delegate_class:addMethod("peripheral:didDiscoverServices:", "v@:@@", didDiscoverServices)
    delegate_class:addMethod("peripheral:didDiscoverCharacteristicsForService:error:", "v@:@@@",
        didDiscoverCharacteristics)
    delegate_class:addMethod("peripheral:didWriteValueForCharacteristic:error:", "v@:@@@", didWriteValueForCharacteristic)
    return objc.CentralManagerDelegate:alloc():init()
end

local function main()
    App.delegate = makeDelegate()
    App.central = objc.CBCentralManager:alloc():initWithDelegate_queue(App.delegate, nil)

    App.run = true
    local run_loop = objc.NSRunLoop:currentRunLoop()
    local distant_future = objc.NSDate:distantFuture()
    while App.run == true do
        run_loop:runMode_beforeDate(NSDefaultRunLoopMode, distant_future);
    end

    NSLog("Done")
end

main()
