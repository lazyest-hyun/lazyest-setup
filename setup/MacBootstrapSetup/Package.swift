// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MacBootstrapSetup",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "MacBootstrapSetup", targets: ["MacBootstrapSetup"])
    ],
    targets: [
        .target(name: "MacBootstrapSetupCore"),
        .executableTarget(
            name: "MacBootstrapSetup",
            dependencies: ["MacBootstrapSetupCore"]
        ),
        .testTarget(
            name: "MacBootstrapSetupCoreTests",
            dependencies: ["MacBootstrapSetupCore"]
        )
    ]
)
