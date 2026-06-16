// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ContainerUI",
    platforms: [
        .macOS("26"),
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "ContainerUI",
            dependencies: [],
            resources: [.process("Resources")]
        )
    ]
)
