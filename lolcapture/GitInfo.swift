import Foundation

class GitInfo {

    class func lastCommitInfo() -> (sha: String, msg: String)? {
        let task = newGitTask(["show", "--format=%h%n%s", "--no-patch"])

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

    /// returns the root directory for the execution context's current git worktree
    class func currentWorktreeRoot() -> String? {
        let task = newGitTask(["rev-parse", "--show-toplevel"])

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
        return output.stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet())
    }

    /// returns the GIT_DIR for the currently active worktree
    class func currentWorktreeGitDir() -> String? {
        if let cwtr = currentWorktreeRoot() {
            let gitdir = cwtr.stringByAppendingPathComponent(".git")
            // verify it's a directory before returning, because it could be
            // one of those annoying separate-git-dir file pointers instead
            // (in theory anyhow, I've never seen this in the wild...)
            var isDir = ObjCBool(true)
            if NSFileManager.defaultManager().fileExistsAtPath(gitdir, isDirectory: &isDir) {
                return gitdir
            } // TODO: support separate-git-dir pointers
        }
        return nil
    }

    private class func newGitTask(args: [String]) -> NSTask {
        let task = NSTask()
        task.launchPath = findInstalledGit()! // TODO: need to handle error nicely
        task.arguments = args

        return task
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