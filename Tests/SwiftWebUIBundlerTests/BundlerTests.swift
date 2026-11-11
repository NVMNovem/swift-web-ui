//
//  BundlerTests.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 11/11/2026.
//

import Foundation
import Testing
@testable import SwiftWebUIBundler

@Suite struct BundlerTests {
    /// A package directory holding what `swift package js` would have left behind.
    private final class Fixture {
        let package: URL
        private let fileManager = FileManager.default

        init(bundleBytes: Int = 2_000, importsBareShim: Bool = true) throws {
            package = fileManager.temporaryDirectory
                .appendingPathComponent("swiftwebui-bundler-\(UUID().uuidString)")
            let input = package.appendingPathComponent(".build/plugins/PackageToJS/outputs/Package")
            try write("export async function init() {}", to: input.appendingPathComponent("index.js"))
            try write(
                importsBareShim
                    ? "import { WASI } from '@bjorn3/browser_wasi_shim';"
                    : "import { WASI } from 'https://cdn.jsdelivr.net/npm/@bjorn3/browser_wasi_shim@0.4.1/+esm';",
                to: input.appendingPathComponent("platforms/browser.js")
            )
            try write("{}", to: input.appendingPathComponent("node_modules/dependency/package.json"))
            try Data(repeating: 0, count: bundleBytes).write(to: input.appendingPathComponent("Shop.wasm"))
        }

        deinit { try? fileManager.removeItem(at: package) }

        func write(_ text: String, to url: URL) throws {
            try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try text.write(to: url, atomically: true, encoding: .utf8)
        }

        func write(_ text: String, at path: String) throws {
            try write(text, to: package.appendingPathComponent(path))
        }

        func text(at path: String) throws -> String {
            try String(contentsOf: package.appendingPathComponent(path), encoding: .utf8)
        }

        func exists(_ path: String) -> Bool {
            fileManager.fileExists(atPath: package.appendingPathComponent(path).path)
        }

        var options: BundleOptions { BundleOptions(packageDirectory: package) }
    }

    @Test func assemblesTheBuildOutputResourcesAndAGeneratedDocument() throws {
        let fixture = try Fixture()
        try fixture.write("body { margin: 0 }", at: "Resources/styles.css")
        try fixture.write("<svg/>", at: "Resources/images/logo.svg")

        let result = try Bundler(options: fixture.options).run()

        #expect(result.bundleName == "Shop.wasm")
        #expect(result.bundleBytes == 2_000)
        #expect(result.generatedDocument)
        #expect(fixture.exists("dist/index.js"))
        #expect(fixture.exists("dist/Shop.wasm"))
        #expect(fixture.exists("dist/platforms/browser.js"))
        #expect(fixture.exists("dist/styles.css"))
        #expect(fixture.exists("dist/images/logo.svg"))
        #expect(!fixture.exists("dist/node_modules"))
        #expect(!fixture.exists(".dist-staging"))

        let document = try fixture.text(at: "dist/index.html")
        #expect(document.contains(#"<div id="app"></div>"#))
        #expect(document.contains(#"name="swiftwebui-bundle" content="Shop.wasm""#))
        #expect(document.contains(#"name="swiftwebui-bundle-bytes" content="2000""#))
        #expect(document.contains(#"name="swiftwebui-base" content="/""#))
        #expect(document.contains(#"id="swiftwebui-splash""#))
        #expect(document.contains(#"<script type="module">"#))
    }

    @Test func theDocumentFollowsItsOptions() throws {
        let fixture = try Fixture()
        var options = fixture.options
        options.title = "Frituur & Co"
        options.language = "nl"
        options.mountPoint = "root"
        options.basePath = "/shop/"

        _ = try Bundler(options: options).run()

        let document = try fixture.text(at: "dist/index.html")
        #expect(document.contains(#"<html lang="nl">"#))
        #expect(document.contains("<title>Frituur &amp; Co</title>"))
        #expect(document.contains(#"<div id="root"></div>"#))
        #expect(document.contains(#"name="swiftwebui-base" content="/shop/""#))
    }

