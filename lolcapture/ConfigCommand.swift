import Foundation

extension String {
    /// Truncates the string to length number of chars & appends "…" if longer
    func truncate(length: Int) -> String {
        if self.characters.count > length {
            return self.substringToIndex(self.startIndex.advancedBy(length-1)) + "…"
        } else {
            return self
        }
    }

    /// Like Ruby ljust plus truncation if over length
    func ljust(width: Int) -> String {
        let length = self.characters.count
        if length >= width {
            return self.truncate(width)
        } else {
            let ccount = width - length
            return self + String(count: ccount, repeatedValue: Character(" "))
        }
    }
}

class ConfigCommand {

    class func run() {
        // TODO: process options
        // punting on this for now to avoid boilerplate code, hopefully can wait
        // and see if I am going to adopt SwiftCLI or just roll my own class
        // based system

        // yep, magic numbers!
        // just doing these manually for now since I control all possible options...
        // yeah I know that's hacky
        let spacer    = "  "
        let maxLen    = 80
        let maxKeyLen = 23
        let maxEnvLen = 20
        let maxSrcLen = 8
        let maxValLen = maxLen - (maxKeyLen+maxEnvLen+maxSrcLen) - spacer.characters.count*3

        print([
            "Config Key".ljust(maxKeyLen),
            "Environment Variable".ljust(maxEnvLen),
            "Configured Value".ljust(maxValLen),
            "Source".ljust(maxSrcLen)
            ].joinWithSeparator(spacer))

        print([
            String(count: maxKeyLen, repeatedValue: Character("-")),
            String(count: maxEnvLen, repeatedValue: Character("-")),
            String(count: maxValLen, repeatedValue: Character("-")),
            String(count: maxSrcLen, repeatedValue: Character("-"))
            ].joinWithSeparator(spacer))

        for opt in Config.exposedOpts {
            let key = "\(FancyConfig.GITCONFIG_SECTION).\(opt.key)".ljust(maxKeyLen)
            let env = (opt.environmentVariable ?? "").ljust(maxEnvLen)
            let val = opt._value.description.ljust(maxValLen)
            let src = opt.source.description.ljust(maxSrcLen)
            print([key, env, val, src].joinWithSeparator(spacer))
        }
    }
}