//
//  DOMBackend.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 20/07/2026.
//

protocol DOMBackend: AnyObject {
    associatedtype Node
    associatedtype ActionRegistration
    /// A cancellable piece of scheduled work.
    ///
    /// Distinct from `ActionRegistration` because cancelling needs the browser's
    /// timer or frame handle, not the closure that was registered.
    associatedtype ScheduledWork

    func createElement(_ tagName: String) -> Node
    func createTextNode(_ content: String) -> Node
    func setText(_ content: String, on node: Node)
    func setAttribute(name: String, value: String, on node: Node)
    func removeAttribute(name: String, from node: Node)
    func setStyle(name: String, value: String, on node: Node)
    func removeStyle(name: String, from node: Node)
    func setClickAction(_ action: @escaping () -> Void, on node: Node) -> ActionRegistration
    func removeClickAction(from node: Node, registration: ActionRegistration)
    /// Installs a key-down handler that fires only for the given `keys`.
    ///
    /// The handler receives the `KeyboardEvent.key` string that matched, so the
    /// caller can dispatch to the right intent.
    func setKeyAction(
        keys: [String],
        action: @escaping (String) -> Void,
        on node: Node
    ) -> ActionRegistration
    func removeKeyAction(from node: Node, registration: ActionRegistration)
    /// Shows `node` as a dialog, in the top layer when `modal` is `true`.
    ///
    /// The node must already be in the document.
    func presentDialog(_ node: Node, modal: Bool)
    /// Closes `node` as a dialog.
    func dismissDialog(_ node: Node)
    /// Installs a handler for the browser closing `node` on its own.
    func setDismissAction(_ action: @escaping () -> Void, on node: Node) -> ActionRegistration
    func removeDismissAction(from node: Node, registration: ActionRegistration)
    func append(_ child: Node, to parent: Node)
    func insert(_ child: Node, into parent: Node, before reference: Node?)
    func remove(_ child: Node, from parent: Node)
    func removeAllChildren(from parent: Node)
    /// Moves focus to `node`.
    ///
    /// A `focus()` on a node that is not in the document is silently a no-op, so
    /// callers must insert first.
    func focus(_ node: Node)
    /// Runs `body` on the next animation frame.
    ///
    /// Applying a class in the same frame as an insertion is the classic no-op:
    /// the browser never paints the pre-transition state, so there is nothing to
    /// transition from.
    func onNextAnimationFrame(_ body: @escaping () -> Void) -> ScheduledWork
    /// Runs `body` after `milliseconds`.
    func schedule(afterMilliseconds milliseconds: Int, _ body: @escaping () -> Void) -> ScheduledWork
    /// Cancels work that has not run yet.
    func cancel(_ work: ScheduledWork)
    /// Whether the reader has asked for reduced motion.
    func prefersReducedMotion() -> Bool
}

enum BrowserHeadBackendError: Error, CustomStringConvertible {
    case documentHeadUnavailable
    case documentBodyUnavailable

    var description: String {
        switch self {
        case .documentHeadUnavailable:
            "the browser document has no head element"
        case .documentBodyUnavailable:
            "the browser document has no body element"
        }
    }
}

protocol BrowserHeadBackend: DOMBackend {
    var documentTitle: String { get }
    func setDocumentTitle(_ title: String)
    func documentHead() throws -> Node
    func documentBody() throws -> Node
    func setResourceText(_ content: String, on node: Node) throws
    /// Reads one inline style declaration back off a node.
    ///
    /// Returns `nil` when the node carries no inline declaration of that name.
    ///
    /// This exists for document-level side effects that must restore what they
    /// found — the body's scroll lock. Reconciliation must not use it: the
    /// mounted tree, not the DOM, is authoritative about an element's styles.
    func inlineStyleValue(name: String, on node: Node) -> String?
}
