//
//  Bundler.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 11/11/2026.
//

import Foundation

/// Assembles the deployable directory of a browser application.
///
/// The WebAssembly bundle and its JavaScript are JavaScriptKit's, built by
/// `swift package js`. This adds what stands around them: the application's own files,
/// the WASI shim the generated JavaScript imports, and the document that loads it all.
struct Bundler {
    /// What a finished bundle consists of.
    struct Result: Equatable {
        var output: URL
        var bundleName: String
        var bundleBytes: Int
        /// `nil` when `gzip` could not be run.
        var gzippedBytes: Int?
        var wasiShim: WASIShim
        var generatedDocument: Bool
    }

    /// Where the page gets the WASI shim that JavaScriptKit's browser platform imports.
    enum WASIShim: Equatable {
        /// The generated JavaScript does not need an import map: it was built with
        /// `--use-cdn`, or for a platform without WASI.
        case notNeeded
        /// Copied into the output from the application's own vendored copy.
        case vendored
        /// Mapped to a public CDN because the application vendors none.
        case cdn
    }

    static let wasiShimSpecifier = "@bjorn3/browser_wasi_shim"
    /// The address JavaScriptKit itself uses with `--use-cdn`.
    static let wasiShimCDN = "https://cdn.jsdelivr.net/npm/@bjorn3/browser_wasi_shim@0.4.1/+esm"

    var options: BundleOptions
    var fileManager: FileManager = .default

    func run() throws -> Result {
        let input = options.resolvedInput
        guard fileManager.fileExists(atPath: input.appendingPathComponent("index.js").path) else {
            throw BundleError.missingInput(input)
        }

        let bundleName = try bundleName(in: input)
        let bundleBytes = try size(of: input.appendingPathComponent(bundleName))

        let output = options.resolvedOutput
        // Assembled beside the output and moved into place, so a failed build never
        // leaves a half-written directory where a deploy would pick it up.
        let staging = output.deletingLastPathComponent()
            .appendingPathComponent(".\(output.lastPathComponent)-staging")
        try? fileManager.removeItem(at: staging)
        try fileManager.createDirectory(at: staging, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: staging) }

        try copyContents(of: input, into: staging, skipping: ["node_modules"])

        let resources = options.resolvedResources
        if fileManager.fileExists(atPath: resources.path) {
            try copyContents(of: resources, into: staging)
        }

        let shim = try installWASIShim(into: staging)

        let documentURL = staging.appendingPathComponent("index.html")
        let generatesDocument = !fileManager.fileExists(atPath: documentURL.path)
        if generatesDocument {
            let document = DefaultDocument(
                title: options.title ?? options.packageDirectory.lastPathComponent,
                language: options.language,
                mountPoint: options.mountPoint,
                basePath: options.basePath,
                bundleName: bundleName,
                bundleBytes: bundleBytes,
                wasiShimAddress: shimAddress(for: shim)
            )
            try (document.htmlString() + "\n").write(to: documentURL, atomically: true, encoding: .utf8)
        }

        try? fileManager.removeItem(at: output)
        try fileManager.moveItem(at: staging, to: output)

        let result = Result(
            output: output,
            bundleName: bundleName,
            bundleBytes: bundleBytes,
            gzippedBytes: gzippedSize(of: output.appendingPathComponent(bundleName)),
            wasiShim: shim,
            generatedDocument: generatesDocument
        )

