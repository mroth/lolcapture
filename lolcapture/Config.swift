import Foundation

struct Config {
    /// Default parent destination directory for images
    static var destination = "~/Pictures/\(programName)"

    /// Default parent destination directory for images in test mode
    static var testDestination = "/tmp/\(programName)/test-captures"
    
    /// Configured delay for camera warmup during capture process.
    static var delay = 0.75
    
    /// Controls whether debug messages are logged to STDERR.
    static var debugMode = false
}
