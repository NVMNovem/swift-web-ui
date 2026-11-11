//
//  DevelopmentServer.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 11/11/2026.
//

import Foundation

/// Serves an assembled application on this machine, for looking at it.
///
/// It is Python's own `http.server` with one addition: a path that names no file is
/// answered with `index.html`, which is what lets an application that reads the address
/// be opened at any of its URLs. It is not a deployment server.
struct DevelopmentServer {
    var directory: URL
    var port: Int = 8080

    static let usage = """
        OVERVIEW: Serve an assembled SwiftWebUI application on this machine.

        USAGE: swift package web-serve [--output <path>] [--port <number>]

        OPTIONS:
          --output <path>   The assembled directory to serve (default: dist)
          --port <number>   The port to listen on (default: 8080)
          -h, --help        Show this text

        Needs python3. Assemble the application first with `swift package web`.
        """

    /// Reads options from command-line arguments, without the executable name.
    ///
    /// - Returns: `nil` when the arguments ask for the usage text.
    static func parse(_ arguments: [String], workingDirectory: URL) throws -> DevelopmentServer? {
        var packageDirectory = workingDirectory
        var output: String?
        var port = 8080

        var remaining = arguments[...]
        while let argument = remaining.popFirst() {
            if argument == "-h" || argument == "--help" { return nil }
            guard let value = remaining.popFirst() else {
                throw BundleError.missingValue(option: argument)
            }
            switch argument {
            case "--package":
                packageDirectory = BundleOptions.resolve(value, in: workingDirectory)
            case "--output":
                output = value
            case "--port":
                guard let number = Int(value), (1...65_535).contains(number) else {
                    throw BundleError.invalidValue(option: argument, value: value)
                }
                port = number
            default:
                throw BundleError.unknownOption(argument)
            }
        }

        return DevelopmentServer(
            directory: BundleOptions.resolve(output ?? "dist", in: packageDirectory),
            port: port
        )
    }

    /// The Python program that serves `directory`.
    static let program = """
        import http.server, os, sys

        directory, port = sys.argv[1], int(sys.argv[2])

        class Handler(http.server.SimpleHTTPRequestHandler):
            extensions_map = {**http.server.SimpleHTTPRequestHandler.extensions_map,
                              ".wasm": "application/wasm", ".js": "text/javascript", ".mjs": "text/javascript"}

            def __init__(self, *args, **kwargs):
                super().__init__(*args, directory=directory, **kwargs)

            def send_head(self):
                path = self.translate_path(self.path)
                if not os.path.exists(path) and "." not in os.path.basename(path):
                    self.path = "/index.html"
                return super().send_head()

            def end_headers(self):
                self.send_header("Cache-Control", "no-store")
                super().end_headers()

        with http.server.ThreadingHTTPServer(("127.0.0.1", port), Handler) as server:
            print(f"Serving {directory} at http://127.0.0.1:{port}", flush=True)
            try:
                server.serve_forever()
            except KeyboardInterrupt:
                pass
        """

    func run() throws {
        guard FileManager.default.fileExists(atPath: directory.appendingPathComponent("index.html").path) else {
            throw BundleError.missingInput(directory)
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["python3", "-c", Self.program, directory.path, String(port)]
        try process.run()
        process.waitUntilExit()
    }
}
