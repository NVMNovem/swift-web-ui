// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "site",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/NVMNovem/swift-web-ui.git", from: "1.2.0"),
    ],
    targets: [
        // Runs on the Mac at build time and writes plain files into dist/.
        // SwiftWebUIStatic re-exports SwiftWebUI and SwiftCSS, so it is the
        // only import a view file needs.
        .executableTarget(
            name: "Site",
            dependencies: [
                .product(name: "SwiftWebUIStatic", package: "swift-web-ui"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
