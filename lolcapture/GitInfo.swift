import Foundation



class GitInfo {

    struct GitCommitInfo {
        var sha: String
        var msg: String
    }

    /// Path to where the `git` binary is installed, or `nil` if not found.
    ///
    /// For now, we only look in the default Xcode Developer Tools (`/usr/bin`)
    /// and Homebrew (`/usr/local/bin`), and don't bother to inspect the user's
    /// $PATH.  This means if the *only* version of Git that is installed is
    /// something custom, we can fail.
    static private var installedGitPath: String? = {
        for potentialLocation in ["/usr/local/bin/git", "/usr/bin/git"] {
            if ShellUtils.pathExistsAsFile(potentialLocation) {
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
    class func configInfo(section section: String) -> [String: String] {
        var config = [String: String]()
        let task = completedGitTask(["config", "-z", "--get-regexp", "^\(section)\\."])

        let stdout = task.stdout!
        let sections = stdout.componentsSeparatedByString("\u{0}") // NUL
        for section in sections {
            let lines = section.componentsSeparatedByString("\n")
            if lines.count >= 2 {
                let (k,v) = (lines[0], lines[1])
                config[k] = v
            }
        }
        Logger.debug(config.description)
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
    class func currentWorktreeRoot() -> NSURL? {
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
        return NSURL(fileURLWithPath: output)
    }

    /// returns the GIT_DIR for the currently active worktree
    class func currentWorktreeGitDir() -> NSURL? {
        if let cwtr = currentWorktreeRoot() {
            let gitdir = cwtr.URLByAppendingPathComponent(".git")
            // verify it's a directory before returning, because it could be
            // one of those annoying separate-git-dir file pointers instead
            // (in theory anyhow, I've never seen this in the wild...)
            // TODO: support separate-git-dir pointers
            if ShellUtils.pathExistsAsDirectory(gitdir.path!) {
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
