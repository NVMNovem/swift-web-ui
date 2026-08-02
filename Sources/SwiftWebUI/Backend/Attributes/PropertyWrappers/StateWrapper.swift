//
//  StateWrapper.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

/// The renderer-neutral invalidation hook used by the first browser runtime.
///
/// This deliberately supports one installed callback. A future mounted state-slot
/// system will replace this proof-of-concept mechanism.
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

@propertyWrapper
public struct State<Value> {
    private final class Storage {
        var value: Value
        init(_ value: Value) { self.value = value }
    }

    private let storage: Storage

    public init(wrappedValue: Value) {
        storage = Storage(wrappedValue)
    }

    public var wrappedValue: Value {
        get { storage.value }
        nonmutating set {
            storage.value = newValue
            ViewInvalidation.invalidate()
        }
    }

    public var projectedValue: Binding<Value> {
        Binding(
            get: { storage.value },
            set: {
                storage.value = $0
                ViewInvalidation.invalidate()
            },
            stateIdentity: StateIdentity(ObjectIdentifier(storage))
        )
    }
}
