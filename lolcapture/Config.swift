import Foundation

struct Config {
    /// current working directory
    /// TODO: this should be refactored out of config
    static let cwd = NSFileManager.defaultManager().currentDirectoryPath
    
    /// Default file name to use when none is specified.
    static let defaultFileName = "snapshot.jpg"
    
    /// Current filePath where we will write the completed image.
    /// TODO: implement default destination folder
    static var filePath: String = cwd.stringByAppendingPathComponent(defaultFileName)
    
    /// Configured delay for camera warmup during capture process.
    static var delay = 0.75
    
    /// Controls whether debug messages are logged to STDERR.
    static var debugMode = false
}
