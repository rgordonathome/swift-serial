//
//  swift-serial - Application for Serial Port Programming in Swift
//
//  Adapted by Russell Gordon on 15-11-15.
//  From instructions at:
//
//  https://www.mac-usb-serial.com/wordpress/serial-port-programming-swift-mac-os-x/
//
//  Note for compilation:
//
//  Make sure you executed 'pod update' in the project root and opened the workspace file
//
//  This file depends on the ORSSerialPort Library

import Foundation
import IOKit
import IOKit.serial

// Did the program compile and get this far?
print("Hello, World!")

// Show the list of serial devices in the debug output area at bottom
//
// Arduino devices on OS X El Capitan often on something like:
//
//    /dev/cu.usbmodem1421
//
// Run the code segment below. Identify your serial device.
var portIterator: io_iterator_t = 0
let kernResult = findSerialDevices(kIOSerialBSDAllTypes, serialPortIterator: &portIterator)
if kernResult == KERN_SUCCESS {
    printSerialPaths(portIterator)
}

// Start to read serial device
print("Starting serial test program")
print("To quit type: 'exit' or 'quit'")

// Uncomment one of the two lines below
//
// Replace first argument with name of serial device on your system
// Replace second argument with name of file to re-direct output to
// Leave second arguemnt as "" if file output is not desired
// File will be created in ~/Documents/Shared Playground Data
//
SerialHandler().readDataFromSerialDevice("/dev/cu.usbmodem1421", writeToFile: "serial-output.txt")
//SerialHandler().readDataFromSerialDevice("/dev/cu.usbmodem1421", writeToFile: "")





