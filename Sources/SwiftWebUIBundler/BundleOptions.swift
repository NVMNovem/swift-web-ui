//
//  BundleOptions.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 11/11/2026.
//

import Foundation

/// What `swift package web` was asked to assemble, and where.
struct BundleOptions: Equatable {
    /// The package whose browser application is being assembled.
    var packageDirectory: URL
    /// The JavaScriptKit `swift package js` output. `nil` means its default location.
    var input: URL?
    /// The deployable directory to write. `nil` means `dist` in the package.
    var output: URL?
    /// Application files copied into the output as they are. `nil` means `Resources`.
    var resources: URL?
    /// A vendored `@bjorn3/browser_wasi_shim`. `nil` means `Vendor/browser_wasi_shim`.
    var wasiShim: URL?
    var title: String?
    var language: String = "en"
    var mountPoint: String = "app"
    /// The path the output is served under, with a leading and trailing slash.
    var basePath: String = "/"
    /// Fails the build when the WebAssembly bundle is larger than this many bytes.
    var maximumBytes: Int?

    static let usage = """
        OVERVIEW: Assemble a deployable browser application from a SwiftWebUI package.

        Build the WebAssembly bundle first, then assemble it:

          swift package --swift-sdk <wasm sdk> js -c release
          swift package --allow-writing-to-package-directory web

        USAGE: swift package web [options]

        OPTIONS:
          --input <path>        The `swift package js` output
                                (default: .build/plugins/PackageToJS/outputs/Package)
          --output <path>       The directory to write (default: dist)
          --resources <path>    Files copied into the output as they are (default: Resources)
          --wasi-shim <path>    A vendored @bjorn3/browser_wasi_shim
                                (default: Vendor/browser_wasi_shim, when it exists)
          --title <text>        The document title (default: the package name)
          --language <code>     The document language (default: en)
          --mount-point <id>    The element the application mounts into (default: app)
          --base-path <path>    The path the output is served under (default: /)
          --max-bytes <count>   Fail when the WebAssembly bundle is larger than this
          -h, --help            Show this text

        An `index.html` in the resources directory is used as it is. Without one, a
        document with a loading screen, the mount point and a loader is generated.
        """

    init(packageDirectory: URL) {
        self.packageDirectory = packageDirectory
    }

    /// Reads options from command-line arguments, without the executable name.
    ///
    /// - Returns: `nil` when the arguments ask for the usage text.
    static func parse(_ arguments: [String], workingDirectory: URL) throws -> BundleOptions? {
        var options = BundleOptions(packageDirectory: workingDirectory)
        var packagePath: String?
        var paths: [String: String] = [:]

        var remaining = arguments[...]
        while let argument = remaining.popFirst() {
            if argument == "-h" || argument == "--help" { return nil }

            func value() throws -> String {
                guard let value = remaining.popFirst() else {
                    throw BundleError.missingValue(option: argument)
                }
                return value
            }

            switch argument {
            case "--package": packagePath = try value()
            case "--input", "--output", "--resources", "--wasi-shim": paths[argument] = try value()
            case "--title": options.title = try value()
            case "--language": options.language = try value()
            case "--mount-point": options.mountPoint = try value()
            case "--base-path": options.basePath = normalizedBasePath(try value())
            case "--max-bytes":
                let text = try value()
                guard let count = Int(text), count > 0 else {
                    throw BundleError.invalidValue(option: argument, value: text)
                }
                options.maximumBytes = count
            default:
                throw BundleError.unknownOption(argument)
            }
        }

        if let packagePath {
            options.packageDirectory = Self.resolve(packagePath, in: workingDirectory)
        }
        // Relative paths are the package's, wherever the tool was started from.
        func resolved(_ option: String) -> URL? {
            paths[option].map { Self.resolve($0, in: options.packageDirectory) }
        }
        options.input = resolved("--input")
        options.output = resolved("--output")
        options.resources = resolved("--resources")
        options.wasiShim = resolved("--wasi-shim")
        return options
    }

    /// An absolute path as it is, a relative one inside `directory`.
    static func resolve(_ path: String, in directory: URL) -> URL {
        path.hasPrefix("/")
            ? URL(fileURLWithPath: path).standardizedFileURL
            : directory.appendingPathComponent(path).standardizedFileURL
    }

    /// `shop`, `/shop` and `shop/` all mean `/shop/`.
    static func normalizedBasePath(_ path: String) -> String {
        let trimmed = path.split(separator: "/", omittingEmptySubsequences: true).joined(separator: "/")
        return trimmed.isEmpty ? "/" : "/\(trimmed)/"
    }

    var resolvedInput: URL {
        input ?? packageDirectory.appendingPathComponent(".build/plugins/PackageToJS/outputs/Package")
    }

    var resolvedOutput: URL {
        output ?? packageDirectory.appendingPathComponent("dist")
    }

    var resolvedResources: URL {
        resources ?? packageDirectory.appendingPathComponent("Resources")
    }

    var resolvedWASIShim: URL {
        wasiShim ?? packageDirectory.appendingPathComponent("Vendor/browser_wasi_shim")
    }
}

enum BundleError: Error, Equatable, CustomStringConvertible {
    case unknownOption(String)
    case missingValue(option: String)
    case invalidValue(option: String, value: String)
    case missingInput(URL)
    case missingBundle(URL)
    case ambiguousBundle([String])
    case missingWASIShim(URL)
    case overBudget(bytes: Int, maximum: Int)

    var description: String {
        switch self {
        case .unknownOption(let option):
            "unknown option '\(option)'. Run `swift package web --help` for the options."
        case .missingValue(let option):
            "'\(option)' needs a value."
        case .invalidValue(let option, let value):
            "'\(value)' is not a valid value for '\(option)'."
        case .missingInput(let url):
            """
            no JavaScriptKit output at \(url.path).
            Build the WebAssembly bundle first:
              swift package --swift-sdk <wasm sdk> js -c release
            """
        case .missingBundle(let url):
            "no .wasm file in \(url.path). Build it with `swift package --swift-sdk <wasm sdk> js -c release`."
        case .ambiguousBundle(let names):
            "more than one .wasm file in the input (\(names.joined(separator: ", "))). Build one product, or pass its own directory with --input."
        case .missingWASIShim(let url):
            "no WASI shim at \(url.path). It needs an index.js."
        case .overBudget(let bytes, let maximum):
            "the WebAssembly bundle is \(bytes) bytes, over the \(maximum) byte budget."
        }
    }
}
