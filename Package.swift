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
        // MediaPipe LiteRT dependencies will be added via CocoaPods
        // or manual framework integration when .tflite models are available
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
