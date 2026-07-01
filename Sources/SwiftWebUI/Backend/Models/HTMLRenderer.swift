//
//  HTMLRenderer.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

import SwiftHTML

/// Renders SwiftWebUI views into HTML content and extracted resources.
///
/// `HTMLRenderer` is the primary bridge from the SwiftWebUI view DSL to
/// SwiftHTML nodes and SwiftCSS resource output.
public struct HTMLRenderer {
    
    public init() {}

    /// Renders a view directly to a compact HTML string.
    public func render<V: View>(_ view: V) -> String {
        renderView(view).htmlString(prettyPrinted: false)
    }

    /// Renders a view into separated content, style resources, and script resources.
    public func renderView<V: View>(_ view: V) -> RenderedView {
        var context = RenderContext()
        let html = view.renderSwiftHTML(context: &context)
        return RenderedView(
            content: RenderedContent(html: html),
            resources: context.renderedResources()
        )
    }

    /// Renders a view into SwiftHTML nodes.
    public func renderNodes<V: View>(_ view: V) -> [any SwiftHTML.HTMLNode] {
        renderView(view).content.html
    }
}
