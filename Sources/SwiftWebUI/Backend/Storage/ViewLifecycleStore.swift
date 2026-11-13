//
//  ViewLifecycleStore.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 13/11/2026.
//

// Implicit everywhere but Embedded Swift, which imports it only on request.
import _Concurrency

/// Owns what ``View/onAppear(perform:)``, ``View/onDisappear(perform:)``,
/// ``View/task(priority:_:)`` and ``View/onChange(of:initial:_:)-(_,_,(V,V)->Void)``
/// remember between builds, keyed by structural view identity.
///
/// It works the way ``StateSlotStore`` does. Each build registers the lifecycle
/// modifiers it reaches, by path. A path reached for the first time has appeared; a
/// path a build no longer reaches has disappeared. What either means — an action to
/// call, a task to start or cancel — is queued during the build and run by
/// ``commit()``, which the mounted root calls once the DOM shows that build. An action
/// therefore never runs inside a `body`, and a task never starts before its view is
/// in the document.
///
/// A mounted root owns one store. With none installed — static rendering, or a view
/// lowered directly — the modifiers register nothing and nothing runs.
@_spi(Runtime)
public final class ViewLifecycleStore {
    private var entries: [ViewIdentityPath: Entry] = [:]
    private var visitedPaths: Set<ViewIdentityPath> = []
    private var isBuilding = false
    /// Work for paths that disappeared, run before ``effects``.
    private var removals: [() -> Void] = []
    /// Work for the build's own registrations, in tree order.
    private var effects: [() -> Void] = []

    public init() {}

    /// What one lifecycle modifier remembers between builds.
    final class Entry {
        /// The latest disappear action, so it sees the values of the newest build.
        var disappear: (() -> Void)?
        /// Cancels the running task, if there is one.
        var cancel: (() -> Void)?
        /// The task's `id` or the observed `onChange` value, boxed.
        var value: AnyObject?
    }

    final class Box<Value> {
        let value: Value
        init(_ value: Value) { self.value = value }
    }

    // MARK: Build lifecycle

    /// Starts recording which lifecycle modifiers this build reaches.
    public func beginBuild() {
        visitedPaths = []
        isBuilding = true
    }

    /// Queues the disappearance of every modifier this build did not reach.
    public func endBuild() {
        guard isBuilding else { return }
        isBuilding = false
        var survivors: [ViewIdentityPath: Entry] = [:]
        survivors.reserveCapacity(entries.count)
        for (path, entry) in entries {
            if visitedPaths.contains(path) {
                survivors[path] = entry
            } else {
                queueDisappearance(of: entry)
            }
        }
        entries = survivors
        visitedPaths = []
    }

    /// Runs what the last build queued: disappearances first, then appearances,
    /// task starts and changes in the order the build reached them.
    ///
    /// An action may write state. That schedules another build rather than running
    /// one, so work queued by that build waits for its own commit.
    public func commit() {
        let due = removals + effects
        removals = []
        effects = []
        for work in due {
            work()
        }
    }

    /// Ends everything: every disappear action runs and every task is cancelled.
    /// Called when a root unmounts.
    public func removeAll() {
        for entry in entries.values {
            queueDisappearance(of: entry)
        }
        entries = [:]
        visitedPaths = []
        isBuilding = false
        effects = []
        commit()
    }

    /// Number of live entries. Exposed for tests and diagnostics.
    public var entryCount: Int { entries.count }

    private func queueDisappearance(of entry: Entry) {
        let disappear = entry.disappear
        let cancel = entry.cancel
        entry.cancel = nil
        removals.append {
            cancel?()
            disappear?()
        }
    }

    // MARK: Registration

    /// The entry at `path`, and whether this build is the first to reach it.
    private func entry(at path: ViewIdentityPath) -> (Entry, isNew: Bool) {
        if isBuilding {
            visitedPaths.insert(path)
        }
        if let existing = entries[path] {
            return (existing, false)
        }
        let entry = Entry()
        entries[path] = entry
        return (entry, true)
    }

    func registerAppear(at path: ViewIdentityPath, perform action: @escaping () -> Void) {
        if entry(at: path).isNew {
            effects.append(action)
        }
    }

    func registerDisappear(at path: ViewIdentityPath, perform action: @escaping () -> Void) {
        entry(at: path).0.disappear = action
    }

    func registerTask<ID: Equatable>(
        at path: ViewIdentityPath,
        id: ID,
        priority: TaskPriority?,
        action: @escaping () async -> Void
    ) {
        let (entry, isNew) = entry(at: path)
        if !isNew, let previous = entry.value as? Box<ID>, previous.value == id {
            return
        }
        entry.value = Box(id)
        effects.append {
            entry.cancel?()
            let operation = UncheckedOperation(action)
            let task = Task(priority: priority) {
                await operation.body()
            }
            entry.cancel = { task.cancel() }
        }
    }

    func registerChange<Value: Equatable>(
        at path: ViewIdentityPath,
        of value: Value,
        initial: Bool,
        action: @escaping (Value, Value) -> Void
    ) {
        let (entry, isNew) = entry(at: path)
        guard !isNew, let previous = entry.value as? Box<Value> else {
            entry.value = Box(value)
            if initial {
                effects.append { action(value, value) }
            }
            return
        }
        guard previous.value != value else { return }
        entry.value = Box(value)
        let oldValue = previous.value
        effects.append { action(oldValue, value) }
    }
}

/// Carries a task's operation into `Task.init`, which wants a sendable closure.
///
/// Unchecked because a mounted root, its views and every task they start all live on
/// the browser's one thread, as ``ViewInvalidation`` and ``EnvironmentStorage``
/// already assume.
private struct UncheckedOperation: @unchecked Sendable {
    let body: () async -> Void

    init(_ body: @escaping () async -> Void) {
        self.body = body
    }
}

/// Installs the active lifecycle store, as ``StateSlotStorage`` installs the state store.
@_spi(Runtime)
public enum ViewLifecycleStorage {
    nonisolated(unsafe) private static var store: ViewLifecycleStore?

    public static func install(_ store: ViewLifecycleStore) {
        self.store = store
    }

    public static func clear() {
        store = nil
    }

    static var active: ViewLifecycleStore? { store }
}
