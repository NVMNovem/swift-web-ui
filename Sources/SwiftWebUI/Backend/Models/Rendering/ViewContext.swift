//
//  ViewContext.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 07/08/2026.
//

/// Traversal context threaded through `makeViewNode(in:)`.
///
/// It carries the structural identity of the view currently being lowered. Primitive
/// views append the component that describes how they descend into their children;
/// composed views append `.body` before evaluating their `body`.
public struct ViewContext: Sendable {
    public let path: ViewIdentityPath

    /// Suppresses state-slot participation for this traversal.
    ///
    /// Some primitives lower their content eagerly inside their own initializer -- `Tab`
    /// and `Button` store an already-lowered `ViewNode`. Such a traversal has no real
    /// position in the tree, so giving it one would let unrelated subtrees collide on the
    /// same path. Detached traversals bind no slots, and `State` inside them falls back
    /// to a private box.
    public let isDetached: Bool

    public static let root = ViewContext(path: .root)
    public static let detached = ViewContext(path: .root, isDetached: true)

    public init(path: ViewIdentityPath = .root, isDetached: Bool = false) {
        self.path = path
        self.isDetached = isDetached
    }

    public func appending(_ component: ViewPathComponent) -> ViewContext {
        ViewContext(path: path.appending(component), isDetached: isDetached)
    }

    /// Descends into positional child `index`.
    public func child(_ index: Int) -> ViewContext {
        appending(.child(index))
    }

    /// Descends into a container's single content view.
    public var content: ViewContext {
        appending(.content)
    }
}
