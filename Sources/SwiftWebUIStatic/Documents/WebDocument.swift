//
//  WebDocument.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

import Foundation
import SwiftHTML
import SwiftWebUI

/// Where the rendered view's own CSS is delivered.
public enum RenderedStyleDelivery: Equatable, Sendable {
    /// Written beside the document at `stylesheetPath` and linked from `<head>`.
    case stylesheet
    /// Emitted as a `<style>` block in `<head>`.
    ///
    /// For a document that has to paint before anything else loads: a second
    /// file to fetch is a second round trip in front of the first frame.
    case inline
}

/// When the `<link rel="stylesheet">` is written.
public enum StylesheetLinkPolicy: Equatable, Sendable {
    /// Only when the rendered view has CSS of its own.
    case automatic
    /// Whenever `stylesheetPath` is set, whatever the rendered view carries.
    ///
    /// For the application stylesheet that is not the rendered view's output —
    /// a hand-written palette the document still has to pull in.
    case always
}

/// A `<script>` element, by content rather than by tag.
public struct WebScript: Equatable, Sendable {
    /// What the browser executes: a URL to fetch, or the text of the element.
    public enum Body: Equatable, Sendable {
        case source(String)
        case inline(String)
    }

    public var body: Body
    /// The `type` attribute: `module`, `importmap`, or nil for a classic script.
    public var type: String?
    public var isDeferred: Bool

    public init(body: Body, type: String? = nil, isDeferred: Bool = false) {
        self.body = body
        self.type = type
        self.isDeferred = isDeferred
    }

    /// A `<script src=…>`.
    public static func source(
        _ path: String,
        type: String? = nil,
        isDeferred: Bool = false
    ) -> WebScript {
        WebScript(body: .source(path), type: type, isDeferred: isDeferred)
    }

    /// A classic inline script.
    public static func inline(_ content: String) -> WebScript {
        WebScript(body: .inline(content))
    }

    /// An inline `<script type="module">`.
    public static func module(_ content: String) -> WebScript {
        WebScript(body: .inline(content), type: "module")
    }

    /// An inline `<script type="importmap">`.
    public static func importMap(_ content: String) -> WebScript {
        WebScript(body: .inline(content), type: "importmap")
    }

    var htmlNode: SwiftHTML.HTMLNode {
        var attributes: [SwiftHTML.Attribute] = []
        if let type { attributes.append(.init("type", type)) }
        var children: [SwiftHTML.HTMLNode] = []
        switch body {
        case .source(let path):
            attributes.append(.init("src", path))
        case .inline(let content):
            // Raw: script bodies are not HTML text, and `&&` or `a < b` would not
            // survive escaping.
            children.append(.rawText(content))
        }
        if isDeferred { attributes.append(.init("defer", "")) }
        return .element(.init(tag: "script", attributes: attributes, children: children, isVoid: false))
    }
}

public struct WebDocument {
    public var language: String?
    /// An explicit document title, overriding the rendered view's navigation title.
    public var title: String?
    public var meta: [MetaTag]
    /// Head content `MetaTag` cannot express — `<link rel>`, a media-scoped
    /// `<meta>`, a hand-written `<style>`. Written after the meta tags and
    /// before the title.
    public var headNodes: [SwiftHTML.HTMLNode]
    public var renderedView: RenderedView
    public var stylesheetPath: String?
    public var stylesheetLinkPolicy: StylesheetLinkPolicy
    public var renderedStyleDelivery: RenderedStyleDelivery
    public var scriptPath: String?
    public var headScripts: [WebScript]
    public var bodyScripts: [WebScript]
    /// Nodes placed before the rendered view in `<body>`.
    public var bodyPrefixNodes: [SwiftHTML.HTMLNode]
    /// Nodes placed after the rendered view in `<body>`, before any script.
    ///
    /// This is what lets a runtime mount point and a build-time rendered view be
    /// siblings in one document.
    public var bodySuffixNodes: [SwiftHTML.HTMLNode]

