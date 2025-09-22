// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Blaink",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "Blaink",
            targets: ["Blaink"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Blaink",
            dependencies: []
        )
    ]
)
