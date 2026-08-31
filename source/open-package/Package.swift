// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OpenPackage",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "OpenPackage", targets: ["OpenPackageCLI"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0")
    ],
    targets: [
        .target(name: "OpenPackage"),
        .executableTarget(
            name: "OpenPackageCLI",
            dependencies: [
                "OpenPackage",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .testTarget(
            name: "OpenPackageTests",
            dependencies: [
                "OpenPackage",
                // Force the executable to build before tests run so the CLI suite can invoke the real binary end-to-end.
                "OpenPackageCLI"
            ]
        )
    ]
)
