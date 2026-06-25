// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-web-ui",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "SwiftWebUI", targets: ["SwiftWebUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/NVMNovem/swift-css", from: "0.0.1"),
        .package(url: "https://github.com/NVMNovem/swift-html", from: "0.0.1")
    ],
    targets: [
        .target(
            name: "SwiftWebUI",
            dependencies: [
                .product(name: "SwiftCSS", package: "swift-css"),
                .product(name: "SwiftHTML", package: "swift-html")
            ]
        ),
        .testTarget(
            name: "SwiftWebUITests",
            dependencies: [
                "SwiftWebUI",
                .product(name: "SwiftHTML", package: "swift-html")
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
