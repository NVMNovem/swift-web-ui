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
}
