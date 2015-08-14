import Foundation

struct Config {
    static let destination = FancyConfig.StringOption(
        key: "destination",
        description: "Parent destination directory for images",
        defaultValue: "~/Pictures/\(programName)",
        envVarStub: "DIR")

    static let testDestination = FancyConfig.StringOption(
        key: "test-destination",
        description: "Parent destination directory for images",
        defaultValue: "/tmp/\(programName)/test-captures",
        envVarStub: "TESTDIR")

    static let delay = FancyConfig.DoubleOption(
        key: "warmup-delay",
        description: "Delay (in seconds) for camera warmup during capture",
        defaultValue: 0.75,
        envVarStub: "DELAY")

//    static let debugMode = FancyConfig.BoolOption(
//        key: "debug-mode",
//        description: "Controls whether debug messages are logged to STDERR",
//        defaultValue: false,
//        envVarStub: "DEBUG")

    /// config options we should show the user in the default UI
    static let exposedOpts = [destination, delay]
}
