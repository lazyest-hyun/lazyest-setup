// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "LazyestSetup",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "LazyestSetup", targets: ["LazyestSetup"])
    ],
    targets: [
        .target(name: "LazyestSetupCore"),
        .executableTarget(
            name: "LazyestSetup",
            dependencies: ["LazyestSetupCore"]
        ),
        .testTarget(
            name: "LazyestSetupCoreTests",
            dependencies: ["LazyestSetupCore"]
        )
    ]
)