    public init(
        title: String? = nil,
        meta: [MetaTag] = [.charset("utf-8"), .viewport],
        renderedView: RenderedView,
        stylesheetPath: String? = "styles.css",
        scriptPath: String? = nil,
        language: String? = nil,
        headNodes: [SwiftHTML.HTMLNode] = [],
        stylesheetLinkPolicy: StylesheetLinkPolicy = .automatic,
        renderedStyleDelivery: RenderedStyleDelivery = .stylesheet,
        headScripts: [WebScript] = [],
        bodyScripts: [WebScript] = [],
        bodyPrefixNodes: [SwiftHTML.HTMLNode] = [],
        bodySuffixNodes: [SwiftHTML.HTMLNode] = []
    ) {
        self.title = title
        self.meta = meta
        self.renderedView = renderedView
        self.stylesheetPath = stylesheetPath
        self.scriptPath = scriptPath
        self.language = language
        self.headNodes = headNodes
        self.stylesheetLinkPolicy = stylesheetLinkPolicy
        self.renderedStyleDelivery = renderedStyleDelivery
        self.headScripts = headScripts
        self.bodyScripts = bodyScripts
        self.bodyPrefixNodes = bodyPrefixNodes
        self.bodySuffixNodes = bodySuffixNodes
    }

    public init<Content: View>(
        title: String? = nil,
        meta: [MetaTag] = [.charset("utf-8"), .viewport],
        stylesheetPath: String? = "styles.css",
        scriptPath: String? = nil,
        language: String? = nil,
        headNodes: [SwiftHTML.HTMLNode] = [],
        stylesheetLinkPolicy: StylesheetLinkPolicy = .automatic,
        renderedStyleDelivery: RenderedStyleDelivery = .stylesheet,
        headScripts: [WebScript] = [],
        bodyScripts: [WebScript] = [],
        bodyPrefixNodes: [SwiftHTML.HTMLNode] = [],
        bodySuffixNodes: [SwiftHTML.HTMLNode] = [],
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            title: title,
            meta: meta,
            renderedView: HTMLRenderer().renderView(content()),
            stylesheetPath: stylesheetPath,
            scriptPath: scriptPath,
            language: language,
            headNodes: headNodes,
            stylesheetLinkPolicy: stylesheetLinkPolicy,
            renderedStyleDelivery: renderedStyleDelivery,
            headScripts: headScripts,
            bodyScripts: bodyScripts,
            bodyPrefixNodes: bodyPrefixNodes,
            bodySuffixNodes: bodySuffixNodes
        )
    }

    public func htmlString(prettyPrinted: Bool = true) -> String {
        SwiftHTML.HTMLStringRenderer(
            options: .init(prettyPrinted: prettyPrinted)
        ).render(htmlDocument())
    }

    private func htmlDocument() -> SwiftHTML.HTMLNode {
        .document(
            .init(
                children: [
                    element(
                        "html",
                        attributes: language.map { [SwiftHTML.Attribute("lang", $0)] } ?? [],
                        children: [
                            element("head", children: renderedHeadNodes()),
                            element("body", children: renderedBodyNodes()),
                        ]
                    )
                ]
            )
        )
    }

    private func renderedHeadNodes() -> [SwiftHTML.HTMLNode] {
        var nodes = meta.map(\.htmlNode)
        nodes.append(contentsOf: self.headNodes)
        if let title = title ?? renderedView.navigationTitle {
            nodes.append(element("title", children: [.text(title)]))
        }
        if let stylesheetPath, linksStylesheet {
            nodes.append(
                element(
                    "link",
                    attributes: [
                        .init("rel", "stylesheet"),
                        .init("href", stylesheetPath),
                    ],
                    isVoid: true
                )
            )
        }
        if renderedStyleDelivery == .inline {
            let css = renderedView.cssString()
            if !css.isBlank {
                nodes.append(element("style", children: [.rawText(css)]))
            }
        }
        nodes.append(contentsOf: headScripts.map(\.htmlNode))
        return nodes
    }

    /// Whether the `<link rel="stylesheet">` is written at all.
    ///
    /// `.automatic` keeps the historical rule — no link when the rendered view
    /// produced no CSS, because `PreviewExporter` would not have written the file
    /// either. Inlining the rendered CSS never links it.
    private var linksStylesheet: Bool {
        switch stylesheetLinkPolicy {
        case .always:
            true
        case .automatic:
            renderedStyleDelivery == .stylesheet && !renderedView.cssString().isBlank
        }
    }

    private func renderedBodyNodes() -> [SwiftHTML.HTMLNode] {
        var nodes = bodyPrefixNodes
        nodes.append(contentsOf: renderedView.content.html)
        nodes.append(contentsOf: bodySuffixNodes)
        if let scriptPath, !renderedView.jsString().isBlank {
            nodes.append(
                element(
                    "script",
                    attributes: [.init("src", scriptPath)]
                )
            )
        }
        nodes.append(contentsOf: bodyScripts.map(\.htmlNode))
        return nodes
    }

    private func element(
        _ tag: String,
        attributes: [SwiftHTML.Attribute] = [],
        children: [SwiftHTML.HTMLNode] = [],
        isVoid: Bool = false
    ) -> SwiftHTML.HTMLNode {
        .element(.init(tag: tag, attributes: attributes, children: children, isVoid: isVoid))
    }
}

