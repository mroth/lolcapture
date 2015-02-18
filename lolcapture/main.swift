import Foundation

let filePath = "/Users/mroth/Desktop/test-capture.jpg"
//var testMode  = false
var debugMode = false

let programName     = "lolcapture"
let programVersion  = "0.0.1 dev"
var programIdentifier: String {
    return "\(programName) \(programVersion)"
}

/// Logs a debug message to STDERR if DEBUG_MODE=true.
func debug(group: String, msg: String) {
    if debugMode {
        println( "DEBUG[\(group)]:\t\(msg)" )
    }
}

/// Process arguments for the CLI
func processArgs(args: [String]) {
    for arg in args {
        switch arg {
            
        case "-h", "--help":
            // wow, no multiline strings in Swift? Really?!
            println("Usage: \(programName) [options]")
            println("")
            println("Experimental one-step webcam capture and text composition for lolcommits.")
            println("")
            println("Options:")
            println("  -h, --help" + "\t\t\t" + "Show this help message and exit")
            println("  --version"  + "\t\t\t" + "Show the \(programName) version")
            println("  -l, --list" + "\t\t\t" + "List available capture devices")
            println("  --debug"    + "\t\t\t" + "Enable DEBUG output")
            exit(0)
        
        case "--version":
            println(programIdentifier)
            exit(0)
        
        case "-l", "--list":
            let devices = CamSnapper.compatibleDevices()
            println(devices)
            exit(0)
        
        //case "-t", "--test":
        //    testMode = true
            
        case "--debug":
            debugMode = true
            
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
        debug("main", "LOL! image written to \(filePath)")
    }
}


let arguments = NSProcessInfo.processInfo().arguments as [String]
let appName = arguments[0].lastPathComponent
let dashedArguments = arguments.filter({$0.hasPrefix("-")})
processArgs(dashedArguments)
runCapture()
