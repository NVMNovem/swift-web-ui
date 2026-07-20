//
//  ClientStateValue.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 28/06/2026.
//

public enum ClientValue: Hashable, Sendable {
    case string(String)
    case integer(Int)
    case boolean(Bool)
}

public protocol ClientStateValue {
    var clientValue: ClientValue { get }
}

extension String: ClientStateValue {
    public var clientValue: ClientValue { .string(self) }
}

extension Int: ClientStateValue {
    public var clientValue: ClientValue { .integer(self) }
}

extension Bool: ClientStateValue {
    public var clientValue: ClientValue { .boolean(self) }
}

func clientValue<Value: ClientStateValue>(_ value: Value) -> ClientValue {
    value.clientValue
}

func clientValue<Value: RawRepresentable>(_ value: Value) -> ClientValue
where Value.RawValue == String {
    .string(value.rawValue)
}

func clientValue<Value: RawRepresentable>(_ value: Value) -> ClientValue
where Value.RawValue == Int {
    .integer(value.rawValue)
}
