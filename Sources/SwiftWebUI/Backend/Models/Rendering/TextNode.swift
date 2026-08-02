//
//  TextNode.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 20/07/2026.
//

public struct TextNode {
    public let content: String
    public let semanticRole: SemanticRole

    public init(content: String, semanticRole: SemanticRole) {
        self.content = content
        self.semanticRole = semanticRole
    }
}
