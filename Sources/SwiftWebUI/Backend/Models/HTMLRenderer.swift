//
//  HTMLRenderer.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

import SwiftHTML

public struct HTMLRenderer {
    
    public init() {}

    public func render<V: View>(_ view: V) -> String {
        renderView(view).htmlString(prettyPrinted: false)
    }

    public func renderView<V: View>(_ view: V) -> RenderedView {
        var context = RenderContext()
        let html = view.renderSwiftHTML(context: &context)
        return RenderedView(
            content: RenderedContent(html: html),
            resources: context.renderedResources()
        )
    }

    public func renderNodes<V: View>(_ view: V) -> [any SwiftHTML.HTMLNode] {
        renderView(view).content.html
    }
}
