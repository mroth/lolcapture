import Foundation

struct Logger {
    /// Log a debug message to STDERR if DEBUG_MODE=true.
    static func debug(msg: String, file: String = #file, line: Int = #line, method: String = #function) {
        if DEBUG_MODE {
            let stderr = NSFileHandle.fileHandleWithStandardError()

            //let id = "\(file.lastPathComponent):\(line) - \(method)"
            let id = "\(method)"
            let debugStr = "DEBUG[\(id)]: \(msg)\n"
            stderr.writeData( debugStr.dataUsingEncoding(NSUTF8StringEncoding)! )
        }
    }
}
