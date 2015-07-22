import Foundation
import AVFoundation
import AppKit

class CaptureCommand {

    static let usageCommandDescription = "Captures an image for the most recent git commit."
    static let usageCommandSignature = "Usage: \(programName) capture [options] <destination>"
    static let usageCommandOptions = "\n".join([
        "Options:",
        "  -l, --list           List available capture devices and exit",
        "  --device=ID          Use specified capture device (matches name or id)",
        "  --test               Create fake msg/SHA values when none provided",
        "  --msg=MSG            Message to be displayed across bottom of image",
        "  --sha=SHA            Hash to be displayed on top right of image",
        "  --warmup=N           Delay capture by N seconds (default: \(Config.delay))"
    ])

    class func usage() -> String {
        return "\n\n".join([
            usageCommandSignature,
            usageCommandDescription,
            usageCommandOptions,
            usageGlobalOptions
            ])
    }

    class func printUsage() {
        println(usage())
    }

    /// dervied values related to the capture command options
    struct Options {
        /// Provide mocked default values for metadata if not specified on the
        /// command line, and automatically open final image for review in the GUI.
        static var testMode  = false

        // metadata to be used in test mode when nothing is parsed
        static let testDefaultMessage = "this is a test message i didnt really commit something"
        static var testDefaultSha: String {
            return NSUUID().UUIDString.componentsSeparatedByString("-")[0].lowercaseString
        }

        /// Provided sha/msg parsed from the command line arguments
        /// If passed, these should always be the first source of truth and
        /// will override anything found
        static var parsedMessage, parsedSha: String?

        /// Git repository sha/msg for last commit
        /// May be nil if not in a repository with current commits
        static var gitMessage, gitSha: String?

        /// Message that will be used for the final image produced.
        ///
        /// Values parsed from the command line will always take precedence.
        /// If nothing is parsed from the command line, these will be blank,
        /// unless `--test` mode is specified, in which case default/random
        /// messages will be used.
        static var finalMessage: String? {
            if parsedMessage != nil { return parsedMessage }
            if testMode             { return testDefaultMessage }
            return gitMessage
        }

        /// SHA that will be used for the final image produced.
        ///
        /// See `Config.finalMessage` for more details.
        static var finalSha: String? {
            if parsedSha != nil     { return parsedSha }
            if testMode             { return testDefaultSha }
            return gitSha
        }

        /// Manually specified device ID by the user
        static var requestedDeviceID: String?
    }

    /// Process dashed options for the CLI
    ///
    /// Mostly these modify the global state for the application process, however
    /// certain options are actually mapped to actions that exit the process after
    /// completing.
    ///
    /// :param: opts all dashed options parsed from the command line
    private class func processOpts(opts: [String]) {
        for opt in opts {
            let splitArg = opt.componentsSeparatedByString("=")
            var argkey: String  = splitArg[0]
            var argval: String? = splitArg.count > 1 ? splitArg[1] : nil

            switch argkey {
            case "-h", "--help":
                printUsage()
                exit(0)
            case "-l", "--list":
                listDevices(CamSnapper.compatibleDevices())
                exit(0)
            case "--device":
                Options.requestedDeviceID = argval
            case "-t", "--test":
                Options.testMode = true
            case "--msg":
                Options.parsedMessage = argval
            case "--sha":
                Options.parsedSha = argval
            case "--warmup":
                if let delayStr = argval {
                    if let delayNum = NSNumberFormatter().numberFromString(delayStr) {
                        Config.delay = delayNum.doubleValue
                    }
                }

            // ignore flags that are already handled globally
            case "--debug":
                break
            // otherwise, if we don't recognize it we should inform the user
            default:
                println("Unknown option: \(opt)\n")
                printUsage()
                exit(1)
            }
        }
    }

    /// Process the git info for the current repository, setting command variables
    /// as necessary.
    private class func processGitInfo() {
        if let gci = GitInfo.lastCommitInfo() {
            Options.gitSha     = gci.sha
            Options.gitMessage = gci.msg
        }
    }

    private class func destinationFilePath() -> String? {
        // MAYBE there is a destination file path specific by user
        // if so with current CLI structure it should be in r_argv[2]
        if r_argc >= 3 {
            let parsedFileName = r_argv[2]

            // standardize the path to remove all junk
            let standardPath = NSString(string: parsedFileName).stringByStandardizingPath

            // if not an absolute path, prepend the current working directory
            let absPath = NSString(string: parsedFileName).absolutePath
            let parsedFilePath = absPath ? standardPath : Config.cwd.stringByAppendingPathComponent(standardPath)

            return parsedFilePath
        }
        return nil
    }

    /// Prints a formatted list of devices to STDOUT
    ///
    /// :param: devices List of devices to print.
    class func listDevices(devices: [AVCaptureDevice]?) {
        if devices?.isEmpty == false {
            for d in devices! {
                println("📷 \(d.localizedName) [\(d.uniqueID)]")
            }
        }
    }

    /// Get a default device based on the UI or otherwise, or die violently
    private class func deviceSelect() -> AVCaptureDevice {
        if let req = Options.requestedDeviceID { // user requested a specific device
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

        } else if let camera = CamSnapper.preferredDevice() {
            return camera
        }

        // ruh roh, no camera found at all!
        println("🚫 no matching capture devices found")
        exit(13)
    }

    /// Runs the main capture process.
    class func run() {
        // process dashed options to set up global state before command
        // if any of those dashed options represent a terminating action, that will be
        // handled for us in this method (so there is the possibility our process will
        // exit expectedly at this point).
        processOpts(optv)

        // process git info for repository
        processGitInfo()

        // see if the user specified an alternate destination for the file
        if let dfp = destinationFilePath() {
            Config.filePath = dfp
        }

        let camera = deviceSelect()
        Logger.debug("using capture device: \(camera)")

        println("📷 \(programName) is preserving this moment in history.")
        if let rawimagedata = CamSnapper.capture(warmupDelay: Config.delay, camera: camera) {
            if let lolimage = LOLImage(data: rawimagedata) {
                lolimage.topMessage    = Options.finalSha
                lolimage.bottomMessage = Options.finalMessage

                let renderedData = lolimage.render()
                let writeSuccess = renderedData.writeToFile(Config.filePath, atomically: true)
                if !writeSuccess {
                    println("ERROR: failure writing to file: \(Config.filePath)")
                    exit(1)
                } else {
                    Logger.debug("image successfully written to \(Config.filePath)")
                }

                // when in test mode, open the image for preview immediately
                if Options.testMode {
                    NSWorkspace.sharedWorkspace().openFile(destination)
                }

                // we're done, exit successfully
                exit(0)
            } else {
                println("ERROR: Didn't understand the image data we got back from camera.")
                exit(1)
            }
        } else {
            println("ERROR: Unable to capture image from camera for some reason.")
            exit(1)
        }
    }

}
