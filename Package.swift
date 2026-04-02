// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RayaChat",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "RayaChatCore", targets: ["RayaChatCore"]),
        .library(name: "RayaChatUI", targets: ["RayaChatUI"]),
    ],
    targets: [
        .target(
            name: "RayaChatCore",
            path: "Sources/RayaChatCore"
        ),
        .target(
            name: "RayaChatUI",
            dependencies: ["RayaChatCore"],
            path: "Sources/RayaChatUI"
        ),
        .testTarget(
            name: "RayaChatCoreTests",
            dependencies: ["RayaChatCore"],
            path: "Tests/RayaChatCoreTests"
        ),
        .testTarget(
            name: "RayaChatUITests",
            dependencies: ["RayaChatUI"],
            path: "Tests/RayaChatUITests"
        ),
    ]
)
