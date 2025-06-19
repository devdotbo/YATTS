// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "YATTS",
    platforms: [.iOS(.v17)],
    dependencies: [
        .package(url: "https://github.com/MacPaw/OpenAI.git", from: "0.3.0")
    ],
    targets: [
        .target(
            name: "YATTS",
            dependencies: ["OpenAI"]
        )
    ]
)