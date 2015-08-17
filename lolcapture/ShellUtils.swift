import Foundation

/// Dealing with the shell in Swift is really annoying.  Some convenience
/// functions to make it slightly less annoying are here.
class ShellUtils {

    struct TaskResults {
        var exitcode: Int32
        var stdout: String?
        var stderr: String?
    }

    /// Execute a shell task, wait for it to complete, then return stuff we care about.
    class func doTaskWithResults(launchPath: String, args: [String]) -> TaskResults {
        let task = NSTask()
        task.launchPath = launchPath
        task.arguments = args

        let (stdoutPipe, stderrPipe) = (NSPipe(), NSPipe())
        task.standardOutput = stdoutPipe
        task.standardError = stderrPipe

        task.launch()
        task.waitUntilExit()

        let stdout = NSString(
            data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: NSUTF8StringEncoding
        ) as String?
        let stderr = NSString(
            data: stderrPipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: NSUTF8StringEncoding
        ) as String?

        return TaskResults(exitcode: task.terminationStatus, stdout: stdout, stderr: stderr)
    }

    
    // more swift-y API around a horrible Obj-C function
    class func fileExistsAtPath(path: String) -> (exists: Bool, isDirectory: Bool) {
        var isDir: ObjCBool = false
        let exists = NSFileManager().fileExistsAtPath(path, isDirectory: &isDir)
        return (exists, isDir ? true : false)
    }
    // convenience functions for the above
    /// Does a file or directory exist at a path?
    class func pathExists(path: String) -> Bool {
        let (exists, _) = fileExistsAtPath(path)
        return exists
    }
    /// Does a file (not a directory) exist at a path?
    class func pathExistsAsFile(path: String) -> Bool {
        let (exists, isDir) = fileExistsAtPath(path)
        return exists && !isDir
    }
    /// Does a directory exist at a path?
    class func pathExistsAsDirectory(path: String) -> Bool {
        let (exists, isDir) = fileExistsAtPath(path)
        return exists && isDir
    }

}
