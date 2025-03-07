// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PayslipStandaloneTests",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "PayslipStandaloneTests",
            targets: ["PayslipStandaloneTests"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "PayslipStandaloneTests",
            dependencies: []),
        .testTarget(
            name: "PayslipStandaloneTestsTests",
            dependencies: ["PayslipStandaloneTests"]),
    ]
)
