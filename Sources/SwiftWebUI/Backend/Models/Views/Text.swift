//
//  Text.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

public struct Text: View {
    public typealias Body = Never
    public let content: String
    public let semanticRole: SemanticRole

    public init(_ content: String, semanticRole: SemanticRole = .span) {
        self.content = content
        self.semanticRole = semanticRole
    }

    public func semanticRole(_ role: SemanticRole) -> Text {
        Text(content, semanticRole: role)
    }

    public var body: Never { fatalError("Text primitive body unavailable") }
    public func makeViewNode() -> ViewNode { .text(.init(content: content, semanticRole: semanticRole)) }
}
