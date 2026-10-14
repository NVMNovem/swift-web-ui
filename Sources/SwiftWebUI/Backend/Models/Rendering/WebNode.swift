//
//  WebNode.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 20/07/2026.
//

/// Renderer-neutral web presentation produced from a ``ViewNode`` tree.
@_spi(Rendering)
public indirect enum WebNode: @unchecked Sendable {
    case empty
    case text(String)
    case element(WebElementNode)
    case fragment([WebNode])
    /// A child that keeps its identity when its siblings are inserted, removed or reordered.
    ///
    /// The key comes from a keyed collection's explicit identity, never from content. It is
    /// only compared between siblings: a key need only be unique within one list of children.
    /// Renders as its content; a static document has nothing to reorder.
    case keyed(String, WebNode)
}
