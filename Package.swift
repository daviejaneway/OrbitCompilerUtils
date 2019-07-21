// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "OrbitCompilerUtils",
    products: [
        .library(
            name: "OrbitCompilerUtils",
            targets: ["OrbitCompilerUtils"]
        )
    ],
    targets: [
        .target(
            name: "OrbitCompilerUtils"
        ),
        .testTarget(
            name: "OrbitCompilerUtilsTests"
        )
    ]
)
