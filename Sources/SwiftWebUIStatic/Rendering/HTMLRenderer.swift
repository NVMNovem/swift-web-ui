//
//  HTMLRenderer.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

import SwiftHTML
@_spi(Rendering) import SwiftWebUI

/// Static HTML/CSS/JavaScript renderer for SwiftWebUI view trees.
public struct HTMLRenderer: ViewRendererProtocol {
    public typealias Output = String

    public init() {}

    public func render<Content: View>(_ view: Content) -> String {
        renderView(view).htmlString(prettyPrinted: false)
    }

    public func renderView<Content: View>(_ view: Content) -> RenderedView {
        var context = StaticRenderContext()
        let loweredView = ViewNodeToWebNodeLowerer().lowerView(view.makeViewNode())
        let html = WebNodeStaticLowerer().lower(loweredView.webNode, context: &context)
        return RenderedView(
            content: RenderedContent(html: html),
            resources: context.renderedResources(),
            navigationTitle: loweredView.documentMetadata.navigationTitle,
            navigationIcon: loweredView.documentMetadata.navigationIcon
        )
    }

    public func renderNodes<Content: View>(_ view: Content) -> [SwiftHTML.HTMLNode] {
        renderView(view).content.html
    }
}
