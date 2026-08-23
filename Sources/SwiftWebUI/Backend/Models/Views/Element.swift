//
//  Element.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/08/2026.
//

/// A container that lowers to an explicitly named element.
///
/// The typed views cover the semantics SwiftWebUI has opinions about. `Element`
/// covers the rest: markup that carries no SwiftWebUI meaning but still has to
/// appear in the tree, such as the `svg` and `circle` of a progress ring.
///
/// It is a tag name, not an escape hatch for markup — the content is an ordinary
/// view tree and attributes come from ``View/attribute(_:_:)``, so the core keeps
/// its rule of holding no HTML strings:
///
/// ```swift
/// Element("svg") {
///     Element("circle") {}
///         .class("ring-track")
///         .attribute("cx", "40")
/// }
/// .attribute("viewBox", "0 0 80 80")
/// ```
///
/// The name is written through to the backends verbatim, so casing is preserved
/// for the foreign elements that need it.
public struct Element<Content: View>: View {
    public typealias Body = Never
    public let tag: String
    public let content: Content

    public init(_ tag: String, @ViewBuilder content: () -> Content) {
        self.tag = tag
        self.content = content()
    }

    public var body: Never { fatalError("Element primitive body unavailable") }

    public func makeViewNode(in context: ViewContext) -> ViewNode {
        .container(.init(kind: .element(tag: tag), children: content.makeViewNode(in: context.content).groupChildren))
    }
}

public extension Element where Content == EmptyView {
    /// An element with no children, for the leaf shapes that only carry attributes.
    init(_ tag: String) {
        self.init(tag) { EmptyView() }
    }
}
