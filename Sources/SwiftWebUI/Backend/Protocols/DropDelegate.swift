//
//  DropDelegate.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 11/11/2026.
//

/// An object that takes part in a drop on a view, step by step.
///
/// SwiftUI's `DropDelegate`, for ``View/onDrop(of:delegate:)``. Every method but
/// ``performDrop(info:)`` has a default.
///
/// The order is the one SwiftUI uses: ``validateDrop(info:)`` decides whether the
/// drag is welcome at all; a welcome drag gets ``dropEntered(info:)``, then
/// ``dropUpdated(info:)`` as it moves, and finally either
/// ``performDrop(info:)`` or ``dropExited(info:)``. A drag whose content conforms
/// to none of the destination's content types is never offered to the delegate.
///
/// Methods are called while the browser delivers the drag event, so a delegate
/// that changes state rerenders the page before the next one.
public protocol DropDelegate {
    /// Whether to accept a drag that has just arrived. Defaults to `true`.
    func validateDrop(info: DropInfo) -> Bool
    /// Called when a welcome drag enters the view.
    func dropEntered(info: DropInfo)
    /// Called as a welcome drag moves over the view.
    ///
    /// Return a proposal to choose the operation, or `nil` — the default — to copy.
    /// A ``DropOperation/cancel`` or ``DropOperation/forbidden`` proposal refuses
    /// the drop.
    func dropUpdated(info: DropInfo) -> DropProposal?
    /// Called when a welcome drag leaves the view without being dropped.
    func dropExited(info: DropInfo)
    /// Called when a welcome drag is dropped on the view.
    ///
    /// Return whether the drop was handled. The browser has already given up the
    /// content by now, so returning `false` does not hand it back to the source.
    func performDrop(info: DropInfo) -> Bool
}

public extension DropDelegate {
    func validateDrop(info: DropInfo) -> Bool { true }
    func dropEntered(info: DropInfo) {}
    func dropUpdated(info: DropInfo) -> DropProposal? { nil }
    func dropExited(info: DropInfo) {}
}
