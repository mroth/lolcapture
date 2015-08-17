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

    static let imageWidth = FancyConfig.DoubleOption(
        key: "image-width",
        description: "Width of final image in pixels",
        defaultValue: 960.0,
        envVarStub: "WIDTH")

    static let imageHeight = FancyConfig.DoubleOption(
        key: "image-height",
        description: "Height of final image in pixels",
        defaultValue: 720.0,
        envVarStub: "HEIGHT")

    static let hookForPostCapture = FancyConfig.StringOption(
        key: "post-hook",
        description: "Plugin hook to run postcapture",
        defaultValue: nil,
        envVarStub: nil)

    /// config options we should show the user in the default UI
    static let exposedOpts = [destination, delay, imageWidth, imageHeight, hookForPostCapture]
}
