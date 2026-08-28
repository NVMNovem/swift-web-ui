//
//  Link.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

public struct Link: View {
    public typealias Body = Never
    public let destination: String
    public let label: ViewNode
    public let usesPlainTextLabel: Bool

    /// Creates a link whose label is a single run of text.
    ///
    /// The label is built in a detached ``ViewContext``, so a `@State` value
    /// declared while producing it does not bind to the mounted root's slot
    /// store and silently falls back to private storage. Declare state on the
    /// enclosing view instead.
    public init(_ label: String, destination: String) {
        self.destination = destination
        self.label = Text(label).makeViewNode(in: .detached)
        self.usesPlainTextLabel = true
    }

    /// Creates a link whose label is arbitrary content.
    ///
    /// The content closure is evaluated in a detached ``ViewContext``, so a
    /// `@State` value declared inside it does not bind to the mounted root's
    /// slot store and silently falls back to private storage. Declare state on
    /// the enclosing view instead.
    public init<Content: View>(destination: String, @ViewBuilder content: () -> Content) {
        self.destination = destination
        self.label = content().makeViewNode(in: .detached)
        self.usesPlainTextLabel = false
    }

    public var body: Never { fatalError("Link primitive body unavailable") }
    public func makeViewNode(in context: ViewContext) -> ViewNode {
        .link(.init(destination: destination, label: label, usesPlainTextLabel: usesPlainTextLabel))
    }
}
