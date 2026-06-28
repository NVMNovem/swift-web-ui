//
//  Text.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

public struct Text: View {
    public typealias Body = AnyView

    var content: String
    var semanticRole: SemanticRole

    public init(_ content: String) {
        self.content = content
        self.semanticRole = .span
    }

    public var body: AnyView {
        AnyView(EmptyView())
    }

    public func semanticRole(_ role: SemanticRole) -> Text {
        var text = self
        text.semanticRole = role
        return text
    }
}
