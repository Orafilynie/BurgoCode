// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BurgoCode",
    platforms: [
            .iOS(.v15),
            .macOS(.v12)
        ],
    products: [
        .library(
            name: "BurgoCode",
            targets: ["BurgoCode"]),
    ],
    targets: [
        .target(
            name: "BurgoCode"),
        .systemLibrary(
            name: "CommonCrypto",
            path: "Sources/CommonCrypto"),

    ]
)
