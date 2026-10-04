//
//  View+Environment.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 29/09/2026.
//

public extension View {

    /// Places `object` in the environment of this view and everything inside it, where
    /// ``Environment`` reads it by its type.
    ///
    /// A second object of the same type placed further in replaces this one for that
    /// subtree only.
    func environment<Object: AnyObject>(_ object: Object) -> EnvironmentWriter<Self, Object> {
        EnvironmentWriter(content: self, object: object)
    }
}

/// A view whose content sees one more object in its environment.
///
/// Adds nothing to the tree it lowers to, so placing an object never changes the DOM.
public struct EnvironmentWriter<Content: View, Object: AnyObject>: View {
    public typealias Body = Never

    let content: Content
    let object: Object

    public var body: Never { fatalError("EnvironmentWriter primitive body unavailable") }

    public func makeViewNode(in context: ViewContext) -> ViewNode {
        EnvironmentStorage.with(EnvironmentStorage.active.inserting(object)) {
            content.makeViewNode(in: context)
        }
    }
}
