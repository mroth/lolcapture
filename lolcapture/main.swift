import Foundation
import AppKit

let programName     = "lolcapture"
let programVersion  = "0.0.1 dev"
var programIdentifier: String {
    return "\(programName) \(programVersion)"
}

// TODO: set a sane default
// TODO: override from CLI
/// the path where the final image will be stored (including filename)
var filePath = "/Users/mroth/Desktop/test-capture.jpg"

/// default delay to pass on for warmup in capture process
var delay = 0.75


var testMode  = false
var debugMode = false

// msg/SHA to be used in test mode when nothing is parsed
let testMessage = "this is a test message i didnt really commit something"
var testSha: String {
    return NSUUID().UUIDString.componentsSeparatedByString("-")[0].lowercaseString
}

// msg/SHA parsed from the CLI arguments
var parsedMessage, parsedSha: String?

// calculated message/SHA values to use
var finalMessage: String? {
    return (testMode && parsedMessage == nil) ? testMessage : parsedMessage
}
var finalSha: String? {
    return (testMode && parsedSha == nil) ? testSha : parsedSha
}

/// Utility function to logs a debug message to STDOUT if DEBUG_MODE=true.
func debug(group: String, msg: String) {
    if debugMode {
        let stderr = NSFileHandle.fileHandleWithStandardError()
        let debugStr = "DEBUG[\(group)]:\t\(msg)\n"
        stderr.writeData( debugStr.dataUsingEncoding(NSUTF8StringEncoding)! )
    }
}

/// Process arguments for the CLI
func processArgs(args: [String]) {
    for arg in args {

        let splitArg = arg.componentsSeparatedByString("=")
        var argkey: String  = splitArg[0]
        var argval: String? = splitArg.count > 1 ? splitArg[1] : nil
        //debug("m", "key: \(key)")
        //debug("m", "val: \(val)")

        switch argkey {

        case "-h", "--help":
            // wow, no multiline string literals in Swift? Really?!
            let sep = "\t\t\t"
            println("Usage: \(programName) [options]")
            println("")
            println("Experimental one-step webcam capture and text composition for lolcommits.")
            println("")
            println("Options:")
            println("  -h, --help"    + sep + "Show this help message and exit")
            println("  -v, --version" + sep + "Show the \(programName) version")
            println("  -l, --list"    + sep + "List available capture devices")
            println("  --test"        + sep + "Create fake msg/SHA values when none provided")
            println("  --msg=<MSG>"   + sep + "Message to be displayed across bottom of image")
            println("  --sha=<SHA>"   + sep + "Hash to be displayed on top right of image")
            println("  --delay=<N>"   + sep + "Delay capture by N seconds (default: \(delay))")
            println("  --debug"       + sep + "Enable DEBUG output")
            exit(0)

        case "-v", "--version":
            println(programIdentifier)
            exit(0)

        case "-l", "--list":
            let devices = CamSnapper.compatibleDevices()
            println(devices)
            exit(0)

        case "-t", "--test":
            testMode = true

        case "--msg":
            parsedMessage = argval

        case "--sha":
            parsedSha = argval
            
        case "--delay":
            if let delayStr = argval {
                if let delayNum = NSNumberFormatter().numberFromString(delayStr) {
                    delay = delayNum.doubleValue
                }
            }

        case "--debug":
            debugMode = true

        default:
            println("Unknown argument: \(arg)")
        }
    }
}

func runCapture() {
    println("📷 lolcommits is preserving this moment in history.")

    if let rawimagedata = CamSnapper.capture(warmupDelay: delay) {
        if let lolimage = LOLImage(data: rawimagedata) {
            lolimage.topMessage = finalSha
            lolimage.bottomMessage = finalMessage

            lolimage.render().writeToFile(filePath, atomically: true)
            // TODO: handle file write error condition

            debug("main", "LOL! image written to \(filePath)")
            println("LOL! image was preserved at: \(filePath)")

            // if in test mode, open the image for preview immediately
            if testMode {
                NSWorkspace.sharedWorkspace().openFile(filePath)
            }
        } else {
            println("ERROR: Didn't understand the image data we got back from camera.")
        }
    } else {
        println("ERROR: Unable to capture image from camera for some reason.")
    }
}


let arguments = NSProcessInfo.processInfo().arguments as [String]
let appName = arguments[0].lastPathComponent
let dashedArguments = arguments.filter({$0.hasPrefix("-")})
processArgs(dashedArguments)
runCapture()
