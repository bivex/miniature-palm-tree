// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "ASTAnalyzer",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", branch: "main"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "ASTAnalyzer",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "Yams", package: "Yams"),
            ],
            path: "Sources/ASTAnalyzer"
        )
    ]
)