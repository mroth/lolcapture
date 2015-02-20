import Foundation

struct Logger {
    
    /// Log a debug message to STDERR if DEBUG_MODE=true.
    static func debug(group: String, _ msg: String) {
        if Config.debugMode {
            let stderr = NSFileHandle.fileHandleWithStandardError()
            let debugStr = "DEBUG[\(group)]:\t\(msg)\n"
            stderr.writeData( debugStr.dataUsingEncoding(NSUTF8StringEncoding)! )
        }
    }
}
