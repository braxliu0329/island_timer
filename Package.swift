// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "IslandTimer",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "IslandTimer", targets: ["IslandTimer"])
    ],
    targets: [
        .executableTarget(
            name: "IslandTimer",
            dependencies: [],
            path: "Sources/IslandTimer"
        ),
        .testTarget(
            name: "IslandTimerTests",
            dependencies: ["IslandTimer"],
            path: "Tests/IslandTimerTests"
        )
    ]
)
