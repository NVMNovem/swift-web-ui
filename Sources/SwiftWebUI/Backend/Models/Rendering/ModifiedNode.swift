//
//  ModifiedNode.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 20/07/2026.
//

public struct ModifiedNode {
    public let content: ViewNode
    public let modifiers: [ViewModifierNode]

    public init(content: ViewNode, modifiers: [ViewModifierNode]) {
        self.content = content
        self.modifiers = modifiers
    }
}
