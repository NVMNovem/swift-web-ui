// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "app",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/NVMNovem/swift-web-ui.git", from: "1.2.0"),
        .package(url: "https://github.com/swiftwasm/JavaScriptKit.git", from: "0.56.1"),
    ],
    targets: [
        // Compiled to WebAssembly and run in the browser.
        //
        // Keep Foundation out of everything this target links: it pulls in ICU
        // and multiplies the size of the bundle every visitor downloads. That
        // is also why this target depends on SwiftWebUI and not on
        // SwiftWebUIStatic, which imports Foundation.
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "SwiftWebUI", package: "swift-web-ui"),
                .product(name: "SwiftWebUIRuntime", package: "swift-web-ui"),
                .product(name: "JavaScriptKit", package: "JavaScriptKit"),
                .product(name: "JavaScriptEventLoop", package: "JavaScriptKit"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("Extern"),
            ],
            linkerSettings: [
                // A reactor stays alive after main() returns, which is what lets
                // a click call back into Swift later.
                .unsafeFlags(
                    [
                        "-Xclang-linker", "-mexec-model=reactor",
                        "-Xlinker", "--export-if-defined=__main_argc_argv",
                    ],
                    .when(platforms: [.wasi])
                ),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
