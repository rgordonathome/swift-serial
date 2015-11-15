//
//  support.swift
//  swift-serial
//
//  Created by Russell Gordon on 2015-11-15.
//  Copyright © 2015 Russell Gordon. All rights reserved.
//

import Foundation

// Find all serial devices
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

// Print serial devices
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

// Class to handle reading of serial port
class SerialHandler : NSObject, ORSSerialPortDelegate {
    let standardInputFileHandle = NSFileHandle.fileHandleWithStandardInput()
    var serialPort: ORSSerialPort?
    
    func readDataFromSerialDevice(fromSerialDevice: String) {
        setbuf(stdout, nil)
        
        standardInputFileHandle.readabilityHandler = { (fileHandle: NSFileHandle!) in
            let data = fileHandle.availableData
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.handleUserInput(data)
            })
        }
        
        self.serialPort = ORSSerialPort(path: fromSerialDevice) // please adjust to your handle
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