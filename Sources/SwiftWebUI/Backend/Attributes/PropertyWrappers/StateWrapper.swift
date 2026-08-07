//
//  StateWrapper.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

/// The renderer-neutral invalidation hook used by the browser runtime.
///
/// This deliberately supports one installed callback: a state write invalidates the
/// whole mounted root rather than a dependency subgraph.
@_spi(Runtime)
public enum ViewInvalidation {
    nonisolated(unsafe) private static var callback: (() -> Void)?

    public static func install(_ callback: @escaping () -> Void) {
        self.callback = callback
    }

    public static func clear() {
        callback = nil
    }

    static func invalidate() {
        callback?()
    }
}

/// View-local mutable state.
///
/// Storage is owned by the mounted root's ``StateSlotStore``, not by the view struct.
/// A view struct is rebuilt from scratch on every invalidation, so a box held inside it
/// could not survive; keying storage on the view's structural identity lets a rebuilt
/// view at the same position resolve to the same box.
///
/// Binding is lazy. A view is constructed while its *parent's* `body` runs, so at
/// construction time the ambient identity is the parent's, not its own. The first read
/// or projection happens while this view's own `body` is being evaluated, which is when
/// the correct identity is available.
///
/// Two consequences are worth knowing:
///
/// - A state that is never read or projected during `body` never binds, and reverts to
///   per-rebuild storage. Such a state cannot affect rendering, so the effect is only
///   observable through side effects in actions.
/// - When no store is installed -- static rendering, or lowering a view directly -- every
///   state falls back to a private box, which is the pre-slot behavior.
@propertyWrapper
public struct State<Value> {
    final class Storage {
        var value: Value
        init(_ value: Value) { self.value = value }
    }

    /// Indirection so a `State` copied into an escaping action closure observes the same
    /// resolved box as the view that created it.
    private final class Cell {
        var storage: Storage?
        let initialValue: Value
        let site: StateDeclarationSite

        init(initialValue: Value, site: StateDeclarationSite) {
            self.initialValue = initialValue
            self.site = site
        }
    }

    private let cell: Cell

    public init(
        wrappedValue: Value,
        file: StaticString = #fileID,
        line: UInt32 = #line,
        column: UInt32 = #column
    ) {
        cell = Cell(
            initialValue: wrappedValue,
            site: StateDeclarationSite(file: file, line: line, column: column)
        )
    }

    private var storage: Storage {
        if let storage = cell.storage { return storage }

        guard let store = StateSlotStorage.activeStore,
              let path = StateSlotStorage.activeScope
        else {
            let storage = Storage(cell.initialValue)
            cell.storage = storage
            return storage
        }

        let key = StateSlotKey(path: path, site: cell.site)
        if let slot = store.slot(for: key),
           slot.valueSize == MemoryLayout<Value>.size,
           slot.valueAlignment == MemoryLayout<Value>.alignment {
            let storage = Unmanaged<Storage>.fromOpaque(slot.pointer).takeUnretainedValue()
            cell.storage = storage
            return storage
        }

        let storage = Storage(cell.initialValue)
        store.setSlot(
            StateSlot(
                pointer: Unmanaged.passRetained(storage).toOpaque(),
                release: { Unmanaged<Storage>.fromOpaque($0).release() },
                valueSize: MemoryLayout<Value>.size,
                valueAlignment: MemoryLayout<Value>.alignment
            ),
            for: key
        )
        cell.storage = storage
        return storage
    }

    public var wrappedValue: Value {
        get { storage.value }
        nonmutating set {
            storage.value = newValue
            ViewInvalidation.invalidate()
        }
    }

    public var projectedValue: Binding<Value> {
        let storage = storage
        return Binding(
            get: { storage.value },
            set: {
                storage.value = $0
                ViewInvalidation.invalidate()
            },
            stateIdentity: StateIdentity(ObjectIdentifier(storage))
        )
    }
}
