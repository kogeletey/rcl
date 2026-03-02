// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RCLParser",
    products: [
        .library(name: "RCLParser", targets: ["RCLParser"]),
    ],
    targets: [
        .target(name: "RCLParser"),
        .testTarget(name: "RCLParserTests", dependencies: ["RCLParser"]),
    ]
)
