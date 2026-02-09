// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DevDeck",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "DevDeck",
            targets: ["DevDeck"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "DevDeck",
            resources: [
                .process("Resources/default_profiles.json")
            ]
        ),
    ]
)
