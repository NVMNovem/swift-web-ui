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
        // `swift package web` and `swift package web-serve`, for packages that depend
        // on this one.
        .plugin(name: "SwiftWebUIBundlePlugin", targets: ["SwiftWebUIBundlePlugin"]),
        .plugin(name: "SwiftWebUIServePlugin", targets: ["SwiftWebUIServePlugin"]),
    ],
    traits: [
        .trait(
            name: "EmbeddedObservation",
            description: "Use swift-observation's own implementation instead of Apple's Observation on every platform, as Embedded Swift always does. For testing it on a host."
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/NVMNovem/swift-css", from: "1.0.6"),
        .package(url: "https://github.com/NVMNovem/swift-html", from: "1.0.0"),
        .package(url: "https://github.com/NVMNovem/swift-localization", from: "0.0.2"),
        .package(url: "https://github.com/swiftwasm/JavaScriptKit.git", from: "0.56.1"),
        // `@Observable` and `withObservationTracking` that also build in Embedded Swift.
        // Apple's `Observation` everywhere else.
        .package(
            url: "https://github.com/NVMNovem/swift-observation",
            branch: "claude/project-thread-xl22mx",
            traits: [
                .defaults,
                .trait(name: "EmbeddedObservation", condition: .when(traits: ["EmbeddedObservation"])),
            ]
        ),
    ],
    targets: [
        .target(
            name: "SwiftWebUI",
            dependencies: [
                .product(name: "SwiftCSS", package: "swift-css"),
                .product(name: "SwiftLocalization", package: "swift-localization"),
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
                .product(name: "SwiftObservation", package: "swift-observation"),
                .product(name: "JavaScriptKit", package: "JavaScriptKit"),
                // `App.main()` installs it, so an application does not have to.
                .product(name: "JavaScriptEventLoop", package: "JavaScriptKit"),
            ],
            exclude: ["SwiftWebUIRuntime.docc"],
            swiftSettings: [
                .enableExperimentalFeature("Extern"),
            ]
        ),
        // The host tool behind the two command plugins. It assembles what stands around
        // a WebAssembly bundle and is never linked into one, so Foundation is fine here.
        .executableTarget(
            name: "SwiftWebUIBundler",
            dependencies: [
                "SwiftWebUIStatic",
                .product(name: "SwiftHTML", package: "swift-html"),
            ]
        ),
        .plugin(
            name: "SwiftWebUIBundlePlugin",
            capability: .command(
                intent: .custom(
                    verb: "web",
                    description: "Assemble a deployable browser application from the JavaScriptKit build output."
                ),
                permissions: [
                    .writeToPackageDirectory(reason: "Writes the assembled application to the dist directory."),
                ]
            ),
            dependencies: ["SwiftWebUIBundler"]
        ),
        .plugin(
            name: "SwiftWebUIServePlugin",
            capability: .command(
                intent: .custom(
                    verb: "web-serve",
                    description: "Serve the assembled browser application on this machine."
                ),
                permissions: [
                    .allowNetworkConnections(
                        scope: .local(ports: []),
                        reason: "Serves the assembled application on a local port."
                    ),
                ]
            ),
            dependencies: ["SwiftWebUIBundler"]
        ),
        .testTarget(
            name: "SwiftWebUIBundlerTests",
            dependencies: ["SwiftWebUIBundler"]
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
                .product(name: "SwiftObservation", package: "swift-observation"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
