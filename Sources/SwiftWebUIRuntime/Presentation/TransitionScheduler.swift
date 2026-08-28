//
//  TransitionScheduler.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 28/08/2026.
//

/// Schedules the two moments a CSS transition needs but a synchronous
/// reconciliation never gives it: the frame after an insertion, and the wait
/// before a removal.
///
/// Owned by ``MountedRoot``, so a torn-down root can cancel work that would
/// otherwise fire against nodes that are already gone.
final class TransitionScheduler<Backend: DOMBackend> {
    private let backend: Backend
    private var pending: [Int: Backend.ScheduledWork] = [:]
    private var nextID = 0

    init(backend: Backend) {
        self.backend = backend
    }

    /// Whether anything is still waiting to run.
    var hasPendingWork: Bool { !pending.isEmpty }

    /// Runs `body` on the frame after this one.
    ///
    /// Applying an enter class in the same frame as the insertion is the classic
    /// no-op — the browser never paints the pre-transition state, so there is
    /// nothing to transition from.
    ///
    /// A reader who prefers reduced motion gets it immediately instead: skipping
    /// the animation but keeping the wait is the worst of both.
    func onNextFrame(_ body: @escaping () -> Void) {
        guard !backend.prefersReducedMotion() else {
            body()
            return
        }
        schedule { [backend] in backend.onNextAnimationFrame($0) }(body)
    }

    /// Runs `body` after `milliseconds`.
    ///
    /// A reader who prefers reduced motion gets it immediately, for the same
    /// reason: the point of skipping the animation is not having to wait for it.
    func after(milliseconds: Int, _ body: @escaping () -> Void) {
        guard !backend.prefersReducedMotion(), milliseconds > 0 else {
            body()
            return
        }
        schedule { [backend] in backend.schedule(afterMilliseconds: milliseconds, $0) }(body)
    }

    /// Drops every pending piece of work without running it.
    ///
    /// A timer that fires after its subtree is gone would try to remove a node
    /// that is no longer a child of anything.
    func cancelAll() {
        for work in pending.values {
            backend.cancel(work)
        }
        pending.removeAll()
    }

    /// Registers `body` with `enqueue`, retaining the handle until it runs.
    private func schedule(
        _ enqueue: @escaping (@escaping () -> Void) -> Backend.ScheduledWork
    ) -> (@escaping () -> Void) -> Void {
        { [self] body in
            nextID += 1
            let id = nextID
            pending[id] = enqueue { [weak self] in
                // Dropped before running, so a cancel that lands in the same
                // turn cannot cancel work that has already fired.
                self?.pending[id] = nil
                body()
            }
        }
    }
}
