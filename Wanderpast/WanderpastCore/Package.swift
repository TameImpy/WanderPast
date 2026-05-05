// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WanderpastCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "WanderpastCore", targets: ["WanderpastCore"]),
    ],
    targets: [
        .target(name: "WanderpastCore"),
        .testTarget(name: "WanderpastCoreTests", dependencies: ["WanderpastCore"]),
    ]
)