    @Test func anApplicationsOwnDocumentIsKept() throws {
        let fixture = try Fixture()
        try fixture.write("<!doctype html><p>mine</p>", at: "Resources/index.html")

        let result = try Bundler(options: fixture.options).run()

        #expect(!result.generatedDocument)
        #expect(try fixture.text(at: "dist/index.html") == "<!doctype html><p>mine</p>")
    }

    @Test func aVendoredShimIsCopiedAndMapped() throws {
        let fixture = try Fixture()
        try fixture.write("export class WASI {}", at: "Vendor/browser_wasi_shim/index.js")

        let result = try Bundler(options: fixture.options).run()

        #expect(result.wasiShim == .vendored)
        #expect(fixture.exists("dist/vendor/browser_wasi_shim/index.js"))
        let document = try fixture.text(at: "dist/index.html")
        #expect(document.contains(#"<script type="importmap">"#))
        #expect(document.contains(#""@bjorn3/browser_wasi_shim": "/vendor/browser_wasi_shim/index.js""#))
    }

    @Test func withoutAVendoredShimTheBareImportIsMappedToTheCDN() throws {
        let fixture = try Fixture()

        let result = try Bundler(options: fixture.options).run()

        #expect(result.wasiShim == .cdn)
        #expect(try fixture.text(at: "dist/index.html").contains(Bundler.wasiShimCDN))
        #expect(result.summary.contains("warning"))
    }

    @Test func aBuildThatAlreadyNamesItsShimGetsNoImportMap() throws {
        let fixture = try Fixture(importsBareShim: false)

        let result = try Bundler(options: fixture.options).run()

        #expect(result.wasiShim == .notNeeded)
        #expect(!(try fixture.text(at: "dist/index.html")).contains("importmap"))
    }

    @Test func aShimPathThatDoesNotExistIsAnError() throws {
        let fixture = try Fixture()
        var options = fixture.options
        options.wasiShim = fixture.package.appendingPathComponent("Nowhere")

        #expect(throws: BundleError.missingWASIShim(options.resolvedWASIShim)) {
            try Bundler(options: options).run()
        }
    }

    @Test func aPreviousOutputIsReplacedWhole() throws {
        let fixture = try Fixture()
        try fixture.write("stale", at: "dist/old.txt")

        _ = try Bundler(options: fixture.options).run()

        #expect(!fixture.exists("dist/old.txt"))
        #expect(fixture.exists("dist/index.html"))
    }

    @Test func aBundleOverItsBudgetFailsAfterTheOutputIsWritten() throws {
        let fixture = try Fixture(bundleBytes: 5_000)
        var options = fixture.options
        options.maximumBytes = 4_000

        #expect(throws: BundleError.overBudget(bytes: 5_000, maximum: 4_000)) {
            try Bundler(options: options).run()
        }
        // Still there to look at: the size is what failed, not the assembly.
        #expect(fixture.exists("dist/Shop.wasm"))
    }

    @Test func aMissingBuildSaysHowToMakeOne() throws {
        let package = FileManager.default.temporaryDirectory
            .appendingPathComponent("swiftwebui-bundler-\(UUID().uuidString)")
        let options = BundleOptions(packageDirectory: package)

        #expect(throws: BundleError.missingInput(options.resolvedInput)) {
            try Bundler(options: options).run()
        }
        #expect(BundleError.missingInput(options.resolvedInput).description.contains("swift package --swift-sdk"))
    }

    @Test func twoBundlesInOneInputAreAmbiguous() throws {
        let fixture = try Fixture()
        try Data([0]).write(
            to: fixture.package.appendingPathComponent(".build/plugins/PackageToJS/outputs/Package/Other.wasm")
        )

        #expect(throws: BundleError.ambiguousBundle(["Other.wasm", "Shop.wasm"])) {
            try Bundler(options: fixture.options).run()
        }
    }

    @Test func theSummaryReportsSizesInMegabytes() {
        let result = Bundler.Result(
            output: URL(fileURLWithPath: "/site/dist"),
            bundleName: "Shop.wasm",
            bundleBytes: 10_806_000,
            gzippedBytes: 3_702_000,
            wasiShim: .vendored,
            generatedDocument: true
        )

        #expect(result.summary.contains("Shop.wasm: 10.81 MB raw, 3.70 MB gzipped"))
    }
}

