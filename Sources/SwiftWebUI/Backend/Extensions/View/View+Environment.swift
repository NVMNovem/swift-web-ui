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

    /// Places `value` under `key` in the environment of this view and everything inside
    /// it, where ``Environment`` reads it with `@Environment(Key.self)`.
    ///
    /// ```swift
    /// Badge().environment(AccentKey.self, .red)
    /// ```
    ///
    /// A value placed further in under the same key replaces this one for that subtree
    /// only.
    ///
    /// This is SwiftUI's `.environment(\.accent, .red)`. It is keyed by type because
    /// key paths are unavailable in Embedded Swift.
    func environment<Key: EnvironmentKey>(_ key: Key.Type, _ value: Key.Value) -> EnvironmentValueWriter<Self, Key> {
        EnvironmentValueWriter(content: self, value: value)
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

/// A view whose content sees one more value in its environment.
///
/// Adds nothing to the tree it lowers to, so placing a value never changes the DOM
/// structure.
public struct EnvironmentValueWriter<Content: View, Key: EnvironmentKey>: View {
    public typealias Body = Never

    let content: Content
    let value: Key.Value

    public var body: Never { fatalError("EnvironmentValueWriter primitive body unavailable") }

    public func makeViewNode(in context: ViewContext) -> ViewNode {
        EnvironmentStorage.with(EnvironmentStorage.active.settingValue(value, for: Key.self)) {
            content.makeViewNode(in: context)
        }
    }
}
