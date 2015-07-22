import Foundation

let programName     = "lolcapture"
let programVersion  = "0.0.3"
var programIdentifier: String {
    return "\(programName) \(programVersion)"
}

// yep, these are globally scoped. this is intentional to keep me from
// overengineering this unnecessarily.  deal with it.
// system arguments
let argv = NSProcessInfo.processInfo().arguments as! [String]
let argc = count(argv)
// options
let optv = argv.filter({$0.hasPrefix("-")})
let optc = count(optv)
// "real" arguments (options/parmams omitted)
let r_argv = argv.filter({!$0.hasPrefix("-")})
let r_argc = count(r_argv)


let usageGlobalDescription = "Experimental one-step webcam capture and text composition for lolcommits."
let usageGlobalSignature   = "Usage: \(programName) <command> [-hv]"
let usageGlobalCommands = "\n".join([
    "Commands:",
    "  enable*              Enables \(programName) for current repository",
    "  disable*             Disable \(programName) for current repository",
    "  capture              Captures an image for the most recent git commit",
    "  browse*              Opens a previous \(programName) image for review",
    "  config*              Displays current configuration values",
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

func printUsage() {
    println(usage())
}

/// Process global options for the CLI
///
/// Mostly these modify the global state for the application process
func processGlobalOpts(opts: [String]) {
    for opt in opts {
        switch opt {
        case "-v", "--version":
            println(programIdentifier)
            exit(0)
        case "--debug":
            Config.debugMode = true
        default:
            break
        }
    }
}


func parseCommand() -> String? {
    if r_argc > 1 {
        return r_argv[1].lowercaseString
    }
    return nil
}

func pending() {
    // TODO: remove me when no longer needed!
    println("not yet implemented!")
    exit(666)
}

func main() {
    processGlobalOpts(optv)

    if let cmd = parseCommand() {
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
            //println(GitInfo.configInfo(section: "core"))
            pending()
        case "help": // undocumented, but we should respect it if the user needs help...
            printUsage()
            exit(0)
        default:
            // before we complain the user typed an unknown command, perhaps they wanted help in yet another way!
            if contains(optv, "-h") || contains(optv, "--help") {
                printUsage()
                exit(0)
            }

            println("unknown command: \(cmd)")
            printUsage()
            exit(1)
        }
    } else { // no command specified at CLI
        printUsage()
        exit(1)
    }

}

main()
