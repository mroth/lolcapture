import Foundation
import AVFoundation
import AppKit

class CaptureCommand {

    static let usageCommandDescription = "Captures an image for the most recent git commit."
    static let usageCommandSignature = "Usage: \(programName) capture [options] <destination>"
    static let usageCommandOptions = [
        "Options:",
        "  -l, --list           List available capture devices and exit",
        "  --device=ID          Use specified capture device (matches name or id)",
        "  --test               Create fake msg/SHA values when none provided",
        "  --msg=MSG            Message to be displayed across bottom of image",
        "  --sha=SHA            Hash to be displayed on top right of image",
        "  --warmup=N           Delay capture by N seconds (default: \(Config.delay))"
    ].joinWithSeparator("\n")

    class func usage() -> String {
        return [
            usageCommandSignature,
            usageCommandDescription,
            usageCommandOptions,
            usageGlobalOptions
            ].joinWithSeparator("\n\n")
    }

    class func printUsage() {
        print(usage())
    }

    /// dervied values related to the capture command options
    struct Options {
        /// Provide mocked default values for metadata if not specified on the
        /// command line, and automatically open final image for review in the GUI.
        static var testMode = false

        // metadata to be used in test mode when nothing is parsed
        static let testDefaultMessage =
            "this is a test message i didnt really commit something"
        static let testDefaultSha =
            NSUUID().UUIDString.componentsSeparatedByString("-")[0].lowercaseString


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

        /// Destination that was (maybe) manually specified on the command line
        ///
        /// Normalizes both relative and absolute paths.
        static var parsedDestinationFilePath: String? {
            // MAYBE there is a destination file path specific by user
            // if so with current CLI structure it should be in r_argv[2]
            if Opts.args.endIndex >= 3 {
                let parsedFileName = Opts.args[2]

                // standardize the path to remove all junk
                let standardPath = NSString(string: parsedFileName).stringByStandardizingPath

                // if not an absolute path, prepend the current working directory
                let absPath = NSString(string: parsedFileName).absolutePath
                let cwd = NSFileManager.defaultManager().currentDirectoryPath
                let parsedFilePath = absPath ? standardPath : cwd.stringByAppendingPathComponent(standardPath)
                return parsedFilePath
            }
            return nil
        }

        /// Best guess at the name of the git repository. For now, this is just
        /// the basename of its worktree root.
        static private var gitRepoName = GitInfo.currentWorktreeRoot()?.pathComponents.last

        /// Subdirectory within the destination where we will place the image file
        static private var derivedDestinationContainerDir = gitRepoName ?? "uncategorized"

        /// Derived destination directory based on options/config combo.
        ///
        /// May end up being overriden by a CLI parsed destination.
        static private var derivedDestination: String {
            let dir = testMode ? Config.testDestination.value! : Config.destination.value!
            return dir.stringByExpandingTildeInPath
                      .stringByAppendingPathComponent(derivedDestinationContainerDir)
        }

        /// Derived filename to use when writing image.
        ///
        /// Normally this will be `[SHA].jpg` (including autogenerated SHAs in
        /// testmode), but in some permutations it's possible we won't have one.
        ///
        /// May end up being overriden by a CLI parsed destination.
        static private var derivedFileName: String {
            return (finalSha ?? "snapshot").stringByAppendingPathExtension("jpg")!
        }

        /// Derived destination file path where we will write the file, as long
        /// as we are not overriden by a CLI parsed manual destination.
        static private var derivedDestinationFilePath: String {
           return derivedDestination.stringByAppendingPathComponent(derivedFileName)
        }

