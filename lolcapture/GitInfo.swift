import Foundation

class GitInfo {
    
    class func parseFromSystem() -> (sha: String, msg: String)? {
        let task = NSTask()
        task.launchPath = findInstalledGit()! // TODO: need to handle error nicely
        task.arguments = ["show", "--format=%h%n%s", "--no-patch"]
        
        let results = NSPipe()
        task.standardOutput = results
        task.launch()
        
        // check exit code, return nil if nonzero
        task.waitUntilExit()
        if task.terminationStatus != 0 {
            return nil
            // TODO: in Swift 2, we can use exceptions for a failure with this
            // method instead of returning nil in an optional, good practice?
        }
        
        let data = results.fileHandleForReading.readDataToEndOfFile()
        let output = NSString(data: data, encoding: NSUTF8StringEncoding) as! String
        let lines = output.componentsSeparatedByString("\n")
        Logger.debug("got git info from system call: \(lines)")
        return (lines[0], lines[1])
    }
    
    /// returns the path to where we think git is, or nil if not found
    private class func findInstalledGit() -> String? {
        let fm = NSFileManager.defaultManager()
        var isDir = ObjCBool(false)
        for potentialLocation in ["/usr/local/bin/git", "/usr/bin/git"] {
            if fm.fileExistsAtPath(potentialLocation, isDirectory: &isDir) {
                Logger.debug("found git binary at \(potentialLocation)")
                return potentialLocation
            }
        }
        return nil
    }
    
}
