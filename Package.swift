// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SQLiteCloud",
    platforms: [
        .macOS(.v12), .iOS(.v13), .watchOS(.v7)
     ],
    products: [
        .library(
            name: "SQLiteCloud",
            targets: ["SQLiteCloud"]),
    ],
    dependencies: [
        .package(url: "https://github.com/realm/SwiftLint", from: "0.52.4")
    ],
    targets: [
        .target(
            name: "SQLiteCloud",
            dependencies: [
                .target(name: "CSQCloud")
            ], 
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ],
            plugins: [
                .plugin(name: "SwiftLintPlugin", package: "SwiftLint")
            ]
        ),
        .target(
           name: "CSQCloud",
           dependencies: ["libsqcloud"]
        ),
        .binaryTarget(
            name: "libtls",
            path: "./Sources/libtls.xcframework"
        ),
        .binaryTarget(
            name: "libsqcloud",
            path: "./Sources/libsqcloud.xcframework"
        ),
        .testTarget(
            name: "SQLiteCloudTests",
            dependencies: ["SQLiteCloud"]
        ),
    ]
)
