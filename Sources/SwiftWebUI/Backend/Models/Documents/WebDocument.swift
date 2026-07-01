//
//  WebDocument.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

import Foundation
import SwiftHTML

/// A complete browser HTML document built from a rendered SwiftWebUI view.
///
/// `WebDocument` wraps ``RenderedView`` content in document markup and links
/// stylesheet or script paths when matching resources exist.
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

    public init<V: View>(
        title: String? = nil,
        meta: [MetaTag] = [.charset("utf-8"), .viewport],
        stylesheetPath: String? = "styles.css",
        scriptPath: String? = nil,
        @ViewBuilder content: () -> V
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
        htmlDocument().render(prettyPrinted: prettyPrinted)
    }

    private func htmlDocument() -> SwiftHTML.HTMLDocument {
        SwiftHTML.HTMLDocument {
            SwiftHTML.HTML([]) {
                SwiftHTML.Head([]) {
                    headNodes()
                }
                SwiftHTML.Body([]) {
                    bodyNodes()
                }
            }
        }
    }

    private func headNodes() -> [any SwiftHTML.HTMLNode] {
        var nodes = meta.map { $0.htmlNode() }

        if let title {
            nodes.append(
                SwiftHTML.Title([]) {
                    SwiftHTML.TextNode(title)
                }
            )
        }

        if let stylesheetPath, !renderedView.cssString(prettyPrinted: true).isBlank {
            nodes.append(
                SwiftHTML.Link(
                    .rel("stylesheet"),
                    .href(stylesheetPath)
                )
            )
        }

        return nodes
    }

    private func bodyNodes() -> [any SwiftHTML.HTMLNode] {
        var nodes = renderedView.content.html

        if let scriptPath, !renderedView.jsString(prettyPrinted: true).isBlank {
            nodes.append(
                SwiftHTML.Script([
                    .src(scriptPath)
                ])
            )
        }

        return nodes
    }
}

/// A metadata tag rendered in a ``WebDocument`` head.
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
}

/// Writes a ``WebDocument`` and its extracted resources to a folder.
public struct PreviewExporter {
    
    public static func export(
        _ document: WebDocument,
        to folder: URL
    ) throws {
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
            let css = document.renderedView.cssString(prettyPrinted: true)
            if !css.isBlank {
                try css.write(
                    to: folder.appendingPathComponent(stylesheetPath),
                    atomically: true,
                    encoding: .utf8
                )
            }
        }

        if let scriptPath = document.scriptPath {
            let js = document.renderedView.jsString(prettyPrinted: true)
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

private extension MetaTag {
    
    func htmlNode() -> any SwiftHTML.HTMLNode {
        SwiftHTML.Meta(htmlAttributes)
    }

    var htmlAttributes: [SwiftHTML.Attribute] {
        var attributes: [SwiftHTML.Attribute] = []
        if let charset {
            attributes.append(.charset(charset))
        }
        if let name {
            attributes.append(.name(name))
        }
        if let property {
            attributes.append(.init("property", property))
        }
        if let content {
            attributes.append(.content(content))
        }
        return attributes
    }
}

private extension SwiftHTML.Meta {
    
    init(_ attributes: [SwiftHTML.Attribute]) {
        self.init(attributes: attributes)
    }

    private init(attributes: [SwiftHTML.Attribute]) {
        switch attributes.count {
        case 0:
            self.init()
        case 1:
            self.init(attributes[0])
        case 2:
            self.init(attributes[0], attributes[1])
        case 3:
            self.init(attributes[0], attributes[1], attributes[2])
        default:
            self.init(attributes[0], attributes[1], attributes[2], attributes[3])
        }
    }
}

private extension String {
    
    var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
