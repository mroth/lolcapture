import Foundation

struct Logger {
    /// Log a debug message to STDERR if DEBUG_MODE=true.
    static func debug(msg: String, file: String = __FILE__, line: Int = __LINE__, method: String = __FUNCTION__) {
        if DEBUG_MODE {
            let stderr = NSFileHandle.fileHandleWithStandardError()

            //let id = "\(file.lastPathComponent):\(line) - \(method)"
            let id = "\(method)"
            let debugStr = "DEBUG[\(id)]: \(msg)\n"
            stderr.writeData( debugStr.dataUsingEncoding(NSUTF8StringEncoding)! )
        }
    }
}
