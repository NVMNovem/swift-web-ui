//
//  Binding.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

public struct Binding<Value> {
    
    private let getter: () -> Value
    private let setter: (Value) -> Void
    public var clientState: ClientStateBinding?

    public init(
        get: @escaping () -> Value,
        set: @escaping (Value) -> Void,
        clientState: ClientStateBinding? = nil
    ) {
        getter = get
        setter = set
        self.clientState = clientState
    }

    public var wrappedValue: Value {
        get { getter() }
        nonmutating set { setter(newValue) }
    }
}
