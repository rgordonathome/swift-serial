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

func findSerialDevices(deviceType: String, inout serialPortIterator: io_iterator_t ) -> kern_return_t {
    var result: kern_return_t = KERN_FAILURE
    let classesToMatch = IOServiceMatching(kIOSerialBSDServiceValue)
    var classesToMatchDict = (classesToMatch as NSDictionary)
        as! Dictionary<String, AnyObject>
    classesToMatchDict[kIOSerialBSDTypeKey] = deviceType
    let classesToMatchCFDictRef = (classesToMatchDict as NSDictionary) as CFDictionaryRef
    result = IOServiceGetMatchingServices(kIOMasterPortDefault, classesToMatchCFDictRef, &serialPortIterator);
    return result
}

func printSerialPaths(portIterator: io_iterator_t) {
    var serialService: io_object_t
    repeat {
        serialService = IOIteratorNext(portIterator)
        if (serialService != 0) {
            let key: CFString! = "IOCalloutDevice"
            let bsdPathAsCFtring: AnyObject? =
            IORegistryEntryCreateCFProperty(serialService, key, kCFAllocatorDefault, 0).takeUnretainedValue()
            let bsdPath = bsdPathAsCFtring as! String?
            if let path = bsdPath {
                print(path)
            }
        }
    } while serialService != 0;
}

// Show the list of serial devices in the debug output area at bottom
var portIterator: io_iterator_t = 0
let kernResult = findSerialDevices(kIOSerialBSDAllTypes, serialPortIterator: &portIterator)
if kernResult == KERN_SUCCESS {
    printSerialPaths(portIterator)
}

// Class to handle reading of serial port
class SerialHandler : NSObject, ORSSerialPortDelegate {
    let standardInputFileHandle = NSFileHandle.fileHandleWithStandardInput()
    var serialPort: ORSSerialPort?
    
    func runProcessingInput() {
        setbuf(stdout, nil)
        
        standardInputFileHandle.readabilityHandler = { (fileHandle: NSFileHandle!) in
            let data = fileHandle.availableData
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.handleUserInput(data)
            })
        }
        
        self.serialPort = ORSSerialPort(path: "/dev/cu.usbmodem1421") // please adjust to your handle
        self.serialPort?.baudRate = 9600
        self.serialPort?.delegate = self
        serialPort?.open()
        
        NSRunLoop.currentRunLoop().run() // loop
    }
    
    
    func handleUserInput(dataFromUser: NSData) {
        if let string = NSString(data: dataFromUser, encoding: NSUTF8StringEncoding) as? String {
            
            if string.lowercaseString.hasPrefix("exit") ||
                string.lowercaseString.hasPrefix("quit") {
                    print("Quitting...")
                    exit(EXIT_SUCCESS)
            }
            self.serialPort?.sendData(dataFromUser)
        }
    }
    
    // ORSSerialPortDelegate
    
    func serialPort(serialPort: ORSSerialPort, didReceiveData data: NSData) {
        if let string = NSString(data: data, encoding: NSUTF8StringEncoding) {
            print("\(string)", terminator: "")
        }
    }
    
    func serialPortWasRemovedFromSystem(serialPort: ORSSerialPort) {
        self.serialPort = nil
    }
    
    func serialPort(serialPort: ORSSerialPort, didEncounterError error: NSError) {
        print("Serial port (\(serialPort)) encountered error: \(error)")
    }
    
    func serialPortWasOpened(serialPort: ORSSerialPort) {
        print("Serial port \(serialPort) was opened")
    }
}

// actually read the serial port
print("Starting serial test program")
print("To quit type: 'exit' or 'quit'")
SerialHandler().runProcessingInput()