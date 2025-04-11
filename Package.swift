// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PayslipMax",
    platforms: [
        .macOS(.v12),
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "PayslipMax",
            targets: ["PayslipMax"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        // Main target
        .target(
            name: "PayslipMax",
            dependencies: [], // Removed Swinject
            path: "PayslipMax"),
        
        // Test targets
        .testTarget(
            name: "PayslipMaxTests",
            dependencies: ["PayslipMax"],
            path: "PayslipMaxTests"),
        
        // Auth tests executable
        .executableTarget(
            name: "AuthTests",
            dependencies: [], // Removed Swinject
            path: "Sources")
    ]
)
