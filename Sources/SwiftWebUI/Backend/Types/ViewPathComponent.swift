//
//  ViewPathComponent.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 07/08/2026.
//

/// One step of structural descent through the view tree.
///
/// Components are chosen so that two different view instances can never share a path,
/// and so that a view whose structural position genuinely changes gets a new path and
/// therefore fresh state.
public enum ViewPathComponent: Hashable, Sendable {
    /// A composed view descending into its own `body`.
    case body
    /// A container descending into its single content view.
    case content
    /// A positional child: a `TupleView` slot or an `ArrayView` index.
    case child(Int)
    /// The taken branch of an `if`/`else`.
    case branch(Bool)
    /// The non-`nil` case of an optional view.
    case unwrapped
    /// A keyed collection element.
    case identified(ViewIdentityToken)
}
