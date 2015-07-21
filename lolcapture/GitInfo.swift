import Foundation

struct GitCommitInfo {
    var sha: String
    var msg: String
}

class GitInfo {

    /// return key-value pairs for a git config section
    class func configInfo(section: String = "lolcommits") -> [String: String] {
        var config = [String: String]()

        let task = newGitTask(["config", "-z", "--get-regexp", "^\(section)\\."])
        let results = NSPipe()
        task.standardOutput = results
        task.launch()
        task.waitUntilExit()

        let data = results.fileHandleForReading.readDataToEndOfFile()
        let output = NSString(data: data, encoding: NSUTF8StringEncoding) as! String
        let sections = output.componentsSeparatedByString("\u{0}") // NUL
        for section in sections {
            let lines = section.componentsSeparatedByString("\n")
            if count(lines) >= 2 {
                let (k,v) = (lines[0], lines[1])
                config[k] = v
            }
        }
        return config
    }

    /// returns info about the most recent commit for the repository
    ///
    /// can be nil if not in an active repo
    class func lastCommitInfo() -> GitCommitInfo? {
        let task = newGitTask(["show", "--format=%h%n%s", "--no-patch"])
        let results = NSPipe()
        task.standardOutput = results
        task.launch()
        task.waitUntilExit()

        // check exit code, return nil if nonzero
        if task.terminationStatus != 0 {
            return nil
            // TODO: in Swift 2, we can use exceptions for a failure with this
            // method instead of returning nil in an optional, good practice?
        }

        let data = results.fileHandleForReading.readDataToEndOfFile()
        let output = NSString(data: data, encoding: NSUTF8StringEncoding) as! String
        let lines = output.componentsSeparatedByString("\n")
        Logger.debug("got git info from system call: \(lines)")
        return GitCommitInfo(sha: lines[0], msg: lines[1])
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
            // TODO: support separate-git-dir pointers
            var isDir = ObjCBool(true)
            if NSFileManager.defaultManager().fileExistsAtPath(gitdir, isDirectory: &isDir) {
                return gitdir
            }
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