public struct MetaTag: Equatable, Sendable, SwiftHTML.HTMLNodeConvertible {
    public var name: String?
    public var property: String?
    public var content: String?
    public var charset: String?

    public init(
        name: String? = nil,
        property: String? = nil,
        content: String? = nil,
        charset: String? = nil
    ) {
        self.name = name
        self.property = property
        self.content = content
        self.charset = charset
    }

    public static func charset(_ value: String) -> MetaTag {
        MetaTag(charset: value)
    }

    public static let viewport = MetaTag.name(
        "viewport",
        content: "width=device-width, initial-scale=1"
    )

    public static func name(_ name: String, content: String) -> MetaTag {
        MetaTag(name: name, content: content)
    }

    public static func property(_ property: String, content: String) -> MetaTag {
        MetaTag(property: property, content: content)
    }

    /// Public so a document that also carries verbatim head nodes can put the
    /// two in one list.
    public var htmlNode: SwiftHTML.HTMLNode {
        var attributes: [SwiftHTML.Attribute] = []
        if let charset { attributes.append(.init("charset", charset)) }
        if let name { attributes.append(.init("name", name)) }
        if let property { attributes.append(.init("property", property)) }
        if let content { attributes.append(.init("content", content)) }
        return .element(
            .init(tag: "meta", attributes: attributes, children: [], isVoid: true)
        )
    }
}

public struct PreviewExporter {
    public static func export(_ document: WebDocument, to folder: URL) throws {
        try FileManager.default.createDirectory(
            at: folder,
            withIntermediateDirectories: true
        )
        try document.htmlString(prettyPrinted: true).write(
            to: folder.appendingPathComponent("index.html"),
            atomically: true,
            encoding: .utf8
        )
        // Inlined CSS is already in the document; writing it beside the document
        // as well would ship the same bytes twice.
        if let stylesheetPath = document.stylesheetPath,
           document.renderedStyleDelivery == .stylesheet {
            let css = document.renderedView.cssString()
            if !css.isBlank {
                try css.write(
                    to: folder.appendingPathComponent(stylesheetPath),
                    atomically: true,
                    encoding: .utf8
                )
            }
        }
        if let scriptPath = document.scriptPath {
            let js = document.renderedView.jsString()
            if !js.isBlank {
                try js.write(
                    to: folder.appendingPathComponent(scriptPath),
                    atomically: true,
                    encoding: .utf8
                )
            }
        }
    }
}

private extension String {
    var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
