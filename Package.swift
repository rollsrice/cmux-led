// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "cmux-led",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "cmux-led",
            path: "Sources/cmux-led"
        )
    ]
)
