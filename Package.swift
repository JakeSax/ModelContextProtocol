// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ModelContextProtocol",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        // Users can import just MCPCore, or choose MCPClient or MCPServer as well.
        .library(
            name: "MCPCore",
            targets: ["MCPCore"]
        ),
        .library(
            name: "MCPClient",
            targets: ["MCPClient"]
        ),
        .library(
            name: "MCPServer",
            targets: ["MCPServer"]
        )
    ],
    dependencies: [
        // Add any dependencies your package needs
        .package(url: "https://github.com/apple/swift-http-types.git", from: "1.3.1")
    ],
    targets: [
        .target(
            name: "MCPCore",
            dependencies: [],
            path: "Sources/Core"
        ),
        .target(
            name: "MCPClient",
            dependencies: [
                "MCPCore",
                .product(name: "HTTPTypes", package: "swift-http-types"),
                .product(name: "HTTPTypesFoundation", package: "swift-http-types")
            ],
            path: "Sources/Client"
        ),
        .target(
            name: "MCPServer",
            dependencies: ["MCPCore"],
            path: "Sources/Server"
        ),
        .testTarget(
            name: "MCPCoreTests",
            dependencies: ["MCPCore"],
            path: "Tests/CoreTests"
        ),
        .testTarget(
            name: "MCPClientTests",
            dependencies: ["MCPClient"],
            path: "Tests/ClientTests"
        ),
        .testTarget(
            name: "MCPServerTests",
            dependencies: ["MCPServer"],
            path: "Tests/ServerTests"
        )
    ]
)