        if let maximum = options.maximumBytes, bundleBytes > maximum {
            throw BundleError.overBudget(bytes: bundleBytes, maximum: maximum)
        }
        return result
    }

    // MARK: - Steps

    private func bundleName(in input: URL) throws -> String {
        let names = try fileManager.contentsOfDirectory(atPath: input.path)
            .filter { $0.hasSuffix(".wasm") }
            .sorted()
        guard let name = names.first else { throw BundleError.missingBundle(input) }
        guard names.count == 1 else { throw BundleError.ambiguousBundle(names) }
        return name
    }

    private func installWASIShim(into staging: URL) throws -> WASIShim {
        let platform = staging.appendingPathComponent("platforms/browser.js")
        let source = (try? String(contentsOf: platform, encoding: .utf8)) ?? ""
        let importsBareSpecifier = source.contains("'\(Self.wasiShimSpecifier)'")
            || source.contains("\"\(Self.wasiShimSpecifier)\"")
        guard importsBareSpecifier else { return .notNeeded }

        let vendored = options.resolvedWASIShim
        if fileManager.fileExists(atPath: vendored.path) {
            guard fileManager.fileExists(atPath: vendored.appendingPathComponent("index.js").path) else {
                throw BundleError.missingWASIShim(vendored)
            }
            let destination = staging.appendingPathComponent("vendor/browser_wasi_shim")
            try fileManager.createDirectory(
                at: destination.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try? fileManager.removeItem(at: destination)
            try fileManager.copyItem(at: vendored, to: destination)
            return .vendored
        }
        // An explicit path that does not exist is a mistake, not a request for the CDN.
        if options.wasiShim != nil { throw BundleError.missingWASIShim(vendored) }
        return .cdn
    }

    private func shimAddress(for shim: WASIShim) -> String? {
        switch shim {
        case .notNeeded: nil
        case .vendored: options.basePath + "vendor/browser_wasi_shim/index.js"
        case .cdn: Self.wasiShimCDN
        }
    }

    /// Copies what is inside `source` into `destination`, replacing files of the same
    /// name and merging directories, so application resources can sit beside — and
    /// override — what the JavaScript build produced.
    private func copyContents(of source: URL, into destination: URL, skipping: Set<String> = []) throws {
        for name in try fileManager.contentsOfDirectory(atPath: source.path).sorted() {
            if skipping.contains(name) || name == ".DS_Store" { continue }
            let from = source.appendingPathComponent(name)
            let to = destination.appendingPathComponent(name)

            var isDirectory: ObjCBool = false
            fileManager.fileExists(atPath: from.path, isDirectory: &isDirectory)
            if isDirectory.boolValue {
                try fileManager.createDirectory(at: to, withIntermediateDirectories: true)
                try copyContents(of: from, into: to)
            } else {
                try? fileManager.removeItem(at: to)
                try fileManager.copyItem(at: from, to: to)
            }
        }
    }

    private func size(of url: URL) throws -> Int {
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        return (attributes[.size] as? NSNumber)?.intValue ?? 0
    }

    /// The size a server that compresses would send, as an indication only.
    private func gzippedSize(of url: URL) -> Int? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["gzip", "-6", "-c", url.path]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do { try process.run() } catch { return nil }

        var count = 0
        while true {
            let chunk = pipe.fileHandleForReading.availableData
            if chunk.isEmpty { break }
            count += chunk.count
        }
        process.waitUntilExit()
        return process.terminationStatus == 0 ? count : nil
    }
}

extension Bundler.Result {
    /// What the command prints when it has finished.
    var summary: String {
        func megabytes(_ bytes: Int) -> String {
            let hundredths = (bytes + 5_000) / 10_000
            let fraction = hundredths % 100
            return "\(hundredths / 100).\(fraction < 10 ? "0" : "")\(fraction) MB"
        }

        var lines = ["Assembled \(output.path)"]
        var size = "  \(bundleName): \(megabytes(bundleBytes)) raw"
        if let gzippedBytes { size += ", \(megabytes(gzippedBytes)) gzipped" }
        lines.append(size)
        lines.append(generatedDocument
            ? "  index.html: generated"
            : "  index.html: the application's own")
        switch wasiShim {
        case .notNeeded: break
        case .vendored: lines.append("  WASI shim: vendored copy")
        case .cdn:
            lines.append("  WASI shim: loaded from cdn.jsdelivr.net")
            lines.append("  warning: visitors' browsers will contact that host. Place a copy in")
            lines.append("           Vendor/browser_wasi_shim to serve it from your own.")
        }
        return lines.joined(separator: "\n")
    }
}
