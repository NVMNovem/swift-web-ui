//
//  StateSlotStore.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 07/08/2026.
//

/// Owns `@State` boxes across rebuilds, keyed by structural view identity.
///
/// A view struct is reconstructed on every rebuild, so a box stored inside the struct
/// cannot survive. The store moves ownership out of the view and into the mount, so a
/// reconstructed view at the same structural path resolves to the same box.
///
/// A mounted root owns one store. When no store is installed -- static rendering, or a
/// view lowered directly in a test -- `State` falls back to a private box and behaves
/// exactly as it did before slots existed.
public final class StateSlotStore {
    private var slots: [StateSlotKey: StateSlot] = [:]
    private var visitedPaths: Set<ViewIdentityPath> = []
    private var isBuilding = false

    public init() {}

    // MARK: Build lifecycle

    /// Starts recording which view paths are reachable in this build.
    public func beginBuild() {
        visitedPaths = []
        isBuilding = true
    }

    /// Releases every slot whose owning view was not reached in this build.
    ///
    /// Liveness is judged by view path, not by whether a slot was read. A view that
    /// renders without touching one of its own states -- `if expanded { Text(detail) }`
    /// -- must keep that state, so sweeping on read would incorrectly reset it.
    public func endBuild() {
        guard isBuilding else { return }
        isBuilding = false
        var survivors: [StateSlotKey: StateSlot] = [:]
        survivors.reserveCapacity(slots.count)
        for (key, slot) in slots {
            if visitedPaths.contains(key.path) {
                survivors[key] = slot
            } else {
                slot.release(slot.pointer)
            }
        }
        slots = survivors
        visitedPaths = []
    }

    func markVisited(_ path: ViewIdentityPath) {
        guard isBuilding else { return }
        visitedPaths.insert(path)
    }

    // MARK: Slot access

    func slot(for key: StateSlotKey) -> StateSlot? {
        slots[key]
    }

    func setSlot(_ slot: StateSlot, for key: StateSlotKey) {
        if let existing = slots[key] {
            existing.release(existing.pointer)
        }
        slots[key] = slot
    }

    /// Releases every slot. Called when a root unmounts.
    public func releaseAll() {
        for slot in slots.values {
            slot.release(slot.pointer)
        }
        slots = [:]
        visitedPaths = []
        isBuilding = false
    }

    /// Number of live slots. Exposed for tests and diagnostics.
    public var slotCount: Int { slots.count }
}

/// Installs the active store and tracks the view scope currently being evaluated.
///
/// This mirrors `ViewInvalidation`: one installed hook, set by the mounted root. The
/// scope is the path of the view whose `body` is currently running, which is what makes
/// lazy binding resolve to the owning view rather than to its parent.
@_spi(Runtime)
public enum StateSlotStorage {
    nonisolated(unsafe) private static var store: StateSlotStore?
    nonisolated(unsafe) private static var scope: ViewIdentityPath?

    public static func install(_ store: StateSlotStore) {
        self.store = store
    }

    public static func clear() {
        store = nil
        scope = nil
    }

    static var activeStore: StateSlotStore? { store }
    static var activeScope: ViewIdentityPath? { scope }

    static func markVisited(_ path: ViewIdentityPath) {
        store?.markVisited(path)
    }

    /// Enters `path` as the current scope, returning the scope to restore afterwards.
    ///
    /// Passing `nil` suppresses binding for the duration, which is how detached
    /// traversals keep their state out of the store.
    static func beginScope(_ path: ViewIdentityPath?) -> ViewIdentityPath? {
        let previous = scope
        scope = path
        return previous
    }

    static func endScope(_ previous: ViewIdentityPath?) {
        scope = previous
    }
}
