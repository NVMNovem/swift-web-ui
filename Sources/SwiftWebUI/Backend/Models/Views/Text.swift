//
//  Text.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

/// A text view that renders escaped text with optional semantic HTML role.
///
/// Plain text renders as a `span`. Use ``semanticRole(_:)`` to render paragraph
/// or heading elements without changing visual styling.
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

    /// Returns a copy of the text view that renders with the given HTML semantic role.
    public func semanticRole(_ role: SemanticRole) -> Text {
        var text = self
        text.semanticRole = role
        return text
    }
}
