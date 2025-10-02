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
local CBManagerStatePoweredOn = ffi.new("NSInteger", 5)
local CBCharacteristicWriteWithoutResponse = ffi.new("NSInteger", 1)
local YES = ffi.new("BOOL", 1)
local MidiUuid = objc.CBUUID:UUIDWithString(NSString("7772E5DB-3868-4112-A1A9-F2669D106BF3"))
local PeripheralName = NSString("CH-8")
local MidiPacket = { 0x80, 0x80, 0x00, 0x00, 0x00 }

-- globals
local App = {
    delegate = nil,
    peripheral = nil,
    characteristic = nil,
}

local function didUpdateState(self, cmd, central)
    local state = central.state
    NSLog("Central state %d", state)
    if (state == CBManagerStatePoweredOn) then
        NSLog("Central manager powered on, starting scan")
        central:scanForPeripheralsWithServices_options(nil, nil)
    end
end

local function didDiscoverPeripheral(self, cmd, central, peripheral,
                                     advertisement_data, rssi)
    local name = peripheral.name
    NSLog("Discovered peripheral: %@", name)
    if name and name:isEqualToString(PeripheralName) == YES then
        NSLog("Matched name: %@, stopping scan and connecting", PeripheralName)
        App.peripheral = peripheral:retain() -- connect will not succeed if peripheral is dropped
        central:stopScan()
        central:connectPeripheral_options(peripheral, nil)
    end
end

local function didConnectPeripheral(self, cmd, central, peripheral)
    NSLog("Connected to peripheral: %@", peripheral.name)
    peripheral.delegate = App.delegate
    peripheral:discoverServices(nil)
end

local function didDiscoverServices(self, cmd, peripheral, error)
    if objc.ptr(error) then
        NSLog("Error discovering services: %@", error)
        return
    end

    NSLog("Discovered services:")
    local services = peripheral.services -- NSArray<CBService*>*
    for i = 0, tonumber(services.count) - 1 do
        local service = services:objectAtIndex(i)
        NSLog("  %@", service.UUID)
        peripheral:discoverCharacteristics_forService(nil, service)
    end
end

local function didDiscoverCharacteristics(self, cmd, peripheral, service, error)
    if objc.ptr(error) then
        NSLog("Error discovering characteristics: %@", error)
        return
    end

    NSLog("Discovered characteristics for service %@", service.UUID)
    local characteristics = service.characteristics
    for i = 0, tonumber(characteristics.count) - 1 do
        local characteristic = characteristics:objectAtIndex(i)
        NSLog("  %@", characteristic.UUID)
        if characteristic.UUID:isEqual(MidiUuid) == YES then
            NSLog("Found MIDI characteristic")
            App.characteristic = characteristic:retain()

            local data = objc.NSData:dataWithBytes_length(
                ffi.cast("const void*", ffi.new("uint8_t[5]", MidiPacket)),
                ffi.new("NSUInteger", 5))

            App.peripheral:writeValue_forCharacteristic_type(data, App.characteristic,
                CBCharacteristicWriteWithoutResponse)
            break
        end
    end
end

local function makeDelegate()
    local delegate_class = objc.newClass("CentralManagerDelegate")
    delegate_class:addMethod("centralManagerDidUpdateState:", "v@:@", didUpdateState)
    delegate_class:addMethod("centralManager:didDiscoverPeripheral:advertisementData:RSSI:", "v@:@@@@",
        didDiscoverPeripheral)
    delegate_class:addMethod("centralManager:didConnectPeripheral:", "v@:@@", didConnectPeripheral)
    delegate_class:addMethod("peripheral:didDiscoverServices:", "v@:@@", didDiscoverServices)
    delegate_class:addMethod("peripheral:didDiscoverCharacteristicsForService:error:", "v@:@@@",
        didDiscoverCharacteristics)
    return objc.CentralManagerDelegate:alloc():init()
end

local function main()
    App.delegate = makeDelegate()
    local central = objc.CBCentralManager:alloc():initWithDelegate_queue(App.delegate, nil)

    objc.NSRunLoop:currentRunLoop():run()
end

main()
