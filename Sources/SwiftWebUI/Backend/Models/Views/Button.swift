//
//  Button.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

public struct Button: View {
    public typealias Body = Never
    public let label: ViewNode
    public let action: (() -> Void)?

    /// Creates a button whose label is a single run of text.
    ///
    /// The label is built in a detached ``ViewContext``, so a `@State` value
    /// declared while producing it does not bind to the mounted root's slot
    /// store and silently falls back to private storage. Declare state on the
    /// enclosing view instead.
    public init(_ label: String, action: (() -> Void)? = nil) {
        self.label = Text(label).makeViewNode(in: .detached)
        self.action = action
    }

    /// Creates a button whose label is arbitrary content.
    ///
    /// Use this when a control's content is more than a string — an image beside
    /// a name, for instance — so that the whole presentation is the control
    /// rather than a decoy element stretched over it.
    ///
    /// The content closure is evaluated in a detached ``ViewContext``, so a
    /// `@State` value declared inside it does not bind to the mounted root's
    /// slot store and silently falls back to private storage. Declare state on
    /// the enclosing view instead.
    public init<Content: View>(
        action: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.label = content().makeViewNode(in: .detached)
        self.action = action
    }

    public var body: Never { fatalError("Button primitive body unavailable") }
    public func makeViewNode(in context: ViewContext) -> ViewNode {
        .button(.init(label: label, action: action.map(ActionIntent.closure)))
    }
}
