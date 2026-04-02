// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NowHybrid",
    platforms: [
        .iOS(.v18),
        .macOS(.v14),
    ],
    products: [
        .library(name: "NowHybrid", targets: ["NowHybrid"]),
    ],
    dependencies: [
        .package(path: "../NowCore"),
    ],
    targets: [
        .target(
            name: "NowHybrid",
            dependencies: [
                .product(name: "NowCore", package: "NowCore"),
            ]
        ),
        .testTarget(
            name: "NowHybridTests",
            dependencies: [
                "NowHybrid",
                .product(name: "NowCore", package: "NowCore"),
            ]
        ),
    ]
)
