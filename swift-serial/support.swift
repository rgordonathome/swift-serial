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


// extension to add string to a file
extension NSString {
    func appendLineToURL(fileURL: NSURL) throws {
        try self.stringByAppendingString("\n").appendToURL(fileURL)
    }
    
    func appendToURL(fileURL: NSURL) throws {
        let data = self.dataUsingEncoding(NSUTF8StringEncoding)!
        try data.appendToURL(fileURL)
    }
}

// extension to write to a file
extension NSData {
    func appendToURL(fileURL: NSURL) throws {
        if let fileHandle = try? NSFileHandle(forWritingToURL: fileURL) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.writeData(self)
        }
        else {
            try writeToURL(fileURL, options: .DataWritingAtomic)
        }
    }
}

// Class to handle reading of serial port
class SerialHandler : NSObject, ORSSerialPortDelegate {
    
    let standardInputFileHandle = NSFileHandle.fileHandleWithStandardInput()
    var outputFile : String = ""
    var serialPort: ORSSerialPort?
    var writeToOutputFile: Bool = false
    
    func readDataFromSerialDevice(fromSerialDevice: String, writeToFile: String, eraseExisting : Bool = false) {
        
        // set outputFile
        if (writeToFile.characters.count != 0) {
            // Get path to the Documents folder
            let documentPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString
            
            // Append folder name of Shared Playground Data folder
            let sharedDataPath = documentPath.stringByAppendingPathComponent("Shared Playground Data")

            outputFile = sharedDataPath + "/" + writeToFile
            writeToOutputFile = true
            
            // remove the existing file if requested
            if (eraseExisting) {
                
                do {
                    let filemgr = NSFileManager.defaultManager()
                    try filemgr.removeItemAtPath(outputFile)
                    print("Existing output file: \(outputFile) removed.")
                }
                catch {
                    print("Error, existing output file: \(outputFile) could not be removed.")
                }

            }
            
            // Report what file is being written to
            print("Writing to file: \(outputFile)")
        }
        
        standardInputFileHandle.readabilityHandler = { (fileHandle: NSFileHandle!) in
            let data = fileHandle.availableData
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.handleUserInput(data)
            })
        }

        setbuf(stdout, nil)

        self.serialPort = ORSSerialPort(path: fromSerialDevice)
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
            
            // print to the output window
            print("\(string)", terminator: "")
            
            // write to the file
            if (writeToOutputFile) {
                do {
                    let url = NSURL(fileURLWithPath: outputFile)
                    try string.appendToURL(url)
                    let result = try String(contentsOfURL: url)
                }
                catch {
                    print("Could not write to file")
                }
            }
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

