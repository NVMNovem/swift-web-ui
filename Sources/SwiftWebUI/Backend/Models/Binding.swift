//
//  Binding.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

public struct Binding<Value> {
    private let getter: () -> Value
    private let setter: (Value) -> Void
    public let stateIdentity: StateIdentity?

    public init(
        get: @escaping () -> Value,
        set: @escaping (Value) -> Void,
        stateIdentity: StateIdentity? = nil
    ) {
        getter = get
        setter = set
        self.stateIdentity = stateIdentity
    }

    public var wrappedValue: Value {
        get { getter() }
        nonmutating set { setter(newValue) }
    }
}
