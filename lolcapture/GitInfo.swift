import Foundation



class GitInfo {

    struct GitCommitInfo {
        var sha: String
        var msg: String
    }

    /// the path to where we think git is, or nil if not found
    static private var installedGitPath: String? = {
        let fm = NSFileManager.defaultManager()
        var isDir = ObjCBool(false)
        for potentialLocation in ["/usr/local/bin/git", "/usr/bin/git"] {
            if fm.fileExistsAtPath(potentialLocation, isDirectory: &isDir) {
                Logger.debug("found git binary at \(potentialLocation)")
                return potentialLocation
            }
        }
        // this will probably result in a fatal error later on, but don't die
        // until we *really* need git for something.
        Logger.debug("WARNING: could not find installed git!")
        return nil
    }()

    /// return key-value pairs for a git config section
    class func configInfo(section: String = "lolcommits") -> [String: String] {
        var config = [String: String]()
        let task = completedGitTask(["config", "-z", "--get-regexp", "^\(section)\\."])

        let stdout = task.stdout!
        let sections = stdout.componentsSeparatedByString("\u{0}") // NUL
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
        let task = completedGitTask(["show", "--format=%h%n%s", "--no-patch"])

        // check exit code, return nil if nonzero
        // TODO: in Swift 2, we can use exceptions for a failure with this
        // method instead of returning nil in an optional, good practice?
        if task.exitcode != 0 {
            Logger.debug("attempt to get repo gitinfo was nonzero exit")
            return nil
        }

        let output = task.stdout!
        let lines = output.componentsSeparatedByString("\n")
        Logger.debug("got git info from system call: \(lines)")
        return GitCommitInfo(sha: lines[0], msg: lines[1])
    }

    /// returns the root directory for the execution context's current git worktree
    class func currentWorktreeRoot() -> String? {
        let task = completedGitTask(["rev-parse", "--show-toplevel"])

        // check exit code, return nil if nonzero
        // TODO: in Swift 2, we can use exceptions for a failure with this
        // method instead of returning nil in an optional, good practice?
        if task.exitcode != 0 {
            Logger.debug("attempt to get git worktree root was nonzero exit")
            return nil
        }

        let output = task.stdout!.stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet())
        Logger.debug("got git worktree root from system call: \(output)")
        return output
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

    private class func completedGitTask(args: [String]) -> ShellUtils.TaskResults {
        let path = installedGitPath! // TODO: need to handle error nicely
        return ShellUtils.doTaskWithResults(path, args: args)
    }

}
