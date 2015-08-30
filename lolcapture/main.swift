import Foundation

let programName     = "lolcapture"
let programVersion  = "0.0.3"
var programIdentifier: String {
    return "\(programName) \(programVersion)"
}

// we need debug mode to be tracked outside of everything else, if we want to
// be able to use it debug configuration etc!
var DEBUG_MODE = false

// yep, these are globally scoped. this is intentional to keep me from
// overengineering this unnecessarily.  deal with it.
struct Opts {
    static private let argv = NSProcessInfo.processInfo().arguments as! [String]

    static var flags = argv.filter({ $0.hasPrefix("-")})
    static let args  = argv.filter({!$0.hasPrefix("-")})

    static var primaryCommand: String? {
        return count(args) > 1 ? args[1].lowercaseString : nil
    }

}


let usageGlobalDescription = "Experimental one-step webcam capture and text composition for lolcommits."
let usageGlobalSignature   = "Usage: \(programName) <command> [-hv]"
let usageGlobalCommands = "\n".join([
    "Commands:",
    "  enable*              Enables \(programName) for current repository",
    "  disable*             Disable \(programName) for current repository",
    "  capture              Captures an image for the most recent git commit",
    "  browse*              Opens a previous \(programName) image for review",
    "  config               Displays current configuration values and exits",
    "\n* = not yet implemented"
])
let usageGlobalOptions = "\n".join([
    "Global options:",
    "  -h, --help           Show this help message and exit",
    "  -v, --version        Show the \(programName) version and exit",
    "  --debug              Enable DEBUG output"
])

func usage() -> String {
    return "\n\n".join([
        usageGlobalSignature,
        usageGlobalCommands,
        usageGlobalOptions,
        "Use `\(programName) [command] --help` for more information about a command."
    ])
}
func printUsage() { println(usage()) }


func processGlobalOpts(opts: [String]) {
    for opt in opts {
        switch opt {
        case "-h", "--help":
            printUsage()
            exit(0)
        case "-v", "--version":
            println(programIdentifier)
            exit(0)
        case "--debug":
            DEBUG_MODE = true
        default:
            break
        }
    }
}


func pending() {
    // TODO: remove me when no longer needed!
    println("⚠️  UNDER CONSTRUCTION ...not yet implemented! ⚠️")
    exit(666)
}



func main() {
    processGlobalOpts(Opts.flags) //TODO: have all consumed ops swallowed so can be passed long

    if let cmd = Opts.primaryCommand {
        switch cmd {
        case "enable":
            pending()
        case "disable":
            pending()
        case "capture":
            CaptureCommand.run()
        case "browse":
            pending()
        case "config":
            ConfigCommand.run()
        case "help": // undocumented, but we should respect it if the user needs help...
            printUsage()
            exit(0)
        default:
            println("unknown command: \(cmd)")
            printUsage()
            exit(1)
        }
    } else {
        defaultCommand()
    }

}

// no command was specified at CLI
func defaultCommand() {
    // first we check if we are being called via git-exec (i.e. a git hook)
    // if so, we'll want to go ahead and do a default mode capture
    //
    // (this allows us to install ourselves as a githook without any wrapper
    //  scripts to specify options, yay!)
    func parentProcessName() -> String? {
        let ppid = getppid()
        Logger.debug("ppid: \(ppid), checking for name")

        // shell out to get name for process, sigh...
        // seems to be no way to get proc_name for given pid in cocoa?
        let ps = ShellUtils.doTaskWithResults("/bin/ps", args: ["-co", "command=", "-p", "\(ppid)"])
        return ps.stdout?.stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet())
    }
    if let ppname = parentProcessName() where ppname == "git" {
        println("parent is: \(ppname) (!)")
        println("in the future we will execute an automatic capture process at this time")
        pending()
    }

    // otherwise, remind the user of possible commands
    printUsage()
    exit(1)
}

main()
