// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-web-ui",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "SwiftWebUI", targets: ["SwiftWebUI"]),
        .library(name: "SwiftWebUIStatic", targets: ["SwiftWebUIStatic"]),
        .library(name: "SwiftWebUIRuntime", targets: ["SwiftWebUIRuntime"]),
    ],
    dependencies: [
        .package(url: "https://github.com/NVMNovem/swift-css", from: "1.0.4"),
        .package(url: "https://github.com/NVMNovem/swift-html", from: "1.0.0"),
        .package(url: "https://github.com/swiftwasm/JavaScriptKit.git", from: "0.56.1"),
    ],
    targets: [
        .target(
            name: "SwiftWebUI",
            dependencies: [
                .product(name: "SwiftCSS", package: "swift-css"),
            ],
            exclude: ["SwiftWebUI.docc"]
        ),
        .target(
            name: "SwiftWebUIStatic",
            dependencies: [
                "SwiftWebUI",
                .product(name: "SwiftCSS", package: "swift-css"),
                .product(name: "SwiftHTML", package: "swift-html"),
            ]
        ),
        .target(
            name: "SwiftWebUIRuntime",
            dependencies: [
                "SwiftWebUI",
                .product(name: "JavaScriptKit", package: "JavaScriptKit"),
            ],
            exclude: ["SwiftWebUIRuntime.docc"],
            swiftSettings: [
                .enableExperimentalFeature("Extern"),
            ]
        ),
        .testTarget(
            name: "SwiftWebUITests",
            dependencies: [
                "SwiftWebUI",
                "SwiftWebUIStatic",
                .product(name: "SwiftHTML", package: "swift-html")
            ]
        ),
        .testTarget(
            name: "SwiftWebUIRuntimeTests",
            dependencies: [
                "SwiftWebUI",
                "SwiftWebUIRuntime",
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
