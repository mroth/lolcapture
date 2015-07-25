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
}
