// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MacBootstrapAgent",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "MacBootstrapAgent", targets: ["MacBootstrapAgent"]),
        .executable(name: "MacBootstrapSetup", targets: ["MacBootstrapSetup"])
    ],
    targets: [
        .executableTarget(name: "MacBootstrapAgent"),
        .executableTarget(name: "MacBootstrapSetup")
    ]
)
