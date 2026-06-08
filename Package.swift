// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Daymark",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "Daymark", targets: ["Daymark"])
    ],
    targets: [
        .executableTarget(
            name: "Daymark",
            path: "Sources/Daymark"
        ),
        .testTarget(
            name: "DaymarkTests",
            dependencies: ["Daymark"],
            path: "Tests/DaymarkTests"
        )
    ]
)
