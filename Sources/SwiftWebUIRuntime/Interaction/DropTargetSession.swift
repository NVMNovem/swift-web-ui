//
//  DropTargetSession.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 11/11/2026.
//

@_spi(Rendering) import SwiftWebUI

/// Turns one element's browser drag events into ``DropTarget`` calls.
///
/// A mounted element keeps one session for as long as it is a drop destination.
/// Reconciliation swaps the ``target`` rather than the session, because a rerender
/// in the middle of a drag — the usual case, since `isTargeted` changes state on
/// entry — must not forget that the drag is in progress, or the browser would
/// refuse the drop.
///
/// The session never counts `dragenter` and `dragleave`: a rerender that replaces
/// a descendant mid-drag loses that descendant's `dragleave`, and a counter would
/// never get back to zero. Instead the backend reports a leave only when the drag
/// has left the element itself, and any `dragover` on an inactive session enters it
/// again, so a missed event heals itself.
final class DropTargetSession {
    var target: DropTarget
    private(set) var isActive = false
    private var isWelcome = false

    init(target: DropTarget) {
        self.target = target
    }

    /// Handles one drag event and returns the operation the browser should show,
    /// or `nil` to refuse the drag.
    ///
    /// A non-`nil` operation that accepts the drop tells the backend to cancel the
    /// event's default, which is how a page tells a browser it takes the drop.
    func handle(_ phase: DragEventPhase, info: DropInfo) -> DropOperation? {
        switch phase {
        case .enter, .over:
            if !isActive {
                isActive = true
                isWelcome = target.validateDrop(info: info)
                if isWelcome {
                    target.dropEntered(info: info)
                }
            }
            guard isWelcome else { return nil }
            return target.dropUpdated(info: info)
        case .leave:
            let wasWelcome = isActive && isWelcome
            reset()
            if wasWelcome {
                target.dropExited(info: info)
            }
            return nil
        case .drop:
            let wasWelcome = isActive && isWelcome
            reset()
            guard wasWelcome else { return nil }
            _ = target.performDrop(info: info)
            // Whatever the delegate answered, the drop happened here: cancelling
            // the default keeps the browser from opening the dropped content.
            return .copy
        }
    }

    private func reset() {
        isActive = false
        isWelcome = false
    }
}
