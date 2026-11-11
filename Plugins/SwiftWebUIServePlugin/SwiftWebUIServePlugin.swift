//
//  SwiftWebUIServePlugin.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 11/11/2026.
//

import Foundation
import PackagePlugin

/// `swift package web-serve`: serves the assembled application on this machine.
@main
struct SwiftWebUIServePlugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        let tool = try context.tool(named: "SwiftWebUIBundler")

        let process = Process()
        process.executableURL = tool.url
        process.arguments = ["serve", "--package", context.package.directoryURL.path] + arguments
        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw Failure(status: process.terminationStatus)
        }
    }

    struct Failure: Error, CustomStringConvertible {
        let status: Int32
        var description: String { "swift package web-serve failed (exit code \(status))." }
    }
}
