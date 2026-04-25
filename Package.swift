// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LA_Hacks",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(name: "LA_Hacks", targets: ["LA_Hacks"])
    ],
    dependencies: [
    ],
    targets: [
        .executableTarget(
            name: "LA_Hacks",
            dependencies: []
        )
    ]
)