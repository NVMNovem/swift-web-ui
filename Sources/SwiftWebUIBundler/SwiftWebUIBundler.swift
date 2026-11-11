//
//  SwiftWebUIBundler.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 11/11/2026.
//

import Foundation

/// The tool behind `swift package web` and `swift package web-serve`.
///
/// It runs on the machine that builds the application and is never part of a
/// WebAssembly bundle, which is why it may use Foundation and `SwiftWebUIStatic`.
@main
struct SwiftWebUIBundler {
    static func main() {
        var arguments = Array(CommandLine.arguments.dropFirst())
        let workingDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

        do {
            if arguments.first == "serve" {
                arguments.removeFirst()
                guard let server = try DevelopmentServer.parse(arguments, workingDirectory: workingDirectory) else {
                    print(DevelopmentServer.usage)
                    return
                }
                try server.run()
            } else {
                guard let options = try BundleOptions.parse(arguments, workingDirectory: workingDirectory) else {
                    print(BundleOptions.usage)
                    return
                }
                print(try Bundler(options: options).run().summary)
            }
        } catch {
            FileHandle.standardError.write(Data("error: \(error)\n".utf8))
            exit(1)
        }
    }
}
