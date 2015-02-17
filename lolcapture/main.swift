//
//  main.swift
//  lolcommits
//
//  Created by Matthew Rothenberg on 2/9/15.
//  Copyright (c) 2015 Matthew Rothenberg. All rights reserved.
//

import Foundation

let filePath = "/Users/mroth/Desktop/test-capture.jpg"
var testMode  = false

func processArgs(args: [String]) {
    for arg in args {
        switch arg {
        
        case "-v", "--version":
            println("lolcapture 0.0.1 dev")
            exit(0)
        
        case "-l", "--list":
            let devices = CamSnapper.compatibleDevices()
            println(devices)
            exit(0)
        
        case "-t", "--test":
            testMode = true
            
        default:
            println("Unknown argument: \(arg)")
        }
    }
}

func runCapture() {
    println("📷 lolcommits is preserving this moment in history.")
    
    if let imagedata = CamSnapper.capture() {
        let renderedImage = LOLImage(imageData: imagedata).render()
        renderedImage.writeToFile(filePath, atomically: true)
    }
}


let arguments = NSProcessInfo.processInfo().arguments as [String]
let appName = arguments[0].lastPathComponent
let dashedArguments = arguments.filter({$0.hasPrefix("-")})
processArgs(dashedArguments)
runCapture()
