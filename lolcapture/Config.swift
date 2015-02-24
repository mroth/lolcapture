import Foundation

struct Config {
    /// Current working directory.
    static let cwd = NSFileManager.defaultManager().currentDirectoryPath
    
    /// Default file name to use when none is specified.
    static let defaultFileName = "test-capture.jpg"
    
    /// Current filePath where we will write the completed image.
    static var filePath: String = cwd.stringByAppendingPathComponent(defaultFileName)
    
    /// Configured delay for camera warmup during capture process.
    static var delay = 0.75
    
    /// Provide mocked default values for metadata if not specified on the
    /// command line, and automatically open final image for review in the GUI.
    static var testMode  = false
    
    /// Controls whether debug messages are logged to STDERR.
    static var debugMode = false
    
    // metadata to be used in test mode when nothing is parsed
    static let testMessage = "this is a test message i didnt really commit something"
    static var testSha: String {
        return NSUUID().UUIDString.componentsSeparatedByString("-")[0].lowercaseString
    }
    
    /// Provided git metadata parsed from the command line arguments.
    static var parsedMessage, parsedSha: String?

    /// Message that will be used for the final image produced.
    ///
    /// Values parsed from the command line will always take precedence.
    /// If nothing is parsed from the command line, these will be blank,
    /// unless `--test` mode is specified, in which case default/random
    /// messages will be used.
    static var finalMessage: String? {
        return (testMode && parsedMessage == nil) ? testMessage : parsedMessage
    }

    /// SHA that will be used for the final image produced.
    ///
    /// See `Config.finalMessage` for more details.
    static var finalSha: String? {
        return (testMode && parsedSha == nil) ? testSha : parsedSha
    }
}
