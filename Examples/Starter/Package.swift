// swift-tools-version: 6.2

import PackageDescription

// An Embedded Swift build (JAVASCRIPTKIT_EXPERIMENTAL_EMBEDDED_WASM=true) needs
// the stdlib's Unicode tables, which Embedded Swift keeps in their own library.
let embedded = Context.environment["JAVASCRIPTKIT_EXPERIMENTAL_EMBEDDED_WASM"] == "true"

// The smallest SwiftWebUI application that runs in a browser.
//
// Copy this directory to start a site, and replace the path dependency with
//
//     .package(url: "https://github.com/NVMNovem/swift-web-ui.git", from: "<version>")
//
// See README.md here for the two commands that build and assemble it.
let package = Package(
    name: "Starter",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(name: "swift-web-ui", path: "../.."),
        // Listed for `swift package js`: SwiftPM only offers the command plugins of
        // direct dependencies.
        .package(url: "https://github.com/swiftwasm/JavaScriptKit.git", from: "0.56.1"),
    ],
    targets: [
        .executableTarget(
            name: "Starter",
            dependencies: [
                .product(name: "SwiftWebUI", package: "swift-web-ui"),
                .product(name: "SwiftWebUIRuntime", package: "swift-web-ui"),
                .product(name: "JavaScriptKit", package: "JavaScriptKit"),
            ],
            linkerSettings: embedded
                ? [.linkedLibrary("swiftUnicodeDataTables", .when(platforms: [.wasi]))]
                : []
        ),
    ],
    swiftLanguageModes: [.v6]
)
