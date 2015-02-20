import Foundation

struct Config {
    /// current working directory
    static let cwd = NSFileManager.defaultManager().currentDirectoryPath
    
    /// default file name to use when none is specified
    static let defaultFileName = "test-capture.jpg"
    
    /// the current filePath where we will write the completed image
    static var filePath: String = cwd.stringByAppendingPathComponent(defaultFileName)
    
    /// configured delay for camera warmup during capture process
    static var delay = 0.75
    
    /// testMode provides mocked default values for msg/sha if not specified on the
    /// command line, and automatically opens the final image for review in the GUI.
    static var testMode  = false
    
    /// debugMode controls whether debug messages are logged to STDERR.
    static var debugMode = false
    
    // msg/SHA to be used in test mode when nothing is parsed
    static let testMessage = "this is a test message i didnt really commit something"
    static var testSha: String {
        return NSUUID().UUIDString.componentsSeparatedByString("-")[0].lowercaseString
    }
    
    /// git message or SHA parsed from the CLI arguments
    static var parsedMessage, parsedSha: String?
    
    /**
    Message that will be used for the final image produced.
    
    Values parsed from the command line will always take precedence.
    If nothing is parsed from the command line, these will be blank,
    unless `--test` mode is specified, in which case default/random
    messages will be used. */
    static var finalMessage: String? {
        return (testMode && parsedMessage == nil) ? testMessage : parsedMessage
    }
    
    /**
    SHA that will be used for the final image produced.
    
    See `Config.finalMessage` for more details.
    */
    static var finalSha: String? {
        return (testMode && parsedSha == nil) ? testSha : parsedSha
    }
}
