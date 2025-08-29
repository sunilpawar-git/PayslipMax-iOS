// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PayslipMax",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "PayslipMax",
            targets: ["PayslipMax"]
        )
    ],
    dependencies: [
        // TensorFlow Lite integration will be added later
        // For now, using mock implementations with feature flags
    ],
    targets: [
        .target(
            name: "PayslipMax",
            dependencies: [],
            path: "PayslipMax",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "PayslipMaxTests",
            dependencies: ["PayslipMax"],
            path: "PayslipMaxTests"
        ),
        .testTarget(
            name: "PayslipMaxUITests",
            dependencies: ["PayslipMax"],
            path: "PayslipMaxUITests"
        )
    ]
)
