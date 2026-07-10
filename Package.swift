// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Mcplist",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Mcplist", targets: ["Mcplist"])
    ],
    targets: [
        .target(name: "Mcplist", path: "Sources")
    ]
)
