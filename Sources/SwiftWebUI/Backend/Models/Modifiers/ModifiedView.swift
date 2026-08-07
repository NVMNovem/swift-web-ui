//
//  ModifiedView.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

public struct ModifiedView<Content: View>: View {
    public typealias Body = Never
    public let content: Content
    public let modifiers: [ViewModifierNode]

    public init(content: Content, modifiers: [ViewModifierNode]) {
        self.content = content
        self.modifiers = modifiers
    }

    public var body: Never { fatalError("ModifiedView primitive body unavailable") }

    public func makeViewNode(in context: ViewContext) -> ViewNode {
        .modified(ModifiedNode(content: content.makeViewNode(in: context.content), modifiers: modifiers))
    }
}
