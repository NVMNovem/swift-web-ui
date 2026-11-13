//
//  View+Lifecycle.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 13/11/2026.
//

// Implicit everywhere but Embedded Swift, which imports it only on request.
import _Concurrency

public extension View {

    /// Adds an action to perform when this view appears.
    ///
    /// The view appears when a build first reaches it and the DOM shows it: on the
    /// first mount, when an `if` starts taking its branch, when a `ForEach` gains its
    /// element. The action runs after that DOM update, never inside a `body`, so it
    /// may write state. That write schedules the next build.
    ///
    /// A view keeps having appeared for as long as rebuilds keep reaching it at the
    /// same structural position, exactly as its `State` survives.
    ///
    /// The action runs only in the browser runtime. A static render never calls it.
    func onAppear(perform action: (() -> Void)? = nil) -> LifecycleView<Self> {
        let action = action.map(EnvironmentStorage.capturing)
        return LifecycleView(content: self) { store, path in
            if let action {
                store.registerAppear(at: path, perform: action)
            } else {
                store.registerAppear(at: path) {}
            }
        }
    }

    /// Adds an action to perform when this view disappears.
    ///
    /// The view disappears when a build no longer reaches it, and when its root
    /// unmounts. The action runs after the DOM update that removed it. It is the
    /// action of the latest build that reached the view, so it sees that build's
    /// values.
    ///
    /// The action runs only in the browser runtime. A static render never calls it.
    func onDisappear(perform action: (() -> Void)? = nil) -> LifecycleView<Self> {
        let action = action.map(EnvironmentStorage.capturing)
        return LifecycleView(content: self) { store, path in
            store.registerDisappear(at: path, perform: action ?? {})
        }
    }

    /// Adds an asynchronous task to perform when this view appears, cancelled when it
    /// disappears.
    ///
    /// ```swift
    /// struct ShopView: View {
    ///     @State private var shop: Shop?
    ///
    ///     var body: some View {
    ///         content
    ///             .task {
    ///                 shop = await service.shop(for: host)
    ///             }
    ///     }
    /// }
    /// ```
    ///
    /// The task starts after the DOM shows the view, so a view can start the work it
    /// needs instead of an ancestor starting it and mounting again. It is cancelled
    /// when a build no longer reaches the view or the root unmounts; cancellation is
    /// cooperative, as for any `Task`, so long work checks `Task.isCancelled`.
    ///
    /// The task is not isolated to an actor: Embedded Swift has no main actor. The
    /// browser has one thread, and the runtime and every task it starts run on it,
    /// so the task may read and write the view's state.
    ///
    /// ``Environment`` properties the view's `body` read keep their values in the
    /// task. One the `body` never read is looked up when the task reads it, after
    /// the traversal, and may not find the view's own placement.
    ///
    /// The task runs only in the browser runtime. A static render never starts it.
    func task(
        priority: TaskPriority = .userInitiated,
        _ action: @escaping () async -> Void
    ) -> LifecycleView<Self> {
        LifecycleView(content: self) { store, path in
            store.registerTask(at: path, id: TaskWithoutID(), priority: priority, action: action)
        }
    }

    /// Adds an asynchronous task to perform when this view appears, and again each
    /// time `value` changes, cancelled when the view disappears.
    ///
    /// ```swift
    /// ProductList(category: category)
    ///     .task(id: category) {
    ///         products = await service.products(in: category)
    ///     }
    /// ```
    ///
    /// When a build finds a value different from the previous build's, the running
    /// task is cancelled and a new one started, after the DOM update. Otherwise this
    /// is ``task(priority:_:)``.
    func task<ID: Equatable>(
        id value: ID,
        priority: TaskPriority = .userInitiated,
        _ action: @escaping () async -> Void
    ) -> LifecycleView<Self> {
        LifecycleView(content: self) { store, path in
            store.registerTask(at: path, id: value, priority: priority, action: action)
        }
    }

    /// Adds an action to perform when `value` changes.
    ///
    /// ```swift
    /// SearchField(text: $query)
    ///     .onChange(of: query) { oldValue, newValue in
    ///         results = []
    ///     }
    /// ```
    ///
    /// Each build compares `value` with what the previous build found at this view.
    /// When they differ, the action receives both, after the DOM update. Pass
    /// `initial: true` to also call it when the view appears, with `value` as both
    /// arguments.
    ///
    /// The action may write state; that write schedules the next build, which
    /// compares again.
    ///
    /// The action runs only in the browser runtime. A static render never calls it.
    func onChange<V: Equatable>(
        of value: V,
        initial: Bool = false,
        _ action: @escaping (_ oldValue: V, _ newValue: V) -> Void
    ) -> LifecycleView<Self> {
        let action = EnvironmentStorage.capturing { (values: (V, V)) in action(values.0, values.1) }
        return LifecycleView(content: self) { store, path in
            store.registerChange(at: path, of: value, initial: initial) { action(($0, $1)) }
        }
    }

    /// Adds an action to perform when `value` changes, without the values.
    ///
    /// See ``onChange(of:initial:_:)-(_,_,(V,V)->Void)``.
    func onChange<V: Equatable>(
        of value: V,
        initial: Bool = false,
        _ action: @escaping () -> Void
    ) -> LifecycleView<Self> {
        let action = EnvironmentStorage.capturing(action)
        return LifecycleView(content: self) { store, path in
            store.registerChange(at: path, of: value, initial: initial) { _, _ in action() }
        }
    }
}

/// The `id` of a task that has none, so it never changes.
private struct TaskWithoutID: Equatable {}

/// A view that registers a lifecycle modifier with the mounted root.
///
/// ``View/onAppear(perform:)``, ``View/onDisappear(perform:)``,
/// ``View/task(priority:_:)``, ``View/task(id:priority:_:)`` and
/// ``View/onChange(of:initial:_:)-(_,_,(V,V)->Void)`` return it. It adds nothing to the
/// tree it lowers to.
///
/// It registers at its own structural position, so two lifecycle modifiers on one
/// view never share an entry, and a detached traversal — the label a ``Button``
/// lowers in its initializer — registers nothing.
public struct LifecycleView<Content: View>: View {
    public typealias Body = Never

    let content: Content
    let register: (ViewLifecycleStore, ViewIdentityPath) -> Void

    public var body: Never { fatalError("LifecycleView primitive body unavailable") }

    public func makeViewNode(in context: ViewContext) -> ViewNode {
        if !context.isDetached, let store = ViewLifecycleStorage.active {
            register(store, context.path)
        }
        return content.makeViewNode(in: context.content)
    }
}
