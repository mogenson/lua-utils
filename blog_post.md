# Automating My Office Blinds with a SwitchBot, Lua, and a Little Objective-C Magic

I have a set of automatic window blinds in my office. They're great, but they have one small flaw: the button to close them is just out of convenient reach. When the afternoon sun hits just right, I have to get up and press it. I recently got my hands on a [SwitchBot Bot](https://us.switch-bot.com/products/switchbot-bot), a small Bluetooth-enabled robot that can physically press buttons. This was the perfect opportunity for a little automation project.

My goal was to write a script that could command the SwitchBot to press the blinds button. Since I'm on a Mac, I decided to use LuaJIT for the task. This post breaks down how I did it using three key Lua files: `switchbot.lua`, `objc.lua`, and `async.lua`.

## The Three Core Components

This project is a great example of combining a high-level control script with lower-level helper modules to accomplish a task that a single language can't easily do on its own.

1.  **`switchbot.lua`**: The main application logic. This is the "brains" of the operation that orchestrates the entire process.
2.  **`objc.lua`**: A bridge to the native world. This module allows Lua to talk to the Objective-C runtime, which is essential for controlling macOS-specific features like Bluetooth.
3.  **`async.lua`**: A utility for taming asynchronicity. It helps manage the event-driven nature of Bluetooth communication, making the code cleaner and easier to read.

Let's look at each one in detail.

### The Brains: `switchbot.lua`

This script contains the high-level logic. Its job is to:
1.  Initialize the system's Bluetooth adapter.
2.  Scan for the specific SwitchBot device.
3.  Connect to it.
4.  Discover the correct Bluetooth "service" and "characteristic" required to send a command.
5.  Send the "press" command.
6.  Disconnect cleanly.

The script defines the unique identifiers for the SwitchBot's services and the specific commands to send. The core of the script is the `main` function, which lays out the sequence of operations.

```lua
local main = a.sync(function()
    Ble.run = true

    -- init and scan
    local delegate = makeDelegate()
    local central = assert(a.wait(Ble:init(delegate)))
    local peripheral = assert(a.wait(Ble:scan(central)))
    peripheral.delegate = delegate -- register for peripheral callbacks

    -- connect and get characteristic
    assert(a.wait(Ble:connect(central, peripheral)))
    local service = assert(a.wait(Ble:discoverService(peripheral, CommandService)))
    local characteristic = assert(a.wait(Ble:discoverCharacteristic(peripheral, service, CommandCharacteristic)))

    -- write command and wait
    a.wait(Ble:sleep(delegate, 2.0)) -- wait for peripheral service discovery to finish
    assert(a.wait(Ble:write(peripheral, characteristic, PressCommand)))
    a.wait(Ble:sleep(delegate, 1.0)) -- wait for command to process

    -- disconnect and stop
    a.wait(Ble:disconnect(central, peripheral))
    Ble.run = false
end)
```

You might notice the `a.sync` and `a.wait` calls. This code looks synchronous, but it's performing highly asynchronous actions. This clean, linear style is made possible by our next module.

### Taming Asynchronicity: `async.lua`

Bluetooth communication is inherently asynchronous. You don't just call a function and get a result back immediately. Instead, you start an operation (like a scan) and then wait for the system to notify you with an event (like `didDiscoverPeripheral`). Handling this with traditional callbacks can lead to deeply nested, hard-to-read code often called "callback hell."

The `async.lua` module solves this elegantly by using Lua's native coroutines to create an `async/await` pattern, similar to what you might find in JavaScript or Python.

At its heart, the library is built on three concepts:
1.  **Coroutines**: Lightweight, cooperatively scheduled threads. A coroutine can be paused (yielded) and resumed later with a value.
2.  **Thunks**: A "thunk" is a function that wraps a delayed computation. In our case, it's a function that takes a single argument: a callback. The `Ble:scan(central)` function is a perfect example—it doesn't return a value directly. Instead, it returns a thunk that, when executed, will perform the scan and call the provided callback with the result.
3.  **The Runner**: The `a.sync` function wraps our main logic in a coroutine and returns a "runner" function. This runner starts the coroutine.

The magic happens when the runner encounters a `yield` from the coroutine. The `a.wait(thunk)` function is simply an alias for `coroutine.yield(thunk)`.

