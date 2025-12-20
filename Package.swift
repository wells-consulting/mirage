// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Mirage",
    platforms: [
        .iOS(.v16),
        .watchOS(.v9),
        .tvOS(.v17),
        .macOS(.v13)
    ],
    products: [
        .library(name: "Mirage", targets: ["Mirage"]),
        .library(name: "MirageUI", targets: ["MirageUI"])
    ],
    targets: [
        .target(
            name: "Mirage",
            path: "Sources/Mirage"
        ),
        .testTarget(
            name: "MirageTests",
            dependencies: ["Mirage"],
            path: "Tests/MirageTests"
        ),
        .target(
            name: "MirageUI",
            dependencies: ["Mirage"],
            path: "Sources/MirageUI"
        )
    ]
)