        /// Actual destination file path where we will attempt to write
        static var finalDestinationFilePath: String {
            return parsedDestinationFilePath ?? derivedDestinationFilePath
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
    /// - parameter opts: all dashed options parsed from the command line
    private class func processOpts(opts: [String]) {
        for opt in opts {
            let splitArg = opt.componentsSeparatedByString("=")
            let argkey: String  = splitArg[0]
            let argval: String? = splitArg.count > 1 ? splitArg[1] : nil

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
                        Config.delay.value = delayNum.doubleValue
                    }
                }

            // ignore flags that are already handled globally
            case "--debug":
                break
            // otherwise, if we don't recognize it we should inform the user
            default:
                print("Unknown option: \(opt)\n")
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

    /// Prints a formatted list of devices to STDOUT
    ///
    /// - parameter devices: List of devices to print.
    class func listDevices(devices: [AVCaptureDevice]?) {
        if devices?.isEmpty == false {
            for d in devices! {
                print("📷 \(d.localizedName) [\(d.uniqueID)]")
            }
        }
    }

    /// Get a default device based on the UI or otherwise, or die violently
    private class func deviceSelect() -> AVCaptureDevice {
        if let req = Options.requestedDeviceID { // user requested a specific device
            if let matches = CamSnapper.devicesMatchingString(req) {
                if matches.count == 1 {
                    return matches.first!
                } else {
                    print("Multiple input devices matched your request: \(req)")
                    listDevices(matches)
                    print("\n... could you please be more specific?")
                    exit(1)
                }
            }

        } else if let camera = CamSnapper.preferredDevice() {
            return camera
        }

        // ruh roh, no camera found at all!
        print("🚫 no matching capture devices found")
        exit(13)
    }

    /// If a post-capture plugin has been configured, run it.
    ///
    /// The environment will be configured to have a number of helpful variables
    /// and the filepath of the captured image will be the first argument.
    private class func runPostcaptureHookIfConfigured() {
        if let hook = Config.hookForPostCapture.value {
            print("🔩 running postcapture hook: \(hook.lastPathComponent)")
            Logger.debug("going to run plugin: \(hook)")
            let NAMESPACE = programName.uppercaseString

            let task = NSTask()
            task.launchPath = hook
            task.environment = [
                "\(NAMESPACE)_COMMIT_MSG":  Options.finalMessage ?? "",
                "\(NAMESPACE)_COMMIT_SHA":  Options.finalSha ?? "",
                "\(NAMESPACE)_REPO_NAME":   Options.derivedDestinationContainerDir,
                "\(NAMESPACE)_IMAGE":       Options.finalDestinationFilePath
            ]
            task.arguments = [Options.finalDestinationFilePath]
            task.launch()
            task.waitUntilExit()
            Logger.debug("plugin completed - status \(task.terminationStatus)")
        }
    }

    /// Runs the main capture process.
    class func run() {
        // process dashed options to set up global state before command
        // if any of those dashed options represent a terminating action, that will be
        // handled for us in this method (so there is the possibility our process will
        // exit expectedly at this point).
        processOpts(Opts.flags)

        // process git info for repository
        processGitInfo()

        let camera = deviceSelect()
        Logger.debug("using capture device: \(camera)")

        print("📷 \(programName) is preserving this moment in history…")
        if let rawimagedata = CamSnapper.capture(Config.delay.value!, camera: camera) {
            if let lolimage = LOLImage(data: rawimagedata) {

                lolimage.topMessage    = Options.finalSha
                lolimage.bottomMessage = Options.finalMessage

                if let cw  = Config.imageWidth.value, ch = Config.imageHeight.value {
                    lolimage.desiredFinalWidth = CGFloat(cw)
                    lolimage.desiredFinalHeight = CGFloat(ch)
                }

                // render the composited LOLimage
                let renderedData = lolimage.render()
                let destination = Options.finalDestinationFilePath

                // create any needed intermediate directories for the destination
                let parent = destination.stringByDeletingLastPathComponent
                let success: Bool
                do {
                    try NSFileManager().createDirectoryAtPath(
                                      parent, withIntermediateDirectories: true, attributes: nil)
                    success = true
                } catch _ {
                    success = false
                }
                Logger.debug("Making sure intermediate directories are present: \(success)")

                // actually write the file
                let writeSuccess = renderedData.writeToFile(destination, atomically: true)
                if !writeSuccess {
                    print("ERROR: failure writing to file: \(destination)")
                    exit(1)
                } else {
                    print("✅ image written to \(destination)")
                    runPostcaptureHookIfConfigured()

                    Logger.debug("image successfully written to \(destination)")
                }

                // when in test mode, open the image for preview immediately
                if Options.testMode {
                    NSWorkspace.sharedWorkspace().openFile(destination)
                }

                // we're done, exit successfully
                exit(0)
            } else {
                print("ERROR: Didn't understand the image data we got back from camera.")
                exit(1)
            }
        } else {
            print("ERROR: Unable to capture image from camera for some reason.")
            exit(1)
        }
    }

}
