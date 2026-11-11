//
//  SwiftWebUIBundlePlugin.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 11/11/2026.
//

import Foundation
import PackagePlugin

/// `swift package web`: assembles a deployable browser application in `dist`.
@main
struct SwiftWebUIBundlePlugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        let tool = try context.tool(named: "SwiftWebUIBundler")

        let process = Process()
        process.executableURL = tool.url
        process.arguments = ["--package", context.package.directoryURL.path] + arguments
        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw Failure(status: process.terminationStatus)
        }
    }

    struct Failure: Error, CustomStringConvertible {
        let status: Int32
        var description: String { "swift package web failed (exit code \(status))." }
    }
}
