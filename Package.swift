// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Mcplist",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "McplistCore", targets: ["McplistCore"]),
        .library(name: "McplistUI", targets: ["McplistUI"]),
    ],
    targets: [
        // Foundation-only domain logic; no SwiftUI so it also builds on Linux.
        .target(name: "McplistCore", path: "Sources/McplistCore"),
        .target(name: "McplistUI", dependencies: ["McplistCore"], path: "Sources/McplistUI"),
        .testTarget(name: "McplistCoreTests", dependencies: ["McplistCore"], path: "Tests/McplistCoreTests"),
    ]
)