Here's the flow:
1.  We call `a.wait(Ble:scan(central))`. This `Ble:scan` function returns a thunk.
2.  `a.wait` yields this thunk, pausing the `main` coroutine and passing the thunk back to the runner.
3.  The runner takes the thunk and executes it, providing its own internal `step` function as the callback.
4.  The thunk tells the CoreBluetooth framework to start scanning. This happens in the background.
5.  Sometime later, when a device is found, the `didDiscoverPeripheral` delegate method is called. This method eventually calls the callback provided in step 3.
6.  The runner's `step` function is now executed. It takes the result (the discovered peripheral) and calls `coroutine.resume`, passing the peripheral back into our `main` function.
7.  Execution inside `main` continues from exactly where it left off. The `a.wait` call returns the peripheral, and the script proceeds to the next line.

This model allows us to write asynchronous, event-driven code in a clean, sequential style, avoiding the complexity of nested callbacks entirely.

### The Bridge to macOS: `objc.lua`

The final, and perhaps most magical, piece of the puzzle is `objc.lua`. Lua doesn't have a built-in library for controlling Bluetooth. On macOS, this is handled by the **CoreBluetooth** framework, which is written in Objective-C.

`objc.lua` is a brilliant Lua module that uses LuaJIT's `ffi` (Foreign Function Interface) library to interact directly with the Objective-C runtime. This allows Lua to act as if it were a first-class Objective-C citizen.

Here’s a deeper look at how it works:

**1. Message Passing with `objc_msgSend`**

The core of the Objective-C language is message passing. The syntax `[myObject myMethod:arg]` is compiled down to a C function call: `objc_msgSend(myObject, "myMethod:", arg)`. The challenge is that `objc_msgSend` is variadic and has no fixed type signature; the types of the arguments and the return value depend on the method being called.

The `msgSend` function in `objc.lua` is a sophisticated wrapper that solves this. When you call `object:method(...)` in Lua, it:
1.  Looks up the Objective-C method on the object's class.
2.  Uses runtime functions like `method_copyReturnType` and `method_copyArgumentType` to determine the exact signature.
3.  Constructs a C function signature string for LuaJIT's FFI on the fly (e.g., `"id (*)(id, SEL, id)"`).
4.  Casts the generic `C.objc_msgSend` function pointer to this specific, dynamically-created signature.
5.  Calls the now correctly-typed function with the provided arguments.

**2. Metatables for Syntactic Sugar**

The module uses `ffi.metatype` to attach `__index` and `__newindex` metamethods to all Objective-C objects. This is what translates natural Lua syntax into Objective-C message sends.
-   When you write `peripheral:discoverServices(...)`, the `__index` metamethod intercepts the access for "discoverServices", creates a function that wraps an `objc_msgSend` call, and executes it.

**3. Creating Objective-C Classes in Lua**

Most importantly, `objc.lua` allows us to define new Objective-C classes and implement their methods with Lua functions. This is the key to handling callbacks. `switchbot.lua` uses `objc.newClass("CentralManagerDelegate")` to create a new class and `objc.addMethod(...)` to attach Lua functions to it.

```lua
-- Create a new Objective-C class
local class = objc.newClass("CentralManagerDelegate")

-- Add a method to it, implemented by a Lua function
objc.addMethod(class, "centralManager:didDiscoverPeripheral:advertisementData:RSSI:", "v@:@@@@",
    didDiscoverPeripheral)

-- Create an instance of our new class
local delegate = objc.CentralManagerDelegate:alloc():init()
```

When we pass this `delegate` object to the `CBCentralManager`, the CoreBluetooth framework holds a reference to a real Objective-C object. When a Bluetooth event occurs, the framework sends a message to our delegate object. The `objc.lua` bridge intercepts this message and invokes the corresponding Lua function (`didDiscoverPeripheral`), seamlessly bridging the gap between the two languages.

## Putting It All Together

The complete workflow is a beautiful dance between the three modules:

1.  The `main` function in `switchbot.lua` kicks off the process.
2.  It calls `a.wait(Ble:scan(...))`, which uses `objc.lua` to tell CoreBluetooth to start scanning. The `async.lua` module then pauses the coroutine.
3.  When the OS detects a Bluetooth device, it calls the `didDiscoverPeripheral` function (written in Lua, thanks to `objc.lua`).
4.  This function checks if it's the right device. If it is, it triggers the callback that `async.lua` is waiting for.
5.  The coroutine in `main` resumes, and it moves to the next step: `a.wait(Ble:connect(...))`.
6.  This cycle repeats for connecting, discovering services, and finally writing the `PressCommand` to the SwitchBot.

## Conclusion

This project demonstrates a powerful pattern: using a high-level scripting language (Lua) for the main logic, a foreign function interface (`objc.lua`) to access platform-specific native APIs, and an async library (`async.lua`) to keep the code clean and manageable. What results is a simple script that can control a physical device in the real world, solving the very important problem of afternoon sun glare.
