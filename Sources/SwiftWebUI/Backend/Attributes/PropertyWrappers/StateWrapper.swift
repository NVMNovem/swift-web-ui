//
//  StateWrapper.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

@propertyWrapper
public struct State<Value> {
    private final class Storage {
        var value: Value

        init(_ value: Value) {
            self.value = value
        }
    }

    private let storage: Storage

    public init(wrappedValue: Value) {
        storage = Storage(wrappedValue)
    }

    public var wrappedValue: Value {
        get { storage.value }
        nonmutating set { storage.value = newValue }
    }

    public var projectedValue: Binding<Value> {
        Binding(
            get: { storage.value },
            set: { storage.value = $0 }
        )
    }
}
