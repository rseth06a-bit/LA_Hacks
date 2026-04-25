// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LA_Hacks",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .library(name: "LA_Hacks", targets: ["LA_Hacks"])
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "LA_Hacks",
            dependencies: []
        )
    ]
)