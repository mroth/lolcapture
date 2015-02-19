import Foundation
import AppKit

let programName     = "lolcapture"
let programVersion  = "0.0.1 dev"
var programIdentifier: String {
    return "\(programName) \(programVersion)"
}

/// the path where the final image will be stored (including filename)
let cwd = NSFileManager.defaultManager().currentDirectoryPath
let defaultFileName = "test-capture.jpg"

/// the current filePath where we will write the completed image
var filePath: String = cwd.stringByAppendingPathComponent(defaultFileName)

/// default delay to pass on for warmup in capture process
var delay = 0.75

// CLI mode state tracking
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

/// Process dashed options for the CLI
///
/// Mostly these modify the global state for the application process, however
/// certain options are actually mapped to actions that exit the process after
/// completing.
///
/// :param: opts all dashed options parsed from the command line
func processDashedOpts(opts: [String]) {
    for opt in opts {

        let splitArg = opt.componentsSeparatedByString("=")
        var argkey: String  = splitArg[0]
        var argval: String? = splitArg.count > 1 ? splitArg[1] : nil

        switch argkey {

        case "-h", "--help":
            // wow, no multiline string literals in Swift? Really?!
            let sep = "\t\t\t"
            println("Usage: \(programName) [options] <destination>")
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
            println("Unknown argument: \(opt)")
        }
    }
}

/// Parse the CLI arguments.
///
/// :returns: A list of all dashed options extracted from the arguments, and an
///   optional destination filePath provided by the user.
func parseArgs() -> (dashedOpts: [String], destinationFilePath: String?) {
    let arguments = NSProcessInfo.processInfo().arguments as [String]
    let dashedOptions = arguments.filter({$0.hasPrefix("-")})
    let realArgs = arguments.filter({!$0.hasPrefix("-")})
    
    var parsedFilePath: String?
    
    // we are assuming the second non-dashed option argument is the filename
    let potentialFileName: String? = (realArgs.count > 1) ? realArgs[1] : nil
    if let parsedFileName = potentialFileName {
        
        // standardize the path to remove all junk
        let standardPath = NSString(string: parsedFileName).stringByStandardizingPath
        
        // if not an absolute path, prepend the current working directory
        let absPath = NSString(string: parsedFileName).absolutePath
        parsedFilePath = absPath ? standardPath : cwd.stringByAppendingPathComponent(standardPath)
    }
    
    return (dashedOptions, parsedFilePath)
}

/// Runs the main capture process.
func runCapture() {
    println("📷 lolcommits is preserving this moment in history.")

    if let rawimagedata = CamSnapper.capture(warmupDelay: delay) {
        if let lolimage = LOLImage(data: rawimagedata) {
            lolimage.topMessage = finalSha
            lolimage.bottomMessage = finalMessage

            let writeSuccess = lolimage.render().writeToFile(filePath, atomically: true)
            if !writeSuccess {
                println("ERROR: failure writing to file: \(filePath)")
                exit(1)
            }
            
            debug("main", "LOL! image written to \(filePath)")
            
            if testMode {
                // in test mode, open the image for preview immediately
                NSWorkspace.sharedWorkspace().openFile(filePath)
            }
        } else {
            println("ERROR: Didn't understand the image data we got back from camera.")
        }
    } else {
        println("ERROR: Unable to capture image from camera for some reason.")
    }
}

func main () {
    // parse the CLI arguments, override destination file path if provided by user
    let (dashedOptions, destinationFilePath) = parseArgs()
    if let dfp = destinationFilePath {
        filePath = dfp
    }
    
    // process dashed options to set up global state
    // if any of those dashed options represent a terminating action, that is
    // currently handled for us in method.
    processDashedOpts(dashedOptions)
    
    // run the "main" capture process
    runCapture()
}
main()
