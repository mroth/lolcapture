import Foundation

/*
Configuration library to automatically handle options that be either set via
`git config`, environment variables, preset defaults, or manually at runtime
(via CLI flags, for example), within a defined hierarchy.

Similar to git itself, the hierarchy would look like:

  Runtime > Environment > Git Config (local) > Git config (global) > Defaults

Sample of what we want to enable with this, example output of `config show`:

Git Config Key           Environment Variable  Configured Value      Source
-----------------------  --------------------  --------------------  -----------
lolcommits.destination   LOLCOMMITS_DIR        ~/Photos/lolcommits   Default
lolcommits.image-width   LOLCOMMITS_WIDTH      720                   Config
lolcommits.image-height  LOLCOMMITS_HEIGHT     480                   Config
lolcommits.warmup-delay  LOLCOMMITS_DELAY      1.5                   Environment
*/

/*
I think the way to do this with extension protocols in Swift 2.0 will be
to require some sort of uniform "Setter" signature in the protocol, and then
the extension can have a function to replace defaultTypeMapper which instead
delegates to that function??
*/

struct FancyConfig {
    static let GITCONFIG_SECTION = programName.lowercaseString
    static let ENVIRONMENT_NAMESPACE = programName.uppercaseString
    
    /// Statically cached table of all git config information for the section
    /// of this program.
    ///
    /// Only need to load once because hey, we exit entirely after we run.
    static let gitConfigInfo = GitInfo.configInfo(section: GITCONFIG_SECTION)
    
    /// The state of the shell environment upon Config instantiation.
    static let environment = NSProcessInfo.processInfo().environment
    
    class Option {
        /// The key that will uniquely identify this option.
        ///
        /// This also determines the key used for gitconfig configuration.
        let key: String
        
        /// Human readable description of what the option controls.
        let description: String
        
        /// The "stub" used to determine the environment variable.
        ///
        /// For example, a stub of `FOO` will result in a final environment
        /// variable of `PROGRAMNAME_FOO`.
        ///
        /// Optional.  If not set, the option will have no environment variable
        let envVarStub: String?
        
        /// The environment variable that can configure this Option, if present.
        ///
        /// Automatically determined based upon the ENVIRONMENT_NAMESPACE and
        /// the `envVarStub`.
        var environmentVariable: String? {
            if let evs = envVarStub {
                return "\(ENVIRONMENT_NAMESPACE)_\(evs)"
            }
            return nil
        }
        
        enum Value: CustomStringConvertible {
            case StringValue(String?)
            case DoubleValue(Double?)
            case BoolValue(Bool?)

            var description: String {
                switch self {
                case .StringValue(.Some(let v)): return v
                case .DoubleValue(.Some(let v)): return v.description
                case .BoolValue(  .Some(let v)): return v.description
                default:
                    return "<NOT SET>"
                }
            }
        }
        
        /// Where was the value for this `Option` determined from?
        enum Source: CustomStringConvertible {
            /// Manually modified at runtime from outside of this library.
            case Manual
            /// Determined from a present environment variable in the shell.
            case Environment
            /// Determined by a set git config variable.
            case GitConfig
            /// Default setting, no modifications.
            case Default

            var description: String {
                switch self {
                case .Manual:       return "Manual"
                case .Environment:  return "Environ"
                case .GitConfig:    return "Config"
                case .Default:      return "Default"
                }
            }
        }
        
        /// Default Value for the configuration
        /// also determines the type derived values will attempt to cast to
        /// A null default still must specify the type, e.g. .StringValue(nil)
        let defaultValue: Value
        
        // description goes here yay
        private var manualValue: Value? = nil
        
        /// Attempts to cast a string value to the appropriate Value type, based
        /// upon the type of the defaultValue.
        ///
        /// This is currently used in environmentValue and gitconfigValue.
        private func defaultTypeMapper(v: String?) -> Value {
            switch self.defaultValue {
            case .StringValue:
                return .StringValue(v)
            case .DoubleValue:
                if let _v = v, num = NSNumberFormatter().numberFromString(_v) {
                    return Value.DoubleValue(num.doubleValue)
                }
                return Value.DoubleValue(nil)
            case .BoolValue:
                if let _v = v {
                    return Value.BoolValue(NSString(string: _v).boolValue)
                }
                return Value.BoolValue(nil)
            }
        }
        
        /// Configured environment variable value for Option, if present.
        var environmentValue: Value? {
            if let
                key = self.environmentVariable,
                val = FancyConfig.environment[key] as? String
            {
                return defaultTypeMapper(val)
            }
            return nil
        }
        
        /// Configured gitconfig value for Option, if present.
        ///
        /// Looks for a value of `Option.key` in a gitconfig section determined
        /// by the
        var gitconfigValue: Value? {
            let qualifiedKey = GITCONFIG_SECTION + "." + self.key
            if let val = FancyConfig.gitConfigInfo[qualifiedKey] {
                return defaultTypeMapper(val)
            }
            return nil
        }
        
        /// The current value for this Option.
        ///
        /// This value is "sticky" in that if it is manually set, we will always
        /// defer to that valye.  Otherwise, getting it will fall down a cascade
        /// of potential locations for the configuration setting in precedence
        /// order.
        var _value: Value {
            get {
                return manualValue ?? environmentValue ?? gitconfigValue ?? defaultValue
            }
            set {
                // TODO: verify newValue is of same Type as defaultValue,
                // throw error otherwise
                manualValue = newValue
            }
        }

        /// Returns the source that the Option value was determined from.
        ///
        /// Use this if you want to know where the active configuration option
        /// setting came from.
        var source: Source {
            if manualValue != nil       { return .Manual }
            if environmentValue != nil  { return .Environment }
            if gitconfigValue != nil    { return .GitConfig }
            else                        { return .Default }
        }
        
        init(key: String, description: String, defaultValue: Value,
                envVarStub: String? = nil) {
            self.key = key
            self.description = description
            self.envVarStub = envVarStub
            self.defaultValue = defaultValue
        }
        
    }

    class BoolOption: Option {
        init(key: String, description: String, defaultValue: Bool?,
                envVarStub: String? = nil) {
            super.init(
                key: key, description: description,
                defaultValue: .BoolValue(defaultValue),
                envVarStub: envVarStub
            )
        }

        var value: Bool? {
            get {
                switch self._value {
                case .BoolValue(let v): return v
                default: return nil
                }
            }
            set {
                self._value = .BoolValue(newValue)
            }
        }
    }

    class DoubleOption: Option {
        init(key: String, description: String, defaultValue: Double?,
                envVarStub: String? = nil) {
            super.init(
                key: key, description: description,
                defaultValue: .DoubleValue(defaultValue),
                envVarStub: envVarStub
            )
        }

        var value: Double? {
            get {
                switch self._value {
                case .DoubleValue(let v): return v
                default: return nil
                }
            }
            set {
                self._value = .DoubleValue(newValue)
            }
        }
    }

    class StringOption: Option {
        init(key: String, description: String, defaultValue: String?,
                envVarStub: String? = nil) {
            super.init(
                key: key, description: description,
                defaultValue: .StringValue(defaultValue),
                envVarStub: envVarStub
            )
        }

        var value: String? {
            get {
                switch self._value {
                case .StringValue(let v): return v
                default: return nil
                }
            }
            set {
                self._value = .StringValue(newValue)
            }
        }
    }

}