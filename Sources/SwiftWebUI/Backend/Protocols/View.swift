//
//  View.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

/// A declarative SwiftWebUI component.
public protocol View {
    associatedtype Body: View

    @ViewBuilder var body: Body { get }

    /// Lowers the view to renderer-neutral semantic data.
    func makeViewNode() -> ViewNode
}

public extension View {
    func makeViewNode() -> ViewNode {
        body.makeViewNode()
    }
}
