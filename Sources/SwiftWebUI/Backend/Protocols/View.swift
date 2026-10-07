//
//  View.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

/// A declarative SwiftWebUI component.
public protocol View {
    associatedtype Body: View

    @ViewBuilder var body: Body { get }

    /// Lowers the view to renderer-neutral semantic data at a structural position.
    func makeViewNode(in context: ViewContext) -> ViewNode
}

public extension View {
    /// Evaluates `body` with this view's structural identity installed as the current
    /// state scope.
    ///
    /// The scope must be established around the `body` evaluation, not around the
    /// view's construction: a view is constructed while its *parent's* body runs, so
    /// binding at construction time would give every subview its parent's identity.
    /// `State` therefore binds lazily on first access, which happens here.
    ///
    /// ``Environment`` properties answer at the same moment and for the same reason:
    /// the objects this view's ancestors placed are known only now. The `body` getter
    /// and the lowering of its result are marked while they run so that a read is
    /// recognised as this view reading its own environment.
    func makeViewNode(in context: ViewContext) -> ViewNode {
        guard !context.isDetached else {
            let previous = StateSlotStorage.beginScope(nil)
            defer { StateSlotStorage.endScope(previous) }
            return EnvironmentStorage.lowering(evaluate: { body }, lower: { $0.makeViewNode(in: context) })
        }
        let scoped = context.appending(.body)
        StateSlotStorage.markVisited(scoped.path)
        let previous = StateSlotStorage.beginScope(scoped.path)
        defer { StateSlotStorage.endScope(previous) }
        return EnvironmentStorage.lowering(evaluate: { body }, lower: { $0.makeViewNode(in: scoped) })
    }

    /// Lowers the view from the root of a fresh traversal.
    func makeViewNode() -> ViewNode {
        makeViewNode(in: .root)
    }
}
