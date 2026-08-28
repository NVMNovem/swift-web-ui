//
//  ScrollLock.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 28/08/2026.
//

/// Stops the document body scrolling while something is presented over it.
///
/// This is not a modifier. It is a document-level side effect with an ownership
/// problem: two presented things must not each independently decide the page can
/// scroll again. The lock is therefore a counter — the body stops scrolling on
/// the first acquire and starts again only on the last release — owned by
/// ``MountedRoot`` and driven by the presentation primitive, never exposed as a
/// `.scrollLocked()` modifier that any caller could unbalance. A counter anyone
/// can increment is a counter that ends up unbalanced, and the symptom is a page
/// that can never scroll again.
final class ScrollLock<Backend: BrowserHeadBackend> {
    private let backend: Backend
    private var depth = 0
    /// The body's own inline `overflow`, captured at the first acquire.
    ///
    /// `nil` means it had none, and release removes the declaration rather than
    /// writing a guessed `visible` over whatever a stylesheet says.
    private var restoredOverflow: String?
    private var lockedBody: Backend.Node?

    init(backend: Backend) {
        self.backend = backend
    }

    var isLocked: Bool { depth > 0 }

    /// Stops the body scrolling, if it is not stopped already.
    func acquire() {
        depth += 1
        guard depth == 1 else { return }
        do {
            let body = try backend.documentBody()
            restoredOverflow = backend.inlineStyleValue(name: "overflow", on: body)
            lockedBody = body
            backend.setStyle(name: "overflow", value: "hidden", on: body)
        } catch {
            print("[SwiftWebUIRuntime] scroll lock unavailable: \(error)")
            // Nothing was locked, so nothing must be released later.
            depth = 0
        }
    }

    /// Lets the body scroll again, once every holder has released.
    func release() {
        guard depth > 0 else { return }
        depth -= 1
        guard depth == 0, let body = lockedBody else { return }
        if let restoredOverflow {
            backend.setStyle(name: "overflow", value: restoredOverflow, on: body)
        } else {
            backend.removeStyle(name: "overflow", from: body)
        }
        self.restoredOverflow = nil
        lockedBody = nil
    }
}
