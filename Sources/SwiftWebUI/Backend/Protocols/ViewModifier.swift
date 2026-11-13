//
//  ViewModifier.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 13/11/2026.
//

/// A modifier you apply to a view to produce a different version of it.
///
/// ```swift
/// struct Card: ViewModifier {
///     func body(content: Content) -> some View {
///         content
///             .padding(.px(16))
///             .background(.white)
///             .cornerRadius(.px(12))
///     }
/// }
///
/// Text("Fries").modifier(Card())
/// ```
///
/// Usually paired with an extension that names it, as SwiftUI's modifiers are:
///
/// ```swift
/// extension View {
///     func card() -> some View { modifier(Card()) }
/// }
/// ```
///
/// A modifier is a composed view of its own: it may declare `@State` and
/// `@Environment` properties, and `body(content:)` reads them exactly as a view's
/// `body` does. Its state belongs to the position the modifier is applied at.
///
/// `content` stands for the modified view, and is lowered wherever `body(content:)`
/// places it. Use it once.
public protocol ViewModifier {
    associatedtype Body: View

    /// The view this modifier is applied to.
    typealias Content = ViewModifierContent<Self>

    /// Wraps `content` in this modifier's views and modifiers.
    @ViewBuilder func body(content: Content) -> Body
}

public extension View {
    /// Applies `modifier` to this view.
    func modifier<Modifier: ViewModifier>(_ modifier: Modifier) -> ModifiedContent<Self, Modifier> {
        ModifiedContent(content: self, modifier: modifier)
    }
}

/// A view with a ``ViewModifier`` applied, returned by ``View/modifier(_:)``.
///
/// It lowers like a composed view whose `body` is the modifier's
/// ``ViewModifier/body(content:)``.
public struct ModifiedContent<Content: View, Modifier: ViewModifier>: View {
    public typealias Body = Never

    public let content: Content
    public let modifier: Modifier

    public init(content: Content, modifier: Modifier) {
        self.content = content
        self.modifier = modifier
    }

    public var body: Never { fatalError("ModifiedContent primitive body unavailable") }

    public func makeViewNode(in context: ViewContext) -> ViewNode {
        let content = self.content
        let placeholder = ViewModifierContent<Modifier> { content.makeViewNode(in: $0) }
        return lowerComposed(in: context) { modifier.body(content: placeholder) }
    }
}

/// The view a ``ViewModifier`` is applied to, as its ``ViewModifier/body(content:)``
/// sees it.
///
/// A modifier cannot know the type of the view it modifies, so this hands that view
/// over as a lowering closure. It is the one place composition erases a view's type,
/// because SwiftUI's `ViewModifier` shape requires it; the closure is called once, at
/// the position the modifier placed it, so the view keeps its own state and sees the
/// environment the modifier set up around it.
public struct ViewModifierContent<Modifier: ViewModifier>: View {
    public typealias Body = Never

    private let lower: (ViewContext) -> ViewNode

    init(lower: @escaping (ViewContext) -> ViewNode) {
        self.lower = lower
    }

    public var body: Never { fatalError("ViewModifierContent primitive body unavailable") }

    public func makeViewNode(in context: ViewContext) -> ViewNode {
        lower(context)
    }
}
