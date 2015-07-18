import Foundation
import AVFoundation
import AppKit

let programName     = "lolcapture"
let programVersion  = "0.0.2 dev"
var programIdentifier: String {
    return "\(programName) \(programVersion)"
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
            println("Usage: \(programName) [options] <destination>")
            println("")
            println("Experimental one-step webcam capture and text composition for lolcommits.")
            println("")
            println("Options:")
            println("  -h, --help           Show this help message and exit")
            println("  -v, --version        Show the \(programName) version and exit")
            println("  -l, --list           List available capture devices")
            println("  --device=ID          Use specified device (matches name or id, partial ok)")
            println("  -g, --gitinfo        Get sha/msg from current repository")
            println("  --test               Create fake msg/SHA values when none provided")
            println("  --msg=MSG            Message to be displayed across bottom of image")
            println("  --sha=SHA            Hash to be displayed on top right of image")
            println("  --warmup=N           Delay capture by N seconds (default: \(Config.delay))")
            println("  --debug              Enable DEBUG output")
            exit(0)

        case "-v", "--version":
            println(programIdentifier)
            exit(0)

        case "-l", "--list":
            listDevices(CamSnapper.compatibleDevices())
            exit(0)

        case "--device":
            Config.requestedDeviceID = argval

        case "-t", "--test":
            Config.testMode = true

        case "-g", "--gitinfo":
            if let parsedInfo = GitInfo.parseFromSystem() {
                Config.parsedSha     = parsedInfo.sha
                Config.parsedMessage = parsedInfo.msg
            } else {
                println("something fucked up, probably not in a git repo?")
                exit(666)
            }

        case "--msg":
            Config.parsedMessage = argval

        case "--sha":
            Config.parsedSha = argval

        case "--warmup":
            if let delayStr = argval {
                if let delayNum = NSNumberFormatter().numberFromString(delayStr) {
                    Config.delay = delayNum.doubleValue
                }
            }

        case "--debug":
            Config.debugMode = true

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
    let arguments = NSProcessInfo.processInfo().arguments as! [String]
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
        parsedFilePath = absPath ? standardPath : Config.cwd.stringByAppendingPathComponent(standardPath)
    }

    return (dashedOptions, parsedFilePath)
}

/// Prints a formatted list of devices to STDOUT
///
/// :param: devices List of devices to print.
func listDevices(devices: [AVCaptureDevice]?) {
    if devices?.isEmpty == false {
        for d in devices! {
            println("📷 \(d.localizedName) [\(d.uniqueID)]")
        }
    }
}

/// Get a default device based on the UI or otherwise, or die violently
func deviceSelect() -> AVCaptureDevice {
    if let req = Config.requestedDeviceID { // user requested a specific device
        if let matches = CamSnapper.devicesMatchingString(req) {
            if count(matches) == 1 {
                return matches.first!
            } else {
                println("Multiple input devices matched your request: \(req)")
                listDevices(matches)
                println("\n... could you please be more specific?")
                exit(1)
            }
        }

    } else {
        if let camera = CamSnapper.preferredDevice() {
            return camera
        }
    }

    // ruh roh, no camera found at all!
    println("🚫 no matching capture devices found")
    exit(13)
}

/// Runs the main capture process.
func runCapture() {
    let camera = deviceSelect()
    Logger.debug("using capture device: \(camera)")

    println("📷 lolcommits is preserving this moment in history.")
    if let rawimagedata = CamSnapper.capture(warmupDelay: Config.delay, camera: camera) {
        if let lolimage = LOLImage(data: rawimagedata) {
            lolimage.topMessage    = Config.finalSha
            lolimage.bottomMessage = Config.finalMessage

            let renderedData = lolimage.render()
            let writeSuccess = renderedData.writeToFile(Config.filePath, atomically: true)
            if !writeSuccess {
                println("ERROR: failure writing to file: \(Config.filePath)")
                exit(1)
            } else {
                Logger.debug("image successfully written to \(Config.filePath)")
            }

            // when in test mode, open the image for preview immediately
            if Config.testMode {
                NSWorkspace.sharedWorkspace().openFile(Config.filePath)
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
        Config.filePath = dfp
    }

    // process dashed options to set up global state
    // if any of those dashed options represent a terminating action, that will be
    // handled for us in this method (so there is the possibility our process will
    // exit expectedly at this point).
    processDashedOpts(dashedOptions)

    // run the "main" capture process
    runCapture()
}
main()
