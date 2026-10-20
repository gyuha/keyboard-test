// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "KeyTest",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "KeyTestCore"),
        .executableTarget(name: "KeyTest", dependencies: ["KeyTestCore"]),
        .executableTarget(name: "keytest-checks", dependencies: ["KeyTestCore"]),
    ]
)
