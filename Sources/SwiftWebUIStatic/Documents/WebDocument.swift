//
//  WebDocument.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

import Foundation
import SwiftHTML
import SwiftWebUI

public struct WebDocument {
    public var title: String?
    public var meta: [MetaTag]
    public var renderedView: RenderedView
    public var stylesheetPath: String?
    public var scriptPath: String?

    public init(
        title: String? = nil,
        meta: [MetaTag] = [.charset("utf-8"), .viewport],
        renderedView: RenderedView,
        stylesheetPath: String? = "styles.css",
        scriptPath: String? = nil
    ) {
        self.title = title
        self.meta = meta
        self.renderedView = renderedView
        self.stylesheetPath = stylesheetPath
        self.scriptPath = scriptPath
    }

    public init<Content: View>(
        title: String? = nil,
        meta: [MetaTag] = [.charset("utf-8"), .viewport],
        stylesheetPath: String? = "styles.css",
        scriptPath: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            title: title,
            meta: meta,
            renderedView: HTMLRenderer().renderView(content()),
            stylesheetPath: stylesheetPath,
            scriptPath: scriptPath
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
                        children: [
                            element("head", children: headNodes()),
                            element("body", children: bodyNodes()),
                        ]
                    )
                ]
            )
        )
    }

    private func headNodes() -> [SwiftHTML.HTMLNode] {
        var nodes = meta.map(\.htmlNode)
        if let title {
            nodes.append(element("title", children: [.text(title)]))
        }
        if let stylesheetPath, !renderedView.cssString().isBlank {
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
        return nodes
    }

    private func bodyNodes() -> [SwiftHTML.HTMLNode] {
        var nodes = renderedView.content.html
        if let scriptPath, !renderedView.jsString().isBlank {
            nodes.append(
                element(
                    "script",
                    attributes: [.init("src", scriptPath)]
                )
            )
        }
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

public struct MetaTag: Equatable, Sendable {
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

    var htmlNode: SwiftHTML.HTMLNode {
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
        if let stylesheetPath = document.stylesheetPath {
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
