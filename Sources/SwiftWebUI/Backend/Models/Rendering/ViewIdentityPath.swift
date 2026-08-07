//
//  ViewIdentityPath.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 07/08/2026.
//

/// The structural location of a view in the tree, used as state-slot identity.
///
/// Unlike the runtime's positional `NodePath`, this path descends through builder
/// carriers, so it distinguishes sibling views, `if`/`else` branches, and keyed
/// collection elements. It is stable across rebuilds as long as the view keeps the
/// same structural position.
public struct ViewIdentityPath: Hashable, Sendable {
    public private(set) var components: [ViewPathComponent]

    public static let root = ViewIdentityPath(components: [])

    public init(components: [ViewPathComponent] = []) {
        self.components = components
    }

    public func appending(_ component: ViewPathComponent) -> ViewIdentityPath {
        ViewIdentityPath(components: components + [component])
    }
}
