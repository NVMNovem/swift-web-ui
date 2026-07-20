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

    public init(_ label: String, destination: String) {
        self.destination = destination
        self.label = Text(label).makeViewNode()
        self.usesPlainTextLabel = true
    }

    public init<Content: View>(destination: String, @ViewBuilder content: () -> Content) {
        self.destination = destination
        self.label = content().makeViewNode()
        self.usesPlainTextLabel = false
    }

    public var body: Never { fatalError("Link primitive body unavailable") }
    public func makeViewNode() -> ViewNode {
        .link(.init(destination: destination, label: label, usesPlainTextLabel: usesPlainTextLabel))
    }
}
