//
//  RenderedModels.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 20/07/2026.
//

import SwiftCSS
import SwiftHTML

public enum ResourceScope: Equatable, Sendable {
    case global
    case component(String)
}

public struct StyleResource: Sendable {
    public var id: String
    public var scope: ResourceScope
    public var content: String

    public init(id: String, scope: ResourceScope, content: String) {
        self.id = id
        self.scope = scope
        self.content = content
    }
}

public struct ScriptResource: Sendable {
    public var id: String
    public var scope: ResourceScope
    public var content: String

    public init(id: String, scope: ResourceScope, content: String) {
        self.id = id
        self.scope = scope
        self.content = content
    }
}

public struct RenderedContent: Sendable {
    public var html: [SwiftHTML.HTMLNode]

    public init(html: [SwiftHTML.HTMLNode]) {
        self.html = html
    }

    public func htmlString(prettyPrinted: Bool = false) -> String {
        let renderer = SwiftHTML.HTMLStringRenderer(
            options: .init(prettyPrinted: prettyPrinted)
        )
        return html.map(renderer.render).joined()
    }
}

public struct RenderedResources: Sendable {
    public var styles: [StyleResource]
    public var scripts: [ScriptResource]

    public init(styles: [StyleResource] = [], scripts: [ScriptResource] = []) {
        self.styles = styles
        self.scripts = scripts
    }

    public func cssString(prettyPrinted: Bool = true) -> String {
        styles
            .map(\.content)
            .filter { !$0.isEmpty }
            .map { prettyPrinted ? $0 : compactResourceContent($0) }
            .joined(separator: prettyPrinted ? "\n\n" : "")
    }

    public func jsString(prettyPrinted: Bool = true) -> String {
        scripts
            .map(\.content)
            .filter { !$0.isEmpty }
            .map { prettyPrinted ? $0 : compactResourceContent($0) }
            .joined(separator: prettyPrinted ? "\n\n" : "")
    }
}

public struct RenderedView: Sendable {
    public var content: RenderedContent
    public var resources: RenderedResources

    public init(content: RenderedContent, resources: RenderedResources) {
        self.content = content
        self.resources = resources
    }

    public func htmlString(prettyPrinted: Bool = false) -> String {
        content.htmlString(prettyPrinted: prettyPrinted)
    }

    public func cssString(prettyPrinted: Bool = true) -> String {
        resources.cssString(prettyPrinted: prettyPrinted)
    }

    public func jsString(prettyPrinted: Bool = true) -> String {
        resources.jsString(prettyPrinted: prettyPrinted)
    }
}

private func compactResourceContent(_ content: String) -> String {
    content.split { $0.isWhitespace }.joined(separator: " ")
}