@Suite struct BundleOptionsTests {
    private let directory = URL(fileURLWithPath: "/work/site")

    @Test func defaultsFollowThePackageLayout() throws {
        let options = try #require(try BundleOptions.parse([], workingDirectory: directory))

        #expect(options.resolvedInput.path == "/work/site/.build/plugins/PackageToJS/outputs/Package")
        #expect(options.resolvedOutput.path == "/work/site/dist")
        #expect(options.resolvedResources.path == "/work/site/Resources")
        #expect(options.resolvedWASIShim.path == "/work/site/Vendor/browser_wasi_shim")
        #expect(options.mountPoint == "app")
        #expect(options.basePath == "/")
        #expect(options.maximumBytes == nil)
    }

    @Test func relativePathsAreThePackagesNotTheWorkingDirectorys() throws {
        let options = try #require(try BundleOptions.parse(
            ["--output", "public", "--package", "/elsewhere/shop", "--input", "/abs/in"],
            workingDirectory: directory
        ))

        #expect(options.resolvedOutput.path == "/elsewhere/shop/public")
        #expect(options.resolvedInput.path == "/abs/in")
    }

    @Test func readsEveryOption() throws {
        let options = try #require(try BundleOptions.parse(
            ["--title", "Shop", "--language", "nl", "--mount-point", "root", "--base-path", "shop", "--max-bytes", "14000000"],
            workingDirectory: directory
        ))

        #expect(options.title == "Shop")
        #expect(options.language == "nl")
        #expect(options.mountPoint == "root")
        #expect(options.basePath == "/shop/")
        #expect(options.maximumBytes == 14_000_000)
    }

    @Test func helpAsksForTheUsageText() throws {
        #expect(try BundleOptions.parse(["--help"], workingDirectory: directory) == nil)
    }

    @Test func mistakesAreNamed() {
        #expect(throws: BundleError.unknownOption("--nope")) {
            try BundleOptions.parse(["--nope"], workingDirectory: directory)
        }
        #expect(throws: BundleError.missingValue(option: "--title")) {
            try BundleOptions.parse(["--title"], workingDirectory: directory)
        }
        #expect(throws: BundleError.invalidValue(option: "--max-bytes", value: "big")) {
            try BundleOptions.parse(["--max-bytes", "big"], workingDirectory: directory)
        }
    }

    @Test func basePathsAreNormalized() {
        #expect(BundleOptions.normalizedBasePath("") == "/")
        #expect(BundleOptions.normalizedBasePath("/") == "/")
        #expect(BundleOptions.normalizedBasePath("shop") == "/shop/")
        #expect(BundleOptions.normalizedBasePath("/a/b") == "/a/b/")
    }
}

@Suite struct DevelopmentServerTests {
    private let directory = URL(fileURLWithPath: "/work/site")

    @Test func servesDistOnPort8080ByDefault() throws {
        let server = try #require(try DevelopmentServer.parse([], workingDirectory: directory))

        #expect(server.directory.path == "/work/site/dist")
        #expect(server.port == 8080)
    }

    @Test func readsItsOptions() throws {
        let server = try #require(try DevelopmentServer.parse(
            ["--package", "/elsewhere", "--output", "public", "--port", "9000"],
            workingDirectory: directory
        ))

        #expect(server.directory.path == "/elsewhere/public")
        #expect(server.port == 9000)
    }

    @Test func aPortOutsideTheRangeIsRefused() {
        #expect(throws: BundleError.invalidValue(option: "--port", value: "70000")) {
            try DevelopmentServer.parse(["--port", "70000"], workingDirectory: directory)
        }
    }
}
