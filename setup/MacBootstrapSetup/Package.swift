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
        .executableTarget(name: "MacBootstrapSetup")
    ]
)
