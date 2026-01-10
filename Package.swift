// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "MirageKit",
    platforms: [
        .iOS(.v16),
        .watchOS(.v9),
        .tvOS(.v17),
        .macOS(.v13)
    ],
    products: [
        .library(name: "MirageCore", targets: ["MirageCore"]),
        .library(name: "MirageUI", targets: ["MirageUI"])
    ],
    targets: [
        .target(
            name: "MirageCore",
            path: "Sources/MirageCore"
        ),
        .testTarget(
            name: "MirageCoreTests",
            dependencies: ["MirageCore"],
            path: "Tests/MirageCoreTests"
        ),
        .target(
            name: "MirageUI",
            dependencies: ["MirageCore"],
            path: "Sources/MirageUI"
        )
    ]
)
