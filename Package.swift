// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-web-ui",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "SwiftWebUI", targets: ["SwiftWebUI"]),
        .library(name: "SwiftWebUIStatic", targets: ["SwiftWebUIStatic"]),
        .library(name: "SwiftWebUIRuntime", targets: ["SwiftWebUIRuntime"]),
        .executable(name: "SwiftWebUIEmbeddedDemo", targets: ["SwiftWebUIEmbeddedDemo"]),
        .executable(name: "SwiftWebUIRuntimeCounter", targets: ["SwiftWebUIRuntimeCounter"]),
    ],
    dependencies: [
        .package(path: "../../SwiftCSS/swift-css"),
        .package(path: "../../SwiftHTML/swift-html"),
        .package(url: "https://github.com/swiftwasm/JavaScriptKit.git", from: "0.56.1"),
    ],
    targets: [
        .target(
            name: "SwiftWebUI",
            dependencies: [
                .product(name: "SwiftCSS", package: "swift-css"),
            ],
            path: "Sources/SwiftWebUI",
            sources: ["Backend", "SwiftWebUI.swift"]
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
            swiftSettings: [
                .enableExperimentalFeature("Extern"),
            ]
        ),
        .executableTarget(
            name: "SwiftWebUIEmbeddedDemo",
            dependencies: ["SwiftWebUI"]
        ),
        .executableTarget(
            name: "SwiftWebUIRuntimeCounter",
            dependencies: [
                "SwiftWebUI",
                "SwiftWebUIRuntime",
                .product(name: "JavaScriptKit", package: "JavaScriptKit"),
            ],
            path: "Examples/RuntimeCounter/Sources",
            swiftSettings: [
                .enableExperimentalFeature("Extern"),
            ],
            linkerSettings: [
                .unsafeFlags(
                    [
                        "-Xclang-linker", "-mexec-model=reactor",
                        "-Xlinker", "--export-if-defined=__main_argc_argv",
                    ],
                    .when(platforms: [.wasi])
                ),
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
